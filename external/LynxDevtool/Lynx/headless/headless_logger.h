// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_HEADLESS_HEADLESS_LOGGER_H_
#define LYNX_HEADLESS_HEADLESS_LOGGER_H_

#include <set>
#include <string>
#include <unordered_map>
#include <utility>

#include "base/blocking_queue.h"
#include "base/log/logging.h"
#include "base/no_destructor.h"

#define Napi NodejsNapi
#include "napi.h"

namespace lynx {

namespace headless {

class Logger {
  using LogSeverity = base::logging::LogSeverity;
  using Callback = std::function<void(LogSeverity, std::string)>;
  using LogMessage = std::pair<LogSeverity, std::string>;

 public:
  static Logger* GetLogger();
  static Napi::Object Init(Napi::Env env, Napi::Object exports);

  Logger();

  ~Logger() = delete;

  void Log(LogSeverity severity, const std::string& message);
  void LogSync(LogSeverity severity, const std::string& message);

  int Subscribe(LogSeverity severity, Callback callback);
  int Subscribe(LogSeverity severity, Napi::Function callback);
  void Unsubscribe(int id);

 private:
  std::mutex callbacks_map_mutex_;
  int callback_id_ = 1;
  std::unordered_map<int, std::pair<LogSeverity, Callback>> callback_map_;
  std::unordered_map<int, std::function<void()>> unsubscribe_cb_;
  base::BlockingQueue<LogMessage> queue_;
};

}  // namespace headless

namespace base::logging {

// Implementation of the Log function in the "base/log/logging.h" file.
void Log(LogMessage* msg);

}  // namespace base::logging
}  // namespace lynx

#undef Napi

#endif  // LYNX_HEADLESS_HEADLESS_LOGGER_H_
