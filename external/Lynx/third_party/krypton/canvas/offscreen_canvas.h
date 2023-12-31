// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_OFFSCREEN_CANVAS_H_
#define CANVAS_OFFSCREEN_CANVAS_H_

#include "canvas_element.h"

namespace lynx {
namespace canvas {

class OffscreenCanvas : public CanvasElement {
 public:
  static std::unique_ptr<OffscreenCanvas> Create(Napi::Number width,
                                                 Napi::Number height) {
    /// TODO by linyiyi
    return nullptr;
  }
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_OFFSCREEN_CANVAS_H_
