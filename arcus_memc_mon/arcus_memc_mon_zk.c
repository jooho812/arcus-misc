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
#include "arcus_memc_mon_zk.h"

#define ZK_DEFAULT_SESSION_TIMEOUT  100000
#define DEFAULT_ZK_ESEMBLE          "127.0.0.1:2181"

#define MASTER_NODE 1
#define SLAVE_NODE  0

zhandle_t   *zh = NULL;
char        *zk_esemble = DEFAULT_ZK_ESEMBLE;
int         zk_session_timeout = ZK_DEFAULT_SESSION_TIMEOUT; /* msec */
clientid_t  myid;

int         connected = 0;
int         expired = 0;

static int  use_syslog = 0;

const char  *zk_root             = "/arcus";
const char  *zk_repl_root        = "/arcus_repl";
const char  *zk_map_path         = "cache_server_mapping"; 
const char  *zk_cache_path       = "cache_list";
#if YSKIM_REPL_ZK_NODE
const char  *zk_repl_group_path  = "group_list";
#else
const char  *zk_repl_group_path  = "cache_server_group";
#endif

#define ZK_ERR_LOG(rc, path) \
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
    if (zh)
        zookeeper_close(zh);
}

/*
 * return success 0, fail -1
 */
int
get_host(char *address, char *host_name)
{
    in_addr_t            in_addr;
    struct hostent       *host;
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

    in_addr = inet_addr(ip);
    host = gethostbyaddr(&in_addr, sizeof(in_addr), AF_INET);
    if (host == NULL) {
        if (strcmp(getenv("ARCUS_CACHE_PUBLIC_IP"), ip) == 0) {
            in_addr = inet_addr("127.0.0.1");
            host = gethostbyaddr(&in_addr, sizeof(in_addr), AF_INET);

            strcpy(host_name, host->h_name);
        } else if (gethostname(host_name, 36) < 0) {
            PRINT_LOG_ERR("host name get error. gethostbyaddr");
            free(addr_buf);

            return -1;
        }
    } else {
        strcpy(host_name, host->h_name);
    }
    free(addr_buf);

    return 0;
}

/* 
 * return success mapping_info_t, fail NULL
 */
