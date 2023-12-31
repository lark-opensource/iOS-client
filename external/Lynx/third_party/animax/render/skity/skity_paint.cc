// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_paint.h"

#include <algorithm>

#include "animax/render/skity/skity_mask_filter.h"
#include "animax/render/skity/skity_path_effect.h"
#include "animax/render/skity/skity_shader.h"
#include "skity/effect/image_filter.hpp"

namespace lynx {
namespace animax {

void SkityPaint::SetAntiAlias(bool anti_alias) {
  paint_.SetAntiAlias(anti_alias);
}

void SkityPaint::SetAlpha(float alpha) {
  paint_.SetAlpha(static_cast<uint8_t>(alpha));
}

void SkityPaint::SetColor(const Color &color) {
  paint_.SetColor(skity::ColorSetARGB(color.GetA(), color.GetR(), color.GetG(),
                                      color.GetB()));
}

void SkityPaint::SetColorFilter(ColorFilter &filter) {}

void SkityPaint::SetStyle(PaintStyle style) {
  switch (style) {
    case PaintStyle::kFill:
      paint_.SetStyle(skity::Paint::kFill_Style);
      break;
    case PaintStyle::kStroke:
      paint_.SetStyle(skity::Paint::kStroke_Style);
      break;
    case PaintStyle::kFillAddStroke:
      paint_.SetStyle(skity::Paint::kStrokeAndFill_Style);
      break;
    default:
      paint_.SetStyle(skity::Paint::kFill_Style);
      break;
  }
}

void SkityPaint::SetStrokeCap(PaintCap cap) {
  switch (cap) {
    case PaintCap::kButt:
      paint_.SetStrokeCap(skity::Paint::kButt_Cap);
      break;
    case PaintCap::kRound:
      paint_.SetStrokeCap(skity::Paint::kRound_Cap);
      break;
    case PaintCap::kSquare:
      paint_.SetStrokeCap(skity::Paint::kSquare_Cap);
      break;
    default:
      paint_.SetStrokeCap(skity::Paint::kButt_Cap);
      break;
  }
}

void SkityPaint::SetStrokeJoin(PaintJoin join) {
  switch (join) {
    case PaintJoin::kMiter:
      paint_.SetStrokeJoin(skity::Paint::kMiter_Join);
      break;
    case PaintJoin::kBevel:
      paint_.SetStrokeJoin(skity::Paint::kBevel_Join);
      break;
    case PaintJoin::kRound:
      paint_.SetStrokeJoin(skity::Paint::kRound_Join);
      break;
    default:
      paint_.SetStrokeJoin(skity::Paint::kRound_Join);
      break;
  }
}

void SkityPaint::SetStrokeMiter(float miter) { paint_.SetStrokeMiter(miter); }

void SkityPaint::SetStrokeWidth(float width) { paint_.SetStrokeWidth(width); }

void SkityPaint::SetXfermode(PaintXfermode mode) {
  switch (mode) {
    case PaintXfermode::kDstOut:
      paint_.SetBlendMode(skity::BlendMode::kDstOut);
      break;
    case PaintXfermode::kDstIn:
      paint_.SetBlendMode(skity::BlendMode::kDstIn);
      break;
    case PaintXfermode::kClear:
      paint_.SetBlendMode(skity::BlendMode::kClear);
      break;
    default:
      paint_.SetBlendMode(skity::BlendMode::kDefault);
      break;
  }
}

void SkityPaint::SetShader(Shader *shader) {
  if (shader == nullptr) {
    paint_.SetShader(nullptr);
    return;
  }

  auto skity_shader = static_cast<SkityShader *>(shader);
  paint_.SetShader(skity_shader->GetShader());
}

void SkityPaint::SetShadowLayer(float radius, float x, float y, int32_t color) {
  shadow_layer_ =
      std::make_shared<SkityShadowLayer>(std::max(radius, 3.f), x, y, color);
}

void SkityPaint::SetMaskFilter(MaskFilter *filter) {
  auto skity_mask_filter = static_cast<SkityMaskFilter *>(filter);

  if (skity_mask_filter) {
    paint_.SetMaskFilter(skity_mask_filter->GetMaskFilter());
  } else {
    paint_.SetMaskFilter(nullptr);
  }
}

void SkityPaint::SetDashPathEffect(DashPathEffect &effect) {
  auto skity_dash_effect = static_cast<SkityDashPathEffect *>(&effect);
  paint_.SetPathEffect(skity_dash_effect->GetEffect());
}

void SkityPaint::SetFontThreshold(float font_size) {
  paint_.SetFontThreshold(font_size);
}

float SkityPaint::GetStrokeWidth() const { return paint_.GetStrokeWidth(); }
}  // namespace animax
}  // namespace lynx
