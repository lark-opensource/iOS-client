// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_SURFACE_H_
#define ANIMAX_RENDER_SKIA_SKIA_SURFACE_H_

#include <memory>

#include "animax/render/include/surface.h"
#include "animax/render/skia/skia_canvas.h"

namespace lynx {
namespace animax {

class SkiaSurface : public Surface {
 public:
  SkiaSurface(AnimaXOnScreenSurface *surface, int32_t width, int32_t height);
  ~SkiaSurface() override;

  Canvas *GetCanvas() override;
  void Resize(AnimaXOnScreenSurface *surface, int32_t width,
              int32_t height) override;
  void Clear() override;
  void Flush() override;
  void Destroy() override;

 private:
  sk_sp<SkSurface> sk_surface_ = {};
  std::unique_ptr<SkiaCanvas> skia_canvas_ = {};
  const bool enable_recorder_ = true;
  SkPictureRecorder recorder_ = {};
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_SURFACE_H_
