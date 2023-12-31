// Copyright 2020 The Lynx Authors. All rights reserved.
#ifndef LYNX_STARLIGHT_STYLE_OUTLINE_DATA_H_
#define LYNX_STARLIGHT_STYLE_OUTLINE_DATA_H_

#include <tuple>

#include "starlight/style/css_type.h"

namespace lynx {
namespace starlight {
struct OutLineData {
  OutLineData();
  ~OutLineData() = default;
  float width;
  BorderStyleType style;
  unsigned int color;
  bool operator==(const OutLineData& rhs) const {
    return std::tie(width, style, color) ==
           std::tie(rhs.width, rhs.style, rhs.color);
  }
};
}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_OUTLINE_DATA_H_
