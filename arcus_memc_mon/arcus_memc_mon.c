#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/types.h>
#include <dirent.h>
#include <syslog.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <pthread.h>
#include <sys/inotify.h>
#include <sys/stat.h>

#include "arcus_memc_mon_logger.h"
#include "arcus_memc_mon_zk.h"

#define DEFAULT_MEMC_NAME               "memcached"
#define DEFAULT_MON_PERIOD_TIME   1000

#define CONV_USEC_TO_MSEC         1000

#define EVENT_SIZE              ( sizeof (struct inotify_event) )
#define BUF_LEN                 ( 1024 * ( EVENT_SIZE + 16 ) )

#define MON_REGI_ERR -1
#define MON_REGI_DUP -2

/*
 * linux/limits.h
 * PATH_MAX = 4096(with null) / NAME_MAX = 255
 */
#define PATH_LEN                ( 4096 + 256 )

typedef struct memcached_info {
    pid_t                   pid;
    char                    *address;
    mapping_info_t          *mapping_info;
    struct memcached_info   *prev;
    struct memcached_info   *next;
} memcached_info_t;

typedef struct memcached_list {
    int                 count;
    memcached_info_t    *memc_head; /* double linked list */
    pthread_mutex_t     mutex;
} memcached_list_t;

memcached_list_t   m_list;
pthread_t          m_mon_tid;
int                inoti_fd, watch_fd; /* inotify variable */

static int         use_syslog = 0;
static char        *zk_ensemble = NULL;
int                stop_mon = 0;
int                mon_period_time = DEFAULT_MON_PERIOD_TIME; /* msec */

char               *pid_path = NULL;
char               *file_prefix = DEFAULT_MEMC_NAME;

int
memc_list_init()
{
    m_list.count = 0;
    m_list.memc_head = NULL;

    /* init m_list mutex */
    if (pthread_mutex_init(&m_list.mutex, NULL) != 0) {
        PRINT_LOG_ERR("Memcached list mutex initializing error. pthread_mutex_init");
        return -1;
    }

    return 0;
}

void
memc_list_free()
{
    memcached_info_t *tmp;

    tmp = m_list.memc_head;

    while (tmp != NULL) {
        m_list.memc_head = tmp->next;
        free(tmp->mapping_info);
        free(tmp->address);
        free(tmp);
        tmp = m_list.memc_head;
    }

    m_list.count = 0;

    /* destroy m_list mutex */
    if (pthread_mutex_destroy(&m_list.mutex) != 0) {
        PRINT_LOG_ERR("Memcached list mutex destroy error. pthread_mutex_destroy");
    }
}

int
memc_insert(pid_t pid, char *address, mapping_info_t *mapping_info)
{
    memcached_info_t *tmp;
    tmp = (memcached_info_t*)malloc(sizeof(memcached_info_t));
    if (tmp == NULL) {
        PRINT_LOG_ERR("Memcached list item allocation error. malloc");
        return -1;
    }

    tmp->pid = pid;
    tmp->address = strdup(address);
    if (tmp->address == NULL) {
        PRINT_LOG_ERR("Memcached list item info creation error. strdup");
        free(tmp);
        return -1;
    }
    tmp->mapping_info = mapping_info;
    tmp->prev = NULL;
    tmp->next = NULL;

    if (m_list.memc_head != NULL) {
        m_list.memc_head->prev = tmp;
        tmp->next = m_list.memc_head;
    }
    m_list.memc_head = tmp;

    m_list.count++;

    return 0;
}

int
memc_delete(memcached_info_t *del_memc)
{
    memcached_info_t *tmp;

    if (m_list.count == 0) {
        PRINT_LOG_NOTI("There is nothing to delete. Memcached list is empty.\n");
        return -1;
    }

    tmp = del_memc->prev;

    if (tmp != NULL)
        tmp->next = del_memc->next;

    if (del_memc->next != NULL)
        del_memc->next->prev = tmp;

    m_list.count--;

    if (del_memc == m_list.memc_head) {
        if (m_list.count == 0)
            m_list.memc_head = NULL;
        else
            m_list.memc_head = del_memc->next;
    }

    free(del_memc->mapping_info);
    free(del_memc->address);
    free(del_memc);

    return 0;
}

