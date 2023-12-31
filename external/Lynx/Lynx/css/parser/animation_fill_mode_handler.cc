// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/animation_fill_mode_handler.h"

#include <string>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/parser/animation_parser_utils.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {

namespace AnimationFillModeHandler {

using starlight::AnimationFillModeType;

lepus_value ToAnimationFillModeType(const std::string& str,
                                    const CSSParserConfigs& configs) {
  AnimationFillModeType animation_fill_mode_type = AnimationFillModeType::kNone;
  if (str == "none") {
    animation_fill_mode_type = AnimationFillModeType::kNone;
  } else if (str == "forwards") {
    animation_fill_mode_type = AnimationFillModeType::kForwards;
  } else if (str == "backwards") {
    animation_fill_mode_type = AnimationFillModeType::kBackwards;
  } else if (str == "both") {
    animation_fill_mode_type = AnimationFillModeType::kBoth;
  } else {
    UnitHandler::CSSWarning(
        false, configs.enable_css_strict_mode, TYPE_UNSUPPORTED,
        CSSProperty::GetPropertyName(kPropertyIDAnimationFillMode).c_str(),
        str.c_str());
  }
  return lepus::Value(static_cast<int>(animation_fill_mode_type));
}

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDAnimationFillMode).c_str(),
          STRING_TYPE)) {
    return false;
  }
  return AnimationParserUtils::ParserLepusStringToCSSValue(
      key, input, output, configs, &ToAnimationFillModeType,
      CSSValuePattern::ENUM);
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDAnimationFillMode] = &Handle; }

}  // namespace AnimationFillModeHandler
}  // namespace tasm
}  // namespace lynx
