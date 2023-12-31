// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_GRID_ITEM_INFO_H_
#define LYNX_STARLIGHT_LAYOUT_GRID_ITEM_INFO_H_

#include "starlight/types/layout_constraints.h"
#include "starlight/types/layout_directions.h"

namespace lynx {
namespace starlight {

constexpr int32_t kGridLineStart = 1;
constexpr int32_t kGridLineUnDefine = 0;

class LayoutObject;
class GridItemInfo {
 public:
  GridItemInfo(LayoutObject* item);
  ~GridItemInfo();

  LayoutObject* Item() const { return item_; }

  // parm: explicit_end is the end of explicit grid.
  // parm: axis_offset is the offset of base line, it make all grid line to
  // positive integer.
  void InitSpanInfo(Dimension dimension, int32_t explicit_end,
                    int32_t axis_offset);
  void SetSpanPosition(Dimension dimension, int32_t start, int32_t end);
  void SetSpanSize(Dimension dimension, int32_t span);

  bool IsRowAxisUnDefine() const {
    return start_row_ == kGridLineUnDefine || end_row_ == kGridLineUnDefine;
  }
  bool IsColumnAxisUnDefine() const {
    return start_column_ == kGridLineUnDefine ||
           end_column_ == kGridLineUnDefine;
  }
  bool IsNoneAxisAuto() const {
    return !IsRowAxisUnDefine() && !IsColumnAxisUnDefine();
  }
  bool IsBothAxisAuto() const {
    return IsRowAxisUnDefine() && IsColumnAxisUnDefine();
  }
  bool IsAxisAuto(Dimension dimension) const {
    return dimension == kHorizontal ? IsColumnAxisUnDefine()
                                    : IsRowAxisUnDefine();
  }

  int32_t SpanSize(Dimension dimension) const {
    return dimension == kHorizontal ? column_span_size_ : row_span_size_;
  }
  int32_t StartLine(Dimension dimension) const {
    return dimension == kHorizontal ? start_column_ : start_row_;
  }
  int32_t EndLine(Dimension dimension) const {
    return dimension == kHorizontal ? end_column_ : end_row_;
  }

  const Constraints& ContainerConstraints() const {
    return container_constraints_;
  }
  void SetContainerConstraints(Dimension dimension,
                               const OneSideConstraint& one_side) {
    container_constraints_[dimension] = one_side;
  }

 private:
  Constraints container_constraints_;

  // item position
  int32_t start_row_ = kGridLineUnDefine;
  int32_t start_column_ = kGridLineUnDefine;
  int32_t end_row_ = kGridLineUnDefine;
  int32_t end_column_ = kGridLineUnDefine;

  // item span
  int32_t row_span_size_ = 0;
  int32_t column_span_size_ = 0;

  LayoutObject* item_;
};

// For item span size sort
struct ItemInfoEntry {
  GridItemInfo* item_info;
  FloatSize layout_size;

  int32_t SpanSize(Dimension dimension) const {
    return item_info->SpanSize(dimension);
  }
  float LayoutSize(Dimension dimension) const {
    return dimension == kHorizontal ? layout_size.width_ : layout_size.height_;
  }
};
}  // namespace starlight
}  // namespace lynx
#endif  // LYNX_STARLIGHT_LAYOUT_GRID_ITEM_INFO_H_
