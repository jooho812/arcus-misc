#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <netdb.h>
#include <syslog.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <zookeeper.h>

#define YSKIM_REPL_ZK_NODE 1

#include "arcus_memc_mon_logger.h"
#include "arcus_memc_mon_rm_znode.h"

typedef struct REPL_MAPPING_INFO {
    char   svc[32];
    char   group_name[32];
    char   listen_addr[32];
} repl_mapping_info_t;

#define ZNODE_PATH_LEN              1024
#define ZK_DEFAULT_SESSION_TIMEOUT  100000
#define DEFAULT_ZK_ESEMBLE          "127.0.0.1:2181"

zhandle_t   *zh = NULL;
char        *zk_esemble = DEFAULT_ZK_ESEMBLE;
int         zk_session_timeout = ZK_DEFAULT_SESSION_TIMEOUT; /* msec */
clientid_t  myid;

int         connected = 0;
int         expired = 0;

static int  use_syslog = 0;

struct sockaddr_in   myaddr;
struct hostent       *host;

const char  *zk_root             = "/arcus";
const char  *zk_cache_path       = "cache_list";
const char  *zk_map_path         = "cache_server_mapping"; 
const char  *zk_repl_root        = "/arcus_repl";
#if YSKIM_REPL_ZK_NODE
const char  *zk_repl_group_path  = "group_list";
#else
const char  *zk_repl_group_path  = "cache_server_group";
#endif

#define ZK_RM_ZNODE_ERR_LOG(rc, path) \
        PRINT_LOG_NOTI("Zookeeper error. zpath=%s, error=%d(%s), %s:%d\n", path, rc, zerror(rc), __FILE__, __LINE__)

void
zk_handle_watcher(zhandle_t *wzh, int type, int state, const char *path, void *context)
{
    if (type == ZOO_SESSION_EVENT) {
        if (state == ZOO_CONNECTED_STATE) {
            const clientid_t *id = zoo_client_id(wzh);

            if (myid.client_id == 0 || myid.client_id != id->client_id) {
                myid = *id;
            }
            connected = 1;

        } else if (state == ZOO_CONNECTING_STATE) {
            connected = 0;
        } else if (state == ZOO_EXPIRED_SESSION_STATE) {
            connected = 0;

            if (zh)
                zookeeper_close(zh);
            zh = zookeeper_init(zk_esemble, zk_handle_watcher, zk_session_timeout, &myid, 0, 0);
        }
    } 
}

int
zk_arcus_mon_init(char *zk, char *proc_name, int sys_log)
{
    use_syslog = sys_log;
    zoo_forward_logs_to_syslog(proc_name, use_syslog);

    zoo_set_debug_level(ZOO_LOG_LEVEL_INFO);
    zh = zookeeper_init(zk == NULL ? zk_esemble : zk, zk_handle_watcher, zk_session_timeout, &myid, 0, 0);

    /*
     * zookeeper_init is asynchronous
     * until wait session is connected
     */
    while (connected == 0)
        usleep(1);

    if (!zh) {
        PRINT_LOG_ERR("Zookeeper init error. zookeeper_init");
        return -1;
    }

    return 0;
}

void
zk_arcus_mon_free()
{
    if (!zh)
        zookeeper_close(zh);
}

/* 
 * return memcached node type
 *        non replication is  ORG_MEMC_NODE
 *        replication is      REP_MEMC_NODE
 *        error               NDF_MEMC_NODE
 */
int
zk_get_memc_node_type(char *address)
{
    int      node_type = 0;
    char     znode_path[ZNODE_PATH_LEN];
    char     znode_repl_path[ZNODE_PATH_LEN];

    /* 
     * non repl znode
     * /arcus/cache_server_mapping/ip:port/{svc}
     * repl znode
     * /arcus_repl/cache_server_mapping/ip:port/{svc}^{group}^{listen_ip:port}
     */
    snprintf(znode_path, ZNODE_PATH_LEN, "%s/%s/%s", zk_root, zk_map_path, address);
    snprintf(znode_repl_path, ZNODE_PATH_LEN, "%s/%s/%s", zk_repl_root, zk_map_path, address);

    if (zoo_exists(zh, znode_path, 0, NULL) == ZOK)
        node_type = ORG_MEMC_NODE;
    else if (zoo_exists(zh, znode_repl_path, 0, NULL) == ZOK)
        node_type = REP_MEMC_NODE;
    else
        node_type = NDF_MEMC_NODE;

    return node_type;
}

