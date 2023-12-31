#ifndef LYNX_BASE_TRACE_EVENT_TRACE_EVENT_H_
#define LYNX_BASE_TRACE_EVENT_TRACE_EVENT_H_

// The following optional arguments can be passed to `TRACE_EVENT` to add extra
// information to events:
//
//  TRACE_EVENT("cat", "name"[, lambda]);
//
//  TRACE_EVENT("cat", "name"[, "debug_name1", debug_value1]
//                           [, "debug_name2", debug_value2]);
//
// Some examples of TRACE_EVENT API:
//
// 1. A simple scoped trace event:
//
//   TRACE_EVENT("category", "Name");
//
// 2. Mark the begin and end of a trace event:
//
//   TRACE_EVENT_BEGIN("category", "Name");
//   TRACE_EVENT_END("category");
//
// Note that track events must be nested consistently, i.e., the following is
// not allowed:
//
//    TRACE_EVENT_BEGIN("a", "bar", ...);
//    TRACE_EVENT_BEGIN("b", "foo", ...);
//    TRACE_EVENT_END("a");  // "foo" must be closed before "bar".
//    TRACE_EVENT_END("b");
//
// 3. a trace event with debug annotations:
//
//   TRACE_EVENT("category", "name", "arg", value);
//   TRACE_EVENT("category", "name", "arg", value, "arg2", value2);
//
// 4. a trace event with a lambda:
//
//   TRACE_EVENT("category", "name", [&](lynx::perfetto::eventcontext ctx) {
//     ctx.event()->set_custom_value(...);
//   });
//
// |name| must be a string with static lifetime (i.e., the same
// address must not be used for a different event name in the future). if you
// want to use a dynamically allocated name, do this:
//
//  TRACE_EVENT("category", nullptr, [&](lynx::perfetto::eventcontext ctx) {
//    ctx.event()->set_name(dynamic_name);
//  });
//
// 5. an instant event with debug annotations:
//
//    TRACE_EVENT_INSTANT("category", "name", "arg", value);
//
// in addition, a color value can be passed as a debug annotations, so that the
// frontend can display events with different colors:
//    TRACE_EVENT_INSTANT("category", "name", "color", "#64b5f6");
//
#include <cstdint>

namespace lynx {
namespace base {
namespace tracing {
__attribute__((unused)) static uint64_t GetFlowId() {
  static uint64_t sTraceEventFlowId = 0;
  return sTraceEventFlowId++;
}
}  // namespace tracing
}  // namespace base
}  // namespace lynx

#if LYNX_ENABLE_TRACING

#define NO_INSTRUMENT __attribute__((no_instrument_function))

#define TRACE_EVENT_PHASE_BEGIN ('B')
#define TRACE_EVENT_PHASE_END ('E')
#define TRACE_EVENT_PHASE_COMPLETE ('X')
#define TRACE_EVENT_PHASE_INSTANT ('I')
#define TRACE_EVENT_PHASE_ASYNC_BEGIN ('S')
#define TRACE_EVENT_PHASE_ASYNC_STEP_INTO ('T')
#define TRACE_EVENT_PHASE_ASYNC_STEP_PAST ('p')
#define TRACE_EVENT_PHASE_ASYNC_END ('F')
#define TRACE_EVENT_PHASE_NESTABLE_ASYNC_BEGIN ('b')
#define TRACE_EVENT_PHASE_NESTABLE_ASYNC_END ('e')
#define TRACE_EVENT_PHASE_NESTABLE_ASYNC_INSTANT ('n')
#define TRACE_EVENT_PHASE_FLOW_BEGIN ('s')
#define TRACE_EVENT_PHASE_FLOW_STEP ('t')
#define TRACE_EVENT_PHASE_FLOW_END ('f')
#define TRACE_EVENT_PHASE_METADATA ('M')
#define TRACE_EVENT_PHASE_COUNTER ('C')
#define TRACE_EVENT_PHASE_SAMPLE ('P')
#define TRACE_EVENT_PHASE_CREATE_OBJECT ('N')
#define TRACE_EVENT_PHASE_SNAPSHOT_OBJECT ('O')
#define TRACE_EVENT_PHASE_DELETE_OBJECT ('D')
#define TRACE_EVENT_PHASE_MEMORY_DUMP ('v')
#define TRACE_EVENT_PHASE_MARK ('R')
#define TRACE_EVENT_PHASE_CLOCK_SYNC ('c')
#define TRACE_EVENT_PHASE_ENTER_CONTEXT ('(')
#define TRACE_EVENT_PHASE_LEAVE_CONTEXT (')')

