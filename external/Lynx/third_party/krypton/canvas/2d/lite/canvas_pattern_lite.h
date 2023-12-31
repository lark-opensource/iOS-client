// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_2D_LITE_CANVAS_PATTERN_LITE_H_
#define CANVAS_2D_LITE_CANVAS_PATTERN_LITE_H_

#include <memory>
#include <string>

#include "canvas/2d/canvas_pattern.h"
#include "canvas/2d/lite/nanovg/include/nanovg.h"
#include "canvas/canvas_image_source.h"

namespace lynx {
namespace canvas {

class CanvasPatternLite : public CanvasPattern {
 public:
  CanvasPatternLite(ExceptionState& exception_state, nanovg::NVGcontext* ctx,
                    CanvasImageSource* image_source,
                    const std::string& repetition_type);
  CanvasPatternLite(const CanvasPatternLite&) = delete;
  ~CanvasPatternLite() override;

  CanvasPatternLite& operator=(const CanvasPatternLite&) = delete;

  nanovg::NVGpaint GetPattern(nanovg::NVGcontext* ctx);

  void SetTransform(ExceptionState& exception_state) override;
  void SetTransform(ExceptionState& exception_state,
                    std::unique_ptr<DOMMatrix2DInit> transform) override;

 private:
  void ParseRepetitionType(const std::string& type);

  int image_id_;
  int flags_;
  std::unique_ptr<DOMMatrix2DInit> transform_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_2D_LITE_CANVAS_PATTERN_LITE_H_
