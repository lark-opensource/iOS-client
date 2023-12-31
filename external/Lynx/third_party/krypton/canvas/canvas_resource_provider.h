// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_CANVAS_RESOURCE_PROVIDER_H_
#define CANVAS_CANVAS_RESOURCE_PROVIDER_H_

#include <functional>
#include <memory>

#include "canvas/gpu/gl_global_device_attributes.h"
#include "canvas/util/count_down_waitable_event.h"
#include "glue/canvas_runtime.h"
#include "shell/lynx_actor.h"
#include "third_party/krypton/canvas/gpu/command_buffer/command_recorder.h"

#ifdef ENABLE_LYNX_CANVAS_SKIA
#include "canvas/util/skia.h"
#endif

namespace lynx {
namespace canvas {
class Surface;
class Raster;
class CanvasElement;
class GLContext;
class FontCache;
class SurfaceRegistry;

struct FlushResult {};

class CanvasResourceProvider
    : public std::enable_shared_from_this<CanvasResourceProvider> {
 public:
  struct Option {
    bool antialias;
  };
  CanvasResourceProvider(CanvasElement*,
                         std::shared_ptr<shell::LynxActor<CanvasRuntime>>,
                         std::shared_ptr<shell::LynxActor<SurfaceRegistry>>,
                         Option option);
  virtual ~CanvasResourceProvider();

  bool Init(const fml::RefPtr<fml::TaskRunner>& gpu_task_runner);

  const std::shared_ptr<shell::LynxActor<CanvasRuntime>>& runtime_actor()
      const {
    return runtime_actor_;
  }

  const std::shared_ptr<shell::LynxActor<Raster>> gpu_actor() const {
    return gpu_actor_;
  }

  void RequestVSync();

  void OnCanvasSizeChanged();

  int GetCanvasWidth() const;
  int GetCanvasHeight() const;

  void SetCanvasElement(CanvasElement* element);

  // only flush gl command buffer, must used in caution to avoid lost user's
  // logic
  FlushResult FlushIgnoreClientSide(bool blit_to_screen = true,
                                    bool is_sync = false, bool force = false);
  FlushResult Flush(bool blit_to_screen = true, bool is_sync = false,
                    bool force = false);
  void SetNeedRedraw();

  void OnAppEnterForeground();
  void OnAppEnterBackground();

  CommandRecorder* GetRecorder() const { return command_recorder_.get(); }

#ifdef ENABLE_LYNX_CANVAS_SKIA
  sk_sp<SkImage> MakeSnapshot(const SkIRect& rect,
                              const SkPixmap* pixmap = nullptr);
#else
  virtual void ReadPixels(int x, int y, int width, int height, void* data,
                          bool premultiply_alpha = false){};
  virtual void PutPixels(void* data, int width, int height, int srcX, int srcY,
                         int srcWidth, int srcHeight, int dstX, int dstY,
                         int dstWidth, int dstHeight){};
#endif

  virtual bool IsCanvas2d() { return false; }

  virtual bool HasCanvasRenderBuffer() { return false; }

  virtual FontCache* GetFontCache() { return nullptr; }

  uint32_t reading_fbo() const;
  uint32_t drawing_fbo() const;

  void SetClientOnFrameCallback(std::function<void()> on_frame) {
    client_on_frame_ = std::move(on_frame);
  }

  virtual void WillAccessRenderBuffer(){};
  void UpdateRasterPriority(int32_t priority);
  void AttachToOnscreenCanvas();
  void DetachFromOnscreenCanvas();

 protected:
  void FlushCommandBufferInternal(bool blit_to_screen, bool is_sync = false);

  virtual void DoRaster(bool blit_to_screen, bool is_sync) = 0;

  virtual Raster* CreateRaster(
      CanvasResourceProvider* resource_provider,
      CountDownWaitableEvent* gpu_waitable_event,
      const fml::RefPtr<fml::TaskRunner>& gpu_task_runner,
      const Option& option) = 0;

  void RunOnGPU(std::function<void(const std::unique_ptr<Raster>& impl)> func);

  void SyncRunOnGPU(
      std::function<void(const std::unique_ptr<Raster>& impl)> func);

  virtual void AdjustCanvasSizeInResizeIfNeeded(int& width, int& height) {}

  virtual void OnCanvasSizeChangedInternal() {}

  void WaitForLastGPUTaskFinished();

  Raster* raster() const { return raster_; }

  CanvasElement* element() const { return element_; }

  CommandRecorder* recorder() const { return command_recorder_.get(); }

 private:
  void DoFrame(int64_t frame_start, int64_t frame_end);
  void FlushNewCanvasSize();

  std::unique_ptr<CommandRecorder> command_recorder_;
  std::shared_ptr<shell::LynxActor<CanvasRuntime>> runtime_actor_;
  std::shared_ptr<shell::LynxActor<SurfaceRegistry>> surface_actor_;
  std::shared_ptr<shell::LynxActor<Raster>> gpu_actor_;
  CanvasElement* element_;
  Option option_;

  Raster* raster_;

  bool need_redraw_{false};
  bool has_requested_vsync_{false};
  bool app_is_visible_{true};

  std::unique_ptr<CountDownWaitableEvent> gpu_waitable_event_;

  std::function<void()> client_on_frame_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_CANVAS_RESOURCE_PROVIDER_H_
