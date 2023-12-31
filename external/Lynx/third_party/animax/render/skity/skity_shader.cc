// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_shader.h"

#include <vector>

#include "animax/render/skity/skity_matrix.h"

namespace lynx {
namespace animax {

static skity::TileMode convert_to_skity_mode(ShaderTileMode mode) {
  switch (mode) {
    case ShaderTileMode::kClamp:
      return skity::TileMode::kClamp;
    case ShaderTileMode::kDecal:
      return skity::TileMode::kDecal;
    case ShaderTileMode::kMirror:
      return skity::TileMode::kMirror;
    case ShaderTileMode::kRepeat:
      return skity::TileMode::kRepeat;
    default:
      return skity::TileMode::kClamp;
  }
}

std::unique_ptr<Shader> SkityShader::MakeLinear(const PointF &sp,
                                                const PointF &ep, int32_t size,
                                                int32_t *colors, float *pos,
                                                ShaderTileMode mode,
                                                Matrix &matrix) {
  auto skity_matrix = static_cast<SkityMatrix *>(&matrix);

  std::vector<skity::Point> pts = {
      skity::Point{sp.GetX(), sp.GetY(), 0.f, 1.f},
      skity::Point{ep.GetX(), ep.GetY(), 0.f, 1.f},
  };

  std::vector<skity::Color4f> skity_colors;

  for (int32_t i = 0; i < size; i++) {
    skity_colors.emplace_back(skity::Color4fFromColor(colors[i]));
  }

  auto skity_mode = convert_to_skity_mode(mode);

  auto ret = std::make_unique<SkityShader>(skity::Shader::MakeLinear(
      pts.data(), skity_colors.data(), pos, size, skity_mode));

  ret->GetShader()->SetLocalMatrix(skity_matrix->GetMatrix());

  return ret;
}

std::unique_ptr<Shader> SkityShader::MakeRadial(const PointF &sp, float r,
                                                int32_t size, int32_t *colors,
                                                float *pos, ShaderTileMode mode,
                                                Matrix &matrix) {
  auto skity_matrix = static_cast<SkityMatrix *>(&matrix);
  auto skity_mode = convert_to_skity_mode(mode);

  skity::Point center{sp.GetX(), sp.GetY(), 0.f, 1.f};

  std::vector<skity::Color4f> skity_colors;

  for (int32_t i = 0; i < size; i++) {
    skity_colors.emplace_back(skity::Color4fFromColor(colors[i]));
  }

  auto ret = std::make_unique<SkityShader>(skity::Shader::MakeRadial(
      center, r, skity_colors.data(), pos, size, skity_mode));

  ret->GetShader()->SetLocalMatrix(skity_matrix->GetMatrix());

  return ret;
}

}  // namespace animax
}  // namespace lynx
