// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_TEXT_FONT_UTIL_H_
#define CANVAS_TEXT_FONT_UTIL_H_

#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {
Napi::Value LoadFont(const Napi::CallbackInfo &info);
}
}  // namespace lynx

#endif  // CANVAS_TEXT_FONT_UTIL_H_
