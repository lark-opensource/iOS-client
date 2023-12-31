// Copyright 2021 The Lynx Authors. All rights reserved.

#include "raster_3d.h"

#include "canvas/base/log.h"
#include "canvas/gpu/gl/gl_api.h"
#include "canvas/gpu/gl/scoped_gl_error_check.h"
#include "canvas/image_data.h"
#include "canvas/workaround/runtime_flags_for_workaround.h"

#ifdef ENABLE_LYNX_CANVAS_SKIA
#include "canvas/util/skia_resource_storage.h"
#include "canvas/util/skia_util.h"
#endif

namespace lynx {
namespace canvas {
Raster3D::Raster3D(const fml::RefPtr<fml::TaskRunner>& gpu_task_runner,
                   DrawingBufferOption drawing_buffer_option,
                   CountDownWaitableEvent* gpu_waitable_event, int32_t width,
                   int32_t height)
    : Raster(gpu_task_runner, std::move(drawing_buffer_option),
             gpu_waitable_event, width, height),
      renderbuffer_dirty(true) {
  KRYPTON_CONSTRUCTOR_LOG(Raster3D);
}

Raster3D::~Raster3D() { KRYPTON_DESTRUCTOR_LOG(Raster3D); }

void Raster3D::DoRaster(
    const std::shared_ptr<command_buffer::RunnableBuffer>& buffer,
    bool blit_to_screen) {
  if (GLMakeCurrent(nullptr)) {
    MakeSureRenderbufferPrepared();

    // once renderbuffer is bound, we assume it is dirty & need to resolve.
    renderbuffer_dirty = true;

    DCHECK(canvas_renderbuffer_);

    if (buffer) {
      buffer->Execute();
    }

    // Without flush, apps may crash on some devices with Adreno GPUs due to GL
    // error in the render thread caused by too many commands. :(
    GL::Flush();

    if (blit_to_screen) {
      DoBlit();

      if (UNLIKELY(drawing_buffer_option_.need_workaround_finish_per_frame)) {
        GL::Finish();
      }
    }
  } else {
    KRYPTON_LOGE("DoRater but make context current failed");
  }

  DidRaster();
}

#ifdef ENABLE_LYNX_CANVAS_SKIA
sk_sp<SkImage> Raster3D::MakeSnapshot(const SkIRect& rect,
                                      const SkPixmap* pixmap) {
  if (canvas_renderbuffer_) {
    auto skia_gl_context = GetThreadLocalGLContextForSkia();
    skia_gl_context->MakeCurrent(nullptr);
    sk_sp<SkSurface> surface = WrapOnscreenSurface(
        GetThreadLocalGrContext(),
        {canvas_renderbuffer_->width(), canvas_renderbuffer_->height()},
        canvas_renderbuffer_->fbo(), 8);

    sk_sp<SkImage> image = surface->makeImageSnapshot(rect);
    skia_gl_context->ClearCurrent();
    return image;
  } else {
    return sk_sp<SkImage>();
  }
}
#endif

class ScopedGLStateForBlit {
 public:
  ScopedGLStateForBlit() {
    enable_scissor_test_ = GL::IsEnabled(GL_SCISSOR_TEST);
    if (enable_scissor_test_) {
      GL::Disable(GL_SCISSOR_TEST);
    }

    GL::GetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &read_buffer_);
    GL::GetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &draw_buffer_);
  }

  ~ScopedGLStateForBlit() {
    if (enable_scissor_test_) {
      GL::Enable(GL_SCISSOR_TEST);
    }

    GL::BindFramebuffer(GL_READ_FRAMEBUFFER, read_buffer_);
    GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, draw_buffer_);
  }

 private:
  GLboolean enable_scissor_test_;
  GLint read_buffer_ = 0;
  GLint draw_buffer_ = 0;
};

