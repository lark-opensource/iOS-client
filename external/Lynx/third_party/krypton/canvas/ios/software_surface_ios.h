// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef CANVAS_IOS_SOFTWARE_SURFACE_IOS_H_
#define CANVAS_IOS_SOFTWARE_SURFACE_IOS_H_

#include <atomic>

#include "canvas/instance_guard.h"
#include "canvas/surface/software_surface.h"

namespace lynx {
namespace canvas {

class SoftwareSurfaceIOS : public SoftwareSurface {
 public:
  SoftwareSurfaceIOS(CAEAGLLayer *layer);
  ~SoftwareSurfaceIOS() override;

  SoftwareSurfaceIOS(const SoftwareSurfaceIOS &) = delete;
  SoftwareSurfaceIOS &operator=(const SoftwareSurfaceIOS &) = delete;

  void Init() override;
  int32_t Width() const override;
  int32_t Height() const override;

  uint8_t *Buffer() const override;
  int32_t BytesPerRow() const override;

  void Flush() override;

  bool Valid() const override;

 private:
  CAEAGLLayer *layer_;
  float width_ = 0.f;
  float height_ = 0.f;
  uint8_t *buffer_ = nullptr;
  CGColorSpaceRef color_space_ = nullptr;
  CGContextRef context_ = nullptr;
  std::atomic<bool> blocked_ = false;
  std::shared_ptr<InstanceGuard<SoftwareSurfaceIOS>> instance_guard_ = nullptr;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_IOS_SOFTWARE_SURFACE_IOS_H_
