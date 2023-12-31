//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "canvas_element_texture_source.h"

#include "canvas/base/log.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"
#include "canvas/raster.h"
#include "canvas/util/texture_util.h"

namespace lynx {
namespace canvas {

CanvasElementTextureSource::CanvasElementTextureSource(
    std::shared_ptr<shell::LynxActor<Raster>> raster, bool is_premul_alpha)
    : raster_(raster), is_premul_alpha_(is_premul_alpha) {}

uint32_t CanvasElementTextureSource::Texture() {
  if (!fb_) {
    return 0;
  }

  return fb_->Texture();
}

uint32_t CanvasElementTextureSource::reading_fbo() {
  if (!raster_) {
    return 0;
  }

  return raster_->Impl()->reading_fbo();
}

void CanvasElementTextureSource::UpdateTextureOrFramebufferOnGPU() {
  if (!raster_) {
    return;
  }

  raster_->Impl()->WillAccessContent(false);

  if (!ReCreateFramebufferIfNeed()) {
    return;
  }

  uint32_t w = Width(), h = Height();
  ScopedGLResetRestore s1(GL_READ_FRAMEBUFFER_BINDING);
  ScopedGLResetRestore s2(GL_DRAW_FRAMEBUFFER_BINDING);
  GL::BindFramebuffer(GL_READ_FRAMEBUFFER, raster_->Impl()->reading_fbo());
  GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, fb_->Fbo());
  GL::BlitFramebuffer(0, 0, w, h, 0, 0, w, h, GL_COLOR_BUFFER_BIT, GL_LINEAR);
}

void CanvasElementTextureSource::OnCanvasSizeChange(uint32_t width,
                                                    uint32_t height) {
  tex_need_update_ = true;
}

int CanvasElementTextureSource::Width() {
  return raster_ ? raster_->Impl()->renderbuffer()->width() : 0;
}

int CanvasElementTextureSource::Height() {
  return raster_ ? raster_->Impl()->renderbuffer()->height() : 0;
}

bool CanvasElementTextureSource::HasFlipY() { return true; }

bool CanvasElementTextureSource::HasPremulAlpha() { return is_premul_alpha_; }

bool CanvasElementTextureSource::ReCreateFramebufferIfNeed() {
  if (fb_ && !tex_need_update_) {
    return true;
  }

  fb_ = std::make_unique<Framebuffer>(Width(), Height());
  if (!fb_->InitOnGPUIfNeed()) {
    KRYPTON_LOGE("framebuffer init failed");
    return false;
  }
  tex_need_update_ = false;
  return true;
}

}  // namespace canvas
}  // namespace lynx
