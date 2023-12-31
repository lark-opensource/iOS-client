// Copyright 2022 The Lynx Authors. All rights reserved.

#include "animation/animation_vsync_proxy.h"

#include <memory>
#include <set>

#include "base/log/logging.h"
#include "base/trace_event/trace_event.h"
#include "shell/common/vsync_monitor.h"

namespace lynx {
namespace tasm {
class ElementManager;
}
namespace animation {

AnimationVSyncProxy::AnimationVSyncProxy(
    tasm::ElementManager *element_manager,
    const std::shared_ptr<shell::VSyncMonitor> &vsync_monitor)
    : element_manager_(element_manager), vsync_monitor_(vsync_monitor){};

void AnimationVSyncProxy::TickAllElement(fml::TimePoint &frame_time) {
  element_manager_->TickAllElement(frame_time);
}

// The first animation starts an infinite loop.
void AnimationVSyncProxy::RequestNextFrameTime() {
  if (!has_requested_next_frame_ && vsync_monitor_) {
    std::weak_ptr<AnimationVSyncProxy> weak_ptr{shared_from_this()};
    vsync_monitor_->AsyncRequestVSync(
        reinterpret_cast<uintptr_t>(this),
        [weak_ptr](int64_t frame_start, int64_t frame_end) {
          TRACE_EVENT(LYNX_TRACE_CATEGORY,
                      "AnimationVsyncProxy::VsyncFrameTime");
          // TODO(WUJINTIAN): Access animation vsync proxy and element manager
          // through engine actor, instead of accessing them directly.
          auto shared_ptr = weak_ptr.lock();
          if (shared_ptr != nullptr) {
            shared_ptr->MarkNextFrameHasArrived();
            fml::TimePoint frame_time = fml::TimePoint::FromEpochDelta(
                fml::TimeDelta::FromNanoseconds(frame_start));
            shared_ptr->TickAllElement(frame_time);
          }
        });
    has_requested_next_frame_ = true;
  }
}

}  // namespace animation
}  // namespace lynx
