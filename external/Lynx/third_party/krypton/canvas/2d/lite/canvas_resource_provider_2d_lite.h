// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_2D_LITE_CANVAS_RESOURCE_PROVIDER_2D_LITE_H_
#define CANVAS_2D_LITE_CANVAS_RESOURCE_PROVIDER_2D_LITE_H_

#include "canvas/2d/lite/nanovg/include/nanovg.h"
#include "canvas/canvas_resource_provider.h"
#include "canvas/gpu/command_buffer/gl_command_buffer.h"
#include "third_party/krypton/canvas/gpu/command_buffer/command_recorder.h"
#include "third_party/krypton/canvas/gpu/gl/gl_include.h"

namespace lynx {
namespace canvas {
class CanvasResourceProvider2DLite : public CanvasResourceProvider {
 public:
  CanvasResourceProvider2DLite(
      CanvasElement *element, std::shared_ptr<shell::LynxActor<CanvasRuntime>>,
      std::shared_ptr<shell::LynxActor<SurfaceRegistry>>);
  ~CanvasResourceProvider2DLite();

  void ReadPixels(int x, int y, int width, int height, void *data,
                  bool premultiply_alpha = false) override;
  void PutPixels(void *data, int width, int height, int srcX, int srcY,
                 int srcWidth, int srcHeight, int dstX, int dstY, int dstWidth,
                 int dstHeight) override;

  bool IsCanvas2d() override { return true; }

  nanovg::NVGcontext *GetNVGContext() const;

  bool HasCanvasRenderBuffer() override;

 protected:
  void DoRaster(bool blit_to_screen, bool is_sync) override;

  void OnCanvasSizeChangedInternal() override;

  Raster *CreateRaster(CanvasResourceProvider *resource_provider,
                       CountDownWaitableEvent *gpu_waitable_event,
                       const fml::RefPtr<fml::TaskRunner> &gpu_task_runner,
                       const Option &option) override;

 private:
  class ScopedNVGContext;

  mutable std::unique_ptr<ScopedNVGContext> nvg_context_;
  std::unique_ptr<GLCommandBuffer> gl_interface_;
  bool during_nvg_flush;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_2D_LITE_CANVAS_RESOURCE_PROVIDER_2D_LITE_H_
