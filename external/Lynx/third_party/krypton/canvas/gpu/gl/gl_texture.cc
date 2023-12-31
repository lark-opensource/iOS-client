// Copyright 2023 The Lynx Authors. All rights reserved.

#include "canvas/gpu/gl/gl_texture.h"

#include "base/base_export.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"

namespace lynx {
namespace canvas {
BASE_EXPORT GLTexture::GLTexture(uint32_t width, uint32_t height)
    : width_(width), height_(height) {
  ScopedGLResetRestore s(GL_TEXTURE_BINDING_2D);
  GL::GenTextures(1, &tex_);
  GL::BindTexture(GL_TEXTURE_2D, tex_);
  GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  GL::TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  GL::TexImage2D(GL_TEXTURE_2D, 0, format_, width_, height_, 0, format_, type_,
                 nullptr);
}

BASE_EXPORT GLTexture::~GLTexture() {
  if (tex_) {
    GL::DeleteTextures(1, &tex_);
  }
}
}  // namespace canvas
}  // namespace lynx
