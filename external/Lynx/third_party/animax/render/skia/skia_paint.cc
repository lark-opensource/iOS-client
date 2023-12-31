// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skia/skia_paint.h"

#include "animax/base/log.h"
#include "animax/render/skia/skia_mask_filter.h"
#include "animax/render/skia/skia_path_effect.h"
#include "animax/render/skia/skia_shader.h"

namespace lynx {
namespace animax {

void SkiaPaint::SetAntiAlias(bool anti_alias) {
  skia_paint_.setAntiAlias(anti_alias);
}

void SkiaPaint::SetAlpha(float alpha) {
  skia_paint_.setAlpha(static_cast<uint8_t>(alpha));
}

void SkiaPaint::SetColor(const Color &color) {
  skia_paint_.setColor(
      SkColorSetARGB(color.GetA(), color.GetR(), color.GetG(), color.GetB()));
}

void SkiaPaint::SetColorFilter(ColorFilter &filter) {}

void SkiaPaint::SetStyle(PaintStyle style) {
  if (style == PaintStyle::kFill) {
    skia_paint_.setStyle(SkPaint::Style::kFill_Style);
  } else if (style == PaintStyle::kFillAddStroke) {
    skia_paint_.setStyle(SkPaint::Style::kStrokeAndFill_Style);
  } else if (style == PaintStyle::kStroke) {
    skia_paint_.setStyle(SkPaint::Style::kStroke_Style);
  }
}

void SkiaPaint::SetStrokeCap(PaintCap cap) {
  if (cap == PaintCap::kButt) {
    skia_paint_.setStrokeCap(SkPaint::Cap::kButt_Cap);
  } else if (cap == PaintCap::kRound) {
    skia_paint_.setStrokeCap(SkPaint::Cap::kRound_Cap);
  } else if (cap == PaintCap::kSquare) {
    skia_paint_.setStrokeCap(SkPaint::Cap::kSquare_Cap);
  }
}

void SkiaPaint::SetStrokeJoin(PaintJoin join) {
  if (join == PaintJoin::kRound) {
    skia_paint_.setStrokeJoin(SkPaint::Join::kRound_Join);
  } else if (join == PaintJoin::kBevel) {
    skia_paint_.setStrokeJoin(SkPaint::Join::kBevel_Join);
  } else if (join == PaintJoin::kMiter) {
    skia_paint_.setStrokeJoin(SkPaint::Join::kMiter_Join);
  }
}

void SkiaPaint::SetStrokeMiter(float miter) {
  skia_paint_.setStrokeMiter(miter);
}

void SkiaPaint::SetStrokeWidth(float width) {
  skia_paint_.setStrokeWidth(width);
}

float SkiaPaint::GetStrokeWidth() const { return skia_paint_.getStrokeWidth(); }

void SkiaPaint::SetXfermode(PaintXfermode mode) {
  if (mode == PaintXfermode::kDstIn) {
    skia_paint_.setBlendMode(SkBlendMode::kDstIn);
  } else if (mode == PaintXfermode::kDstOut) {
    skia_paint_.setBlendMode(SkBlendMode::kDstOut);
  } else if (mode == PaintXfermode::kClear) {
    skia_paint_.setBlendMode(SkBlendMode::kClear);
  }
}

void SkiaPaint::SetShader(Shader *shader) {
  if (shader == nullptr) {
    skia_paint_.setShader(nullptr);
    return;
  }

  auto sk_shader = static_cast<SkiaShader *>(shader);
  skia_paint_.setShader(sk_shader->GetSkShader());
}

void SkiaPaint::SetShadowLayer(float radius, float x, float y, int32_t color) {
  skia_paint_.setImageFilter(
      SkImageFilters::DropShadow(x, y, radius, radius, color, nullptr));
}

void SkiaPaint::SetMaskFilter(MaskFilter *filter) {
  auto skia_mask_filter = static_cast<SkiaMaskFilter *>(filter);
  if (skia_mask_filter) {
    skia_paint_.setMaskFilter(skia_mask_filter->GetSkMaskFilter());
  } else {
    skia_paint_.setMaskFilter(nullptr);
  }
}

void SkiaPaint::SetDashPathEffect(DashPathEffect &effect) {
  auto skia_dash_effect = static_cast<SkiaDashPathEffect *>(&effect);
  skia_paint_.setPathEffect(skia_dash_effect->GetEffect());
}

void SkiaPaint::SetFontThreshold(float font_size) {
  // do noting
}

}  // namespace animax
}  // namespace lynx