#if LYNX_ENABLE_TRACING_BACKEND_NATIVE

#include <string>
#include <unordered_map>

#if OS_ANDROID

namespace lynx {
namespace base {
extern void *(*ATrace_beginSection)(const char *section_name);
extern void *(*ATrace_endSection)(void);
extern void *(*ATrace_beginAsyncSection)(const char *section_name,
                                         int32_t cookie);
extern void *(*ATrace_endAsyncSection)(const char *section_name,
                                       int32_t cookie);

class ScopedTracer {
 public:
  inline ScopedTracer(const char *name) {
    if (ATrace_beginSection) ATrace_beginSection(name);
  }

  inline ~ScopedTracer() {
    if (ATrace_endSection) ATrace_endSection();
  }
};
}  // namespace base
}  // namespace lynx
#define TRACE_EVENT_CATEGORY_ENABLED(category) true
#define TRACE_EVENT(category, name, ...) TRACE_EVENT0(category, name)
#define TRACE_EVENT_BEGIN(category, name, ...) \
  TRACE_EVENT_BEGIN0(category, name)
#define TRACE_EVENT_END(category) TRACE_EVENT_END0(category, "end")
#define TRACE_EVENT_END_WITH_NAME(category, name) \
  TRACE_EVENT_END0(category, "end")
#define TRACE_EVENT_INSTANT(category, name, ...) \
  TRACE_EVENT_INSTANT0(category, name)

#define INTERNAL_TRACE_EVENT_UID3(a, b) trace_event_uid_##a##b
#define INTERNAL_TRACE_EVENT_UID2(a, b) INTERNAL_TRACE_EVENT_UID3(a, b)
#define INTERNAL_TRACE_EVENT_UID(name) INTERNAL_TRACE_EVENT_UID2(name, __LINE__)

#define TRACE_EVENT0(category, name) \
  lynx::base::ScopedTracer INTERNAL_TRACE_EVENT_UID(tracer)(name);
#define TRACE_EVENT1(category, name, arg1_name, arg1_val) \
  TRACE_EVENT0(category, name)
#define TRACE_EVENT2(category, name, arg1_name, arg1_val, arg2_name, arg2_val) \
  TRACE_EVENT0(category, name)

#define TRACE_EVENT_BEGIN0(category, name) \
  if (lynx::base::ATrace_beginSection) lynx::base::ATrace_beginSection(name);
#define TRACE_EVENT_BEGIN1(category, name, arg1_name, arg1_val) \
  TRACE_EVENT_BEGIN0(category, name)
#define TRACE_EVENT_BEGIN2(category, name, arg1_name, arg1_val, arg2_name, \
                           arg2_val)                                       \
  TRACE_EVENT_BEGIN0(category, name)

#define TRACE_EVENT_END0(category, name) \
  if (lynx::base::ATrace_endSection) lynx::base::ATrace_endSection();
#define TRACE_EVENT_END1(category, name, arg1_name, arg1_val) \
  TRACE_EVENT_END0(category, name)
#define TRACE_EVENT_END2(category, name, arg1_name, arg1_val, arg2_name, \
                         arg2_val)                                       \
  TRACE_EVENT_END0(category, name)

#define TRACE_EVENT_ASYNC_BEGIN0(category, name, id) \
  if (lynx::base::ATrace_beginAsyncSection)          \
    lynx::base::ATrace_beginAsyncSection(name, (int32_t)id);
#define TRACE_EVENT_ASYNC_BEGIN1(category, name, id, arg1_name, arg1_val) \
  TRACE_EVENT_ASYNC_BEGIN0(category, name, id)
#define TRACE_EVENT_ASYNC_BEGIN2(category, name, id, arg1_name, arg1_val, \
                                 arg2_name, arg2_val)                     \
  TRACE_EVENT_ASYNC_BEGIN0(category, name, id)

#define TRACE_EVENT_ASYNC_END0(category, name, id) \
  if (lynx::base::ATrace_endAsyncSection)          \
    lynx::base::ATrace_endAsyncSection(name, (int32_t)id);
