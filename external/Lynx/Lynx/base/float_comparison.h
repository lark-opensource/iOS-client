// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_FLOAT_COMPARISON_H_
#define LYNX_BASE_FLOAT_COMPARISON_H_

#include <math.h>

namespace lynx {
namespace base {

constexpr float EPSILON = 0.01f;

inline bool FloatsEqual(const float first, const float second) {
  return fabs(first - second) < EPSILON;
}

inline bool FloatsNotEqual(const float first, const float second) {
  return fabs(first - second) >= EPSILON;
}

inline bool FloatsLarger(const float first, const float second) {
  return fabs(first - second) >= EPSILON && first > second;
}

inline bool FloatsLargerOrEqual(const float first, const float second) {
  return first > second || fabs(first - second) < EPSILON;
}

inline bool IsZero(const float f) { return FloatsEqual(f, 0.0f); }

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_FLOAT_COMPARISON_H_
