//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_TEXTURE_SOURCE_H_
#define CANVAS_TEXTURE_SOURCE_H_

#include "base/base_export.h"
#include "canvas/gpu/frame_buffer.h"
#include "canvas/gpu/texture_shader.h"

namespace lynx {
namespace canvas {

class BASE_EXPORT TextureSource {
 public:
  virtual ~TextureSource(){};

  virtual uint32_t Texture() = 0;

  virtual uint32_t reading_fbo() { return 0; };

  virtual void UpdateTextureOrFramebufferOnGPU() = 0;

  virtual int Width();

  virtual int Height();

  TextureShader* GetShader();

  virtual bool HasPremulAlpha() { return false; }

  virtual bool HasFlipY() { return false; }

 protected:
  int width_{0};
  int height_{0};

  std::unique_ptr<TextureShader> shader_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_TEXTURE_SOURCE_H_