#define TRACE_EVENT_ASYNC_END1(category, name, id, arg1_name, arg1_val) \
  TRACE_EVENT_ASYNC_END0(category, name, id)
#define TRACE_EVENT_ASYNC_END2(category, name, id, arg1_name, arg1_val, \
                               arg2_name, arg2_val)                     \
  TRACE_EVENT_ASYNC_END0(category, name, id)

#define TRACE_EVENT_FLOW_BEGIN0(category, name, id)
#define TRACE_EVENT_FLOW_BEGIN1(category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_FLOW_BEGIN2(category, name, id, arg1_name, arg1_val, \
                                arg2_name, arg2_val)

#define TRACE_EVENT_FLOW_STEP0(category, name, id)
#define TRACE_EVENT_FLOW_STEP1(category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_FLOW_STEP2(category, name, id, arg1_name, arg1_val, \
                               arg2_name, arg2_val)

#define TRACE_EVENT_FLOW_END0(category, name, id)
#define TRACE_EVENT_FLOW_END1(category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_FLOW_END2(category, name, id, arg1_name, arg1_val, \
                              arg2_name, arg2_val)

#define TRACE_EVENT_INSTANT0(category, name)
#define TRACE_EVENT_INSTANT1(category, name, arg1_name, arg1_val)
#define TRACE_EVENT_INSTANT2(category, name, arg1_name, arg1_val, arg2_name, \
                             arg2_val)
#define TRACE_EVENT_CLOCK_SYNC_RECEIVER(sync_id)
#elif OS_IOS || OS_OSX
#include <sys/kdebug_signpost.h>

#include "base/log/logging.h"

// IOS 10.0,*
// /macOS 10.12 ,*
namespace lynx {
namespace base {
// TODO: ios 10.0 string -> int

class TraceMap {
 public:
  static TraceMap *GetInstance() {
    static TraceMap *instance = new TraceMap();
    return instance;
  }
  std::unordered_map<std::string, uint32_t> ios_trace_map;
  Lock g_lock_ios_trace_map;
  uint32_t ios_trace_name;

 private:
  TraceMap() {}
  TraceMap(const TraceMap &obj) = delete;
  TraceMap(TraceMap &&obj) = delete;
};

#define IOS_TRACE_MAP lynx::base::TraceMap::GetInstance()->ios_trace_map
#define G_LOCK_IOS_TRACE_MAP \
  lynx::base::TraceMap::GetInstance()->g_lock_ios_trace_map
#define IOS_TRACE_NAME lynx::base::TraceMap::GetInstance()->ios_trace_name

class ScopedTracer {
 public:
  ScopedTracer(uint32_t code, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
               uintptr_t arg4)
      : code_(code), arg1_(arg1), arg2_(arg2), arg3_(arg3), arg4_(arg4) {
    if (__builtin_available(iOS 10.0, macOS 10.12, *)) {
      kdebug_signpost_start(code_, arg1_, arg2_, arg3_, arg4_);
    }
  }
  ~ScopedTracer() {
    if (__builtin_available(iOS 10.0, macOS 10.12, *)) {
      kdebug_signpost_end(code_, arg1_, arg2_, arg3_, arg4_);
    }
  }

 private:
  uint32_t code_;
  uintptr_t arg1_, arg2_, arg3_, arg4_;

  ScopedTracer(const ScopedTracer &) = delete;
  ScopedTracer &operator=(const ScopedTracer &) = delete;
};
}  // namespace base
}  // namespace lynx

#define INTERNAL_TRACE_EVENT_UID3(a, b) trace_event_uid_##a##b
#define INTERNAL_TRACE_EVENT_UID2(a, b) INTERNAL_TRACE_EVENT_UID3(a, b)
#define INTERNAL_TRACE_EVENT_UID(name) INTERNAL_TRACE_EVENT_UID2(name, __LINE__)

#define INNER_BEGIN_LOG(name, arg1, arg2, arg3, arg4)         \
  if (__builtin_available(iOS 10.0, macOS 10.12, *)) {        \
    if (name != nullptr) {                                    \
      {                                                       \
        lynx::base::AutoLock auto_lock(G_LOCK_IOS_TRACE_MAP); \
        if (IOS_TRACE_MAP.find(name) == IOS_TRACE_MAP.end())  \
          IOS_TRACE_MAP[name] = IOS_TRACE_NAME++;             \
      }                                                       \
      kdebug_signpost_start(IOS_TRACE_MAP[name], 0, 0, 0, 0); \
    }                                                         \
  }