mapping_info_t*
zk_get_node_mapping_info(char *address)
{
    int                   i;

    char                  znode_path[ZNODE_PATH_LEN];
    char                  znode_repl_path[ZNODE_PATH_LEN];
    mapping_info_t        *mapping_info = NULL;

    int                   rc = 0;
    struct String_vector  str_v = {0, NULL};
    struct Stat           stat;
    char                  get_buf[10];
    int                   get_lbuf;

    char                  *mapping_str = NULL;
    char                  *last_buf = NULL;
    char                  svc[32];
    char                  group_name[32];
    char                  host_name[256]; /* max hostname size is 256 bytes, but gethostname return max 36 bytes */

    mapping_info = (mapping_info_t*)malloc(sizeof(mapping_info_t));
    memset(mapping_info, 0, sizeof(mapping_info_t));

    /* 
     * find znode that match address
     * /arcus/cache_server_mapping/ip:port/{svc}
     * /arcus_repl/cache_server_mapping/ip:port/{svc}^{group}^{listen_ip:port}
     */
    snprintf(znode_path, ZNODE_PATH_LEN, "%s/%s/%s", zk_root, zk_map_path, address);
    snprintf(znode_repl_path, ZNODE_PATH_LEN, "%s/%s/%s", zk_repl_root, zk_map_path, address);
    if (zoo_exists(zh, znode_path, 0, NULL) == ZOK)
        mapping_info->node_type = ORG_MEMC_NODE;
    else if (zoo_exists(zh, znode_repl_path, 0, NULL) == ZOK)
        mapping_info->node_type = REP_MEMC_NODE;
    else {
        free(mapping_info);
        return NULL;
    }

    rc = zoo_get_children(zh, mapping_info->node_type == REP_MEMC_NODE ? znode_repl_path : znode_path, 0, &str_v);
    if (rc != ZOK || str_v.count == 0) {
        ZK_ERR_LOG(rc, mapping_info->node_type == REP_MEMC_NODE ? znode_repl_path : znode_path);
        free(mapping_info);
        deallocate_String_vector(&str_v);
        return NULL;
    }

    if (mapping_info->node_type == REP_MEMC_NODE) {
        /* mapping_str == {svc}^{group}^{listen_ip:port} */
        mapping_str = strdup(str_v.data[0]);

        strcpy(svc, strtok_r(mapping_str, "^", &last_buf)); 
        strcpy(group_name, strtok_r(NULL, "^", &last_buf));

        free(mapping_str);
    } else {
        /* mapping_str == {svc} */
        strcpy(svc, str_v.data[0]);
    }
    deallocate_String_vector(&str_v);

    if (mapping_info->node_type == REP_MEMC_NODE) {
#if YSKIM_REPL_ZK_NODE
        /* 
         * find group list path 
         * /arcus_repl/group_list/{svc}/{group}
         */ 
        snprintf(znode_path, ZNODE_PATH_LEN,
                 "%s/%s/%s/%s",
                 zk_repl_root, zk_repl_group_path, svc, group_name);
#else
        /* 
         * find group list path 
         * /arcus_repl/cache_server_group/{svc}/{group}/lock
         */ 
        snprintf(znode_path, ZNODE_PATH_LEN,
                 "%s/%s/%s/%s/lock",
                 zk_repl_root, zk_repl_group_path, svc, group_name);
#endif
        rc = zoo_get_children(zh, znode_path, 0, &str_v);
        if (rc != ZOK) {
            ZK_ERR_LOG(rc, znode_path);
            deallocate_String_vector(&str_v);
            free(mapping_info);
            return NULL;
        }

        for (i = 0; i < str_v.count; i++) {
            if (strstr(str_v.data[i], address) != NULL)
                break;
        }

        if (str_v.count == 0 || i == str_v.count) {
            ZK_ERR_LOG(rc, znode_path);
            deallocate_String_vector(&str_v);
            free(mapping_info);
            return NULL;
        }

#if YSKIM_REPL_ZK_NODE
        /*
         * make group list path
         * /arcus_repl/group_list/{svc}/{group}/{ip:port}^{listen_ip:port}^seq
         */
        snprintf(mapping_info->group_list_path, ZNODE_PATH_LEN,
                 "%s/%s/%s/%s/%s",
                 zk_repl_root, zk_repl_group_path, svc, group_name, str_v.data[i]);
#else
        /*
         * make group list path
         * /arcus_repl/cache_server_group/{svc}/{group}/lock/{ip:port}^{listen_ip:port}^seq
         */
        snprintf(mapping_info->group_list_path, ZNODE_PATH_LEN,
                 "%s/%s/%s/%s/lock/%s",
                 zk_repl_root, zk_repl_group_path, svc, group_name, str_v.data[i]);
#endif
        deallocate_String_vector(&str_v);
    }

    /* make cache list path */ 
    if (get_host(address, host_name) < 0) {
        PRINT_LOG_ERR("Can't find hostnamen");
        free(mapping_info);
        return NULL;
    }

    /* don't make cache list for replication node */
    if (mapping_info->node_type == ORG_MEMC_NODE) {
        /*
         * /arcus/cache_list/{svc}/{ip:port-hostname}
         */
        snprintf(mapping_info->cache_list_path, ZNODE_PATH_LEN,
                 "%s/%s/%s/%s-%s",
                 zk_root, zk_cache_path, svc, address, host_name);
    }

    /* get ephemeralOwner of znode */
    rc = zoo_get(zh, mapping_info->node_type == REP_MEMC_NODE ? mapping_info->group_list_path :
                                                                mapping_info->cache_list_path, 0, get_buf, &get_lbuf, &stat);
    if (rc != ZOK) {
        ZK_ERR_LOG(rc, mapping_info->node_type == REP_MEMC_NODE ? mapping_info->group_list_path :
                                                                  mapping_info->cache_list_path);
        free(mapping_info);
        return NULL;
    }
    mapping_info->ephemeralOwner = stat.ephemeralOwner;
 
    return mapping_info;
}

/*
 * return success 0, fail -1
 */
int
zk_rm_init_group_matched_node(mapping_info_t *mapping_info, zoo_op_t *op)
{
    int                   rc = 0;
    struct Stat           stat;
    char                  get_buf[10];
    int                   get_lbuf;

    /* check ephemeralOwner */
    rc = zoo_get(zh, mapping_info->group_list_path, 0, get_buf, &get_lbuf, &stat);
    if (rc != ZOK) {
        ZK_ERR_LOG(rc, mapping_info->group_list_path);
        return -1;
    }

    if (mapping_info->ephemeralOwner != stat.ephemeralOwner)
        return -1;

    zoo_delete_op_init(op, mapping_info->group_list_path, -1);

    return 0;
}

