// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_INCLUDE_PAINT_H_
#define ANIMAX_RENDER_INCLUDE_PAINT_H_

#include "animax/model/basic_model.h"
#include "animax/render/include/color_filter.h"
#include "animax/render/include/mask_filter.h"
#include "animax/render/include/path_effect.h"
#include "animax/render/include/shader.h"

namespace lynx {
namespace animax {

enum class PaintStyle : uint8_t { kFill = 0, kStroke, kFillAddStroke };

enum class PaintCap : uint8_t { kButt = 0, kRound, kSquare };

enum class PaintJoin : uint8_t { kMiter = 0, kRound, kBevel };

enum class PaintXfermode : uint8_t { kDstOut = 0, kDstIn, kClear };

class Paint {
 public:
  virtual ~Paint() = default;

  virtual void SetAntiAlias(bool anti_alias) = 0;
  virtual void SetAlpha(float alpha) = 0;
  virtual void SetColor(const Color& color) = 0;
  virtual void SetColorFilter(ColorFilter& filter) = 0;
  virtual void SetStyle(PaintStyle style) = 0;
  virtual void SetStrokeCap(PaintCap cap) = 0;
  virtual void SetStrokeJoin(PaintJoin join) = 0;
  virtual void SetStrokeMiter(float miter) = 0;
  virtual void SetStrokeWidth(float width) = 0;
  virtual void SetXfermode(PaintXfermode mode) = 0;
  virtual void SetShader(Shader* shader) = 0;
  virtual void SetShadowLayer(float radius, float x, float y,
                              int32_t color) = 0;
  virtual void SetMaskFilter(MaskFilter* filter) = 0;
  virtual void SetDashPathEffect(DashPathEffect& effect) = 0;
  virtual void SetFontThreshold(float font_size) = 0;
  virtual float GetStrokeWidth() const = 0;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_INCLUDE_PAINT_H_