/*
 * return success repl_mapping_info_t, fail NULL
 */
repl_mapping_info_t *
zk_get_svc_group(char *address, int node_type)
{
    repl_mapping_info_t   *mapping_info = NULL;
    struct String_vector  str_v = {0, NULL};
    char                  znode_path[ZNODE_PATH_LEN];
    char                  *mapping_str = NULL;
    char                  *last_buf = NULL;
    int                   rc = 0;

    /*
     * /arcus/cache_server_mapping/ip:port/{svc}
     * or
     * /arcus_repl/cache_server_mapping/ip:port/{svc}^{group}^{listen_ip:port}
     */
    snprintf(znode_path, ZNODE_PATH_LEN, "%s/%s/%s",
            node_type == REP_MEMC_NODE ? zk_repl_root : zk_root, zk_map_path, address);

    rc = zoo_get_children(zh, znode_path, 0, &str_v);
    if (rc != ZOK) {
        ZK_RM_ZNODE_ERR_LOG(rc, znode_path);
        deallocate_String_vector(&str_v);
        return NULL;
    } else if (str_v.count == 0) {
        ZK_RM_ZNODE_ERR_LOG(rc, znode_path);
        deallocate_String_vector(&str_v);
        return NULL;
    }


    mapping_info = (repl_mapping_info_t*)malloc(sizeof(repl_mapping_info_t));
    memset(mapping_info, 0, sizeof(repl_mapping_info_t));

    if (node_type) {
        /* mapping_str == {svc}^{group}^{listen_ip:port} */
        mapping_str = strdup(str_v.data[0]);

        strcpy(mapping_info->svc, strtok_r(mapping_str, "^", &last_buf)); 
        strcpy(mapping_info->group_name, strtok_r(NULL, "^", &last_buf));
        strcpy(mapping_info->listen_addr, last_buf);

        free(mapping_str);
    } else {
        strcpy(mapping_info->svc, str_v.data[0]);
    }

    deallocate_String_vector(&str_v);

    return mapping_info;
}

/*
 * return success 0, fail -1
 */
int
zk_rm_init_group_matched_node(char *address, repl_mapping_info_t *mapping_info, zoo_op_t *op, char *op_path)
{
    int         i = 0, rc = 0;
    char        znode_path[ZNODE_PATH_LEN];

    struct String_vector str_v = {0, NULL};

#if YSKIM_REPL_ZK_NODE
    snprintf(znode_path, ZNODE_PATH_LEN, "%s/%s/%s/%s",
            zk_repl_root, zk_repl_group_path, mapping_info->svc, mapping_info->group_name);
#else
    snprintf(znode_path, ZNODE_PATH_LEN, "%s/%s/%s/%s/lock",
            zk_repl_root, zk_repl_group_path, mapping_info->svc, mapping_info->group_name);
#endif

    /* get */
    rc = zoo_get_children(zh, znode_path, 0, &str_v);
    if (rc != ZOK) {
        ZK_RM_ZNODE_ERR_LOG(rc, znode_path);
        deallocate_String_vector(&str_v);
        return -1;
    }

#if YSKIM_REPL_ZK_NODE
    /*
     * find matched znode
     * /arcus_repl/cache_server_group/{svc}/{group}/{ip:port}^{listen_ip:port}^seq
     */
#else
    /*
     * find matched znode
     * /arcus_repl/cache_server_group/{svc}/{group}/lock/{ip:port}^{listen_ip:port}^seq
     */
#endif
    for (i = 0; i < str_v.count; i++) {
        if (strstr(str_v.data[i], address) != NULL)
            break;
    }

    if (str_v.count == 0 || i == str_v.count) {
        ZK_RM_ZNODE_ERR_LOG(rc, znode_path);
        deallocate_String_vector(&str_v);
        return -1;
    }

#if YSKIM_REPL_ZK_NODE
    /*
     * delete matched znode
     * /arcus_repl/cache_server_group/{svc}/{group}/{ip:port}^{listen_ip:port}^seq
     */
    snprintf(op_path, ZNODE_PATH_LEN, "%s/%s/%s/%s/%s",
            zk_repl_root, zk_repl_group_path, mapping_info->svc, mapping_info->group_name, str_v.data[i]);
#else
    /*
     * delete matched znode
     * /arcus_repl/cache_server_group/{svc}/{group}/lock/{ip:port}^{listen_ip:port}^seq
     */
    snprintf(op_path, ZNODE_PATH_LEN, "%s/%s/%s/%s/lock/%s",
            zk_repl_root, zk_repl_group_path, mapping_info->svc, mapping_info->group_name, str_v.data[i]);
#endif

    zoo_delete_op_init(op, op_path, -1);

    deallocate_String_vector(&str_v);

    return 0;
}

