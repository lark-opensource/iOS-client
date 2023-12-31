// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_2D_CANVAS_GRADIENT_H_
#define CANVAS_2D_CANVAS_GRADIENT_H_

#include <string>
#include <vector>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/exception_state.h"

namespace lynx {
namespace canvas {

using piper::ExceptionState;

class CanvasGradient : public piper::ImplBase {
 public:
  virtual void AddColorStop(ExceptionState& exception_state, double offset,
                            const std::string& color) = 0;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_2D_CANVAS_GRADIENT_H_
