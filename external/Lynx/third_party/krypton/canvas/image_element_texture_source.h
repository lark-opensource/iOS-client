// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_IMAGE_ELEMENT_TEXTURE_SOURCE_H_
#define CANVAS_IMAGE_ELEMENT_TEXTURE_SOURCE_H_

#include "canvas/base/log.h"
#include "canvas/bitmap.h"
#include "canvas/texture_source.h"

namespace lynx {
namespace canvas {

class ImageElementTextureSource : public TextureSource {
 public:
  ImageElementTextureSource(const std::shared_ptr<Bitmap>& bitmap)
      : bitmap_(bitmap),
        has_flipY_(bitmap->HasFlipY()),
        has_premul_alpha_(bitmap->HasPremulAlpha()) {}

  ~ImageElementTextureSource();

  uint32_t Texture() override;

  uint32_t reading_fbo() override;

  bool HasPremulAlpha() override { return has_premul_alpha_; }

  bool HasFlipY() override { return has_flipY_; }

  void UpdateTextureOrFramebufferOnGPU() override{};

 private:
  std::shared_ptr<Bitmap> bitmap_;

  uint32_t tex_{0};
  bool has_flipY_{false};
  bool has_premul_alpha_{false};
  std::unique_ptr<Framebuffer> fb_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_IMAGE_ELEMENT_TEXTURE_SOURCE_H_
