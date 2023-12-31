// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/2d/lite/canvas_pattern_lite.h"

#include "canvas/2d/lite/nanovg/include/nanovg_gl.h"

namespace lynx {
namespace canvas {

CanvasPatternLite::CanvasPatternLite(ExceptionState& exception_state,
                                     nanovg::NVGcontext* ctx,
                                     CanvasImageSource* source,
                                     const std::string& repetition_type) {
  image_id_ = source->CreateNVGImage(ctx, false);
  if (!image_id_) {
    exception_state.SetException(
        "CanvasPatternLite Constructor FetchTexture Fail");
    return;
  }
  ParseRepetitionType(repetition_type);
}

CanvasPatternLite::~CanvasPatternLite() = default;

void CanvasPatternLite::ParseRepetitionType(const std::string& type) {
  flags_ = nanovg::NVG_IMAGE_TRANSFORM;
  if (type.empty() || type == "repeat") {
    flags_ |= nanovg::NVG_IMAGE_REPEATX | nanovg::NVG_IMAGE_REPEATY;
    return;
  }

  if (type == "no-repeat") {
    return;
  }

  if (type == "repeat-x") {
    flags_ |= nanovg::NVG_IMAGE_REPEATX;
    return;
  }

  if (type == "repeat-y") {
    flags_ |= nanovg::NVG_IMAGE_REPEATY;
    return;
  }
}

nanovg::NVGpaint CanvasPatternLite::GetPattern(nanovg::NVGcontext* ctx) {
  int width, height;
  nanovg::nvgImageSize(ctx, image_id_, &width, &height);
  nanovg::NVGpaint pattern =
      nvgImagePattern(ctx, 0, 0, width, height, 0.0, image_id_, flags_);
  std::vector<float> matrix = {1.0, 0.0, 0.0, 1.0, 0.0, 0.0};
  if (transform_) {
    matrix = {static_cast<float>(transform_->a()),
              static_cast<float>(transform_->b()),
              static_cast<float>(transform_->c()),
              static_cast<float>(transform_->d()),
              static_cast<float>(transform_->e()),
              static_cast<float>(transform_->f())};
  }
  nvgSetImagePatternTransform(ctx, &pattern, matrix.data());
  return pattern;
}

void CanvasPatternLite::SetTransform(ExceptionState& exception_state) {
  transform_.reset();
}

void CanvasPatternLite::SetTransform(
    ExceptionState& exception_state,
    std::unique_ptr<DOMMatrix2DInit> transform) {
  transform_ = std::move(transform);
}

}  // namespace canvas
}  // namespace lynx
