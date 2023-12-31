// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/2d/lite/canvas_gradient_lite.h"

#include "css/css_color.h"

namespace lynx {
namespace canvas {

CanvasGradientLite::CanvasGradientLite(double x0, double y0, double x1,
                                       double y1)
    : type_(kLinearType), x0_(x0), y0_(y0), x1_(x1), y1_(y1) {}

CanvasGradientLite::CanvasGradientLite(double x0, double y0, double r0,
                                       double x1, double y1, double r1)
    : type_(kRadialType),
      x0_(x0),
      y0_(y0),
      r0_(r0),
      x1_(x1),
      y1_(y1),
      r1_(r1) {}

nanovg::NVGpaint CanvasGradientLite::GetGradient(nanovg::NVGcontext* ctx) {
  SortStopsIfNecessary();

  switch (type_) {
    case kLinearType:
      return nanovg::nvgLinearGradient(ctx, x0_, y0_, x1_, y1_,
                                       gradient_.get());
    case kRadialType:
      return nanovg::nvgRadialGradient(ctx, x0_, y0_, x1_, y1_, r0_, r1_,
                                       gradient_.get());
    default:
      return nanovg::NVGpaint();
  }
}

void CanvasGradientLite::SortStopsIfNecessary() {
  if (gradient_) return;

  if (color_stops_.empty()) return;

  std::stable_sort(
      color_stops_.begin(), color_stops_.end(),
      [](const ColorStop& a, const ColorStop& b) { return a.stop < b.stop; });

  nanovg::GradientItems* items = (nanovg::GradientItems*)malloc(
      sizeof(nanovg::GradientItems) + 8 * color_stops_.size());
  items->count = static_cast<uint32_t>(color_stops_.size());
  for (size_t i = 0; i < color_stops_.size(); ++i) {
    items->items[i].pos = color_stops_[i].stop;
    items->items[i].color = color_stops_[i].color;
  }
  gradient_ = std::unique_ptr<nanovg::GradientItems>(items);
}

void CanvasGradientLite::AddColorStop(ExceptionState& exception_state,
                                      double offset, const std::string& color) {
  if (!(offset >= 0.0 && offset <= 1.0)) {
    exception_state.SetException("The provided value (" +
                                     std::to_string(offset) +
                                     ") is outside the range (0.0, 1.0).",
                                 piper::ExceptionState::kRangeError);
    return;
  }

  tasm::CSSColor css_color;
  if (!tasm::CSSColor::Parse(color, css_color)) {
    return;
  }

  // Clear gradient cache.
  gradient_.reset();

  unsigned int abgr_color =
      (0xffffffff & css_color.r_) | ((0xffffffff & css_color.g_) << 8) |
      ((0xffffffff & css_color.b_) << 16) |
      ((0xffffffff & ((unsigned char)(css_color.a_ * 255))) << 24);
  color_stops_.push_back({static_cast<float>(offset), abgr_color});
}

}  // namespace canvas
}  // namespace lynx
