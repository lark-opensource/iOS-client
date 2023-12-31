// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_surface.h"

#include <skity/render/render_context_gl.hpp>

#include "animax/bridge/animax_onscreen_surface.h"
#include "animax/render/include/context.h"

namespace lynx {
namespace animax {
#if OS_IOS
typedef void (*SkityGLFuncPtr)();

static SkityGLFuncPtr getProcAddress_skityGL(const char *procname) {
  static CFBundleRef esBundle =
      CFBundleGetBundleWithIdentifier(CFSTR("com.apple.opengles"));

  CFStringRef symbolName = CFStringCreateWithCString(
      kCFAllocatorDefault, procname, kCFStringEncodingASCII);
  SkityGLFuncPtr symbol =
      (SkityGLFuncPtr)CFBundleGetFunctionPointerForName(esBundle, symbolName);
  CFRelease(symbolName);
  return symbol;
}
#endif

static void EmptyDataProc(const void *, void *) {}

void SkitySurface::InitMSAARootFBO(int32_t width, int32_t height) {
  glGenFramebuffers(1, &root_fbo_);
  glGenRenderbuffers(2, fbo_buffers_.data());
  glBindFramebuffer(GL_FRAMEBUFFER, root_fbo_);

  glBindRenderbuffer(GL_RENDERBUFFER, fbo_buffers_[0]);
  glRenderbufferStorageMultisample(GL_RENDERBUFFER, 4, GL_RGBA8, width, height);

  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                            GL_RENDERBUFFER, fbo_buffers_[0]);

  glBindRenderbuffer(GL_RENDERBUFFER, fbo_buffers_[1]);
  glRenderbufferStorageMultisample(GL_RENDERBUFFER, 4, GL_STENCIL_INDEX8, width,
                                   height);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                            GL_RENDERBUFFER, fbo_buffers_[1]);
}

void SkitySurface::InitFXAARootFBO(int32_t width, int32_t height) {
  glGenFramebuffers(1, &root_fbo_);
  glGenTextures(2, fbo_buffers_.data());

  glBindFramebuffer(GL_FRAMEBUFFER, root_fbo_);

  glBindTexture(GL_TEXTURE_2D, fbo_buffers_[0]);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, static_cast<GLsizei>(width),
               static_cast<GLsizei>(height), 0, GL_RGBA, GL_UNSIGNED_BYTE,
               reinterpret_cast<void *>(0));

  glBindTexture(GL_TEXTURE_2D, fbo_buffers_[1]);

  glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH24_STENCIL8,
               static_cast<GLsizei>(width), static_cast<GLsizei>(height), 0,
               GL_DEPTH_STENCIL, GL_UNSIGNED_INT_24_8,
               reinterpret_cast<void *>(0));

  glBindTexture(GL_TEXTURE_2D, 0);

  glBindFramebuffer(GL_FRAMEBUFFER, root_fbo_);

  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                         fbo_buffers_[0], 0);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT,
                         GL_TEXTURE_2D, fbo_buffers_[1], 0);

  glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void SkitySurface::ReleaseMSAARootFBO() {
  if (!root_fbo_) {
    return;
  }
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glDeleteFramebuffers(1, &root_fbo_);
  glDeleteRenderbuffers(2, fbo_buffers_.data());
  root_fbo_ = 0;
  fbo_buffers_[0] = 0;
  fbo_buffers_[1] = 0;
}

void SkitySurface::ReleaseFXAARootFBO() {
  if (!root_fbo_) {
    return;
  }
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glDeleteFramebuffers(1, &root_fbo_);
  glDeleteTextures(2, fbo_buffers_.data());
  root_fbo_ = 0;
  fbo_buffers_[0] = 0;
  fbo_buffers_[1] = 0;
}

void *SkitySurface::GetProcLoader() const {
  void *proc_loader = nullptr;
#ifdef OS_IOS
  proc_loader = reinterpret_cast<void *>(getProcAddress_skityGL);
#else
  proc_loader = reinterpret_cast<void *>(eglGetProcAddress);
#endif
  return proc_loader;
}

SkitySurface::SkitySurface(AnimaXOnScreenSurface *surface, int32_t width,
                           int32_t height)
    : Surface(surface, width, height) {
  is_gpu_ = surface->IsGPUBacked();
  if (is_gpu_) {
    // TODO make RenderContext be single instance
    render_ctx_ = skity::RenderContextGL::CreateContext(GetProcLoader());
  }
  Resize(surface, width, height);
}

Canvas *SkitySurface::GetCanvas() { return wrap_.get(); }

void SkitySurface::Resize(AnimaXOnScreenSurface *surface, int32_t width,
                          int32_t height) {
  Destroy();

  if (surface->IsGPUBacked()) {
    if (fxaa_) {
      InitFXAARootFBO(width, height);
    } else {
      InitMSAARootFBO(width, height);
    }
    if (fxaa_) {
      ctx_ = std::make_unique<FXAAGPUContext>(GetProcLoader(), root_fbo_,
                                              surface->GLContextFBO(),
                                              fbo_buffers_[0], width, height);
    } else {
      ctx_ = std::make_unique<MSAAGPUContext>(
          GetProcLoader(), root_fbo_, surface->GLContextFBO(), width, height);
    }
    ctx_->MakeCurrent();
    ctx_->enable_scissor = false;
    ctx_->screen_scale = 1;
    ctx_->fbo_cache_limit = 0;

    canvas_ = skity::Canvas::MakeHardwareAccelerationCanvas(
        width, height, ctx_.get(), render_ctx_);

    glClearColor(0, 0, 0, 0);
    glClearStencil(0x0);
    glStencilMask(0xFF);
    glEnable(GL_STENCIL_TEST);
    glEnable(GL_BLEND);
    glEnable(GL_SCISSOR_TEST);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glScissor(0, 0, width, height);
  } else {
    auto data = skity::Data::MakeWithProc(
        surface->Buffer(), surface->Height() * surface->BytesPerRow(),
        EmptyDataProc, nullptr);

    auto pixmap = std::make_shared<skity::Pixmap>(
        data, surface->BytesPerRow(), surface->Width(), surface->Height(),
        skity::AlphaType::kPremul_AlphaType);

    bitmap_ = std::make_unique<skity::Bitmap>(std::move(pixmap), false);

    canvas_ = skity::Canvas::MakeSoftwareCanvas(bitmap_.get());
  }
  wrap_ = std::make_unique<SkityCanvas>(
      canvas_.get(), canvas_->Width(), canvas_->Height(),
      render_ctx_ ? render_ctx_.get() : nullptr);
}

void SkitySurface::Clear() {
  if (is_gpu_) {
    glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
  } else {
    std::memset(bitmap_->GetPixelAddr(), 0,
                bitmap_->Height() * bitmap_->RowBytes());
  }
}

void SkitySurface::Flush() {
  if (ctx_) {
    ctx_->MakeCurrent();
  }
  canvas_->Flush();
  if (ctx_) {
    ctx_->Flush();
  }
}

void SkitySurface::Destroy() {
  if (fxaa_) {
    ReleaseFXAARootFBO();
  } else {
    ReleaseMSAARootFBO();
  }
}

}  // namespace animax
}  // namespace lynx
