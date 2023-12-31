// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_PAINT_H_
#define ANIMAX_RENDER_SKITY_SKITY_PAINT_H_

#include <memory>

#include "animax/render/include/paint.h"
#include "skity/skity.hpp"

namespace lynx {
namespace animax {

struct SkityShadowLayer {
  float radius;
  float off_x;
  float off_y;
  int32_t color;

  SkityShadowLayer(float radius, float offX, float offY, int32_t color)
      : radius(radius), off_x(offX), off_y(offY), color(color) {}
};

class SkityPaint : public Paint {
 public:
  SkityPaint() = default;
  ~SkityPaint() override = default;

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

  skity::Paint const &GetPaint() const { return paint_; }

  std::shared_ptr<SkityShadowLayer> const &GetShadowLayer() const {
    return shadow_layer_;
  }

 private:
  skity::Paint paint_ = {};
  std::shared_ptr<SkityShadowLayer> shadow_layer_ = {};
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_PAINT_H_
