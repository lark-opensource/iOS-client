//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_CANVAS_ELEMENT_TEXTURE_SOURCE_H_
#define CANVAS_WEBGL_CANVAS_ELEMENT_TEXTURE_SOURCE_H_

#include "canvas/gpu/texture_shader.h"
#include "canvas/raster.h"
#include "canvas/texture_source.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace canvas {

class CanvasElementTextureSource : public TextureSource {
 public:
  CanvasElementTextureSource(std::shared_ptr<shell::LynxActor<Raster>> raster,
                             bool is_premul_alpha);

  uint32_t Texture() override;

  uint32_t reading_fbo() override;

  void UpdateTextureOrFramebufferOnGPU() override;

  void OnCanvasSizeChange(uint32_t width, uint32_t height);

  int Width() override;

  int Height() override;

  bool HasFlipY() override;

  bool HasPremulAlpha() override;

 private:
  std::shared_ptr<shell::LynxActor<Raster>> raster_;

  std::unique_ptr<Framebuffer> fb_;
  bool tex_need_update_{false};
  bool is_premul_alpha_{false};

  bool ReCreateFramebufferIfNeed();
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_CANVAS_ELEMENT_TEXTURE_SOURCE_H_
