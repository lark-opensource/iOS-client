// Copyright 2021 The Lynx Authors. All rights reserved.

#include "starlight/layout/grid_item_info.h"

#include <utility>

#include "starlight/layout/layout_object.h"

namespace lynx {
namespace starlight {

GridItemInfo::GridItemInfo(LayoutObject* item) : item_(item) {}

GridItemInfo::~GridItemInfo() = default;

void GridItemInfo::InitSpanInfo(Dimension dimension, int32_t explicit_end,
                                int32_t axis_offset) {
  const auto* style = Item()->GetCSSStyle();

  int32_t start = dimension == kHorizontal ? style->GetGridColumnStart()
                                           : style->GetGridRowStart();
  int32_t end = dimension == kHorizontal ? style->GetGridColumnEnd()
                                         : style->GetGridRowEnd();
  int32_t span = dimension == kHorizontal ? style->GetGridColumnSpan()
                                          : style->GetGridRowSpan();
  // If a negative integer is given, starting from the end edge of the explicit
  // grid.
  start = start < 0 ? start + explicit_end : start;
  end = end < 0 ? end + explicit_end : end;

  // Move base line,make ever axis is positive integer.
  if (start != kGridLineUnDefine) {
    start += axis_offset;
  }
  if (end != kGridLineUnDefine) {
    end += axis_offset;
  }

  if (start != kGridLineUnDefine && end == kGridLineUnDefine) {
    end = start + span;
  }
  if (end != kGridLineUnDefine && start == kGridLineUnDefine) {
    start = end - span;
  }

  if (start > end) {
    std::swap(start, end);
  }

  if (start != kGridLineUnDefine && end != kGridLineUnDefine) {
    span = end - start;
  }

  SetSpanPosition(dimension, start, end);
  SetSpanSize(dimension, span);
}

void GridItemInfo::SetSpanPosition(Dimension dimension, int32_t start,
                                   int32_t end) {
  if (dimension == kHorizontal) {
    start_column_ = start;
    end_column_ = end;
  } else {
    start_row_ = start;
    end_row_ = end;
  }
}

void GridItemInfo::SetSpanSize(Dimension dimension, int32_t span) {
  if (dimension == kHorizontal) {
    column_span_size_ = span;
  } else {
    row_span_size_ = span;
  }
}

}  // namespace starlight
}  // namespace lynx