#define INNER_END_LOG(name, arg1, arg2, arg3, arg4)           \
  if (__builtin_available(iOS 10.0, macOS 10.12, *)) {        \
    if (name != nullptr) {                                    \
      if (IOS_TRACE_MAP.find(name) != IOS_TRACE_MAP.end())    \
        kdebug_signpost_end(IOS_TRACE_MAP[name], 0, 0, 0, 0); \
    }                                                         \
  }

#define INNER_BEGIN_LOG_WITH_ID(name, arg1, arg2, arg3, arg4)               \
  if (__builtin_available(iOS 10.0, macOS 10.12, *)) {                      \
    {                                                                       \
      if (name != nullptr) {                                                \
        lynx::base::AutoLock auto_lock(G_LOCK_IOS_TRACE_MAP);               \
        if (IOS_TRACE_MAP.find(name) == IOS_TRACE_MAP.end())                \
          IOS_TRACE_MAP[name] = IOS_TRACE_NAME++;                           \
      }                                                                     \
      kdebug_signpost_start(IOS_TRACE_MAP[name], (uintptr_t)arg1, 0, 0, 0); \
    }                                                                       \
  }

#define INNER_END_LOG_WITH_ID(name, arg1, arg2, arg3, arg4)                 \
  if (__builtin_available(iOS 10.0, macOS 10.12, *)) {                      \
    if (name != nullptr) {                                                  \
      if (IOS_TRACE_MAP.find(name) != IOS_TRACE_MAP.end())                  \
        kdebug_signpost_end(IOS_TRACE_MAP[name], (uintptr_t)arg1, 0, 0, 0); \
    }                                                                       \
  }

#define INNER_EVENT_EMIT_LOG(name, arg1, arg2, arg3, arg4)    \
  if (__builtin_available(iOS 10.0, macOS 10.12, *)) {        \
    {                                                         \
      if (name != nullptr) {                                  \
        lynx::base::AutoLock auto_lock(G_LOCK_IOS_TRACE_MAP); \
        if (IOS_TRACE_MAP.find(name) == IOS_TRACE_MAP.end())  \
          IOS_TRACE_MAP[name] = IOS_TRACE_NAME++;             \
      }                                                       \
      kdebug_signpost(IOS_TRACE_MAP[name], 0, 0, 0, 0);       \
    }                                                         \
  }

#define TRACE_EVENT(category, name, ...) TRACE_EVENT0(category, name)
#define TRACE_EVENT_BEGIN(category, name, ...) \
  TRACE_EVENT_BEGIN0(category, name)
#define TRACE_EVENT_END(category) TRACE_EVENT_END0(category, "end")
#define TRACE_EVENT_END_WITH_NAME(category, name) \
  TRACE_EVENT_END0(category, "end")
#define TRACE_EVENT_INSTANT(category, name, ...) \
  TRACE_EVENT_INSTANT0(category, name)
#define TRACE_EVENT_CATEGORY_ENABLED(category) true

#define TRACE_EVENT0(category, name)                           \
  if (name != nullptr) {                                       \
    {                                                          \
      lynx::base::AutoLock auto_lock(G_LOCK_IOS_TRACE_MAP);    \
      if (IOS_TRACE_MAP.find(name) == IOS_TRACE_MAP.end())     \
        IOS_TRACE_MAP[name] = IOS_TRACE_NAME++;                \
    }                                                          \
    lynx::base::ScopedTracer INTERNAL_TRACE_EVENT_UID(tracer)( \
        IOS_TRACE_MAP[name], 0, 0, 0, 0);                      \
  }

#define TRACE_EVENT1(category, name, arg1_name, arg1_val) \
  TRACE_EVENT0(category, name)
#define TRACE_EVENT2(category, name, arg1_name, arg1_val, arg2_name, arg2_val) \
  TRACE_EVENT0(category, name)

