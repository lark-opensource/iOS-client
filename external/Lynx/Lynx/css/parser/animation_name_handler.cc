// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/animation_name_handler.h"

#include <string>

#include "base/debug/lynx_assert.h"
#include "css/parser/animation_parser_utils.h"
#include "css/unit_handler.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace tasm {

namespace AnimationNameHandler {

lepus_value ToAnimationNameType(const std::string& str,
                                const CSSParserConfigs& configs) {
  return lepus::Value(str.c_str());
}

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDAnimationName).c_str(),
          STRING_TYPE)) {
    return false;
  }
  return AnimationParserUtils::ParserLepusStringToCSSValue(
      key, input, output, configs, &ToAnimationNameType,
      CSSValuePattern::STRING);
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDAnimationName] = &Handle; }

}  // namespace AnimationNameHandler

}  // namespace tasm
}  // namespace lynx
