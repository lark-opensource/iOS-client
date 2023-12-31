// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas_renderbuffer.h"

#include "canvas/base/log.h"
#include "canvas/gpu/gl/scoped_gl_error_check.h"
#include "canvas/gpu/gl_context.h"
#include "canvas/gpu/gl_global_device_attributes.h"

namespace lynx {
namespace canvas {

CanvasRenderbuffer::CanvasRenderbuffer()
    : device_attributes_(
          GLGlobalDeviceAttributes::Instance().GetDeviceAttributes()),
      msaa_mode_(kNone) {}

CanvasRenderbuffer::~CanvasRenderbuffer() {
  // must be disposed in destructor.
  DCHECK(fbo_ == 0);
}

int CanvasRenderbuffer::width() const { return static_cast<int>(w_); }

int CanvasRenderbuffer::height() const { return static_cast<int>(h_); }

class ScopedGLStateForBuild {
 public:
  ScopedGLStateForBuild() {
    enable_scissor_test_ = GL::IsEnabled(GL_SCISSOR_TEST);
    if (enable_scissor_test_) {
      GL::Disable(GL_SCISSOR_TEST);
    }

    GL::GetBooleanv(GL_COLOR_WRITEMASK, color_mask_);
    GL::GetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &read_buffer_);
    GL::GetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &draw_buffer_);
    GL::GetIntegerv(GL_RENDERBUFFER_BINDING, &render_buffer_);

    GL::GetFloatv(GL_COLOR_CLEAR_VALUE, clear_color_);
    GL::GetFloatv(GL_DEPTH_CLEAR_VALUE, &clear_depth_);
    GL::GetIntegerv(GL_STENCIL_CLEAR_VALUE, &clear_stencil_);
  }

  ~ScopedGLStateForBuild() {
    if (enable_scissor_test_) {
      GL::Enable(GL_SCISSOR_TEST);
    }
    GL::ColorMask(color_mask_[0], color_mask_[1], color_mask_[2],
                  color_mask_[3]);

    GL::BindRenderbuffer(GL_RENDERBUFFER, render_buffer_);
    GL::BindFramebuffer(GL_READ_FRAMEBUFFER, read_buffer_);
    GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, draw_buffer_);

    GL::ClearColor(clear_color_[0], clear_color_[1], clear_color_[2],
                   clear_color_[3]);
    GL::ClearDepthf(clear_depth_);
    GL::ClearStencil(clear_stencil_);
  }

 private:
  GLboolean enable_scissor_test_;
  GLboolean color_mask_[4] = {GL_TRUE};
  GLint read_buffer_ = 0;
  GLint draw_buffer_ = 0;
  GLint render_buffer_ = 0;
  GLfloat clear_color_[4] = {0};
  GLfloat clear_depth_ = 0;
  GLint clear_stencil_ = 0;
};

bool CanvasRenderbuffer::Build(int w, int h, int aa) {
  DCHECK(w > 0 && h > 0);
  DCHECK(GLContext::GetCurrent());

  KRYPTON_LOGI("CanvasRenderBuffer build with ")
      << w << ", " << h << ", " << aa;

  ScopedGLErrorCheck scoped_gl_error_check;

  GLint texture_max_size = 0;
  GL::GetIntegerv(GL_MAX_TEXTURE_SIZE, &texture_max_size);
  if (w >= texture_max_size || h >= texture_max_size) {
    return false;
  }

  w_ = w;
  h_ = h;

  // actually, aa = 1 is diff from no msaa
  if (aa > 0) {
    // TODO(luchengxuan) enable implicit resolve if support
    msaa_mode_ = kExplicitResolve;

    GLint samples;
    GL::GetIntegerv(GL_MAX_SAMPLES, &samples);
    if (aa > samples) {
      aa = samples;
    }
  }

  ScopedGLStateForBuild scoped_gl_state_for_build;

  if (msaa_mode_ == kImplicitResolve) {
    BuildMSAAFramebuffer(kImplicitResolve, aa, w, h);
    BuildNoMSAAFramebuffer(w, h, false);
  } else if (msaa_mode_ == kExplicitResolve) {
    BuildMSAAFramebuffer(kExplicitResolve, aa, w, h);
    BuildNoMSAAFramebuffer(w, h, false);
  } else {
    BuildNoMSAAFramebuffer(w, h, true);
  }

  return true;
}

bool CanvasRenderbuffer::Dispose() {
  DCHECK(GLContext::GetCurrent());

  w_ = h_ = 0;

  if (0 != fbo_) {
    GL::DeleteFramebuffers(1, &fbo_);
    fbo_ = 0;
  }

  if (0 != rbo_) {
    GL::DeleteRenderbuffers(1, &rbo_);
    rbo_ = 0;
  }

  if (0 != depth_) {
    GL::DeleteRenderbuffers(1, &depth_);
    depth_ = 0;
  }

  if (0 != msaa_fbo_) {
    GL::DeleteFramebuffers(1, &msaa_fbo_);
    msaa_fbo_ = 0;
  }

  if (0 != msaa_rbo_) {
    GL::DeleteRenderbuffers(1, &msaa_rbo_);
    msaa_rbo_ = 0;
  }

  if (0 != msaa_depth_) {
    GL::DeleteRenderbuffers(1, &msaa_depth_);
    msaa_depth_ = 0;
  }

  KRYPTON_LOGI("CanvasRenderbuffer Disposed");
  return true;
}

