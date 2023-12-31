// Copyright 2021 The Lynx Authors. All rights reserved.

#include "text_metrics.h"

namespace lynx {
namespace canvas {

TextMetrics::TextMetrics(double width, double actual_bounding_box_left,
                         double actual_bounding_box_right,
                         double font_bounding_box_ascent,
                         double font_bounding_box_descent,
                         double actual_bounding_box_ascent,
                         double actual_bounding_box_descent,
                         double missing_glyph_count)
    : width_(width),
      actual_bounding_box_left_(actual_bounding_box_left),
      actual_bounding_box_right_(actual_bounding_box_right),
      font_bounding_box_ascent_(font_bounding_box_ascent),
      font_bounding_box_descent_(font_bounding_box_descent),
      actual_bounding_box_ascent_(actual_bounding_box_ascent),
      actual_bounding_box_descent_(actual_bounding_box_descent),
      missing_glyph_count_(missing_glyph_count) {}
}  // namespace canvas
}  // namespace lynx
