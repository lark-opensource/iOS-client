// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_FLEX_INFO_H_
#define LYNX_STARLIGHT_LAYOUT_FLEX_INFO_H_

#include <vector>

#include "starlight/layout/layout_global.h"

namespace lynx {
namespace starlight {
class LayoutObject;

struct LineInfo {
  LineInfo(int start, int end, float line_cross_size,
           float remaining_free_space, bool is_flex_grow)
      : start_(start),
        end_(end),
        line_cross_size_(line_cross_size),
        remaining_free_space_(remaining_free_space),
        largest_baseline_delta_(0.0f),
        baseline_(0.0f),
        is_flex_grow_(is_flex_grow) {}
  int start_;
  int end_;
  float line_cross_size_;
  float remaining_free_space_;    // internal
  float largest_baseline_delta_;  // max(height - baseline)
  float baseline_;
  bool is_flex_grow_;
};

class FlexInfo {
 public:
  friend class LayoutObject;
  FlexInfo(int flex_count)
      : flex_base_size_(flex_count, 0),
        hypothetical_main_size_(flex_count, 0),
        hypothetical_cross_size_(flex_count, 0),
        flex_main_size_(flex_count, 0),
        flex_cross_size_(flex_count, 0),
        apply_stretch_later_(flex_count, false),
        has_item_flex_grow_(0),
        has_item_flex_shrink_(0) {}
  ~FlexInfo();
  void Reset();

  std::vector<float> flex_base_size_;
  std::vector<float> hypothetical_main_size_;
  std::vector<float> hypothetical_cross_size_;

  std::vector<float> flex_main_size_;
  std::vector<float> flex_cross_size_;
  std::vector<bool> apply_stretch_later_;

  std::vector<LineInfo*> line_info_;

  unsigned has_item_flex_grow_ : 1;
  unsigned has_item_flex_shrink_ : 1;
};
}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_LAYOUT_FLEX_INFO_H_