/*
 * return success 0, fail -1
 */
int
zk_rm_init_cache_list(mapping_info_t *mapping_info, zoo_op_t *op)
{
    int                   i;
    int                   rc = 0;
    struct Stat           stat;
    char                  get_buf[10];
    int                   get_lbuf;

    struct String_vector  str_v = {0, NULL};
    char                  znode_path[ZNODE_PATH_LEN];
 
    /* if replication node
     * then make cache list znode path
     */
    if (mapping_info->node_type == REP_MEMC_NODE) {
        /* get address and service code*/
        char org[128];
        char *temp, *last_buf;
        char *svc, *address;
        
        strcpy(org, mapping_info->group_list_path);
        strtok_r(org, "/", &last_buf);
        strtok_r(NULL, "/", &last_buf);
        svc = strtok_r(NULL, "/", &last_buf);
        strtok_r(NULL, "/", &last_buf);
        temp = strtok_r(NULL, "/", &last_buf);
        address = strtok_r(temp, "^", &last_buf);
        /*
         * /arcus_repl/cache_list/{svc}/{group}^{M/S}^{ip:port-hostname}
         */
        snprintf(znode_path, ZNODE_PATH_LEN, "%s/%s/%s", zk_repl_root, zk_cache_path, svc);
        rc = zoo_get_children(zh, znode_path, 0, &str_v);
        if (rc != ZOK) {
            ZK_ERR_LOG(rc, znode_path);
            deallocate_String_vector(&str_v);
            return -1;
        }

        for (i = 0; i < str_v.count; i++) {
            if (strstr(str_v.data[i], address) != NULL) 
                break;
        }

        if (str_v.count == 0 || i == str_v.count) {
            ZK_ERR_LOG(ZNONODE, znode_path);
            deallocate_String_vector(&str_v);
            return -1;
        }

        snprintf(mapping_info->cache_list_path, ZNODE_PATH_LEN, "%s/%s/%s/%s", zk_repl_root, zk_cache_path, svc, str_v.data[i]);
        deallocate_String_vector(&str_v);
    }

    /* check ephemeralOwner */
    rc = zoo_get(zh, mapping_info->cache_list_path, 0, get_buf, &get_lbuf, &stat);
    if (rc != ZOK) {
        ZK_ERR_LOG(rc, mapping_info->cache_list_path);
        return -1;
    }

    if (mapping_info->ephemeralOwner != stat.ephemeralOwner)
        return -1;

    zoo_delete_op_init(op, mapping_info->cache_list_path, -1);

    return 0;
}

/*
 * return success 0, fail -1
 */
int
zk_rm_znode(mapping_info_t *mapping_info)
{
#define RM_ZNODE_OP_COUNT 2
    zoo_op_t             ops[RM_ZNODE_OP_COUNT];
    zoo_op_result_t      results[RM_ZNODE_OP_COUNT];
    int                  i, rc = -1;
    int                  op_count = 0;

    do {
        /*
         * get cache_server_group children znode
         * find matched znode
         * delete matched znode
         */
        if (mapping_info->node_type == REP_MEMC_NODE &&
            zk_rm_init_group_matched_node(mapping_info, &ops[op_count]) < 0)
            break;
        else
            op_count++;

        /*
         * find and delete cache_list znode
         * /arcus/cache_list/{svc}/{ip:port-hostname}
         * /arcus_repl/cache_list/{svc}/{group}^{M/S}^{ip:port-hostname}
         */
            if (zk_rm_init_cache_list(mapping_info, &ops[op_count]) < 0)
                break;
            else
                op_count++;

        if (op_count > 0 && (rc = zoo_multi(zh, op_count, ops, results)) == ZOK) {
            if (mapping_info->node_type == REP_MEMC_NODE) {
                PRINT_LOG_INFO("Delete cache server group znode : %s\n", ops[0].delete_op.path);
                PRINT_LOG_INFO("Delete cache list znode : %s\n", ops[1].delete_op.path);
            } else {
                PRINT_LOG_INFO("Delete cache list znode : %s\n", ops[0].delete_op.path);
            }
            rc = 0;
        } else {
            ZK_ERR_LOG(rc, "zoo_multi");
            for (i = 0; i < op_count; i++)
                ZK_ERR_LOG(results[i].err, ops[i].delete_op.path);
            rc = -1;
        }
    } while (0);

    return rc;
}
