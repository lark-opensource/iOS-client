// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_2D_TEXT_METRICS_H_
#define CANVAS_2D_TEXT_METRICS_H_

#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {
class TextMetrics : public piper::ImplBase {
 public:
  TextMetrics(double width, double actual_bounding_box_left,
              double actual_bounding_box_right, double font_bounding_box_ascent,
              double font_bounding_box_descent,
              double actual_bounding_box_ascent,
              double actual_bounding_box_descent, double missing_glyph_count);

  double GetWidth() const { return width_; }
  double GetActualBoundingBoxLeft() const { return actual_bounding_box_left_; }
  double GetActualBoundingBoxRight() const {
    return actual_bounding_box_right_;
  }

  double GetFontBoundingBoxAscent() const { return font_bounding_box_ascent_; }
  double GetFontBoundingBoxDescent() const {
    return font_bounding_box_descent_;
  }
  double GetActualBoundingBoxAscent() const {
    return actual_bounding_box_ascent_;
  }
  double GetActualBoundingBoxDescent() const {
    return actual_bounding_box_descent_;
  }
  double GetMissingGlyphCount() const { return missing_glyph_count_; }

 private:
  // x-direction
  double width_ = 0.0;
  double actual_bounding_box_left_ = 0.0;
  double actual_bounding_box_right_ = 0.0;

  // y-direction
  double font_bounding_box_ascent_ = 0.0;
  double font_bounding_box_descent_ = 0.0;
  double actual_bounding_box_ascent_ = 0.0;
  double actual_bounding_box_descent_ = 0.0;

  double missing_glyph_count_ = 0.0;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_2D_TEXT_METRICS_H_
