// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_2D_LITE_CANVAS_GRADIENT_LITE_H_
#define CANVAS_2D_LITE_CANVAS_GRADIENT_LITE_H_

#include <string>
#include <vector>

#include "canvas/2d/canvas_gradient.h"
#include "canvas/2d/lite/nanovg/include/nanovg.h"

namespace lynx {
namespace canvas {

class CanvasGradientLite : public CanvasGradient {
 public:
  CanvasGradientLite(double x0, double y0, double x1, double y1);
  CanvasGradientLite(double x0, double y0, double r0, double x1, double y1,
                     double r1);
  CanvasGradientLite(const CanvasGradientLite&) = delete;
  ~CanvasGradientLite() override = default;

  CanvasGradientLite& operator=(const CanvasGradientLite&) = delete;

  nanovg::NVGpaint GetGradient(nanovg::NVGcontext* ctx);

  void AddColorStop(ExceptionState& exception_state, double offset,
                    const std::string& color) override;

 private:
  void SortStopsIfNecessary();

  enum Type { kConicType, kLinearType, kRadialType };

  Type type_;

  double x0_ = 0.0;
  double y0_ = 0.0;
  double r0_ = 0.0;
  double x1_ = 0.0;
  double y1_ = 0.0;
  double r1_ = 0.0;

  struct ColorStop {
    float stop;
    uint32_t color;
  };

  std::vector<ColorStop> color_stops_;

  std::unique_ptr<nanovg::GradientItems> gradient_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_2D_LITE_CANVAS_GRADIENT_LITE_H_