/*
 * param pid
 * param command 
 * return if proc_cmdline contain cmd, then return 1, not 0
 */
int
contains_proc_stat(pid_t pid, char *cmd)
{
#define STAT_LINE_LEN   1024
#define PROC_PATH_LEN  32
    char stat_str[STAT_LINE_LEN];
    char proc_path[PROC_PATH_LEN];
    FILE *pf = NULL;
    char *bin_start = NULL, *bin_end = NULL;
    char bin[255] = { 0 };

    if (pid <= 1 || cmd == NULL)
        return 0;

    snprintf(proc_path, PROC_PATH_LEN, "/proc/%d/stat", pid);
    if ((pf = fopen(proc_path, "r")) == NULL) {
        PRINT_LOG_ERR("Process stat file open error to get command string. fopen");
        return 0;
    }

    if (fgets(stat_str, STAT_LINE_LEN, pf) == NULL) {
        PRINT_LOG_ERR("Process stat information read error to get command string. fgets");
        fclose(pf);
        return 0;
    }

    bin_start = strchr(stat_str, '(');
    bin_end  = strrchr(stat_str, ')');
    strncpy(bin, bin_start + 1, bin_end - bin_start - 1);

    if (strcmp(bin, cmd) == 0) {
        fclose(pf);
        return 1;
    }

    fclose(pf);
    return 0;
}

/*
 * param file name. pid_file_name is must <file_prefix>.ip:port
 * return address (ip:port), if invalidate filename then NULL
 */
char *
validate_file_name_and_get_address(char *file_name)
{
    char *file_name_buf = NULL;
    char *file_name_buf_last = NULL;
    char *prefix = NULL;
    char *address = NULL;
    char *ip = NULL, *port = NULL;
    int  i = 0, port_len = 0;

    file_name_buf = strdup(file_name);
    if (file_name_buf == NULL) {
        PRINT_LOG_ERR("file name buffer allocation error. strdup");
        return NULL;
    }

    prefix = strtok_r(file_name_buf, ".", &file_name_buf_last);
    if (prefix == NULL) {
        PRINT_LOG_NOTI("Invalid pid file name : no prefix");
        free(file_name_buf);
        return NULL;
    }

    /* validate file_prefix */
    if (strcmp(file_prefix, prefix) != 0) {
        PRINT_LOG_NOTI("Invalid pid file name : invalid prefix\n");
        free(file_name_buf);
        return NULL;
    }

    address = strdup(file_name_buf_last);
    if (address == NULL) {
        PRINT_LOG_ERR("ip:port address buffer allocation error. strdup");
        free(file_name_buf);
        return NULL;
    }

    /* if ip variable is NULL then address format isn't ip:port */
    ip = strtok_r(file_name_buf_last, ":", &port);
    if (ip == NULL) {
        PRINT_LOG_NOTI("Invalid ip:port address : (%s)\n", address);
        free(file_name_buf);
        free(address);
        return NULL;
    }

    /* validate ip */
    if (inet_addr (ip) == INADDR_NONE) {
        PRINT_LOG_NOTI("Invalid ip address : (%s)\n", ip);
        free(file_name_buf);
        free(address);
        return NULL;
    }

    /* 
     * validate port
     * must compare by loop
     * because of case that port string is 11211.swp
     * ex) memcached.127.0.0.1:11211.swp
     */
    port_len = strlen(port);
    for (i = 0; i < port_len; i++) {
        if (port[i] < '0' || port[i] > '9') {
            PRINT_LOG_NOTI("Invalid port : (%s)\n", port);
            free(file_name_buf);
            free(address);
            return NULL;
        }
    }

    free(file_name_buf);
    /* 
     * don't free address here!
     * free(address)
     */

    return address;
}

