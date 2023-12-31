#include "base/log/logging.h"

#include <algorithm>
#include <ctime>
#include <iomanip>
#include <ostream>
#include <string>
#include <utility>

#if !defined(_WIN32)
#include <unistd.h>
#endif

#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace base {
namespace logging {
namespace {

const char* const log_severity_names[LOG_NUM_SEVERITIES] = {
    "VERBOSE", "DEBUG", "INFO", "WARNING", "ERROR", "FATAL"};

const char* log_severity_name(int severity) {
  if (severity >= 0 && severity < LOG_NUM_SEVERITIES)
    return log_severity_names[severity];
  return "UNKNOWN";
}

int g_min_log_level = LOG_INFO;

}  // namespace

// Keep the interface to prevent compilation failure
// Prohibited to use!!!!!!!!
void SetLoggingDelegate(std::unique_ptr<LoggingDelegate> delegate) {}

// Keep the interface to prevent compilation failure
// Prohibited to use!!!!!!!!
void ClearLoggingDelegate() {}

void SetMinLogLevel(int level) {
  if (g_min_log_level >= level) {
    return;
  }
  g_min_log_level = std::min(LOG_FATAL, level);
}

int GetMinLogLevel() { return g_min_log_level; }

LogMessage::LogMessage(const char* file, int line, LogSeverity severity,
                       LogSource source, int64_t rt_id, LogChannel channel_type)
    : severity_(severity),
      file_(file),
      line_(line),
      source_(source),
      runtime_id_(rt_id),
      channel_type_(channel_type) {
  // FIXME(shouqun): Suppress unused warning.
  (void)line_;
  (void)file_;
  Init(file, line);
}

LogMessage::LogMessage(const char* file, int line, LogSeverity severity)
    : severity_(severity),
      file_(file),
      line_(line),
      source_(LOG_SOURCE_NATIVE),
      runtime_id_(-1),
      channel_type_(LOG_CHANNEL_LYNX_INTERNAL) {
  Init(file, line);
}

LogMessage::~LogMessage() {
  // on Windows, use spdlog which add newline at the end of each line.
#if !defined(_WIN32)
  stream_ << std::endl;
#endif

#if defined(OS_ANDROID) || defined(OS_IOS) || defined(OS_OSX) || \
    defined(MODE_HEADLESS)
  lynx::base::logging::Log(this);
#else
  std::string str_newline(stream_.str());
  printf("lynx: %s\n", str_newline.c_str());
#endif

  if (severity_ == LOG_FATAL) {
    abort();
  }
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
}

// writes the common header info to the stream
void LogMessage::Init(const char* file, int line) {
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "LogMessage");
  std::string filename(file);

  stream_ << '[';
#if OS_ANDROID
  stream_ << gettid() << ':';
#endif

  // function localtime_r will call getenv which system function, but getenv is
  // not thread-safe although, it does not make crash directly, but when setenv
  // will be called in other thread it possibly will crash in lynx log. Then,
  // the time tag is useless, and other user, like ALog, has owner time tag so
  // disable it here.
  //  time_t t = time(NULL);
  // #if defined(OS_WIN)
  //  struct tm local_time = {0};
  //
  //  localtime_s(&local_time, &t);
  // #else
  //  struct tm local_time = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, nullptr};
  //  localtime_r(&t, &local_time);
  // #endif
  //
  //  struct tm* tm_time = &local_time;
  //  stream_ << std::setfill('0') << std::setw(2) << 1 + tm_time->tm_mon
  //          << std::setw(2) << tm_time->tm_mday << '/' << std::setw(2)
  //          << tm_time->tm_hour << std::setw(2) << tm_time->tm_min <<
  //          std::setw(2)
  //          << tm_time->tm_sec << ':';

  stream_ << log_severity_name(severity_);
  stream_ << ":" << filename << "(" << line << ")] ";

  message_start_ = stream_.str().length();
}

}  // namespace logging
}  // namespace base
}  // namespace lynx
