#include "basic/log/logging.h"

#include <unistd.h>

#include <algorithm>
#include <cstring>
#include <ctime>
#include <iomanip>
#include <ostream>
#include <string>

namespace vmsdk {
namespace general {
namespace logging {
namespace {

const char *const log_severity_names[LOG_NUM_SEVERITIES] = {"INFO", "WARNING",
                                                            "ERROR", "FATAL"};

const char *log_severity_name(int severity) {
  if (severity >= 0 && severity < LOG_NUM_SEVERITIES)
    return log_severity_names[severity];
  return "UNKNOWN";
}

int g_min_log_level = 0;
}  // namespace

void SetMinLogLevel(int level) { g_min_log_level = std::min(LOG_FATAL, level); }

int GetMinAllLogLevel() { return std::min(g_min_log_level, LOG_INFO); }

LogMessage::LogMessage(const char *file, int line, LogSeverity severity)
    : severity_(severity), file_(file), line_(line) {
  Init(file_, line_);
}

LogMessage::~LogMessage() {
  // on Windows, use spdlog which add newline at the end of each line.
#if !defined(_WIN32)
  stream_ << std::endl;
#endif

#if defined(OS_ANDROID) || defined(OS_IOS) || defined(OS_OSX)
  vmsdk::general::logging::Log(this);
#else
  std::string str_newline(stream_.str());
  printf("vmsdk: %s\n", str_newline.c_str());
#endif

  if (severity_ == LOG_FATAL) {
    abort();
  }
}

// writes the common header info to the stream
void LogMessage::Init(const char *file, int line) {
  std::string filename(file);
  size_t last_slash_pos = filename.find_last_of("\\/");
  if (last_slash_pos != std::string::npos) {
    size_t size = last_slash_pos + 1;
    filename = filename.substr(size, filename.length() - size);
  }

  stream_ << '[';
#if OS_ANDROID
//  stream_ << general::Thread::CurrentId() << ':';
#endif

  time_t t = time(NULL);
  struct tm local_time = {0};

  localtime_r(&t, &local_time);

  struct tm *tm_time = &local_time;
  stream_ << std::setfill('0') << std::setw(2) << 1 + tm_time->tm_mon
          << std::setw(2) << tm_time->tm_mday << '/' << std::setw(2)
          << tm_time->tm_hour << std::setw(2) << tm_time->tm_min << std::setw(2)
          << tm_time->tm_sec << ':';

  if (severity_ >= 0)
    stream_ << log_severity_name(severity_);
  else
    stream_ << "VERBOSE" << -severity_;

  stream_ << ":" << filename << "(" << line << ")] ";
}

}  // namespace logging
}  // namespace general
}  // namespace vmsdk