/* 
 * get pid in pid file <pid_path>/file_name
 * 
 * return pid_t, error -1
 *        if pid is 0 then pid file is blank
 */
pid_t
get_pid(char *file_name)
{
#define PID_LEN 16
    char file_path[PATH_LEN];
    char pid[PID_LEN];
    FILE *pf = NULL;

    snprintf(file_path, PATH_LEN, "%s/%s", pid_path, file_name);

    if ((pf = fopen(file_path, "r")) == NULL) {
        PRINT_LOG_ERR("PID file open error. fopen");
        return -1;
    }

    if (fgets(pid, PID_LEN, pf) == NULL) {
        PRINT_LOG_ERR("PID get error. fgets");
        fclose(pf);
        return -1;
    }

    fclose(pf);

    return atoi(pid);
}

/*
 * param pid
 * param address. ip:port
 * return register success 0, fail -1
 */
int
mon_regi_memcached(pid_t pid, char *address)
{
    mapping_info_t   *mapping_info;
    memcached_info_t *tmp_mc_info = NULL;

    /* if pid = 1 is init process */
    if (pid <= (pid_t)1 || address == NULL) {
        PRINT_LOG_NOTI("invalid pid (%d) or ip:port address (%s)\n", 
                pid, address ? address : "NULL");
        return MON_REGI_ERR;
    }

    /*
     * pid file contains invalid memcached pid
     * don't register 
     */
    if (contains_proc_stat(pid, DEFAULT_MEMC_NAME) != 1) {
        PRINT_LOG_NOTI("(%d, %s) is not memcached node. Ignore it.\n", pid, address);
        return MON_REGI_ERR;
    }

    /* check duplicated */
    tmp_mc_info = m_list.memc_head;
    while (tmp_mc_info != NULL) {
        if (tmp_mc_info->pid == pid) {
            /*
             * memcached process
             * case : one action (create, modify) occur two or three event
             * case : user create pid file. prev mistake delete pid file, then already monitoring
             */
            if (strcmp(tmp_mc_info->address, address) == 0) {
                PRINT_LOG_NOTI("Memcached%snode is already registered. Ignore it. : (%d, %s)\n",
                               tmp_mc_info->mapping_info->node_type == REP_MEMC_NODE ? " repl " : " ",
                               pid, address);
                return MON_REGI_DUP;
            }

            /*
             * case : change address. is this possible? same pid
             * unregister previous info and new info register
             */
            PRINT_LOG_NOTI("Memcached info changed. : (%d, %s) --> (%d, %s)\n",
                           tmp_mc_info->pid, tmp_mc_info->address, pid, address);

            memc_delete(tmp_mc_info);
            break;
        }
        tmp_mc_info = tmp_mc_info->next;
    }

    /* get memcached node type
     * must sleep!
     * sometimes not yet create cache list
     */
    if ((mapping_info = zk_get_node_mapping_info(address)) == NULL) {
        PRINT_LOG_NOTI("Memcached node does not exist on zookeeper. : (%d, %s)\n", pid, address);
        return MON_REGI_ERR;
    }

    /* register */
    if (memc_insert(pid, address, mapping_info) != 0) {
        free(mapping_info);
        return MON_REGI_ERR;
    }

    PRINT_LOG_NOTI("Register memcached%snode. Start monitoring. : (%d, %s)\n",
                    mapping_info->node_type == REP_MEMC_NODE ? " repl " : " ",
                    pid, address);

    return 0;
}

/*
 * param pid. if pid = -1 then don't compare pid
 * param address. ip:port
 * return unregister success 0, fail -1
 */
