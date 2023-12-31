// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_DYNAMIC_DIRECTION_STYLES_MANAGER_H_
#define LYNX_TASM_REACT_DYNAMIC_DIRECTION_STYLES_MANAGER_H_

#include <map>
#include <utility>

#include "css/css_property.h"
#include "css/css_value.h"
#include "starlight/style/computed_css_style.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace tasm {
using CSSStyleValue = std::pair<CSSPropertyID, CSSValue>;
using IsLogic = bool;
bool IsDirectionAwareStyle(CSSPropertyID css_id);

bool IsLogicalDirectionStyle(CSSPropertyID css_id);

CSSPropertyID ResolveDirectionAwareProperty(CSSPropertyID css_id,
                                            starlight::DirectionType direction);
CSSStyleValue ResolveTextAlign(CSSPropertyID css_id,
                               const tasm::CSSValue& value,
                               starlight::DirectionType direction);

std::pair<CSSPropertyID, IsLogic> ResolveLogicStyleID(CSSPropertyID css_id);
CSSPropertyID ResolveDirectionRelatedStyleID(CSSPropertyID trans_id,
                                             starlight::DirectionType direction,
                                             bool is_logic_style);
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_DYNAMIC_DIRECTION_STYLES_MANAGER_H_
