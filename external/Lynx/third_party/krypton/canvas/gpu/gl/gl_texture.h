// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_GL_TEXTURE_H_
#define CANVAS_GPU_GL_GL_TEXTURE_H_

#include <cstdint>

#include "third_party/krypton/canvas/gpu/gl/gl_api.h"

namespace lynx {
namespace canvas {
class GLTexture {
 public:
  GLTexture(uint32_t width, uint32_t height);
  ~GLTexture();

  uint32_t Texture() { return tex_; }

 private:
  uint32_t width_{0}, height_{0};
  uint32_t tex_{0};
  GLenum format_{GL_RGBA}, type_{GL_UNSIGNED_BYTE};
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_GL_TEXTURE_H_
