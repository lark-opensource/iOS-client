// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_STARLIGHT_TYPES_LAYOUT_PERFORMANCE_H_
#define LYNX_STARLIGHT_TYPES_LAYOUT_PERFORMANCE_H_

#include <chrono>
#include <iostream>
#include <list>

namespace lynx {
namespace starlight {

struct LayoutPref {
  bool has_cache_;
  bool is_final_measure_;
  uint32_t perf_id_;
  uint64_t start_time_;
  uint64_t end_time_;
  uint64_t duration_time_;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_TYPES_LAYOUT_PERFORMANCE_H_
