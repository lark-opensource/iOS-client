// Copyright 2021 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a Apache License.
// See http://www.apache.org/licenses/LICENSE-2.0 for details.

#ifndef LYNX_BASE_TRACE_EVENT_PERFETTO_TRACE_BACKEND_H_
#define LYNX_BASE_TRACE_EVENT_PERFETTO_TRACE_BACKEND_H_

#if LYNX_ENABLE_TRACING

#include <memory>

#include "base/trace_event/cpu_info_trace.h"
#include "base/trace_event/perfetto_wrapper.h"
#include "base/trace_event/trace_backend.h"

#if OS_ANDROID
// Keep these in sync with system/core/libcutils/include/cutils/trace.h in
// android source code.
#define ATRACE_TAG_NEVER 0          // This tag is never enabled.
#define ATRACE_TAG_ALWAYS (1 << 0)  // This tag is always enabled.
#define ATRACE_TAG_GRAPHICS (1 << 1)
#define ATRACE_TAG_INPUT (1 << 2)
#define ATRACE_TAG_VIEW (1 << 3)
#define ATRACE_TAG_WEBVIEW (1 << 4)
#define ATRACE_TAG_WINDOW_MANAGER (1 << 5)
#define ATRACE_TAG_ACTIVITY_MANAGER (1 << 6)
#define ATRACE_TAG_SYNC_MANAGER (1 << 7)
#define ATRACE_TAG_AUDIO (1 << 8)
#define ATRACE_TAG_VIDEO (1 << 9)
#define ATRACE_TAG_CAMERA (1 << 10)
#define ATRACE_TAG_HAL (1 << 11)
#define ATRACE_TAG_APP (1 << 12)
#define ATRACE_TAG_RESOURCES (1 << 13)
#define ATRACE_TAG_DALVIK (1 << 14)
#define ATRACE_TAG_RS (1 << 15)
#define ATRACE_TAG_BIONIC (1 << 16)
#define ATRACE_TAG_POWER (1 << 17)
#define ATRACE_TAG_PACKAGE_MANAGER (1 << 18)
#define ATRACE_TAG_SYSTEM_SERVER (1 << 19)
#define ATRACE_TAG_DATABASE (1 << 20)
#define ATRACE_TAG_NETWORK (1 << 21)
#define ATRACE_TAG_ADB (1 << 22)
#define ATRACE_TAG_VIBRATOR (1 << 23)
#define ATRACE_TAG_AIDL (1 << 24)
#define ATRACE_TAG_NNAPI (1 << 25)
#define ATRACE_TAG_RRO (1 << 26)
#define ATRACE_TAG_LAST ATRACE_TAG_RRO
#define ATRACE_TAG_ALL ~((uint64_t)(-1) << 27)
#endif

namespace lynx {
namespace base {
namespace tracing {

class PerfettoTraceBackend : public TraceBackend::Impl {
 public:
  PerfettoTraceBackend() = default;
  virtual ~PerfettoTraceBackend() = default;

  void Start(bool capture_system_trace) override;

  void Stop(bool capture_system_trace) override;

  bool CategoryEnabled(const char *category) override;

  void TraceEventImpl(const char *category, const char *event_name, char phase,
                      TraceBackend::EventCallbackType callback) override;

  void TraceEventImpl(const char *category, const char *event_name,
                      uint64_t timestamp, char phase,
                      TraceBackend::EventCallbackType callback) override;

  void UpdateThreadName(const char *thread_name) override;

 private:
  static void InstallSystemTraceHooks();
  static void UninstallSystemTraceHooks();
  std::unique_ptr<lynx::perfetto::TracingSession> tracing_session_;
  CpuInfoTrace cpu_info_trace_;
};
}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif  // LYNX_ENABLE_TRACING
#endif  // LYNX_BASE_TRACE_EVENT_PERFETTO_TRACE_BACKEND_H_
