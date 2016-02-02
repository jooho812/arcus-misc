#ifndef ARCUS_MEMC_MON_LOGGER_H
#define ARCUS_MEMC_MON_LOGGER_H

#define PRINT_LOG_ERR(fmt, args...)                                                  \
        print_log (use_syslog, ARCUS_MON_LOG_ERR, fmt" - %s(%d) (%s : %d)\n",    \
                   ##args, strerror(errno), errno, __FILE__, __LINE__)

#define PRINT_LOG_NOTI(fmt, args...)                              \
        print_log (use_syslog, ARCUS_MON_LOG_NOTICE, fmt, ##args)

#define PRINT_LOG_INFO(fmt, args...)                              \
        print_log (use_syslog, ARCUS_MON_LOG_INFO, fmt, ##args)

typedef enum {
    ARCUS_MON_LOG_ERR,
    ARCUS_MON_LOG_NOTICE,
    ARCUS_MON_LOG_INFO
} ARCUS_MON_LOG;

extern ARCUS_MON_LOG log_level;

void print_log (int use_syslog, int log_lev, const char *fmt, ...)
__attribute__ ((__format__ (__printf__, 3, 4)));
void log_init(int log_lev);

#endif /* ARCUS_MEMC_MON_LOGGER_H */