void CanvasRenderbuffer::BuildNoMSAAFramebuffer(int w, int h, bool need_depth) {
  if (0 == fbo_) {
    GL::GenFramebuffers(1, &fbo_);
  }
  GL::BindFramebuffer(GL_FRAMEBUFFER, fbo_);

  if (0 == rbo_) {
    GL::GenRenderbuffers(1, &rbo_);
  }
  GL::BindRenderbuffer(GL_RENDERBUFFER, rbo_);
  GL::RenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, w, h);
  GL::FramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, rbo_);

  if (need_depth) {
    if (0 == depth_) {
      GL::GenRenderbuffers(1, &depth_);
    }
    GL::BindRenderbuffer(GL_RENDERBUFFER, depth_);
    GL::RenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, w, h);
    GL::FramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                GL_RENDERBUFFER, depth_);
    GL::FramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                                GL_RENDERBUFFER, depth_);
  }

  GL::ClearColor(0, 0, 0, 0);
  GLbitfield clear_mask = GL_COLOR_BUFFER_BIT;
  if (need_depth) {
    GL::ClearStencil(0);
    GL::ClearDepthf(1.0f);
    clear_mask |= GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT;
  }
  GL::Clear(clear_mask);

  DCHECK(GL::CheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
}

void CanvasRenderbuffer::BuildMSAAFramebuffer(MSAAMode msaa_mode, int samples,
                                              int w, int h) {
  DCHECK(msaa_mode != kNone);

  if (0 == msaa_fbo_) {
    GL::GenFramebuffers(1, &msaa_fbo_);
  }
  GL::BindFramebuffer(GL_FRAMEBUFFER, msaa_fbo_);

  if (0 == msaa_rbo_) {
    GL::GenRenderbuffers(1, &msaa_rbo_);
  }
  GL::BindRenderbuffer(GL_RENDERBUFFER, msaa_rbo_);
  if (msaa_mode == kExplicitResolve) {
    GL::RenderbufferStorageMultisample(GL_RENDERBUFFER, samples, GL_RGBA8, w,
                                       h);
  } else {
    GL::RenderbufferStorageMultisampleEXT(GL_RENDERBUFFER, samples, GL_RGBA8, w,
                                          h);
  }
  GL::FramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, msaa_rbo_);

  if (0 == msaa_depth_) {
    GL::GenRenderbuffers(1, &msaa_depth_);
  }
  GL::BindRenderbuffer(GL_RENDERBUFFER, msaa_depth_);
  if (msaa_mode == kExplicitResolve) {
    GL::RenderbufferStorageMultisample(GL_RENDERBUFFER, samples,
                                       GL_DEPTH24_STENCIL8, w, h);
  } else {
    GL::RenderbufferStorageMultisampleEXT(GL_RENDERBUFFER, samples,
                                          GL_DEPTH24_STENCIL8, w, h);
  }
  GL::FramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                              GL_RENDERBUFFER, msaa_depth_);
  GL::FramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                              GL_RENDERBUFFER, msaa_depth_);

  GL::ClearColor(0, 0, 0, 0);
  GL::ClearStencil(0);
  GL::ClearDepthf(1.0f);
  GL::Clear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

  DCHECK(GL::CheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
}

class ScopedGLStateForResolve {
 public:
  ScopedGLStateForResolve() {
    enable_scissor_test_ = GL::IsEnabled(GL_SCISSOR_TEST);
    if (enable_scissor_test_) {
      GL::Disable(GL_SCISSOR_TEST);
    }

    GL::GetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &read_buffer_);
    GL::GetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &draw_buffer_);
  }

  ~ScopedGLStateForResolve() {
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

void CanvasRenderbuffer::ResolveIfNeeded() {
  DCHECK(GLContext::GetCurrent());

  if (msaa_mode_ == kNone) {
    return;
  }

  // TODO(luchengxuan) implicit resolve need refactor to remove blit, now all
  // resolve is explicit
  DCHECK(msaa_fbo_ && fbo_);

  ScopedGLStateForResolve scoped_gl_state_for_resolve;
  GL::BindFramebuffer(GL_READ_FRAMEBUFFER, msaa_fbo_);
  GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, fbo_);

  GL::BlitFramebuffer(0, 0, w_, h_, 0, 0, w_, h_, GL_COLOR_BUFFER_BIT,
                      GL_NEAREST);
}

GLuint CanvasRenderbuffer::reading_fbo() const { return fbo_; }

GLuint CanvasRenderbuffer::drawing_fbo() const {
  if (msaa_mode_ == kNone) {
    return fbo_;
  }
  return msaa_fbo_;
}

}  // namespace canvas
}  // namespace lynx
