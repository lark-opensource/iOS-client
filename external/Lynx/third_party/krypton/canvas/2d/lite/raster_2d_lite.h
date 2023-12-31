// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_2D_LITE_RASTER_2D_LITE_H_
#define CANVAS_2D_LITE_RASTER_2D_LITE_H_

#include "canvas/raster.h"
#include "canvas/webgl/canvas_renderbuffer.h"
#include "third_party/krypton/canvas/gpu/command_buffer_ng/runnable_buffer.h"

namespace lynx {
namespace canvas {
class Raster2DLite : public Raster {
 public:
  Raster2DLite(const fml::RefPtr<fml::TaskRunner> &gpu_task_runner,
               DrawingBufferOption drawing_buffer_option,
               CountDownWaitableEvent *gpu_waitable_event, int32_t width,
               int32_t height);

  ~Raster2DLite() override;

  void DoRaster(const std::shared_ptr<command_buffer::RunnableBuffer> &buffer,
                bool blit_to_screen) override;

  bool HasCanvasRenderBuffer();

 private:
  void MakeSureRenderbufferPrepared();

  void DoBlit() const;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_2D_LITE_RASTER_2D_LITE_H_