#define TRACE_EVENT_BEGIN0(category, name) INNER_BEGIN_LOG(name, 0, 0, 0, 0)
#define TRACE_EVENT_BEGIN1(category, name, arg1_name, arg1_val) \
  TRACE_EVENT_BEGIN0(category, name)
#define TRACE_EVENT_BEGIN2(category, name, arg1_name, arg1_val, arg2_name, \
                           arg2_val)                                       \
  TRACE_EVENT_BEGIN0(category, name)

#define TRACE_EVENT_END0(category, name) INNER_END_LOG(name, 0, 0, 0, 0)
#define TRACE_EVENT_END1(category, name, arg1_name, arg1_val) \
  TRACE_EVENT_END0(category, name)
#define TRACE_EVENT_END2(category, name, arg1_name, arg1_val, arg2_name, \
                         arg2_val)                                       \
  TRACE_EVENT_END0(category, name)

#define TRACE_EVENT_ASYNC_BEGIN0(category, name, id) \
  INNER_BEGIN_LOG_WITH_ID(name, id, 0, 0, 0)
#define TRACE_EVENT_ASYNC_BEGIN1(category, name, id, arg1_name, arg1_val) \
  TRACE_EVENT_ASYNC_BEGIN0(category, name, id)
#define TRACE_EVENT_ASYNC_BEGIN2(category, name, id, arg1_name, arg1_val, \
                                 arg2_name, arg2_val)                     \
  TRACE_EVENT_ASYNC_BEGIN0(category, name, id)

#define TRACE_EVENT_ASYNC_END0(category, name, id) \
  INNER_END_LOG_WITH_ID(name, id, 0, 0, 0)
#define TRACE_EVENT_ASYNC_END1(category, name, id, arg1_name, arg1_val) \
  TRACE_EVENT_ASYNC_END0(category, name, id)
#define TRACE_EVENT_ASYNC_END2(category, name, id, arg1_name, arg1_val, \
                               arg2_name, arg2_val)                     \
  TRACE_EVENT_ASYNC_END0(category, name, id)

#define TRACE_EVENT_FLOW_BEGIN0(category, name, id)
#define TRACE_EVENT_FLOW_BEGIN1(category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_FLOW_BEGIN2(category, name, id, arg1_name, arg1_val, \
                                arg2_name, arg2_val)

#define TRACE_EVENT_FLOW_STEP0(category, name, id)
#define TRACE_EVENT_FLOW_STEP1(category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_FLOW_STEP2(category, name, id, arg1_name, arg1_val, \
                               arg2_name, arg2_val)

#define TRACE_EVENT_FLOW_END0(category, name, id)
#define TRACE_EVENT_FLOW_END1(category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_FLOW_END2(category, name, id, arg1_name, arg1_val, \
                              arg2_name, arg2_val)

#define TRACE_EVENT_INSTANT0(category, name) \
  INNER_EVENT_EMIT_LOG(name, 0, 0, 0, 0)
#define TRACE_EVENT_INSTANT1(category, name, arg1_name, arg1_val) \
  TRACE_EVENT_INSTANT0(category, name)
#define TRACE_EVENT_INSTANT2(category, name, arg1_name, arg1_val, arg2_name, \
                             arg2_val)                                       \
  TRACE_EVENT_INSTANT0(category, name)
#endif  // OS_ANDROID or OS_IOS
// LYNX_ENABLE_TRACING_BACKEND_NATIVE
#elif OS_WIN
#include "base/trace_event/log_tracer.h"
#define TRACE_EVENT_BEGIN(category, name, ...) \
  lynx::base::tracing::GLogTracer::GetInstance()->Begin(category, name)
#define TRACE_EVENT_END(category, ...) \
  lynx::base::tracing::GLogTracer::GetInstance()->End(category)
#define TRACE_EVENT_END_WITH_NAME(category, name) \
  TRACE_EVENT_END0(category, "end")               \
  lynx::base::tracing::GLogTracer::GetInstance()->End(category)

#define INTERNAL_TRACE_EVENT_UID2(a, b) trace_event_uid_##a##b
#define INTERNAL_TRACE_EVENT_UID(name) INTERNAL_TRACE_EVENT_UID2(name, __LINE__)
#define TRACE_EVENT(category, name, ...)                                       \
  lynx::base::tracing::ScopedTracer INTERNAL_TRACE_EVENT_UID(tracer)(category, \
                                                                     name)

