// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/2d/lite/canvas_style.h"

#include "canvas/base/log.h"
#include "canvas/util/nanovg_util.h"

namespace lynx {
namespace canvas {

CanvasStyle::CanvasStyle()
    : type_(kColorRGBAType),
      color_(nanovg::nvgRGB(0, 0, 0)),
      unparsed_color_("#000000") {}

CanvasStyle::CanvasStyle(const std::string& color) : type_(kColorRGBAType) {
  if (ParseColorString(color, color_)) {
    unparsed_color_ = color;
  } else {
    type_ = kColorErrorType;
  }
}

CanvasStyle::CanvasStyle(CanvasGradient* gradient)
    : type_(kGradientType),
      canvas_gradient_(gradient),
      gradient_or_pattern_ref_(gradient->ObtainStrongRef()) {}

CanvasStyle::CanvasStyle(CanvasPattern* pattern)
    : type_(kImagePatternType),
      canvas_pattern_(pattern),
      gradient_or_pattern_ref_(pattern->ObtainStrongRef()) {}

CanvasStyle::~CanvasStyle() = default;

CanvasStyle::CanvasStyle(const CanvasStyle& other)
    : type_(other.type_),
      color_(other.color_),
      unparsed_color_(other.unparsed_color_),
      canvas_gradient_(other.canvas_gradient_),
      canvas_pattern_(other.canvas_pattern_) {
  if (!other.gradient_or_pattern_ref_.IsEmpty()) {
    gradient_or_pattern_ref_ =
        Persistent(other.gradient_or_pattern_ref_.Value());
  }
}

CanvasStyle& CanvasStyle::operator=(const CanvasStyle& other) {
  if (&other != this) {
    type_ = other.type_;
    color_ = other.color_;
    unparsed_color_ = other.unparsed_color_;
    canvas_gradient_ = other.canvas_gradient_;
    canvas_pattern_ = other.canvas_pattern_;
    if (!other.gradient_or_pattern_ref_.IsEmpty()) {
      gradient_or_pattern_ref_ =
          Persistent(other.gradient_or_pattern_ref_.Value());
    }
  }
  return *this;
}

CanvasStyle::CanvasStyle(CanvasStyle&& other) = default;

CanvasStyle& CanvasStyle::operator=(CanvasStyle&& other) = default;

Napi::Value CanvasStyle::GetJsValue(const Napi::Env& env) const {
  switch (type_) {
    case kColorRGBAType:
      return Napi::String::New(env, unparsed_color_);
    case kGradientType:
    case kImagePatternType:
      return gradient_or_pattern_ref_.Value();
    default:
      return Napi::String::New(env, "");
  }
}

}  // namespace canvas
}  // namespace lynx
