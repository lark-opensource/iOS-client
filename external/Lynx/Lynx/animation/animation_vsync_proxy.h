// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_ANIMATION_ANIMATION_VSYNC_PROXY_H_
#define LYNX_ANIMATION_ANIMATION_VSYNC_PROXY_H_

#include <memory>
#include <set>

#include "third_party/fml/time/time_point.h"

namespace lynx {
namespace shell {
class VSyncMonitor;
}
namespace tasm {
class Element;
class ElementManager;
}  // namespace tasm

namespace animation {

class AnimationVSyncProxy
    : public std::enable_shared_from_this<AnimationVSyncProxy> {
 public:
  AnimationVSyncProxy(
      tasm::ElementManager *element_manager,
      const std::shared_ptr<shell::VSyncMonitor> &vsync_monitor = nullptr);
  ~AnimationVSyncProxy() = default;

  // Tick all element of set.
  void TickAllElement(fml::TimePoint &time);

  void RequestNextFrameTime();

  void MarkNextFrameHasArrived() { has_requested_next_frame_ = false; }

  bool HasRequestedNextFrame() { return has_requested_next_frame_; }

 private:
  // It marks whether has requested next frame time.
  bool has_requested_next_frame_ = false;
  tasm::ElementManager *element_manager_;
  // TODO(wujintian): move the member variable to element manager. Then some
  // member function such as `RegistToSet` and `NotifyElementDestroy` and
  // `GetAnimationElements` can be removed.
  std::shared_ptr<shell::VSyncMonitor> vsync_monitor_{nullptr};
};

}  // namespace animation
}  // namespace lynx
#endif  // LYNX_ANIMATION_ANIMATION_VSYNC_PROXY_H_"
