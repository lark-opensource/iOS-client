//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_FRAME_BUFFER_H_
#define CANVAS_GPU_FRAME_BUFFER_H_

#include <cstdint>

#include "base/base_export.h"
#include "canvas/gpu/gl/gl_api.h"

namespace lynx {
namespace canvas {

class Framebuffer {
 public:
  Framebuffer(uint32_t width, uint32_t height, GLenum internal_format,
              GLenum format, GLenum type);
  Framebuffer(uint32_t width, uint32_t height);
  BASE_EXPORT Framebuffer(uint32_t tex);

  BASE_EXPORT ~Framebuffer();

  BASE_EXPORT bool InitOnGPUIfNeed();
  void UpdateTexture(uint32_t tex);

  BASE_EXPORT uint32_t Fbo();
  uint32_t Texture();

  uint32_t Width() { return width_; }
  uint32_t Height() { return height_; }

 private:
  uint32_t width_{0};
  uint32_t height_{0};

  uint32_t fb_{0};
  uint32_t tex_{0};
  GLenum internal_format_{GL_RGBA};
  GLenum format_{GL_RGBA};
  GLenum type_{GL_UNSIGNED_BYTE};
  bool inited_{false};
  bool need_delete_tex_{false};
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_FRAME_BUFFER_H_
