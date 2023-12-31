// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/length_handler.h"

#include <string>

#include "base/debug/lynx_assert.h"
#include "base/string/string_number_convert.h"
#include "css/unit_handler.h"
#include "lepus/string_util.h"

namespace lynx {
namespace tasm {
namespace LengthHandler {

void CheckLengthUnitValid(CSSPropertyID key, const lepus::Value& input,
                          const CSSParserConfigs& configs) {
  // TODO，currently the testcases online still doesnt carry units, so that
  // this red box warning message would block CQ test, add the sdk version
  // to turn off the warning until the testcases are fixed.
  if (!configs.enable_length_unit_check) {
    return;
  }
  // line-height: 3 is a valid css value(means the 3 times of font size)
  if (key == CSSPropertyID::kPropertyIDLineHeight) {
    return;
  }
  // judge whether the string is all number
  std::string str = input.String()->c_str();
  std::stringstream sin(str);
  double d;
  char c;
  if (!(sin >> d) || sin >> c) {
    return;
  }
  // number 0 doesnt need to carry any units
  if (str != "0") {
    LynxWarning(false, LYNX_ERROR_CODE_CSS,
                "CSS Property %s of length type with value %s need to carry "
                "units (except 0)",
                CSSProperty::GetPropertyName(key).c_str(), str.c_str());
  }
}

bool Process(const lepus::Value& input, CSSValue& css_value,
             const CSSParserConfigs& configs) {
  if (!(input.IsString() || input.IsNumber())) {
    return false;
  }
  if (input.IsNumber()) {
    css_value.SetValue(input);
    css_value.SetPattern(CSSValuePattern::NUMBER);
    return true;
  }

  std::string str = input.String()->c_str();
  auto length = str.length();
  if (str == "auto") {
    css_value.SetValue(
        lepus::Value(static_cast<int>(starlight::LengthValueType::kAuto)));
    css_value.SetPattern(CSSValuePattern::ENUM);
    return true;
  }
  int unit_len = 0;
  CSSValuePattern pattern;
  if (length > 3 && lepus::EndsWith(str, "rpx")) {
    unit_len = 3;
    pattern = CSSValuePattern::RPX;
  } else if (length > 3 && lepus::EndsWith(str, "ppx")) {
    unit_len = 3;
    pattern = CSSValuePattern::PPX;
  } else if (length > 2 && lepus::EndsWith(str, "px")) {
    unit_len = 2;
    pattern = CSSValuePattern::PX;
  } else if ((length > 3 && lepus::EndsWith(str, "rem"))) {
    unit_len = 3;
    pattern = CSSValuePattern::REM;
  } else if (length > 2 && lepus::EndsWith(str, "em")) {
    unit_len = 2;
    pattern = CSSValuePattern::EM;
  } else if (length > 2 && lepus::EndsWith(str, "vw")) {
    unit_len = 2;
    pattern = CSSValuePattern::VW;
  } else if (length > 2 && lepus::EndsWith(str, "vh")) {
    unit_len = 2;
    pattern = CSSValuePattern::VH;
  } else if (length > 1 && lepus::EndsWith(str, "%")) {
    unit_len = 1;
    pattern = CSSValuePattern::PERCENT;
  } else if (length > 6 && lepus::BeginsWith(str, "calc(") &&
             lepus::EndsWith(str, ")")) {
    pattern = CSSValuePattern::CALC;
  } else if (length > 5 && lepus::BeginsWith(str, "env(") &&
             lepus::EndsWith(str, ")")) {
    pattern = CSSValuePattern::ENV;
  } else if (str == "max-content" || lepus::BeginsWith(str, "fit-content")) {
    pattern = CSSValuePattern::INTRINSIC;
  } else if (length > 2 && lepus::EndsWith(str, "sp")) {
    unit_len = 2;
    pattern = CSSValuePattern::SP;
  } else {
    unit_len = 0;
    pattern = CSSValuePattern::NUMBER;
  }

  if (pattern == CSSValuePattern::CALC || pattern == CSSValuePattern::ENV ||
      pattern == CSSValuePattern::INTRINSIC) {
    css_value.SetValue(lepus::Value(lepus::StringImpl::Create(str.c_str())));
    css_value.SetPattern(pattern);
    return true;
  } else {
    double dest = 0;
    std::string value_str = str.substr(0, str.length() - unit_len);
    bool ret = base::StringToDouble(value_str, dest, true);
    // As the FE developer's wish, red screen won't show if no value exists
    // before unit. Only show a red screen when the value is Inf or NaN.

    bool is_normal_number = !(std::isnan(dest) || std::isinf(dest));
    UnitHandler::CSSWarning(is_normal_number, configs.enable_css_strict_mode,
                            "invalid length: %s", str.c_str());

    if (pattern != CSSValuePattern::NUMBER && is_normal_number) {
      // To be compatable with legacy version pages, an invalid value with a
      // valid suffix should be treated as 0 but not an invalid value.
      ret = true;
    }

    if (ret) {
      css_value.SetValue(lepus::Value(dest));
      css_value.SetPattern(pattern);
    }
    return ret;
  }
}

HANDLER_IMPL() {
  CSSValue css_value;
  CheckLengthUnitValid(key, input, configs);
  if (!UnitHandler::CSSWarning(Process(input, css_value, configs),
                               configs.enable_css_strict_mode, TYPE_UNSUPPORTED,
                               CSSProperty::GetPropertyName(key).c_str(),
                               input.String()->c_str())) {
    return false;
  }
  output[key] = css_value;
  return true;
}
HANDLER_REGISTER_IMPL() {
  // AUTO INSERT, DON'T CHANGE IT!
  array[kPropertyIDTop] = &Handle;
  array[kPropertyIDLeft] = &Handle;
  array[kPropertyIDRight] = &Handle;
  array[kPropertyIDBottom] = &Handle;
  array[kPropertyIDHeight] = &Handle;
  array[kPropertyIDWidth] = &Handle;
  array[kPropertyIDMaxWidth] = &Handle;
  array[kPropertyIDMinWidth] = &Handle;
  array[kPropertyIDMaxHeight] = &Handle;
  array[kPropertyIDMinHeight] = &Handle;
  array[kPropertyIDPaddingLeft] = &Handle;
  array[kPropertyIDPaddingRight] = &Handle;
  array[kPropertyIDPaddingTop] = &Handle;
  array[kPropertyIDPaddingBottom] = &Handle;
  array[kPropertyIDMarginLeft] = &Handle;
  array[kPropertyIDMarginRight] = &Handle;
  array[kPropertyIDMarginTop] = &Handle;
  array[kPropertyIDMarginBottom] = &Handle;
  array[kPropertyIDFontSize] = &Handle;
  array[kPropertyIDFlexBasis] = &Handle;
  array[kPropertyIDMarginInlineStart] = &Handle;
  array[kPropertyIDMarginInlineEnd] = &Handle;
  array[kPropertyIDPaddingInlineStart] = &Handle;
  array[kPropertyIDPaddingInlineEnd] = &Handle;
  array[kPropertyIDInsetInlineStart] = &Handle;
  array[kPropertyIDInsetInlineEnd] = &Handle;
  array[kPropertyIDGridColumnGap] = &Handle;
  array[kPropertyIDGridRowGap] = &Handle;
  array[kPropertyIDPerspective] = &Handle;
  array[kPropertyIDTextIndent] = &Handle;
  // AUTO INSERT END, DON'T CHANGE IT!
}

}  // namespace LengthHandler
}  // namespace tasm
}  // namespace lynx
