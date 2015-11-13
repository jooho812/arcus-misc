#include <stdio.h>
#include <stdarg.h>
#include <syslog.h>

#include "arcus_memc_mon_logger.h"

ARCUS_MON_LOG log_level = ARCUS_MON_LOG_ERR;

void
log_init (int log_lev)
{
    log_level = log_lev;
}

void
print_log (int use_syslog, int log_lev, const char *fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    if (use_syslog) {
        if (log_level >= ARCUS_MON_LOG_INFO) {
            vsyslog(LOG_ERR, fmt, ap);
        } else {
            switch (log_lev) {
                case ARCUS_MON_LOG_ERR:
                    log_lev = LOG_ERR;
                    break;
                case ARCUS_MON_LOG_NOTICE:
                    log_lev = LOG_NOTICE;
                    break;
                case ARCUS_MON_LOG_INFO:
                    log_lev = LOG_INFO;
                    break;
            }
            vsyslog(log_lev, fmt, ap);
        }
    } else if (log_lev <= log_level) {
        vfprintf(stdout, fmt, ap);
        fflush(stdout);
    }
    va_end(ap);
}
