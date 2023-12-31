// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_2D_LITE_CANVAS_RENDERING_CONTEXT_2D_LITE_STATE_H_
#define CANVAS_2D_LITE_CANVAS_RENDERING_CONTEXT_2D_LITE_STATE_H_

#include <string>

#include "canvas/2d/lite/canvas_style.h"
#include "canvas/2d/lite/nanovg/include/fontstash.h"
#include "canvas/2d/lite/nanovg/include/nanovg.h"
#include "canvas/util/css_font_parser.h"

namespace lynx {
namespace canvas {

class CanvasRenderingContext2DLiteState {
 public:
  CanvasRenderingContext2DLiteState();
  CanvasRenderingContext2DLiteState(const CanvasRenderingContext2DLiteState&);
  ~CanvasRenderingContext2DLiteState();

  const CanvasStyle& StrokeStyle() const { return stroke_style_; }
  void SetStrokeStyle(CanvasStyle style) { stroke_style_ = std::move(style); }

  const CanvasStyle& FillStyle() const { return fill_style_; };
  void SetFillStyle(CanvasStyle style) { fill_style_ = std::move(style); }

  bool HasRealizedFont() { return realized_font_; }

  void SetFont(CSSFont font);

  const CSSFont& Font() const { return font_; }

  void SetUnparsedFont(std::string font) { unparsed_font_ = std::move(font); }
  const std::string& UnparsedFont() const { return unparsed_font_; }

  void SetTextAlign(std::string text_align) {
    text_align_ = std::move(text_align);
  };
  std::string TextAlign() const { return text_align_; }

  void SetTextBaseline(std::string text_baseline) {
    text_baseline_ = std::move(text_baseline);
  }
  std::string TextBaseline() const { return text_baseline_; }

  void SetCompositeMode(nanovg::NVGcompositeOperation composite_operation) {
    composite_operation_ = composite_operation;
  }
  nanovg::NVGcompositeOperation CompositeOperation() const {
    return composite_operation_;
  }

 private:
  std::string unparsed_font_;
  CSSFont font_;
  bool realized_font_;
  CanvasStyle stroke_style_;
  CanvasStyle fill_style_;
  std::string text_align_;
  std::string text_baseline_;
  nanovg::NVGcompositeOperation composite_operation_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_2D_LITE_CANVAS_RENDERING_CONTEXT_2D_LITE_STATE_H_