int 
mon_unregi_memcached(pid_t pid, char *address)
{
    memcached_info_t *tmp_mc_info = NULL;

    /*
     * if pid is -1
     * then don't know pid because deleted pid file
     */
    if (address == NULL || pid == 0 || pid == 1) {
        PRINT_LOG_NOTI("Invalid pid (%d), or ip:port address (%s)\n", pid, address ? address : "NULL");
        return -1;
    }

    tmp_mc_info = m_list.memc_head;

    while (tmp_mc_info != NULL) {
        if (pid == -1) {
            if (strcmp(address, tmp_mc_info->address) == 0) {
                break;
            }
        } else {
            if ((pid == tmp_mc_info->pid) &&
                (strcmp(address, tmp_mc_info->address) == 0)) {
                break;
            }
        }
        tmp_mc_info = tmp_mc_info->next;
    }

    /*
     * sleep moment. and check [pid] process existence
     * because if normal shutdown
     * then process will stop after file is deleted
     */
    usleep (mon_period_time * CONV_USEC_TO_MSEC);

    /* check pid process existence */
    if (tmp_mc_info == NULL) {
        return -1;
    }
    else if (kill(tmp_mc_info->pid, 0) == 0) {
        if (contains_proc_stat (tmp_mc_info->pid, DEFAULT_MEMC_NAME) == 1)  {
            /*
             * deleted pid file, but memcached process is exist
             * case : user mistake - delete pid file
             * don't unregister
             */
            PRINT_LOG_NOTI("Memcached process exists. Do not unregister. : (%d, %s)\n", pid, address);
            return -1;
        }
        else {
            /*
             * delete pid file, but another process is exist
             * m_list[i] is invalid info
             * nothing todo here. invalid info unregister
             */
            PRINT_LOG_NOTI("Unregister invalid previous info. Stop monitoring. : (%d, %s)\n", tmp_mc_info->pid, tmp_mc_info->address);
        }
    }
    else {
        PRINT_LOG_NOTI("Unregister memcached%snode. Stop monitoring. : (%d, %s)\n",
                       tmp_mc_info->mapping_info->node_type == REP_MEMC_NODE ? " repl " : " ",
                       tmp_mc_info->pid, tmp_mc_info->address);
    }

    /* unregister */
    memc_delete(tmp_mc_info);

    return 0;
}

/*
 * check exist pid file
 * and register pid in pid file directory
 * 
 * return if don't exist or register success then 0
 *        error -1
 */
int
exist_pid_file_register()
{
    DIR             *dp;
    struct dirent   *dirp;
    struct stat     stat_buf;
    char            *address = NULL;
    pid_t           pid;
    char            full_path[PATH_LEN] = { 0 };

    if ((dp = opendir(pid_path)) == NULL) {
        PRINT_LOG_ERR("Can't open pid file directory. opendir");
        return -1;
    }

    while ((dirp = readdir(dp)) != NULL) {
        /* exclude current, parent directory */
        if (strcmp(dirp->d_name, ".") == 0 ||
                strcmp(dirp->d_name, "..") == 0)
            continue;

        snprintf(full_path, PATH_LEN, "%s/%s", pid_path, dirp->d_name);

        /* get file status in pid file directory */
        if (lstat(full_path, &stat_buf) < 0) {
            PRINT_LOG_ERR("File status get error in pid file directory. lstat");
            continue;
        }

        /* 
         * check regular file for dirp->d_name
         * in pid file directory
         *
         */
        if (!S_ISREG(stat_buf.st_mode))
            continue;

        if ((address =
             validate_file_name_and_get_address(dirp->d_name)) != NULL) {

            if ((pid = get_pid(dirp->d_name)) <= 0) {
                PRINT_LOG_NOTI("(%s) file does not exist or contains invalid pid.\n", dirp->d_name);
                free(address);
                continue;
            }

            PRINT_LOG_NOTI("Found the existing pid file : %s (pid : %d, addr : %s)\n", dirp->d_name, pid, address);
            mon_regi_memcached(pid, address);
            free(address);
        }
    }

    closedir(dp);

    return 0;
}

