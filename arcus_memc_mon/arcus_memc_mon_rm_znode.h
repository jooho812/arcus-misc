#ifndef ARCUS_MEMC_MON_RM_ZNODE_H
#define ARCUS_MEMC_MON_RM_ZNODE_H

#define ORG_MEMC_NODE  0
#define REP_MEMC_NODE  1
#define NDF_MEMC_NODE -1

#define NODE_EXIST 1
#define NODE_NOT_EXIST 0

int zk_get_memc_node_type(char *address);
int zk_rm_znode(char *address, int node_type);
int zk_check_exist(char *address, int node_type);
int zk_arcus_mon_init(char *zk, char *proc_name, int sys_log);
void zk_arcus_mon_free();

#endif /* ARCUS_MEMC_MON_RM_ZNODE_H */
