// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_HELPER_INSPECTOR_CSS_HELPER_H_
#define LYNX_INSPECTOR_HELPER_INSPECTOR_CSS_HELPER_H_

#include <string>

#include "css/css_property.h"

namespace lynxdev {
namespace devtool {

class InspectorCSSHelper {
 public:
  static lynx::tasm::CSSPropertyID GetPropertyID(const std::string& name);
  static const std::string& GetPropertyName(lynx::tasm::CSSPropertyID id);

  static const std::string& ToPropsName(lynx::tasm::CSSPropertyID id);
  static bool IsColor(lynx::tasm::CSSPropertyID id);
  static bool IsDimension(lynx::tasm::CSSPropertyID id);
  static bool IsAutoDimension(lynx::tasm::CSSPropertyID id);
  static bool IsStringProp(lynx::tasm::CSSPropertyID id);
  static bool IsIntProp(lynx::tasm::CSSPropertyID id);
  static bool IsFloatProp(lynx::tasm::CSSPropertyID id);
  static bool IsBorderProp(lynx::tasm::CSSPropertyID id);
  static bool IsSupportedProp(lynx::tasm::CSSPropertyID id);

  static bool IsLegal(const std::string& name, const std::string& value);
  static bool IsAnimationLegal(const std::string& name,
                               const std::string& value);
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_HELPER_INSPECTOR_CSS_HELPER_H_
