// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_TRANSFORM_RAW_DATA_H_
#define LYNX_STARLIGHT_STYLE_TRANSFORM_RAW_DATA_H_

#include <tuple>

#include "starlight/style/css_type.h"
#include "starlight/types/nlength.h"

namespace lynx {
namespace starlight {
struct TransformRawData {
  static constexpr int INDEX_FUNC = 0;
  static constexpr int INDEX_TRANSLATE_0 = 1;
  static constexpr int INDEX_TRANSLATE_0_UNIT = 2;
  static constexpr int INDEX_TRANSLATE_1 = 3;
  static constexpr int INDEX_TRANSLATE_1_UNIT = 4;
  static constexpr int INDEX_TRANSLATE_2 = 5;
  static constexpr int INDEX_TRANSLATE_2_UNIT = 6;
  static constexpr int INDEX_ROTATE_ANGLE = 1;
  static constexpr int INDEX_SCALE_0 = 1;
  static constexpr int INDEX_SCALE_1 = 2;
  static constexpr int INDEX_SKEW_0 = 1;
  static constexpr int INDEX_SKEW_1 = 2;

  TransformRawData();
  ~TransformRawData() = default;

  TransformType type;
  NLength p0;
  NLength p1;
  NLength p2;

  bool operator==(const TransformRawData& rhs) const {
    return std::tie(type, p0, p1, p2) ==
           std::tie(rhs.type, rhs.p0, rhs.p1, rhs.p2);
  }

  bool operator!=(const TransformRawData& rhs) const { return !(*this == rhs); }

  void Reset();

  bool Empty() {
    return (p0.GetRawValue() - 0 < 0.0001f) &&
           (p1.GetRawValue() - 0 < 0.0001f) && (p2.GetRawValue() - 0 < 0.0001f);
  }
};
}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_TRANSFORM_RAW_DATA_H_
