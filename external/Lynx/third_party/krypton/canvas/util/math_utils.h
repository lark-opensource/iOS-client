// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_UTIL_MATH_UTILS_H_
#define CANVAS_UTIL_MATH_UTILS_H_

#include <limits>

namespace lynx {
namespace canvas {

inline float ClampDoubleToFloat(double value) {
  if (value < std::numeric_limits<float>::lowest()) {
    return std::numeric_limits<float>::lowest();
  }
  if (value > std::numeric_limits<float>::max()) {
    return std::numeric_limits<float>::max();
  }

  return static_cast<float>(value);
}

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_UTIL_MATH_UTILS_H_
