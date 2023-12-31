#ifndef LYNX_BASE_LOG_LOGGING_H_
#define LYNX_BASE_LOG_LOGGING_H_

#include <memory>
#include <sstream>
#include <string>

#include "base/base_export.h"
#include "base/path_utils.h"

namespace lynx {
namespace base {
namespace logging {

class LoggingDelegate;

class LogMessage;
void Log(LogMessage* msg);

// Keep the interface to prevent compilation failure
// Prohibited to use!!!!!!!!
BASE_EXPORT void SetLoggingDelegate(std::unique_ptr<LoggingDelegate> delegate);

// Keep the interface to prevent compilation failure
// Prohibited to use!!!!!!!!
BASE_EXPORT void ClearLoggingDelegate();

BASE_EXPORT void SetMinLogLevel(int level);

BASE_EXPORT int GetMinLogLevel();

#define LYNX_LOG_LEVEL_VERBOSE 0
#define LYNX_LOG_LEVEL_DEBUG 1
#define LYNX_LOG_LEVEL_INFO 2
#define LYNX_LOG_LEVEL_WARNING 3
#define LYNX_LOG_LEVEL_ERROR 4
#define LYNX_LOG_LEVEL_FATAL 5
#define LYNX_LOG_LEVEL_NUM 6

typedef int LogSeverity;
const LogSeverity LOG_VERBOSE = LYNX_LOG_LEVEL_VERBOSE;
const LogSeverity LOG_DEBUG = LYNX_LOG_LEVEL_DEBUG;
const LogSeverity LOG_INFO = LYNX_LOG_LEVEL_INFO;
const LogSeverity LOG_WARNING = LYNX_LOG_LEVEL_WARNING;
const LogSeverity LOG_ERROR = LYNX_LOG_LEVEL_ERROR;
// The error in windi.h in the windows environment will pollute the LOG_0 here,
// and a LOG_0 needs to be defined directly
#ifdef OS_WIN
const LogSeverity LOG_0 = LOG_ERROR;
#endif
const LogSeverity LOG_FATAL = LYNX_LOG_LEVEL_FATAL;
const LogSeverity LOG_NUM_SEVERITIES = LYNX_LOG_LEVEL_NUM;

// !!! Need to be aligned with platform layer. !!!
// !!! in file <LogSource.java> !!!
typedef int LogSource;
const LogSource LOG_SOURCE_NATIVE = 0;
const LogSource LOG_SOURCE_JS = 1;
const LogSource LOG_SOURCE_JS_EXT =
    2;  // used for console.alog & console.report

// channel type from lynx internal and external developer
using LogChannel = int32_t;
constexpr LogChannel LOG_CHANNEL_LYNX_INTERNAL = 0;
constexpr LogChannel LOG_CHANNEL_LYNX_EXTERNAL = 1;

// This class is used to explicitly ignore values in the conditional
// logging macros.  This avoids compiler warnings like "value computed
// is not used" and "statement has no effect".
class LogMessageVoidify {
 public:
  LogMessageVoidify() {}
  // This has to be an operator with a precedence lower than << but
  // higher than ?:
  void operator&(std::ostream&) {}
};

#define LOG_IS_ON(severity)                 \
  ((lynx::base::logging::LOG_##severity) >= \
   lynx::base::logging::GetMinLogLevel())

#define LOG_STREAM(severity)                                              \
  lynx::base::logging::LogMessage(                                        \
      lynx::base::PathUtils::GetLastPath(__FILE__, sizeof(__FILE__) - 1), \
      __LINE__, lynx::base::logging::LOG_##severity)                      \
      .stream()

#define JS_LOG_STREAM(severity, source, runtime_id, channel_type)         \
  lynx::base::logging::LogMessage(                                        \
      lynx::base::PathUtils::GetLastPath(__FILE__, sizeof(__FILE__) - 1), \
      __LINE__, lynx::base::logging::LOG_##severity,                      \
      lynx::base::logging::LOG_SOURCE_JS, runtime_id, channel_type)       \
      .stream()

#define JS_ALOG_STREAM(severity, source, runtime_id, channel_type)        \
  lynx::base::logging::LogMessage(                                        \
      lynx::base::PathUtils::GetLastPath(__FILE__, sizeof(__FILE__) - 1), \
      __LINE__, lynx::base::logging::LOG_##severity,                      \
      lynx::base::logging::LOG_SOURCE_JS_EXT, runtime_id, channel_type)   \
      .stream()

#define LAZY_STREAM(stream, condition) \
  !(condition) ? (void)0 : lynx::base::logging::LogMessageVoidify() & (stream)

// Use this macro to suppress warning if the variable in log is not used.
#define UNUSED_LOG_VARIABLE __attribute__((unused))

#ifndef LYNX_MIN_LOG_LEVEL
#define LYNX_MIN_LOG_LEVEL LYNX_LOG_LEVEL_VERBOSE
#endif

// TODO(zhixuan): Currently, the usage of log macros is like "LOGI("abc" <<
// variable)", which is mixed of stream pattern and format string pattern.
// Change the logging fashion entirely to format string pattern in future.
#if LYNX_MIN_LOG_LEVEL <= LYNX_LOG_LEVEL_VERBOSE
#define LOGV(msg) LAZY_STREAM(LOG_STREAM(VERBOSE), LOG_IS_ON(VERBOSE)) << msg
#define DLOGV(msg) LAZY_STREAM(LOG_STREAM(VERBOSE), LOG_IS_ON(VERBOSE)) << msg
#else
#define LOGV(msg)
#define DLOGV(msg)
#endif

#if LYNX_MIN_LOG_LEVEL <= LYNX_LOG_LEVEL_DEBUG
#define LOGD(msg) LAZY_STREAM(LOG_STREAM(DEBUG), LOG_IS_ON(DEBUG)) << msg
#define DLOGD(msg) LAZY_STREAM(LOG_STREAM(DEBUG), LOG_IS_ON(DEBUG)) << msg
#else
#define LOGD(msg)
#define DLOGD(msg)
#endif

#if LYNX_MIN_LOG_LEVEL <= LYNX_LOG_LEVEL_INFO
#define LOGI(msg) LAZY_STREAM(LOG_STREAM(INFO), LOG_IS_ON(INFO)) << msg
#define DLOGI(msg) LAZY_STREAM(LOG_STREAM(INFO), LOG_IS_ON(INFO)) << msg
#else
#define LOGI(msg)
#define DLOGI(msg)
#endif

#if LYNX_MIN_LOG_LEVEL <= LYNX_LOG_LEVEL_WARNING
#define LOGW(msg) LAZY_STREAM(LOG_STREAM(WARNING), LOG_IS_ON(WARNING)) << msg
#define DLOGW(msg) LAZY_STREAM(LOG_STREAM(WARNING), LOG_IS_ON(WARNING)) << msg
#else
#define LOGW(msg)
#define DLOGW(msg)
#endif

#if LYNX_MIN_LOG_LEVEL <= LYNX_LOG_LEVEL_ERROR
#define LOGE(msg) LAZY_STREAM(LOG_STREAM(ERROR), LOG_IS_ON(ERROR)) << msg
#define DLOGE(msg) LAZY_STREAM(LOG_STREAM(ERROR), LOG_IS_ON(ERROR)) << msg
#else
#define LOGE(msg)
#define DLOGE(msg)

#endif
#if LYNX_MIN_LOG_LEVEL <= LYNX_LOG_LEVEL_ERROR
#define LOGR(msg) LAZY_STREAM(LOG_STREAM(ERROR), LOG_IS_ON(ERROR)) << msg
#define DLOGR(msg) LAZY_STREAM(LOG_STREAM(ERROR), LOG_IS_ON(ERROR)) << msg
#else
#define LOGR(msg)
#define DLOGR(msg)
#endif

#if LYNX_MIN_LOG_LEVEL <= LYNX_LOG_LEVEL_FATAL
#define LOGF(msg) LAZY_STREAM(LOG_STREAM(FATAL), LOG_IS_ON(FATAL)) << msg
#define DLOGF(msg) LAZY_STREAM(LOG_STREAM(FATAL), LOG_IS_ON(FATAL)) << msg
#else
#define LOGF(msg)
#define DLOGF(msg)
#endif

#define JSLOG(severity, runtime_id, channel_type) \
  LAZY_STREAM(JS_LOG_STREAM(severity, JS, runtime_id, channel_type), true)

#define JSALOG(severity, runtime_id, channel_type) \
  LAZY_STREAM(JS_ALOG_STREAM(severity, JS, runtime_id, channel_type), true)

#define CHECK(condition)                       \
  LAZY_STREAM(LOG_STREAM(FATAL), !(condition)) \
      << "Check failed: " #condition ". "

// now support DCHECK(...) << ...
#ifndef DCHECK
// for debug, if check failed, log fatal and abort
#ifndef NDEBUG
#define DCHECK(condition) CHECK(condition)
#else
// for release, do nothing
#define DCHECK(condition)                                                \
  true || (condition) ? (void)0                                          \
                      : lynx::base::logging::LogMessageVoidify() &       \
                            lynx::base::logging::LogMessage(             \
                                "", 0, lynx::base::logging::LOG_VERBOSE) \
                                .stream()
#endif
#endif

#define NOTREACHED() LOGF("")
#define DCHECK_EQ(v1, v2) DCHECK((v1) == (v2))

class BASE_EXPORT LogMessage {
 public:
  LogMessage(const char* file, int line, LogSeverity severity, LogSource source,
             int64_t rt_id, LogChannel channel_type);
  LogMessage(const char* file, int line, LogSeverity severity);
  ~LogMessage();
  std::ostringstream& stream() { return stream_; }
  LogSeverity severity() { return severity_; }
  LogSource source() { return source_; }
  size_t messageStart() { return message_start_; }
  int64_t runtimeId() { return runtime_id_; }
  LogChannel ChannelType() { return channel_type_; }

 private:
  void Init(const char* file, int line);

  LogSeverity severity_;
  std::ostringstream stream_;
  size_t message_start_;

  const char* file_;
  const int line_;
  LogSource source_;
  int64_t runtime_id_;
  LogChannel channel_type_;
  LogMessage(const LogMessage&) = delete;
  LogMessage& operator=(const LogMessage&) = delete;
};

// Keep the base class to prevent compilation failures
// Forbidden to inherit!!!!!!!!
class BASE_EXPORT_FOR_DEVTOOL LoggingDelegate {
 public:
  BASE_EXPORT_FOR_DEVTOOL virtual ~LoggingDelegate() {}
  BASE_EXPORT_FOR_DEVTOOL virtual void Log(LogMessage* msg) = 0;
};
}  // namespace logging
}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_LOG_LOGGING_H_