/*
 * return success 0, fail -1
 */
int
zk_rm_init_cache_list(char *address, int node_type, repl_mapping_info_t *mapping_info, zoo_op_t *op, char *op_path)
{
    int         i = 0, rc = 0;
    char        znode_path[ZNODE_PATH_LEN];
    char        memc_mnode_name[ZNODE_PATH_LEN];
    char        memc_snode_name[ZNODE_PATH_LEN];
    char        memc_node_name[ZNODE_PATH_LEN];

    struct String_vector str_v = {0, NULL};

    /*
     * /arcus/cache_list/{svc}/{ip:port-hostname}"
     * or
     * /arcus_repl/cache_list/{svc}/{group}^{M/S}^{ip:port-hostname}
     */
    snprintf(znode_path, ZNODE_PATH_LEN, "%s/%s/%s",
            node_type == REP_MEMC_NODE ? zk_repl_root : zk_root, zk_cache_path, mapping_info->svc);
    rc = zoo_get_children(zh, znode_path, 0, &str_v);

    if (rc != ZOK) {
        ZK_RM_ZNODE_ERR_LOG(rc, znode_path);
        deallocate_String_vector(&str_v);
        return -1;
    }

    if (node_type) {
        snprintf(memc_mnode_name, ZNODE_PATH_LEN, "%s^%s^%s-%s",
                mapping_info->group_name, "M", address, host->h_name);
        snprintf(memc_snode_name, ZNODE_PATH_LEN, "%s^%s^%s-%s",
                mapping_info->group_name, "S", address, host->h_name);

        for (i = 0; i < str_v.count; i++) {
            if (strstr(str_v.data[i], memc_mnode_name) != NULL || 
                    strstr(str_v.data[i], memc_snode_name) != NULL)
                break;
        }
    } else {
        snprintf(memc_node_name, ZNODE_PATH_LEN, "%s-%s", address, host->h_name);
        for (i = 0; i < str_v.count; i++) {
            if (strstr(str_v.data[i], memc_node_name) != NULL)
                break;
        }
    }

    if (str_v.count == 0 || i == str_v.count) {
        ZK_RM_ZNODE_ERR_LOG(ZNONODE, znode_path);
        deallocate_String_vector(&str_v);
        return -1;
    }

    snprintf(op_path, ZNODE_PATH_LEN, "%s/%s/%s/%s",
            node_type == REP_MEMC_NODE ? zk_repl_root : zk_root, zk_cache_path, mapping_info->svc, str_v.data[i]);

    zoo_delete_op_init(op, op_path, -1);

    deallocate_String_vector(&str_v);

    return 0;
}

/*
 * return success 0, fail -1
 */
int
get_host_name(char *address)
{
    char *addr_buf = NULL, *ip = NULL;

    addr_buf = strdup(address);
    if (addr_buf == NULL) {
        PRINT_LOG_ERR("address buffer allocation error to get host name. strdup");

        return -1;
    }

    ip = strtok(addr_buf, ":");
    if (ip == NULL) {
        PRINT_LOG_NOTI("The address to get host name is not ip:port format.\n");
        free(addr_buf);
        
        return -1;
    }

    memset(&myaddr, 0, sizeof(myaddr));
    myaddr.sin_addr.s_addr = inet_addr(ip);

    host = gethostbyaddr((char*)&myaddr.sin_addr.s_addr, 
            sizeof(myaddr.sin_addr.s_addr), AF_INET);
    if (host == NULL) {
        PRINT_LOG_ERR("host name get error. gethostbyaddr");
        free(addr_buf);

        return -1;
    }

    free(addr_buf);

    return 0;
}

/*
 * return success 0, fail -1
 */
