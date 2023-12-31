// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_2D_LITE_CANVAS_STYLE_H_
#define CANVAS_2D_LITE_CANVAS_STYLE_H_

#include "canvas/2d/canvas_gradient.h"
#include "canvas/2d/canvas_pattern.h"
#include "canvas/2d/lite/nanovg/include/nanovg.h"

namespace lynx {
namespace canvas {

class CanvasStyle {
 public:
  CanvasStyle();
  explicit CanvasStyle(const std::string& color);
  explicit CanvasStyle(CanvasGradient* gradient);
  explicit CanvasStyle(CanvasPattern* pattern);
  ~CanvasStyle();

  CanvasStyle(const CanvasStyle& other);
  CanvasStyle& operator=(const CanvasStyle& other);

  CanvasStyle(CanvasStyle&& other);
  CanvasStyle& operator=(CanvasStyle&& other);

  nanovg::NVGcolor PaintColor() const { return color_; }

  Napi::Value GetJsValue(const Napi::Env& env) const;

  bool Valid() const { return type_ != kColorErrorType; }

 private:
  enum Type {
    kColorErrorType = -1,
    kColorRGBAType = 0,
    kGradientType,
    kImagePatternType
  };

  Type type_;
  nanovg::NVGcolor color_;
  std::string unparsed_color_;
  CanvasGradient* canvas_gradient_ = nullptr;
  CanvasPattern* canvas_pattern_ = nullptr;
  Napi::ObjectReference gradient_or_pattern_ref_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_2D_LITE_CANVAS_STYLE_H_
