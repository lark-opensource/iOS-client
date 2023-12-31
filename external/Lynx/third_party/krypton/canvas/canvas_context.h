// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_CANVAS_CONTEXT_H_
#define CANVAS_CANVAS_CONTEXT_H_

#include "canvas/canvas_element.h"
#include "canvas/surface/surface.h"
#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {

class CanvasElement;
using piper::BridgeBase;
using piper::ImplBase;

class CanvasContext : public ImplBase {
 public:
  enum class Type { k2D = 0, kWebgl };

  static CanvasContext* Create(CanvasElement* element) {
    return new CanvasContext(element);
  }
  CanvasContext(CanvasElement* element) : element_(element) {}
  CanvasElement* GetCanvas() { return element_; }

 protected:
  CanvasElement* element_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_CANVAS_CONTEXT_H_
