// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_DYNAMIC_CSS_CONFIGS_H_
#define LYNX_TASM_REACT_DYNAMIC_CSS_CONFIGS_H_

#include <unordered_set>

#include "css/css_property.h"

namespace lynx {
namespace tasm {

struct DynamicCSSConfigs {
  bool enable_css_inheritance_ = false;
  std::unordered_set<CSSPropertyID> custom_inherit_list_;
  // Hack to keep the old behavior that vw is resolved against screen metrics
  // only for font size if viweport size is specified as definite value.
  bool unify_vw_vh_behavior_ = false;
  bool font_scale_sp_only = false;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_DYNAMIC_CSS_CONFIGS_H_
