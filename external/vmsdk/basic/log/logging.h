#ifndef BASE_LOG_LOGGING_H_
#define BASE_LOG_LOGGING_H_

#include <memory>
#include <sstream>
#include <string>

#include "basic/base_export.h"

#if defined(OS_ANDROID)
#include <android/log.h>

#define VLOGW(...) __android_log_print(ANDROID_LOG_WARN, "VMSDK", __VA_ARGS__)
#define VLOGE(...) __android_log_print(ANDROID_LOG_ERROR, "VMSDK", __VA_ARGS__)
#define VLOGI(...) __android_log_print(ANDROID_LOG_INFO, "VMSDK", __VA_ARGS__)
#define VLOGD(...) __android_log_print(ANDROID_LOG_DEBUG, "VMSDK", __VA_ARGS__)
#else

#include <cstdlib>

#define VLOGW(format, ...) \
  fprintf(stderr, "[VMSDK] " format "\n", ##__VA_ARGS__)
#define VLOGE(format, ...) \
  fprintf(stderr, "[VMSDK] " format "\n", ##__VA_ARGS__)
#define VLOGI(format, ...) \
  fprintf(stderr, "[VMSDK] " format "\n", ##__VA_ARGS__)
#define VLOGD(format, ...) \
  fprintf(stderr, "[VMSDK] " format "\n", ##__VA_ARGS__)
#endif

namespace vmsdk {
namespace general {
namespace logging {

class LogMessage;
void Log(LogMessage *msg);

VMSDK_HIDE void SetMinLogLevel(int level);

int GetMinAllLogLevel();

#define VMSDK_LOG_LEVEL_VERBOSE -1
#define VMSDK_LOG_LEVEL_INFO 0
#define VMSDK_LOG_LEVEL_WARNING 1
#define VMSDK_LOG_LEVEL_ERROR 2
#define VMSDK_LOG_LEVEL_FATAL 3
#define VMSDK_LOG_LEVEL_NUM 4

typedef int LogSeverity;
const LogSeverity LOG_VERBOSE = VMSDK_LOG_LEVEL_VERBOSE;
const LogSeverity LOG_INFO = VMSDK_LOG_LEVEL_INFO;
const LogSeverity LOG_WARNING = VMSDK_LOG_LEVEL_WARNING;
const LogSeverity LOG_ERROR = VMSDK_LOG_LEVEL_ERROR;
const LogSeverity LOG_FATAL = VMSDK_LOG_LEVEL_FATAL;
const LogSeverity LOG_NUM_SEVERITIES = VMSDK_LOG_LEVEL_NUM;

// This class is used to explicitly ignore values in the conditional
// logging macros.  This avoids compiler warnings like "value computed
// is not used" and "statement has no effect".
class LogMessageVoidify {
 public:
  LogMessageVoidify() {}
  // This has to be an operator with a precedence lower than << but
  // higher than ?:
  void operator&(std::ostream &) {}
};

#define LOG_IS_ON(severity)                     \
  ((vmsdk::general::logging::LOG_##severity) >= \
   vmsdk::general::logging::GetMinAllLogLevel())

#define LOG_STREAM(severity)                                                   \
  vmsdk::general::logging::LogMessage(__FILE__, __LINE__,                      \
                                      vmsdk::general::logging::LOG_##severity) \
      .stream()

#define LAZY_STREAM(stream, condition) \
  !(condition) ? (void)0               \
               : vmsdk::general::logging::LogMessageVoidify() & (stream)

// Use this macro to suppress warning if the variable in log is not used.
#define UNUSED_LOG_VARIABLE __attribute__((unused))

#ifndef VMSDK_MIN_LOG_LEVEL
#define VMSDK_MIN_LOG_LEVEL VMSDK_LOG_LEVEL_VERBOSE
#endif

// TODO(zhixuan): Currently, the usage of log macros is like "LOGI("abc" <<
// variable)", which is mixed of stream pattern and format string pattern.
// Change the loggin fashion entirely to format string pattern in future.
#if VMSDK_MIN_LOG_LEVEL <= VMSDK_LOG_LEVEL_VERBOSE
#define LOGV(msg) LAZY_STREAM(LOG_STREAM(VERBOSE), LOG_IS_ON(VERBOSE)) << msg
#define DLOGV(msg) LAZY_STREAM(LOG_STREAM(VERBOSE), LOG_IS_ON(VERBOSE)) << msg
#else
#define LOGV(msg)
#define DLOGV(msg)
#endif

#if VMSDK_MIN_LOG_LEVEL <= VMSDK_LOG_LEVEL_INFO
#define LOGI(msg) LAZY_STREAM(LOG_STREAM(INFO), LOG_IS_ON(INFO)) << msg
#define DLOGI(msg) LAZY_STREAM(LOG_STREAM(INFO), LOG_IS_ON(INFO)) << msg
#else
#define LOGI(msg)
#define DLOGI(msg)
#endif

#if VMSDK_MIN_LOG_LEVEL <= VMSDK_LOG_LEVEL_WARNING
#define LOGW(msg) LAZY_STREAM(LOG_STREAM(WARNING), LOG_IS_ON(WARNING)) << msg
#define DLOGW(msg) LAZY_STREAM(LOG_STREAM(WARNING), LOG_IS_ON(WARNING)) << msg
#else
#define LOGW(msg)
#define DLOGW(msg)
#endif

#if VMSDK_MIN_LOG_LEVEL <= VMSDK_LOG_LEVEL_ERROR
#define LOGE(msg) LAZY_STREAM(LOG_STREAM(ERROR), LOG_IS_ON(ERROR)) << msg
#define DLOGE(msg) LAZY_STREAM(LOG_STREAM(ERROR), LOG_IS_ON(ERROR)) << msg
#else
#define LOGE(msg)
#define DLOGE(msg)
#endif

#if VMSDK_MIN_LOG_LEVEL <= VMSDK_LOG_LEVEL_FATAL
#define LOGF(msg) LAZY_STREAM(LOG_STREAM(FATAL), LOG_IS_ON(FATAL)) << msg
#define DLOGF(msg) LAZY_STREAM(LOG_STREAM(FATAL), LOG_IS_ON(FATAL)) << msg
#else
#define LOGF(msg)
#define DLOGF(msg)
#endif

#ifndef DCHECK
// for debug, if check failed, log fatal and abort
#ifndef NDEBUG
#define DCHECK(condition)                      \
  LAZY_STREAM(LOG_STREAM(FATAL), !(condition)) \
      << "Check failed: " #condition ". "
#else
// for release, do nothing
#define DCHECK(condition) !(condition) ? (void)0 : (void)0
#endif
#endif

#define NOTREACHED() LOGF("")

class LogMessage {
 public:
  LogMessage(const char *file, int line, LogSeverity severity);
  ~LogMessage();
  std::ostringstream &stream() { return stream_; }
  LogSeverity severity() { return severity_; }

 private:
  void Init(const char *file, int line);

  LogSeverity severity_;
  std::ostringstream stream_;

  const char *file_;
  const int line_;
  LogMessage(const LogMessage &) = delete;
  LogMessage &operator=(const LogMessage &) = delete;
};

}  // namespace logging
}  // namespace general
}  // namespace vmsdk

#endif
