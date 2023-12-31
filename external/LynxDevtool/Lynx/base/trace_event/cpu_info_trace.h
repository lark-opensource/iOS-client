// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_TRACE_EVENT_CPU_INFO_TRACE_H_
#define LYNX_BASE_TRACE_EVENT_CPU_INFO_TRACE_H_

#if LYNX_ENABLE_TRACING
#include <memory>
#include <utility>
#include <vector>

#include "base/base_export.h"
#include "base/thread/timed_task.h"
#include "third_party/fml/thread.h"

namespace lynx {
namespace base {
namespace tracing {

class CpuInfoTrace {
 public:
  using CpuFreq = std::pair</*cpu_index*/ uint32_t, /* cpu_freq(GHz) */ float>;

  CpuInfoTrace();
  ~CpuInfoTrace() = default;
  void DispatchBegin();
  void DispatchEnd();

 private:
  const std::vector<CpuFreq> ReadCpuCurFreq();
  fml::Thread thread_;
  std::unique_ptr<TimedTaskManager> timer_;
};

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif  // LYNX_ENABLE_TRACING

#endif  // LYNX_BASE_TRACE_EVENT_CPU_INFO_TRACE_H_
