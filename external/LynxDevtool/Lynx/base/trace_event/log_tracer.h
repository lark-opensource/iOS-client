// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_TRACE_EVENT_LOG_TRACER_H_
#define LYNX_BASE_TRACE_EVENT_LOG_TRACER_H_

#include <chrono>
#include <fstream>
#include <list>
#include <mutex>
#include <string>

namespace lynx {
namespace base {
namespace tracing {

class LogTracer {
 public:
  explicit LogTracer(const std::string& filepath = "");
  LogTracer(const LogTracer&) = delete;
  LogTracer operator=(const LogTracer&) = delete;

  void Begin(const char* category, const char* name);
  void End(const char* category);

  void Log(const std::string& msg);

  using Clock = std::chrono::high_resolution_clock;
  using Duration = Clock::duration;
  using TimePoint = std::chrono::time_point<Clock, Duration>;
  static TimePoint Now() { return Clock::now(); }

  struct Event {
    std::string category;
    std::string name;
    TimePoint tp;
    Event() = default;
    Event(const std::string& c, const std::string& n, const TimePoint& t)
        : category(c), name(n), tp(t) {}
    bool operator==(const Event& that) {
      return category == that.category && name == that.name;
    }
  };

 private:
  std::string filepath_;
  std::ofstream ofs_;
  // events in the time sequence (front is the newest)
  std::list<Event> events_;
  std::mutex events_mutex_;
};

class GLogTracer {
 public:
  static LogTracer* GetInstance() {
    static LogTracer* instance = new LogTracer("lynx_trace.log");
    return instance;
  }

 private:
  GLogTracer() {}
  GLogTracer(const GLogTracer& obj) = delete;
  GLogTracer(GLogTracer&& obj) = delete;
};

class ScopedTracer {
 public:
  ScopedTracer(const char* category, const char* name) : category_(category) {
    GLogTracer::GetInstance()->Begin(category, name);
  }
  ~ScopedTracer() { GLogTracer::GetInstance()->End(category_); }

 private:
  const char* category_{};
};

}  // namespace tracing
}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_TRACE_EVENT_LOG_TRACER_H_
