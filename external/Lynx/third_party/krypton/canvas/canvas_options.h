//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_CANVAS_OPTIONS_H_
#define CANVAS_CANVAS_OPTIONS_H_

#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace canvas {

class CanvasOptions {
 public:
  void Update(Napi::Object option);

  bool skip_error_check{true};
  bool enable_auto_release_image_mem{false};
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_CANVAS_OPTIONS_H_
