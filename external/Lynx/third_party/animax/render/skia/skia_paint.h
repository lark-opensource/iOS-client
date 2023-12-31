// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_PAINT_H_
#define ANIMAX_RENDER_SKIA_SKIA_PAINT_H_

#include "animax/render/include/paint.h"
#include "animax/render/skia/skia_util.h"

namespace lynx {
namespace animax {

class SkiaPaint : public Paint {
 public:
  SkiaPaint() = default;
  ~SkiaPaint() override = default;

  void SetAntiAlias(bool anti_alias) override;
  void SetAlpha(float alpha) override;
  void SetColor(const Color &color) override;
  void SetColorFilter(ColorFilter &filter) override;
  void SetStyle(PaintStyle style) override;
  void SetStrokeCap(PaintCap cap) override;
  void SetStrokeJoin(PaintJoin join) override;
  void SetStrokeMiter(float miter) override;
  void SetStrokeWidth(float width) override;
  void SetXfermode(PaintXfermode mode) override;
  void SetShader(Shader *shader) override;
  void SetShadowLayer(float radius, float x, float y, int32_t color) override;
  void SetMaskFilter(MaskFilter *filter) override;
  void SetDashPathEffect(DashPathEffect &effect) override;
  void SetFontThreshold(float font_size) override;

  float GetStrokeWidth() const override;

  SkPaint const &GetSkPaint() const { return skia_paint_; }

 private:
  SkPaint skia_paint_ = {};
};
}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_PAINT_H_
