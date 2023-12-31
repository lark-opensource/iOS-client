//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_FILTER_DATA_H_
#define LYNX_STARLIGHT_STYLE_FILTER_DATA_H_

#include <tuple>

#include "starlight/style/css_type.h"
#include "starlight/types/nlength.h"

namespace lynx {
namespace starlight {
struct FilterData {
  static constexpr int kIndexType = 0;
  static constexpr int kIndexAmount = 1;
  static constexpr int kIndexUnit = 2;
  FilterType type;
  NLength amount;

  FilterData();
  ~FilterData() = default;

  bool operator==(const FilterData& rhs) const {
    return std::tie(type, amount) == std::tie(rhs.type, rhs.amount);
  };

  bool operator!=(const FilterData& rhs) const { return !(*this == rhs); }

  void Reset();
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_FILTER_DATA_H_
