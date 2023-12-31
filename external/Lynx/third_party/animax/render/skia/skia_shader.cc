// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skia/skia_shader.h"

#include <array>

#include "animax/render/skia/skia_matrix.h"

namespace lynx {
namespace animax {

static SkTileMode ConvertToSkMode(ShaderTileMode mode) {
  SkTileMode sk_mode = SkTileMode::kDecal;
  if (mode == ShaderTileMode::kClamp) {
    sk_mode = SkTileMode::kClamp;
  } else if (mode == ShaderTileMode::kRepeat) {
    sk_mode = SkTileMode::kRepeat;
  } else if (mode == ShaderTileMode::kMirror) {
    sk_mode = SkTileMode::kMirror;
  } else if (mode == ShaderTileMode::kDecal) {
    sk_mode = SkTileMode::kDecal;
  }

  return sk_mode;
}

std::unique_ptr<Shader> SkiaShader::MakeSkiaLinear(
    const PointF &sp, const PointF &ep, int32_t size, int32_t *colors,
    float *positions, ShaderTileMode mode, Matrix &matrix) {
  std::array<SkPoint, 2> pts{
      SkPoint::Make(sp.GetX(), sp.GetY()),
      SkPoint::Make(ep.GetX(), ep.GetY()),
  };

  auto sk_matrix = static_cast<SkiaMatrix *>(&matrix);

  auto sk_shader = SkGradientShader::MakeLinear(
      pts.data(), reinterpret_cast<const SkColor *>(colors), positions, size,
      ConvertToSkMode(mode), 0, &sk_matrix->GetSkMatrix());

  if (sk_shader) {
    return std::make_unique<SkiaShader>(sk_shader);
  } else {
    return {};
  }
}

std::unique_ptr<Shader> SkiaShader::MakeSkiaRadial(
    const PointF &sp, float r, int32_t size, int32_t *colors, float *positions,
    ShaderTileMode mode, Matrix &matrix) {
  SkPoint center = SkPoint::Make(sp.GetX(), sp.GetY());

  auto sk_matrix = static_cast<SkiaMatrix *>(&matrix);

  auto sk_shader = SkGradientShader::MakeRadial(
      center, r, reinterpret_cast<const SkColor *>(colors), positions, size,
      ConvertToSkMode(mode), 0, &sk_matrix->GetSkMatrix());

  if (sk_shader) {
    return std::make_unique<SkiaShader>(sk_shader);
  } else {
    return {};
  }
}

}  // namespace animax
}  // namespace lynx
