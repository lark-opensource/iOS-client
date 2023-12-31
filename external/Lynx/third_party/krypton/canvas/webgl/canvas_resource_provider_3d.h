// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_CANVAS_RESOURCE_PROVIDER_3D_H_
#define CANVAS_WEBGL_CANVAS_RESOURCE_PROVIDER_3D_H_

#include <memory>

#include "canvas/canvas_resource_provider.h"

namespace lynx {
namespace canvas {
class CanvasResourceProvider3D : public CanvasResourceProvider {
 public:
  CanvasResourceProvider3D(CanvasElement *,
                           std::shared_ptr<shell::LynxActor<CanvasRuntime>>,
                           std::shared_ptr<shell::LynxActor<SurfaceRegistry>>,
                           Option option);

  ~CanvasResourceProvider3D() override;

  int GetDrawingBufferSizeWidth();
  int GetDrawingBufferSizeHeight();

  void ReadPixels(int x, int y, int width, int height, void *data,
                  bool premultiply_alpha = false) override;

  void WillAccessRenderBuffer() override;

 protected:
  void DoRaster(bool blit_to_screen, bool is_sync) override;

  Raster *CreateRaster(CanvasResourceProvider *resource_provider,
                       CountDownWaitableEvent *gpu_waitable_event,
                       const fml::RefPtr<fml::TaskRunner> &gpu_task_runner,
                       const Option &option) override;

  void AdjustCanvasSizeInResizeIfNeeded(int &width, int &height) override;

 private:
  int drawing_buffer_width_;
  int drawing_buffer_height_;
  int max_viewport_size_[2];
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_CANVAS_RESOURCE_PROVIDER_3D_H_
