// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_TRACING_TRACE_EVENT_DEVTOOL_H_
#define LYNX_BASE_TRACING_TRACE_EVENT_DEVTOOL_H_

#if LYNX_ENABLE_TRACING
#include <stdint.h>

#include "base/trace_event/trace_backend.h"
#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"

using TraceEvent = lynx::perfetto::protos::pbzero::TrackEvent;

#define TRACE_EVENT_DEVTOOL_INTERNAL_CONCAT2(a, b) a##b
#define TRACE_EVENT_DEVTOOL_INTERNAL_CONCAT(a, b) \
  TRACE_EVENT_DEVTOOL_INTERNAL_CONCAT2(a, b)
#define TRACE_EVENT_DEVTOOL_UID(prefix) \
  TRACE_EVENT_DEVTOOL_INTERNAL_CONCAT(prefix, __LINE__)

#define INTERNAL_TRACE_EVENT_DEVTOOL_ADD(category, name, phase, ...)   \
  lynx::base::tracing::TraceBackend::TraceEvent(category, name, phase, \
                                                ##__VA_ARGS__)
#define INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(phase, category, name, id, \
                                                 ...)                       \
  lynx::base::tracing::TraceBackend::TraceEvent(category, name, phase,      \
                                                ##__VA_ARGS__)

#define INTERNAL_SCOPED_TRACK_EVENT_DEVTOOL(category, name, ...)              \
  struct TRACE_EVENT_DEVTOOL_UID(ScopedEvent) {                               \
    struct EventFinalizer {                                                   \
      /* The parameter is an implementation detail. It allows the          */ \
      /* anonymous struct to use aggregate initialization to invoke the    */ \
      /* lambda (which emits the BEGIN event and returns an integer)       */ \
      /* with the proper reference capture for any                         */ \
      /* TrackEventArgumentFunction in |__VA_ARGS__|. This is required so  */ \
      /* that the scoped event is exactly ONE line and can't escape the    */ \
      /* scope if used in a single line if statement.                      */ \
      EventFinalizer(...) {}                                                  \
      ~EventFinalizer() { TRACE_EVENT_DEVTOOL_END(category); }                \
    } finalizer;                                                              \
  } TRACE_EVENT_DEVTOOL_UID(scoped_event) {                                   \
    [&]() {                                                                   \
      TRACE_EVENT_DEVTOOL_BEGIN(category, name, ##__VA_ARGS__);               \
      return 0;                                                               \
    }()                                                                       \
  }

using TraceEvent = lynx::base::tracing::TraceBackend::EventType;
#define TRACE_EVENT_DEVTOOL(category, name, ...) \
  INTERNAL_SCOPED_TRACK_EVENT_DEVTOOL(category, name, ##__VA_ARGS__)
#define TRACE_EVENT_DEVTOOL_BEGIN(category, name, ...)                      \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(category, name, TRACE_EVENT_PHASE_BEGIN, \
                                   ##__VA_ARGS__)
#define TRACE_EVENT_DEVTOOL_END(category, ...)                 \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(category, /*name=*/nullptr, \
                                   TRACE_EVENT_PHASE_END, ##__VA_ARGS__)
#define TRACE_EVENT_DEVTOOL_INSTANT(category, name, ...)                      \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(category, name, TRACE_EVENT_PHASE_INSTANT, \
                                   ##__VA_ARGS__)
#define TRACE_EVENT_DEVTOOL_CATEGORY_ENABLED(category) \
  lynx::base::tracing::TraceBackend::CategoryEnabled(category)

#define INTERNAL_TRACE_EVENT_DEVTOOL_UID2(a, b) trace_event_uid_##a##b
#define INTERNAL_TRACE_EVENT_DEVTOOL_UID(name) \
  INTERNAL_TRACE_EVENT_DEVTOOL_UID2(name, __LINE__)

#define STRINGIFY(S) #S
#define DEFER_STRINGIFY(S) STRINGIFY(S)
#define FILENAME() __FILE__ "-" DEFER_STRINGIFY(__LINE__)

#define TRACE_EVENT_DEVTOOL0(category, name) TRACE_EVENT_DEVTOOL(category, name)

#define TRACE_EVENT_DEVTOOL1(category, name, arg1_name, arg1_val) \
  TRACE_EVENT_DEVTOOL(category, name, arg1_name, arg1_val);

#define TRACE_EVENT_DEVTOOL2(category, name, arg1_name, arg1_val, arg2_name, \
                             arg2_val)                                       \
  TRACE_EVENT_DEVTOOL(category, name, arg1_name, arg1_val, arg2_name, arg2_val);

#define TRACE_EVENT_DEVTOOL_BEGIN0(category, name) \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(TRACE_EVENT_PHASE_BEGIN, category, name)
#define TRACE_EVENT_DEVTOOL_BEGIN1(category, name, arg1_name, arg1_val)     \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(TRACE_EVENT_PHASE_BEGIN, category, name, \
                                   arg1_name, arg1_val)
#define TRACE_EVENT_DEVTOOL_BEGIN2(category, name, arg1_name, arg1_val,     \
                                   arg2_name, arg2_val)                     \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(TRACE_EVENT_PHASE_BEGIN, category, name, \
                                   arg1_name, arg1_val, arg2_name, arg2_val)

