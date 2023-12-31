// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_UTIL_NANOVG_UTIL_H_
#define CANVAS_UTIL_NANOVG_UTIL_H_

#include "canvas/2d/lite/nanovg/include/nanovg.h"
#include "css/css_color.h"

namespace lynx {
namespace canvas {

bool ParseColorString(const std::string& color, nanovg::NVGcolor& result);
std::string SerializeNVGcolor(nanovg::NVGcolor color);

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_UTIL_NANOVG_UTIL_H_
