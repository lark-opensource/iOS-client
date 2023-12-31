// Copyright 2021 The Lynx Authors. All rights reserved.
#include "css/parser/animation_iteration_count_handler.h"

#include <string>

#include "base/debug/lynx_assert.h"
#include "base/string/string_number_convert.h"
#include "css/parser/animation_parser_utils.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace AnimIterCountHandler {

lepus_value ToAnimIterCountType(const std::string& str,
                                const CSSParserConfigs& configs) {
  double num = 0;
  if (str == "infinite") {
    num = 10E8;
  } else {
    UnitHandler::CSSWarning(
        base::StringToDouble(str, num, true), configs.enable_css_strict_mode,
        TYPE_UNSUPPORTED,
        CSSProperty::GetPropertyName(kPropertyIDAnimationIterationCount)
            .c_str(),
        str.c_str());
  }
  return lepus::Value(num);
}

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDAnimationIterationCount)
              .c_str(),
          STRING_TYPE)) {
    return false;
  }
  return AnimationParserUtils::ParserLepusStringToCSSValue(
      key, input, output, configs, &ToAnimIterCountType,
      CSSValuePattern::NUMBER);
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDAnimationIterationCount] = &Handle; }

}  // namespace AnimIterCountHandler

}  // namespace tasm
}  // namespace lynx
