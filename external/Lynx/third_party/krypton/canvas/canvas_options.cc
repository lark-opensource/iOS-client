//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "canvas_options.h"

namespace lynx {
namespace canvas {

void CanvasOptions::Update(Napi::Object option) {
  Napi::Value js_skip_err_check = option.Get("skipErrorCheck");
  if (js_skip_err_check.IsBoolean()) {
    skip_error_check = js_skip_err_check.ToBoolean();
  }

  Napi::Value js_enable_auto_relase_image_mem =
      option.Get("autoReleaseImageMem");
  if (js_enable_auto_relase_image_mem.IsBoolean()) {
    enable_auto_release_image_mem = js_enable_auto_relase_image_mem.ToBoolean();
  }
}

}  // namespace canvas
}  // namespace lynx