void *
memcached_mon(void *arg)
{
    char remove_path[PATH_LEN];
    int  rc;
    int  m_count, i;
    memcached_info_t *tmp_mc_info = NULL;
    memcached_info_t *next_mc_info = NULL;

    while (!stop_mon) {

        pthread_mutex_lock(&m_list.mutex);
        if (m_list.count > 0) {

            m_count = m_list.count;
            i = 0;
            tmp_mc_info = m_list.memc_head;
            while (tmp_mc_info != NULL) {

                i++;
                /* print monitoring memcached list for debug */
                PRINT_LOG_INFO("=== Checking memcached process (%d/%d) - pid : %d - addr : %s",
                               i, m_count, tmp_mc_info->pid, tmp_mc_info->address);

                /* check process. use kill */
                if (kill(tmp_mc_info->pid, 0) != 0) {
                    PRINT_LOG_INFO(" ... NOK\n");
                    PRINT_LOG_NOTI("Memcached process does not exist. It may abnormally terminate. : (%d, %s)\n",
                                   tmp_mc_info->pid, tmp_mc_info->address);

                    /* delete znode */
                    rc = zk_rm_znode(tmp_mc_info->mapping_info);
                    if (rc == 0) {
                        PRINT_LOG_NOTI("Znode deletion success.\n");
                    } else {
                        /*
                         * case : memcached start & stop repeat
                         * process exist, but znode and pid file don't exist sometimes...
                         */
                        PRINT_LOG_NOTI("Znode deletion fails.\n");
                    }

                    /* delete pid file */
                    snprintf(remove_path, PATH_LEN, "%s/%s.%s", pid_path, file_prefix, tmp_mc_info->address);
                    if (remove(remove_path) != 0) {
                        /* 
                         * if it is case that don't exist pid file, but memcached process exist
                         * then can't remove pid file
                         * must unregister memcached info
                         */
                        PRINT_LOG_ERR("PID file remove error. Maybe does not exist or already removed.");
                    }
                    PRINT_LOG_NOTI("Unregister memcached%snode. Stop monitoring. : (%d, %s)\n",
                                   tmp_mc_info->mapping_info->node_type == REP_MEMC_NODE ? " repl " : " ",
                                   tmp_mc_info->pid, tmp_mc_info->address);
                    next_mc_info = tmp_mc_info->next;
                    memc_delete(tmp_mc_info);
                    tmp_mc_info = next_mc_info;
                }
                else {
                    PRINT_LOG_INFO(" ... OK\n");
                    tmp_mc_info = tmp_mc_info->next;
                }

            }
        }
        pthread_mutex_unlock(&m_list.mutex);

        /* to delay for monitoring */
        usleep (mon_period_time * CONV_USEC_TO_MSEC);
    }

    return NULL;
}

/*
 * param struct inotify_event
 * return success 0, some error occurs -1
 */
int
inoti_event_handler(struct inotify_event *event)
{
    char *address = NULL;
    pid_t pid = 0;

    /*
     * print debug log for inotify event
     *
     * one action that change file. occur several events.
     * create action (memcached create pid file)   : IN_CREATE, IN_MODIFY
     * modify action (user modify pid file by vim) : IN_MODIFY, IN_MODIFY
     */
    switch (event->mask) {
        case IN_CREATE:
            PRINT_LOG_INFO("=== Detection : pid file created : %s\n", event->name);
            break;
        case IN_MODIFY:
            PRINT_LOG_INFO("=== Detection : pid file modified : %s\n", event->name);
            break;
        case IN_MOVED_TO:
            PRINT_LOG_INFO("=== Detection : pid file moved to : %s\n", event->name);
            break;
        case IN_DELETE:
            PRINT_LOG_INFO("=== Detection : pid file deleted : %s\n", event->name);
            break;
        case IN_MOVED_FROM:
            PRINT_LOG_INFO("=== Detection : pid file moved from : %s\n", event->name);
            break;
    }

    /* validated filename : <file_prefix>.ip:port */
    if ((address =
         validate_file_name_and_get_address(event->name)) == NULL)
        return -1;

    /*
     * only IN_CREATE, IN_MODIFY, IN_MOVED_TO events
     * register pid
     */
    if (event->mask &
        (IN_MODIFY | IN_MOVED_TO)) {
        if ((pid = get_pid(event->name)) <= 0) {
            PRINT_LOG_NOTI("%s file does not exist or contains invalid pid.\n", event->name);
            free(address);
            return -1;
        }
        
        if (mon_regi_memcached (pid, address) == MON_REGI_ERR) {
            PRINT_LOG_NOTI("Pid file created, but cannot register (%d, %s) memcached node! "
                           "Check the contents of %s file.\n", pid, address, event->name);
            free(address);
            return -1;
        }
    }
    else if (event->mask & (IN_DELETE | IN_MOVED_FROM)) {
        /*
         * if event is deletion of file
         * then don't know pid. only know ip:port (file name)
         */
        if (mon_unregi_memcached (-1, address) < 0) { 
            PRINT_LOG_NOTI("Pid file deleted, but cannot unregister %s memcached node!\n", address);
            free(address);
            return -1;
        }
    }

    free(address);

    return 0;
}

