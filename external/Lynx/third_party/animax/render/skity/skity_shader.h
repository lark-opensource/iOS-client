// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_SHADER_H_
#define ANIMAX_RENDER_SKITY_SKITY_SHADER_H_

#include "animax/render/include/shader.h"
#include "skity/skity.hpp"

namespace lynx {
namespace animax {

class SkityShader : public Shader {
 public:
  static std::unique_ptr<Shader> MakeLinear(PointF const& sp, PointF const& ep,
                                            int32_t size, int32_t* colors,
                                            float* positions,
                                            ShaderTileMode mode,
                                            Matrix& matrix);

  static std::unique_ptr<Shader> MakeRadial(PointF const& sp, float r,
                                            int32_t size, int32_t* colors,
                                            float* positions,
                                            ShaderTileMode mode,
                                            Matrix& matrix);

  explicit SkityShader(std::shared_ptr<skity::Shader> shader)
      : shader_(std::move(shader)) {}

  ~SkityShader() override = default;

  std::shared_ptr<skity::Shader> const& GetShader() const { return shader_; }

 private:
  std::shared_ptr<skity::Shader> shader_ = {};
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_SHADER_H_
