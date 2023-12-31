//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "canvas/texture_source.h"

#include "canvas/media/video_element.h"

namespace lynx {
namespace canvas {

int TextureSource::Width() { return width_; }

int TextureSource::Height() { return height_; }

TextureShader* TextureSource::GetShader() {
  if (!shader_) {
    shader_ = std::make_unique<TextureShader>();
    shader_->InitOnGPU();
  }

  return shader_.get();
}

}  // namespace canvas
}  // namespace lynx
