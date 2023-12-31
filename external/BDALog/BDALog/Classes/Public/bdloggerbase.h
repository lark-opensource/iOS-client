#ifndef BDLOGGERBASE_H_
#define BDLOGGERBASE_H_

#include <sys/time.h>
#include <time.h>
#include <stdarg.h>
#include <stdint.h>

#ifdef __cplusplus

#include <string>

extern "C" {
#endif

typedef enum {
    kLevelAll = 0,
    kLevelVerbose = 0,
    kLevelDebug = 1,    // Detailed information on the flow through the system.
    kLevelInfo = 2,     // Interesting runtime events (startup/shutdown), should be cautious and keep to a minimum.
    kLevelWarn = 3,     // Other runtime situations that are undesirable or unexpected, but not necessarily "wrong".
    kLevelError = 4,    // Other runtime errors or unexpected conditions.
    kLevelFatal = 5,    // Severe errors that cause premature termination.
    kLevelNone = 10000,     // Special level used to disable all log messages.
} kBDALogLevel;
    
typedef struct BDLoggerInfo_t {
    kBDALogLevel level;
    const char* tag;
    const char* filename;
    const char* func_name;
    int line;

    struct timeval timeval;
    intmax_t pid;
    intmax_t tid;
    intmax_t maintid;
} BDLoggerInfo;

typedef enum {
    kRemoveReasonNon = 0,
    kRemoveReasonOutDate,
    kRemoveReasonMaxSize,
    kRemoveReasonOutDateAndMaxSize,
    kRemoveReasonTriggleByHost,
} kBDALogRemoveReason;

extern intmax_t bdlogger_pid(void);
extern intmax_t bdlogger_tid(void);
extern intmax_t bdlogger_maintid(void);

// log callback define
typedef void (*type_log_callback)(const char * log);
typedef void (*type_log_detail_callback)(const char * time, intmax_t pid, intmax_t tid, int is_main_thread, const char * level, const char * tag, const char * func_name, const char * file_name, int line, const char * log);
typedef void (*type_oslog_detail_callback)(const char * time, intmax_t pid, intmax_t tid, int is_main_thread, int level, const char * tag, const char * func_name, const char * file_name, int line, const char * log);

// remove operation callback
typedef void (*type_files_remove_callback)(const char * instance_name, kBDALogRemoveReason reason, int removed_files_count);

#ifdef __cplusplus
typedef void (*type_log_modify_handler)(std::string& log, std::string& tag, bool& isAbandon);

typedef void (*type_log_detail_modify_handler)(intmax_t pid, intmax_t tid, bool is_main_thread, const char * level, const char * func_name, const char * file_name, std::string& log, std::string& tag, bool& isAbandon);
}
#endif

#endif