int
zk_rm_znode(char *address, int node_type)
{
#define RM_ZNODE_OP_COUNT 2
    repl_mapping_info_t  *mapping_info = NULL;
    zoo_op_t             ops[RM_ZNODE_OP_COUNT];
    char                 op_path[RM_ZNODE_OP_COUNT][ZNODE_PATH_LEN];
    zoo_op_result_t      results[RM_ZNODE_OP_COUNT];
    int                  i, rc = -1;

    /* get host name by ip address */
    if (get_host_name(address) < 0)
        return rc;

    do {
        /* get service code and group name */
        if ((mapping_info = zk_get_svc_group(address, node_type)) == NULL)
            break;

        /*
         * get cache_server_group children znode
         * find matched znode
         * delete matched znode
         */
        if (node_type == REP_MEMC_NODE &&
            zk_rm_init_group_matched_node(address, mapping_info, &ops[0], op_path[0]) < 0)
            break;

        /*
         * find and delete cache_list znode
         * /arcus_repl/cache_list/{svc}/{group}^{M/S}^{ip:port-hostname}
         */
        if (zk_rm_init_cache_list(address, node_type, mapping_info, &ops[1], op_path[1]) < 0)
            break;

        if ((rc = zoo_multi(zh, RM_ZNODE_OP_COUNT, ops, results)) == ZOK) {
            PRINT_LOG_INFO("Delete cache server group znode : %s\n", ops[0].delete_op.path);
            PRINT_LOG_INFO("Delete cache list znode : %s\n", ops[1].delete_op.path);
            rc = 0;
        } else {
            ZK_RM_ZNODE_ERR_LOG(rc, "zoo_multi");
            for (i = 0; i < RM_ZNODE_OP_COUNT; i++)
                ZK_RM_ZNODE_ERR_LOG(results[i].err, op_path[i]);
            rc = -1;
        }
    } while (0);
     
    if (mapping_info != NULL)
        free(mapping_info);

    return rc;
}

/*
 * return : if exist 1, not 0, error -1
 */
int
zk_check_exist(char *address, int node_type)
{
    repl_mapping_info_t  *mapping_info = NULL;

    int         i = 0, rc = 0, exist_node = NODE_NOT_EXIST;
    char        znode_path[ZNODE_PATH_LEN];
    char        memc_mnode_name[ZNODE_PATH_LEN];
    char        memc_snode_name[ZNODE_PATH_LEN];
    char        memc_node_name[ZNODE_PATH_LEN];

    struct String_vector str_v = {0, NULL};

    /* get host name by ip address */
    if (get_host_name(address) < 0)
        return -1;

    do {
        /* get service code and group name */
        if ((mapping_info = zk_get_svc_group(address, node_type)) == NULL)
            break;

        /*
         * /arcus/cache_list/{svc}/{ip:port-hostname}"
         * or
         * /arcus_repl/cache_list/{svc}/{group}^{M/S}^{ip:port-hostname}
         */
        snprintf(znode_path, ZNODE_PATH_LEN, "%s/%s/%s",
                node_type == REP_MEMC_NODE ? zk_repl_root : zk_root, zk_cache_path, mapping_info->svc);
        rc = zoo_get_children(zh, znode_path, 0, &str_v);

        if (rc == ZNONODE) {
            break;
        } else if (rc != ZOK) {
            ZK_RM_ZNODE_ERR_LOG(rc, znode_path);
            break;
        }

        if (node_type) {
            snprintf(memc_mnode_name, ZNODE_PATH_LEN, "%s^%s^%s-%s",
                    mapping_info->group_name, "M", address, host->h_name);
            snprintf(memc_snode_name, ZNODE_PATH_LEN, "%s^%s^%s-%s",
                    mapping_info->group_name, "S", address, host->h_name);

            for (i = 0; i < str_v.count; i++) {
                if (strstr(str_v.data[i], memc_mnode_name) != NULL || 
                        strstr(str_v.data[i], memc_snode_name) != NULL) {
                    exist_node = NODE_EXIST;
                    break;
                }
            }
        } else {
            snprintf(memc_node_name, ZNODE_PATH_LEN, "%s-%s", address, host->h_name);
            for (i = 0; i < str_v.count; i++) {
                if (strstr(str_v.data[i], memc_node_name) != NULL) {
                    exist_node = NODE_EXIST;
                    break;
                }
            }
        }

    } while (0);

    if (mapping_info != NULL)
        free(mapping_info);

    deallocate_String_vector(&str_v);

    return exist_node;
}