#define TRACE_EVENT_FLOW_BEGIN0(category, name, id)                            \
  lynx::base::tracing::ScopedTracer INTERNAL_TRACE_EVENT_UID(tracer)(category, \
                                                                     name)
#define TRACE_EVENT_FLOW_END0(category, name, id)                              \
  lynx::base::tracing::ScopedTracer INTERNAL_TRACE_EVENT_UID(tracer)(category, \
                                                                     name)

#define TRACE_EVENT_INSTANT(category, name, ...)

#else
#include "base/trace_event/perfetto_wrapper.h"
#include "base/trace_event/trace_backend.h"

using TraceEvent = lynx::perfetto::protos::pbzero::TrackEvent;

#define TRACE_EVENT_FLOW_BEGIN0(category, name, id)                   \
  TRACE_EVENT(category, name, [=](lynx::perfetto::EventContext ctx) { \
    ctx.event()->add_flow_ids(id);                                    \
  })

#define TRACE_EVENT_FLOW_END0(category, name, id)                     \
  TRACE_EVENT(category, name, [=](lynx::perfetto::EventContext ctx) { \
    ctx.event()->add_terminating_flow_ids(id);                        \
  })

#endif  // LYNX_ENABLE_TRACING_BACKEND_NATIVE
#else   // LYNX_ENABLE_TRACING

#define TRACE_EVENT_BEGIN(category, name, ...)
#define TRACE_EVENT_END(category, ...)
#define TRACE_EVENT_END_WITH_NAME(category, name)

#define TRACE_EVENT(category, name, ...)
#define TRACE_EVENT_INSTANT(category, name, ...)
#define TRACE_EVENT_CATEGORY_ENABLED(category)
#define TRACE_COUNTER(category, track, ...)

#define TRACE_EVENT0(category, name)
#define TRACE_EVENT1(category, name, arg1_name, arg1_val)
#define TRACE_EVENT2(category, name, arg1_name, arg1_val, arg2_name, arg2_val)

#define TRACE_EVENT_BEGIN0(category, name)
#define TRACE_EVENT_BEGIN1(category, name, arg1_name, arg1_val)
#define TRACE_EVENT_BEGIN2(category, name, arg1_name, arg1_val, arg2_name, \
                           arg2_val)

#define TRACE_EVENT_END0(category, name)
#define TRACE_EVENT_END1(category, name, arg1_name, arg1_val)
#define TRACE_EVENT_END2(category, name, arg1_name, arg1_val, arg2_name, \
                         arg2_val)

#define TRACE_EVENT_ASYNC_BEGIN0(category, name, id)
#define TRACE_EVENT_ASYNC_BEGIN1(category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_ASYNC_BEGIN2(category, name, id, arg1_name, arg1_val, \
                                 arg2_name, arg2_val)

#define TRACE_EVENT_ASYNC_END0(category, name, id)
#define TRACE_EVENT_ASYNC_END1(category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_ASYNC_END2(category, name, id, arg1_name, arg1_val, \
                               arg2_name, arg2_val)

#define TRACE_EVENT_FLOW_BEGIN0(category, name, id)
#define TRACE_EVENT_FLOW_BEGIN1(category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_FLOW_BEGIN2(category, name, id, arg1_name, arg1_val, \
                                arg2_name, arg2_val)

#define TRACE_EVENT_FLOW_STEP0(category, name, id)
#define TRACE_EVENT_FLOW_STEP1(category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_FLOW_STEP2(category, name, id, arg1_name, arg1_val, \
                               arg2_name, arg2_val)

#define TRACE_EVENT_FLOW_END0(category, name, id)
#define TRACE_EVENT_FLOW_END1(category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_FLOW_END2(category, name, id, arg1_name, arg1_val, \
                              arg2_name, arg2_val)

#define TRACE_EVENT_INSTANT0(category, name)
#define TRACE_EVENT_INSTANT1(category, name, arg1_name, arg1_val)
#define TRACE_EVENT_INSTANT2(category, name, arg1_name, arg1_val, arg2_name, \
                             arg2_val)

#define TRACE_EVENT_CLOCK_SYNC_RECEIVER(sync_id)
#endif  // LYNX_ENABLE_TRACING
#endif  // LYNX_BASE_TRACE_EVENT_TRACE_EVENT_H_
