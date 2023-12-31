// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_POSITION_LAYOUT_UTILS_H_
#define LYNX_STARLIGHT_LAYOUT_POSITION_LAYOUT_UTILS_H_

#include <array>

#include "starlight/layout/box_info.h"
#include "starlight/layout/layout_global.h"
#include "starlight/types/layout_directions.h"
#include "starlight/types/layout_types.h"

namespace lynx {
namespace starlight {
class LayoutObject;

namespace position_utils {

void CalcRelativePosition(LayoutObject* item,
                          const Constraints& content_constraints);

void CalcAbsoluteOrFixedPosition(
    LayoutObject* absolute_or_fixed_item, LayoutObject* container,
    const Constraints& container_constraints,
    BoxPositions absolute_or_fixed_item_initial_position,
    std::array<Direction, 2> directions);

Constraints GetAbsoluteOrFixedItemSizeAndMode(
    LayoutObject* absolute_or_fixed_item, LayoutObject* container,
    const Constraints& content_constraints);

void UpdateStickyItemPosition(LayoutObject* sticky_item, float screen_width,
                              const Constraints& content_constraints);

Position ReversePosition(Position pos);

}  // namespace position_utils
}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_LAYOUT_POSITION_LAYOUT_UTILS_H_