int
arcus_mon_init(char *proc_name)
{
   /* inotify init */
    if((inoti_fd = inotify_init()) < 0) {
        PRINT_LOG_ERR("Inotify init error to watch pid file directory. inotify_init");
        return -1;
    }

    /* watch pid path by inotify */
    if ((watch_fd = inotify_add_watch(inoti_fd, pid_path,
                    IN_CREATE | IN_MODIFY | IN_MOVED_TO |      /* register memcached pid */
                    IN_MOVED_FROM | IN_DELETE)) < 0) {         /* unregister memcached pid */
        PRINT_LOG_ERR("Inotify add watch error to pid file directory. inotify_add_watch");
        close(inoti_fd);
        return -1;
    }

    /* 
     * zookeeper init
     * for delete znode of abnormal shutdown memcached node 
     */
    if (zk_arcus_mon_init(zk_ensemble, proc_name, use_syslog) < 0) {
        inotify_rm_watch(inoti_fd, watch_fd);
        close(inoti_fd);
        return -1;
    }

    /* monitoring list init */
    if (memc_list_init() < 0) {
        PRINT_LOG_ERR("Memcached list init error");
        zk_arcus_mon_free();
        inotify_rm_watch(inoti_fd, watch_fd);
        close(inoti_fd);
        return -1;
    }

    if (pthread_create (&m_mon_tid, NULL, memcached_mon, NULL) != 0) {
        PRINT_LOG_ERR("Memcached monitoring thread creation error. pthread_create");
        memc_list_free();
        zk_arcus_mon_free();
        inotify_rm_watch(inoti_fd, watch_fd);
        close(inoti_fd);
        return -1;
    }

    return 0;
}

int
arcus_mon_final()
{
    /* wait memcached_mon thread */
    if (pthread_join(m_mon_tid, NULL) != 0) {
        PRINT_LOG_ERR("Memcached monitoring thread join error. pthread_join");
    }
    
    memc_list_free();
    zk_arcus_mon_free();

    if (inotify_rm_watch(inoti_fd, watch_fd) != 0) {
        PRINT_LOG_ERR("Inotify watcher remove error. inotify_rm_watch");
    }

    if (close(inoti_fd) != 0) {
        PRINT_LOG_ERR("Inotify close error. close");
    }

    return 0;
}

void
sig_handler(int signo)
{
    stop_mon = 1;
    PRINT_LOG_NOTI("Arcus - memcached monitoring process shutdown by signal(%s)\n",
                   strsignal(signo));
}

