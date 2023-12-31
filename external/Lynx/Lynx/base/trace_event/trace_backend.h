// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_TRACE_EVENT_TRACE_BACKEND_H_
#define LYNX_BASE_TRACE_EVENT_TRACE_BACKEND_H_
#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/compiler_specific.h"

#if LYNX_ENABLE_TRACING
#include "third_party/perfetto/gen/protos/perfetto/trace/track_event/debug_annotation.pbzero.h"
#include "third_party/perfetto/gen/protos/perfetto/trace/track_event/track_event.pbzero.h"
#endif

namespace lynx {
namespace base {
namespace tracing {

class TraceBackend {
 public:
#if LYNX_ENABLE_TRACING
  using EventType = lynx::perfetto::protos::pbzero::TrackEvent;
  using EventCallbackType = std::function<void(EventType*)>;
#endif

  class Impl {
   public:
    Impl() = default;

    virtual ~Impl() = default;

    virtual void Start(bool capture_system_trace = false){};

    virtual void Stop(bool capture_system_trace = false){};

    virtual bool CategoryEnabled(const char* category) { return false; }

#if LYNX_ENABLE_TRACING
    virtual void TraceEventImpl(const char* category, const char* event_name,
                                char phase, EventCallbackType callback){};
    virtual void TraceEventImpl(const char* category, const char* event_name,
                                uint64_t timestamp, char phase,
                                EventCallbackType callback){};
#endif

    virtual void UpdateThreadName(const char* thread_name){};
  };

  TraceBackend() = delete;

  ~TraceBackend() = delete;

  // mark this function as NO_INLINE to reduce package (about 25K)
  template <typename... Arguments>
  static void TraceEvent(const char* category, const char* event_name,
                         char phase, Arguments... args) NO_INLINE {
#if LYNX_ENABLE_TRACING
    if (LIKELY(!impl_)) {
      return;
    }
    impl_->TraceEventImpl(
        category, event_name, phase,
        [&args...](EventType* event) { WriteTraceEventArgs(event, args...); });
#endif
  };

  // ADD for FrameView TRACE
  template <typename... Arguments>
  static void TraceEventWithTimestamp(const char* category,
                                      const char* event_name,
                                      uint64_t timestamp, char phase,
                                      Arguments... args) NO_INLINE {
#if LYNX_ENABLE_TRACING
    if (LIKELY(!impl_)) {
      return;
    }
    impl_->TraceEventImpl(
        category, event_name, timestamp, phase,
        [&args...](EventType* event) { WriteTraceEventArgs(event, args...); });
#endif
  };

  template <typename... Arguments>
  static void TraceEvent(const char* category, const char* event_name,
                         char phase, int64_t timestamp, Arguments... args) {
#if LYNX_ENABLE_TRACING
    if (LIKELY(!impl_)) {
      return;
    }
    impl_->TraceEventImpl(category, event_name, phase,
                          [timestamp, &args...](EventType* event) {
                            event->set_timestamp_absolute_us(timestamp);
                            WriteTraceEventArgs(event, args...);
                          });
#endif
  }

  static bool CategoryEnabled(const char* category) {
#if LYNX_ENABLE_TRACING
    if (LIKELY(!impl_)) {
      return false;
    }
    return impl_->CategoryEnabled(category);
#else
    return false;
#endif
  }

#if LYNX_ENABLE_TRACING
  static void SetImpl(Impl* impl) { impl_ = impl; };

  static void ResetImpl() { impl_ = nullptr; }

  static Impl* GetImpl() { return impl_; }
#endif

 private:
#if LYNX_ENABLE_TRACING
  static void WriteTraceEventArgs(EventType* event, const char* arg_name,
                                  const char* arg_value) ALWAYS_INLINE {
    auto* debug = event->add_debug_annotations();
    debug->set_name(arg_name);
    debug->set_string_value(arg_value);
  }

  static void WriteTraceEventArgs(EventType* event, const char* arg_name,
                                  int64_t arg_value) ALWAYS_INLINE {
    auto* debug = event->add_debug_annotations();
    debug->set_name(arg_name);
    debug->set_int_value(arg_value);
  }

  static void WriteTraceEventArgs(EventType* event,
                                  EventCallbackType callback) ALWAYS_INLINE {
    callback(event);
  }

  static void WriteTraceEventArgs(EventType* event) ALWAYS_INLINE {}

  template <typename... Arguments>
  static void WriteTraceEventArgs(EventType* event, const char* arg_name,
                                  const char* arg_value,
                                  Arguments... args) ALWAYS_INLINE {
    auto* debug = event->add_debug_annotations();
    debug->set_name(arg_name);
    debug->set_string_value(arg_value);
    WriteTraceEventArgs(event, args...);
  }

  template <typename... Arguments>
  static void WriteTraceEventArgs(EventType* event, const char* arg_name,
                                  int64_t arg_value,
                                  Arguments... args) ALWAYS_INLINE {
    auto* debug = event->add_debug_annotations();
    debug->set_name(arg_name);
    debug->set_int_value(arg_value);
    WriteTraceEventArgs(event, args...);
  }
#endif
  BASE_EXPORT_FOR_DEVTOOL static Impl* impl_;
};

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif  // LYNX_BASE_TRACE_EVENT_TRACE_BACKEND_H_
