// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_CSS_VARIABLE_HANDLER_H_
#define LYNX_CSS_CSS_VARIABLE_HANDLER_H_

#include <string>

#include "base/base_export.h"
#include "css/css_property.h"
#include "tasm/attribute_holder.h"

namespace lynx {
namespace tasm {

class CSSVariableHandler {
 public:
  void SetEnableFiberArch(bool fiberArch) { enable_fiber_arch_ = fiberArch; }

  bool HandleCSSVariables(StyleMap& map, AttributeHolder* holder,
                          const CSSParserConfigs& configs);

  BASE_EXPORT_FOR_DEVTOOL std::string FormatStringWithRule(
      const std::string& format, AttributeHolder* holder,
      lepus::String& default_props);

 private:
  static lepus::String FindSuitableProperty(const std::string& key,
                                            AttributeHolder* holder);

  bool enable_fiber_arch_{false};
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_VARIABLE_HANDLER_H_