void Raster3D::DoBlit() const {
  if (!IsSurfaceAvailable()) {
    return;
  }

  ScopedGLStateForBlit scoped_gl_state;

  DCHECK_SCOPED_NO_GL_ERROR;

  // read only need bind once
  canvas_renderbuffer_->ResolveIfNeeded();
  GL::BindFramebuffer(GL_READ_FRAMEBUFFER, canvas_renderbuffer_->reading_fbo());
  const auto& surface_vector = GetSurfaceVector();
  for (const auto& cur : surface_vector) {
    GLSurface* surface = static_cast<GLSurface*>(cur->surface.get());
    auto key = cur->surface_key;
    auto size = cur->size;

    if (size.IsEmpty()) {
      KRYPTON_LOGW("DoBlit but surface size is empty, key is ") << key;
      continue;
    }

    // should make surface current, strangle egl api design
    GLMakeCurrent(surface);

    // start blit
    GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, surface->GLContextFBO());

    if (drawing_buffer_option_.need_workaround_egl_sync_after_resize &&
        workaround::any_surface_resized.load(std::memory_order_relaxed)) {
      // call eglquery to avoid crash, see issues for details
      // TODO(luchengxuan) replaced with generic workaround method & on-demand
      // get this method now can take more than 1 ms
      KRYPTON_LOGI("need_workaround_egl_sync_after_resize query ")
          << surface->Width();
      workaround::any_surface_resized.store(false, std::memory_order_relaxed);
    }

    if (surface->NeedFlipY()) {
      GL::BlitFramebuffer(0, 0, canvas_renderbuffer_->width(),
                          canvas_renderbuffer_->height(), 0, size.height,
                          size.width, 0, GL_COLOR_BUFFER_BIT, GL_LINEAR);
    } else {
      GL::BlitFramebuffer(0, 0, canvas_renderbuffer_->width(),
                          canvas_renderbuffer_->height(), 0, 0, size.width,
                          size.height, GL_COLOR_BUFFER_BIT, GL_LINEAR);
    }

    surface->Flush();
  }
}

void Raster3D::MakeSureRenderbufferPrepared() {
  if (!offscreen_surface_size_changed_ && canvas_renderbuffer_) {
    return;
  }

  if (canvas_renderbuffer_ &&
      canvas_renderbuffer_->width() == offscreen_surface_size_.width &&
      canvas_renderbuffer_->height() == offscreen_surface_size_.height) {
    return;
  }

  bool is_first = !canvas_renderbuffer_;

  CreateOrRecreateCanvasRenderbuffer();

  DCHECK_SCOPED_NO_GL_ERROR;

  offscreen_surface_size_changed_ = false;

  if (is_first) {
    auto width = canvas_renderbuffer_->width();
    auto height = canvas_renderbuffer_->height();
    auto reading_fbo = canvas_renderbuffer_->reading_fbo();
    auto drawing_fbo = canvas_renderbuffer_->drawing_fbo();
    KRYPTON_LOGI("canvas renderbuffer set vp to ")
        << width << ", " << height << " reading_fbo " << reading_fbo
        << " drawing_fbo " << drawing_fbo;
    GL::Viewport(0, 0, width, height);
    GL::BindFramebuffer(GL_READ_FRAMEBUFFER, reading_fbo);
    GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, drawing_fbo);
  }
}

void Raster3D::WillAccessContent(bool should_make_current_ctx) {
  // actually accessing content before renderbuffer init is something wrong,
  // fully fix will be land on 2.7
  if (!canvas_renderbuffer_) {
    KRYPTON_LOGW("WillAccessContent but renderbuffer is null.");
    return;
  }

  if (drawing_buffer_option_.msaa_sample_count == 0) {
    return;
  }

  if (!renderbuffer_dirty) {
    return;
  }

  /**
   MakeCurrent is needed when should_make_current_ctx is true.
   There are currently two situations:
   1. WillAccessContent calling on JS Thread: should_make_current_ctx should be
   true. To make sure there have a gl context;
   2. WillAccessContent calling on GPU Thread: TexImage2D and DrawImage will
   access canvas's fbo on GPU thread. In this case you can ensure that there are
   other GLContexts currently. If MakeCurrent is executed, it will cause
   confusion in the context state
   */
  if (should_make_current_ctx) {
    GLMakeCurrent(nullptr);
  }

  canvas_renderbuffer_->ResolveIfNeeded();
  renderbuffer_dirty = false;
}
}  // namespace canvas
}  // namespace lynx
