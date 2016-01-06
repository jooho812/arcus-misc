#ifndef ARCUS_MEMC_MON_RM_ZNODE_H
#define ARCUS_MEMC_MON_RM_ZNODE_H

/*
 * non replication is  ORG_MEMC_NODE
 * replication is      REP_MEMC_NODE
 */
#define ORG_MEMC_NODE  0
#define REP_MEMC_NODE  1

#define ZNODE_PATH_LEN 1024

typedef struct MAPPING_INFO {
    int             node_type;
    char            cache_list_path[ZNODE_PATH_LEN];
    char            group_list_path[ZNODE_PATH_LEN];
    long long int   ephemeralOwner;
} mapping_info_t;

mapping_info_t * zk_get_node_mapping_info(char *address);
int zk_rm_znode(mapping_info_t *mapping_info);
int zk_arcus_mon_init(char *zk, char *proc_name, int sys_log);
void zk_arcus_mon_free();

#endif /* ARCUS_MEMC_MON_RM_ZNODE_H */
