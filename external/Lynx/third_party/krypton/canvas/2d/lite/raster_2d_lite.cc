// Copyright 2021 The Lynx Authors. All rights reserved.

#include "raster_2d_lite.h"

#include "canvas/base/log.h"
#include "canvas/gpu/gl/scoped_gl_error_check.h"
#include "canvas/workaround/runtime_flags_for_workaround.h"

namespace lynx {
namespace canvas {
Raster2DLite::Raster2DLite(const fml::RefPtr<fml::TaskRunner> &gpu_task_runner,
                           DrawingBufferOption drawing_buffer_option,
                           CountDownWaitableEvent *gpu_waitable_event,
                           int32_t width, int32_t height)
    : Raster(gpu_task_runner, drawing_buffer_option, gpu_waitable_event, width,
             height) {
  KRYPTON_CONSTRUCTOR_LOG(Raster2DLite);
}

Raster2DLite::~Raster2DLite() { KRYPTON_DESTRUCTOR_LOG(Raster2DLite); }

void Raster2DLite::DoRaster(
    const std::shared_ptr<command_buffer::RunnableBuffer> &buffer,
    bool blit_to_screen) {
  if (GLMakeCurrent(nullptr)) {
    MakeSureRenderbufferPrepared();

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
    // 2d should never generate gl err
    DCHECK(GL::GetError() == GL_NO_ERROR);
  } else {
    KRYPTON_LOGE("DoRater but make context current failed");
  }

  DidRaster();
}

class ScopedGLStateForBlit {
 public:
  ScopedGLStateForBlit() {
    enable_scissor_test_ = ::glIsEnabled(GL_SCISSOR_TEST);
    if (enable_scissor_test_) {
      ::glDisable(GL_SCISSOR_TEST);
    }

    ::glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &read_buffer_);
    ::glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &draw_buffer_);
  }

  ~ScopedGLStateForBlit() {
    if (enable_scissor_test_) {
      ::glEnable(GL_SCISSOR_TEST);
    }

    ::glBindFramebuffer(GL_READ_FRAMEBUFFER, read_buffer_);
    ::glBindFramebuffer(GL_DRAW_FRAMEBUFFER, draw_buffer_);
  }

 private:
  GLboolean enable_scissor_test_;
  GLint read_buffer_ = 0;
  GLint draw_buffer_ = 0;
};

void Raster2DLite::DoBlit() const {
  if (!IsSurfaceAvailable()) {
    return;
  }

  ScopedGLStateForBlit scoped_gl_state;

  DCHECK_SCOPED_NO_GL_ERROR;

  // read only need bind once
  GL::BindFramebuffer(GL_READ_FRAMEBUFFER, canvas_renderbuffer_->reading_fbo());
  const auto &surface_vector = GetSurfaceVector();
  for (const auto &cur : surface_vector) {
    GLSurface *surface = static_cast<GLSurface *>(cur->surface.get());
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

bool Raster2DLite::HasCanvasRenderBuffer() {
  return canvas_renderbuffer_ != nullptr;
}

void Raster2DLite::MakeSureRenderbufferPrepared() {
  DCHECK_SCOPED_NO_GL_ERROR;

  if (offscreen_surface_size_changed_ || !canvas_renderbuffer_) {
    CreateOrRecreateCanvasRenderbuffer();
    offscreen_surface_size_changed_ = false;
  }

  // TODO(luchengxuan) 2d support msaa
  glBindFramebuffer(GL_FRAMEBUFFER, canvas_renderbuffer_->drawing_fbo());
  glViewport(0, 0, canvas_renderbuffer_->width(),
             canvas_renderbuffer_->height());
}
}  // namespace canvas
}  // namespace lynx
