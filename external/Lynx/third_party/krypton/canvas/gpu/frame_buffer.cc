//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "frame_buffer.h"

#include "canvas/background_lock.h"
#include "canvas/base/log.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"

namespace lynx {
namespace canvas {
Framebuffer::Framebuffer(uint32_t width, uint32_t height,
                         GLenum internal_format, GLenum format, GLenum type)
    : width_(width),
      height_(height),
      internal_format_(internal_format),
      format_(format),
      type_(type) {}

Framebuffer::Framebuffer(uint32_t width, uint32_t height)
    : width_(width), height_(height) {}

Framebuffer::Framebuffer(uint32_t tex) : tex_(tex) {}

Framebuffer::~Framebuffer() {
  if (fb_) {
    GL::DeleteFramebuffers(1, &fb_);
  }

  if (need_delete_tex_ && tex_) {
    GL::DeleteTextures(1, &tex_);
  }
}

bool Framebuffer::InitOnGPUIfNeed() {
  if (inited_) {
    return true;
  }

  GL::GenFramebuffers(1, &fb_);
  ScopedGLResetRestore s0(GL_DRAW_FRAMEBUFFER_BINDING);
  GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, fb_);

  {
    ScopedGLResetRestore s1(GL_TEXTURE_BINDING_2D);
    if (!tex_) {
      GL::GenTextures(1, &tex_);
      GL::BindTexture(GL_TEXTURE_2D, tex_);
      GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
      GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      GL::TexImage2D(GL_TEXTURE_2D, 0, internal_format_, width_, height_, 0,
                     format_, type_, nullptr);
      need_delete_tex_ = true;
    }

    GL::BindTexture(GL_TEXTURE_2D, tex_);
    GL::FramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                             GL_TEXTURE_2D, tex_, 0);

    int res = GL::CheckFramebufferStatus(GL_DRAW_FRAMEBUFFER);
    if (res != GL_FRAMEBUFFER_COMPLETE) {
      KRYPTON_LOGE("external texture as renderstorage falied ") << res;

      if (fb_) {
        GL::DeleteFramebuffers(1, &fb_);
      }

      if (need_delete_tex_ && tex_) {
        GL::DeleteTextures(1, &tex_);
        need_delete_tex_ = false;
      }

      fb_ = 0;
      tex_ = 0;
      return false;
    }
  }

  inited_ = true;

  return true;
}

void Framebuffer::UpdateTexture(uint32_t tex) {
  if (!fb_) {
    KRYPTON_LOGE("call InitOnGPU before Update Texture");
    return;
  }

  if (tex_ && need_delete_tex_) {
    GL::DeleteTextures(1, &tex_);
  }

  need_delete_tex_ = false;
  tex_ = tex;
  ScopedGLResetRestore s(GL_FRAMEBUFFER_BINDING);
  ScopedGLResetRestore s1(GL_TEXTURE_BINDING_2D);
  GL::BindFramebuffer(GL_FRAMEBUFFER, fb_);
  GL::BindTexture(GL_TEXTURE_2D, tex_);
  GL::FramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                           tex_, 0);

  int res = GL::CheckFramebufferStatus(GL_FRAMEBUFFER);
  if (res != GL_FRAMEBUFFER_COMPLETE) {
    KRYPTON_LOGE(
        "tex commit command failed, texture as renderstorage "
        "falied ")
        << res;

    return;
  }
}

uint32_t Framebuffer::Fbo() { return fb_; }

uint32_t Framebuffer::Texture() { return tex_; }

}  // namespace canvas
}  // namespace lynx
