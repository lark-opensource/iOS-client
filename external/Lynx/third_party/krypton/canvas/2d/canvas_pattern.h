// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_2D_CANVAS_PATTERN_H_
#define CANVAS_2D_CANVAS_PATTERN_H_

#include <memory>
#include <string>

#include "jsbridge/bindings/canvas/napi_dom_matrix_2d_init.h"
#include "jsbridge/napi/base.h"
#include "jsbridge/napi/exception_state.h"

namespace lynx {
namespace canvas {

using piper::ExceptionState;

class CanvasPattern : public piper::ImplBase {
 public:
  virtual void SetTransform(ExceptionState& exception_state) = 0;
  virtual void SetTransform(ExceptionState& exception_state,
                            std::unique_ptr<DOMMatrix2DInit> transform) = 0;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_2D_CANVAS_PATTERN_H_
