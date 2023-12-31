// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/animation_direction_handler.h"

#include <string>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/parser/animation_parser_utils.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace AnimationDirectionHandler {

using starlight::AnimationDirectionType;

lepus_value ToAnimationDirectionType(const std::string& str,
                                     const CSSParserConfigs& configs) {
  AnimationDirectionType animation_direction_type =
      AnimationDirectionType::kNormal;
  if (str == "normal") {
    animation_direction_type = AnimationDirectionType::kNormal;
  } else if (str == "reverse") {
    animation_direction_type = AnimationDirectionType::kReverse;
  } else if (str == "alternate") {
    animation_direction_type = AnimationDirectionType::kAlternate;
  } else if (str == "alternate-reverse") {
    animation_direction_type = AnimationDirectionType::kAlternateReverse;
  } else {
    UnitHandler::CSSWarning(
        false, configs.enable_css_strict_mode, TYPE_UNSUPPORTED,
        CSSProperty::GetPropertyName(kPropertyIDAnimationDirection).c_str(),
        str.c_str());
  }
  return lepus::Value(static_cast<int>(animation_direction_type));
}

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDAnimationDirection).c_str(),
          STRING_TYPE)) {
    return false;
  }
  return AnimationParserUtils::ParserLepusStringToCSSValue(
      key, input, output, configs, &ToAnimationDirectionType,
      CSSValuePattern::ENUM);
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDAnimationDirection] = &Handle; }

}  // namespace AnimationDirectionHandler

}  // namespace tasm
}  // namespace lynx
