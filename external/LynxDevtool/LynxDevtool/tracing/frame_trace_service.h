// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_TRACE_EVENT_FRAME_TRACE_SERVICE_H_
#define LYNX_BASE_TRACE_EVENT_FRAME_TRACE_SERVICE_H_

#if LYNX_ENABLE_TRACING
#include <string>

#include "third_party/fml/thread.h"

namespace lynx {
namespace base {
namespace tracing {

class FrameTraceService
    : public std::enable_shared_from_this<FrameTraceService> {
 public:
  FrameTraceService();
  ~FrameTraceService() = default;
  void SendScreenshots(const std::string& snapshot);
  void SendFPSData(const uint64_t& startTime, const uint64_t& endTime);
  void Initialize();

 private:
  void FPSTrace(const uint64_t startTime, const uint64_t endTime);
  void Screenshots(const std::string& snapshot);

 private:
  fml::Thread thread_;
};

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif  // LYNX_ENABLE_TRACING
#endif  // LYNX_BASE_TRACE_EVENT_FRAME_TRACE_CONTROLLER_H_
