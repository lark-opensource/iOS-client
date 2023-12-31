// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/aspect_ratio_handler.h"

#include <string>

#include "base/debug/lynx_assert.h"
#include "base/float_comparison.h"
#include "base/string/string_number_convert.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace AspectRatioHandler {

HANDLER_IMPL() {
  bool enable_strict_mode = configs.enable_css_strict_mode;
  if (!UnitHandler::CSSWarning(input.IsString() || input.IsNumber(),
                               enable_strict_mode, TYPE_MUST_BE,
                               CSSProperty::GetPropertyName(key).c_str(),
                               STRING_OR_NUMBER_TYPE)) {
    return false;
  }
  if (input.IsNumber()) {
    output[key] = CSSValue(input, CSSValuePattern::NUMBER);
    return true;
  } else {
    auto& str = input.String()->str();
    size_t pos = str.find('/');
    if (pos == std::string::npos) {
      float result;
      if (!UnitHandler::CSSWarning(
              base::StringToFloat(str, result, true), enable_strict_mode,
              FORMAT_ERROR,
              CSSProperty::GetPropertyName(kPropertyIDAspectRatio).c_str(),
              str.c_str())) {
        return false;
      }
      output[key] = CSSValue(lepus::Value(result), CSSValuePattern::NUMBER);
      return true;
    } else {
      std::string str1 = str.substr(0, pos);
      std::string str2 = str.substr(pos + 1, str.length() - pos - 1);
      float num1, num2;
      if (!UnitHandler::CSSWarning(
              base::StringToFloat(str1, num1, true), enable_strict_mode,
              FORMAT_ERROR,
              CSSProperty::GetPropertyName(kPropertyIDAspectRatio).c_str(),
              str1.c_str())) {
        return false;
      }
      if (!UnitHandler::CSSWarning(
              base::StringToFloat(str2, num2, true), enable_strict_mode,
              FORMAT_ERROR,
              CSSProperty::GetPropertyName(kPropertyIDAspectRatio).c_str(),
              str1.c_str())) {
        return false;
      }
      if (!UnitHandler::CSSWarning(
              !base::FloatsEqual(num2, 0.0f), enable_strict_mode, FORMAT_ERROR,
              CSSProperty::GetPropertyName(kPropertyIDAspectRatio).c_str(),
              str1.c_str())) {
        return false;
      }
      float result = num1 / num2;
      output[key] = CSSValue(lepus::Value(result), CSSValuePattern::NUMBER);
      return true;
    }
  }
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDAspectRatio] = &Handle; }

}  // namespace AspectRatioHandler

}  // namespace tasm
}  // namespace lynx
