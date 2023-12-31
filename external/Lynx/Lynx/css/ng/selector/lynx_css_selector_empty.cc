// Copyright 2022 The Lynx Authors. All rights reserved.

#include <memory>

#include "css/ng/selector/lynx_css_selector.h"
#include "css/ng/selector/lynx_css_selector_list.h"

namespace lynx {
namespace css {

void LynxCSSSelector::UpdatePseudoType(PseudoType pseudo_type) {}

unsigned LynxCSSSelector::CalcSpecificity() const { return 0; }

unsigned LynxCSSSelector::CalcSpecificityForSimple() const { return 0; }

}  // namespace css
}  // namespace lynx
