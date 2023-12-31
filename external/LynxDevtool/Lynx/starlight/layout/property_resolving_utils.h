// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_PROPERTY_RESOLVING_UTILS_H_
#define LYNX_STARLIGHT_LAYOUT_PROPERTY_RESOLVING_UTILS_H_

#include <stdio.h>

#include "starlight/types/layout_types.h"
#include "starlight/types/measure_context.h"

namespace lynx {
namespace starlight {
class ComputedCSSStyle;
class BoxInfo;
namespace property_utils {

void HandleBoxSizing(const ComputedCSSStyle& style, const BoxInfo& box_info,
                     DimensionValue<LayoutUnit>& size,
                     const LayoutConfigs& layout_config);

DimensionValue<LayoutUnit> ComputePreferredSize(
    const LayoutObject& item, const Constraints& container_constraint);

void ApplyAspectRatio(const LayoutObject* layout_object, Constraints& size);

Constraints GenerateDefaultConstraints(const LayoutObject& item,
                                       const Constraints& container_constraint);

void ApplyMinMaxToConstraints(Constraints& constraints,
                              const LayoutObject& item);

float StripMargins(float value, const LayoutObject& obj, Dimension dimension);
}  // namespace property_utils

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_LAYOUT_PROPERTY_RESOLVING_UTILS_H_
