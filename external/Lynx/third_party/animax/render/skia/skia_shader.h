// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_SHADER_H_
#define ANIMAX_RENDER_SKIA_SKIA_SHADER_H_

#include "animax/render/include/shader.h"
#include "animax/render/skia/skia_util.h"

namespace lynx {
namespace animax {

class SkiaShader : public Shader {
 public:
  static std::unique_ptr<Shader> MakeSkiaLinear(
      PointF const& sp, PointF const& ep, int32_t size, int32_t* colors,
      float* positions, ShaderTileMode mode, Matrix& matrix);
  static std::unique_ptr<Shader> MakeSkiaRadial(PointF const& sp, float r,
                                                int32_t size, int32_t* colors,
                                                float* positions,
                                                ShaderTileMode mode,
                                                Matrix& matrix);

  SkiaShader(sk_sp<SkShader> sk_shader) : sk_shader_(std::move(sk_shader)) {}

  ~SkiaShader() override = default;

  sk_sp<SkShader> GetSkShader() const { return sk_shader_; }

 private:
  sk_sp<SkShader> sk_shader_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_SHADER_H_
