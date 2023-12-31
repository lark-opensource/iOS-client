// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_RASTER_H_
#define CANVAS_RASTER_H_

#include <vector>

#include "canvas/base/size.h"
#include "canvas/gpu/gl_context.h"
#include "canvas/surface/surface.h"
#include "canvas/surface_client.h"
#include "canvas/texture_source.h"
#include "canvas/util/count_down_waitable_event.h"
#include "canvas/webgl/canvas_renderbuffer.h"
#include "shell/lynx_actor.h"
#include "third_party/krypton/canvas/gpu/command_buffer_ng/runnable_buffer.h"

#ifdef ENABLE_LYNX_CANVAS_SKIA
#include "canvas/util/skia.h"
#endif

namespace lynx {
namespace canvas {
class CanvasResourceProvider;
class ScopedGLContext;

struct DrawingBufferOption {
  uint32_t msaa_sample_count;
  // on some gpus, flushing per frame on app start up may also produce crash due
  // to job scheduler of the driver reach the limitation.
  bool need_workaround_finish_per_frame;
  bool need_workaround_egl_sync_after_resize;
};

class Raster {
 public:
  Raster(const fml::RefPtr<fml::TaskRunner> &gpu_task_runner,
         DrawingBufferOption drawing_buffer_option,
         CountDownWaitableEvent *gpu_waitable_event, int32_t offscreenWidth = 0,
         int32_t offscreenWidthHeight = 0)
      : offscreen_surface_size_changed_(false),
        gpu_waitable_event_(gpu_waitable_event),
        offscreen_surface_size_({offscreenWidth, offscreenWidthHeight}),
        gpu_task_runner_(gpu_task_runner),
        drawing_buffer_option_(std::move(drawing_buffer_option)) {
    KRYPTON_LOGI("drawing_buffer_option msaa_sample_count ")
        << drawing_buffer_option_.msaa_sample_count
        << " need_workaround_finish_per_frame "
        << drawing_buffer_option_.need_workaround_finish_per_frame;
  }

  virtual ~Raster();

  // make sure all APIs run on GPU thread
  void Init();

  bool GLMakeCurrent(Surface *surface) const;
  void GLClearCurrent();

  virtual void WillAccessContent(bool should_make_current_ctx){};

  void OnCanvasSizeChanged(int width, int height);

  virtual void DoRaster(
      const std::shared_ptr<command_buffer::RunnableBuffer> &buffer,
      bool blit_to_screen){};

  bool IsSurfaceAvailable() const {
    return surface_client_ && !surface_client_->surface_vector().empty();
  }

  const std::vector<CanvasSurfaceInfo *> &GetSurfaceVector() const {
    return surface_client_->surface_vector();
  }

  void UpdateSurfaceClientPriority(int32_t priority,
                                   bool need_reassign_surface = true) {
    if (surface_client_) {
      surface_client_->UpdatePriority(priority, need_reassign_surface);
    }
  }

  void ReleaseSurfaceClient() { surface_client_.reset(); }

  void set_surface_client(std::unique_ptr<SurfaceClient> client) {
    surface_client_ = std::move(client);
  }
#ifdef ENABLE_LYNX_CANVAS_SKIA
  virtual sk_sp<SkImage> MakeSnapshot(const SkIRect &rect,
                                      const SkPixmap *pixmap) = 0;
#endif

#ifndef ENABLE_RENDERKIT_CANVAS
  GLuint reading_fbo() const { return offscreen_reading_fbo_id_; };
  GLuint drawing_fbo() const { return offscreen_drawing_fbo_id_; };
  CanvasRenderbuffer *renderbuffer() { return canvas_renderbuffer_.get(); }
#else
  GLuint reading_fbo() const { return 0; };
  GLuint drawing_fbo() const { return 0; };
#endif

 protected:
  GLContext *GetGLContext() const;

  void DidRaster() const;

  bool CheckOnGPUThread() const;

  void CreateOrRecreateCanvasRenderbuffer();

  bool offscreen_surface_size_changed_;

  CountDownWaitableEvent *gpu_waitable_event_;

  ISize offscreen_surface_size_;

#ifndef ENABLE_RENDERKIT_CANVAS
  std::atomic_uint32_t offscreen_reading_fbo_id_{0};
  std::atomic_uint32_t offscreen_drawing_fbo_id_{0};
  mutable std::unique_ptr<GLContext> gl_context_;
  std::unique_ptr<CanvasRenderbuffer> canvas_renderbuffer_;
#endif

  const fml::RefPtr<fml::TaskRunner> gpu_task_runner_;
  const DrawingBufferOption drawing_buffer_option_;
  std::unique_ptr<SurfaceClient> surface_client_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_RASTER_H_
