// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_RASTER_3D_H_
#define CANVAS_WEBGL_RASTER_3D_H_

#include <memory>

#include "canvas/raster.h"
#include "canvas/webgl/canvas_renderbuffer.h"

namespace lynx {
namespace canvas {
class Raster3D : public Raster {
 public:
  Raster3D(const fml::RefPtr<fml::TaskRunner> &gpu_task_runner,
           DrawingBufferOption drawing_buffer_option,
           CountDownWaitableEvent *gpu_waitable_event, int32_t width,
           int32_t height);

  ~Raster3D() override;

  void DoRaster(const std::shared_ptr<command_buffer::RunnableBuffer> &buffer,
                bool blit_to_screen) override;

#ifdef ENABLE_LYNX_CANVAS_SKIA
  sk_sp<SkImage> MakeSnapshot(const SkIRect &rect,
                              const SkPixmap *pixmap) override;
#endif

  void WillAccessContent(bool should_make_current_ctx) override;

 private:
  void MakeSureRenderbufferPrepared();

  void DoBlit() const;

  bool renderbuffer_dirty;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_RASTER_3D_H_
