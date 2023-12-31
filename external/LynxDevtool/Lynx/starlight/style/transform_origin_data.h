// Copyright 2020 The Lynx Authors. All rights reserved.
#ifndef LYNX_STARLIGHT_STYLE_TRANSFORM_ORIGIN_DATA_H_
#define LYNX_STARLIGHT_STYLE_TRANSFORM_ORIGIN_DATA_H_

#include <tuple>

#include "starlight/style/css_type.h"
#include "starlight/types/nlength.h"

namespace lynx {
namespace starlight {
struct TransformOriginData {
  static constexpr int INDEX_X = 0;
  static constexpr int INDEX_X_UNIT = 1;
  static constexpr int INDEX_Y = 2;
  static constexpr int INDEX_Y_UNIT = 3;

  NLength x;
  NLength y;
  TransformOriginData();
  ~TransformOriginData() = default;

  void Reset();

  bool operator==(const TransformOriginData& rhs) const {
    return std::tie(x, y) == std::tie(rhs.x, rhs.y);
  }
};

}  // namespace starlight
}  // namespace lynx
#endif  // LYNX_STARLIGHT_STYLE_TRANSFORM_ORIGIN_DATA_H_