#define TRACE_EVENT_DEVTOOL_END0(category, name) \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(TRACE_EVENT_PHASE_END, category, name)
#define TRACE_EVENT_DEVTOOL_END1(category, name, arg1_name, arg1_val)     \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(TRACE_EVENT_PHASE_END, category, name, \
                                   arg1_name, arg1_val)
#define TRACE_EVENT_DEVTOOL_END2(category, name, arg1_name, arg1_val,     \
                                 arg2_name, arg2_val)                     \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(TRACE_EVENT_PHASE_END, category, name, \
                                   arg1_name, arg1_val, arg2_name, arg2_val)

#define TRACE_EVENT_DEVTOOL_ASYNC_BEGIN0(category, name, id) \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(                  \
      TRACE_EVENT_PHASE_NESTABLE_ASYNC_BEGIN, category, name, id)
#define TRACE_EVENT_DEVTOOL_ASYNC_BEGIN1(category, name, id, arg1_name,      \
                                         arg1_val)                           \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(                                  \
      TRACE_EVENT_PHASE_NESTABLE_ASYNC_BEGIN, category, name, id, arg1_name, \
      arg1_val)
#define TRACE_EVENT_DEVTOOL_ASYNC_BEGIN2(category, name, id, arg1_name,      \
                                         arg1_val, arg2_name, arg2_val)      \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(                                  \
      TRACE_EVENT_PHASE_NESTABLE_ASYNC_BEGIN, category, name, id, arg1_name, \
      arg1_val, arg2_name, arg2_val)

#define TRACE_EVENT_DEVTOOL_ASYNC_END0(category, name, id) \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(                \
      TRACE_EVENT_PHASE_NESTABLE_ASYNC_END, category, name, id)
#define TRACE_EVENT_DEVTOOL_ASYNC_END1(category, name, id, arg1_name,      \
                                       arg1_val)                           \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(                                \
      TRACE_EVENT_PHASE_NESTABLE_ASYNC_END, category, name, id, arg1_name, \
      arg1_val)
#define TRACE_EVENT_DEVTOOL_ASYNC_END2(category, name, id, arg1_name,      \
                                       arg1_val, arg2_name, arg2_val)      \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(                                \
      TRACE_EVENT_PHASE_NESTABLE_ASYNC_END, category, name, id, arg1_name, \
      arg1_val, arg2_name, arg2_val)

#define TRACE_EVENT_DEVTOOL_FLOW_BEGIN0(category, name, id)              \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_BEGIN, \
                                           category, name, id)
#define TRACE_EVENT_DEVTOOL_FLOW_BEGIN1(category, name, id, arg1_name, \
                                        arg1_val)                      \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(                            \
      TRACE_EVENT_PHASE_FLOW_BEGIN, category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_DEVTOOL_FLOW_BEGIN2(category, name, id, arg1_name,    \
                                        arg1_val, arg2_name, arg2_val)    \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_BEGIN,  \
                                           category, name, id, arg1_name, \
                                           arg1_val, arg2_name, arg2_val)

#define TRACE_EVENT_DEVTOOL_FLOW_STEP0(category, name, id)              \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_STEP, \
                                           category, name, id)
#define TRACE_EVENT_DEVTOOL_FLOW_STEP1(category, name, id, arg1_name, \
                                       arg1_val)                      \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(                           \
      TRACE_EVENT_PHASE_FLOW_STEP, category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_DEVTOOL_FLOW_STEP2(category, name, id, arg1_name,     \
                                       arg1_val, arg2_name, arg2_val)     \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_STEP,   \
                                           category, name, id, arg1_name, \
                                           arg1_val, arg2_name, arg2_val)

#define TRACE_EVENT_DEVTOOL_FLOW_END0(category, name, id)              \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_END, \
                                           category, name, id)
#define TRACE_EVENT_DEVTOOL_FLOW_END1(category, name, id, arg1_name, arg1_val) \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(                                    \
      TRACE_EVENT_PHASE_FLOW_END, category, name, id, arg1_name, arg1_val)
#define TRACE_EVENT_DEVTOOL_FLOW_END2(category, name, id, arg1_name, arg1_val, \
                                      arg2_name, arg2_val)                     \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_END,         \
                                           category, name, id, arg1_name,      \
                                           arg1_val, arg2_name, arg2_val)

#define TRACE_EVENT_DEVTOOL_INSTANT0(category, name) \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(TRACE_EVENT_PHASE_INSTANT, category, name)
#define TRACE_EVENT_DEVTOOL_INSTANT1(category, name, arg1_name, arg1_val)     \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(TRACE_EVENT_PHASE_INSTANT, category, name, \
                                   arg1_name, arg1_val)
#define TRACE_EVENT_DEVTOOL_INSTANT2(category, name, arg1_name, arg1_val,     \
                                     arg2_name, arg2_val)                     \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(TRACE_EVENT_PHASE_INSTANT, category, name, \
                                   arg1_name, arg1_val, arg2_name, arg2_val)
#define TRACE_EVENT_DEVTOOL_CLOCK_SYNC_RECEIVER(sync_id)                       \
  INTERNAL_TRACE_EVENT_DEVTOOL_ADD(TRACE_EVENT_PHASE_CLOCK_SYNC, "clock_sync", \
                                   "__metadata", "sync_id", sync_id)

#endif  // LYNX_ENABLE_TRACING
#endif  // LYNX_BASE_TRACING_TRACE_EVENT_DEVTOOL_H_
