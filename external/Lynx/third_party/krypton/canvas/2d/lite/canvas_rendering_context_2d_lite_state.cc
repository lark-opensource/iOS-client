// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas_rendering_context_2d_lite_state.h"

namespace lynx {
namespace canvas {
namespace {
const char *const kDefaultTextAlign = "start";
const char *const kDefaultTextBaseline = "alphabetic";
}  // namespace

CanvasRenderingContext2DLiteState::CanvasRenderingContext2DLiteState()
    : realized_font_(false),
      text_align_(kDefaultTextAlign),
      text_baseline_(kDefaultTextBaseline),
      composite_operation_(nanovg::NVG_SOURCE_OVER) {}

CanvasRenderingContext2DLiteState::CanvasRenderingContext2DLiteState(
    const CanvasRenderingContext2DLiteState &others) = default;

void CanvasRenderingContext2DLiteState::SetFont(CSSFont font) {
  realized_font_ = true;
  font_ = std::move(font);
}

CanvasRenderingContext2DLiteState::~CanvasRenderingContext2DLiteState() =
    default;

}  // namespace canvas
}  // namespace lynx