void
print_usage()
{
    printf("Arcus - memcached monitoring process version 1.0\n"
            "USAGE : memc_mon [Options] <pid file directory>\n"
            "      : memc_mon -z 127.0.0.1:2181 -p memcached -t 1000 -X -L LOG_NOTI memc_pid_list\n"
            "\n"
            "<pid_file_directory>         directory path to read pid file\n"
            "\n"
            "Options:\n"
            "  -z ip:port list   Zookeeper ensemble cluster servers (default : 127.0.0.1:2181)\n"
            "  -p <prefix>       pretfix to read pid file in pid directory path (default : memcached)\n"
            "  -t <msec>         memc_mon monitroing period time. msec (default : 1000 msec)\n"
            "  -X                print log to syslog (default : stderr)\n"
            "  -L <log level>    log level option. in order of decreasing importance. (default : LOG_ERR)\n"
            "                    LOG_ERR  : error\n"
            "                    LOG_NOTI : normal, but significant\n"
            "                    LOG_INFO : information\n"
            "  -h                help usage\n");
    printf("\n");
}

int
main(int argc, char *argv[])
{
    int         opt;
    int         length, i;
    char        inoti_buf[BUF_LEN];
    struct stat stat_buf;

    signal(SIGINT, (void*)sig_handler);
    signal(SIGTERM, (void*)sig_handler);

    while ((opt = getopt(argc, argv, "z:p:t:XL:h?")) != EOF) {
        switch (opt) {
            case 'z':
                zk_ensemble = optarg;
                break;
            case 'p':
                file_prefix = optarg;
                break;
            case 't':
                mon_period_time = atoi(optarg);
                if (mon_period_time <= 0) {
                    print_usage();
                    exit(EXIT_FAILURE);
                }
                break;
            case 'X':
                openlog(argv[0], LOG_NDELAY | LOG_CONS | LOG_PID, LOG_DAEMON);
                use_syslog = 1;
                break;
            case 'L':
                if (!strcmp("LOG_ERR", optarg))
                    log_init(ARCUS_MON_LOG_ERR);
                else if (!strcmp("LOG_NOTI", optarg))
                    log_init(ARCUS_MON_LOG_NOTICE);
                else if (!strcmp("LOG_INFO", optarg))
                    log_init(ARCUS_MON_LOG_INFO);
                else {
                    print_usage();
                    exit(EXIT_FAILURE);
                }
                break;
            case 'h':
            case '?':
            default :
                print_usage();
                exit(EXIT_FAILURE);
        }
    }

    if (optind == argc) {
        print_usage();
        exit(EXIT_FAILURE);
    }

    /* validate pid path */
    if ((pid_path = argv[optind]) == NULL) {
        print_usage();
        exit(EXIT_FAILURE);
    }
    
    if (lstat(pid_path, &stat_buf) < 0 || S_ISDIR(stat_buf.st_mode) == 0) {
        PRINT_LOG_ERR("Pid file path is invalid.");
        print_usage();
        exit(EXIT_FAILURE);
    }

    if (arcus_mon_init(argv[0]) < 0) {
        exit(EXIT_FAILURE);
    }
    PRINT_LOG_NOTI("Arcus - Memcached monitoring process start\n");

    /* 
     * first. check exist pid file
     * if exist register monitoring list
     */
    if (exist_pid_file_register() == -1) {
        stop_mon = 1;
    }

    while (!stop_mon) {
        i = 0;
        memset(inoti_buf, 0, BUF_LEN);

        if ((length = read(inoti_fd, inoti_buf, BUF_LEN)) < 0) {
            PRINT_LOG_ERR("Inotify event read error. read");
            if (errno != EINTR)
                stop_mon = 1;
            continue;
        }

        pthread_mutex_lock(&m_list.mutex);
        while (i < length) {
            struct inotify_event *event = (struct inotify_event *)&inoti_buf[i];

            if (event->len) {
                /*
                 * error handling is not necessary, isn't it? FIXME
                 * don't use continue
                 * because of next event handling
                 */
                inoti_event_handler(event);
            }

            i += EVENT_SIZE + event->len;
        }
        pthread_mutex_unlock(&m_list.mutex);
    }

    arcus_mon_final();
    PRINT_LOG_NOTI("Arcus - Memcached monitoring process shutdown\n");

    return 0;
}
