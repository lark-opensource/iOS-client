// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/animation_play_state_handler.h"

#include <string>

#include "base/debug/lynx_assert.h"
#include "css/parser/animation_parser_utils.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace AnimationPlayStateHandler {

using starlight::AnimationPlayStateType;

lepus_value ToAnimationPlayStateType(const std::string& str,
                                     const CSSParserConfigs& configs) {
  AnimationPlayStateType animation_play_state_type =
      AnimationPlayStateType::kRunning;
  if (str == "paused") {
    animation_play_state_type = AnimationPlayStateType::kPaused;
  } else if (str == "running") {
    animation_play_state_type = AnimationPlayStateType::kRunning;
  } else {
    UnitHandler::CSSWarning(
        false, configs.enable_css_strict_mode, TYPE_UNSUPPORTED,
        CSSProperty::GetPropertyName(kPropertyIDAnimationPlayState).c_str(),
        str.c_str());
  }
  return lepus::Value(static_cast<int>(animation_play_state_type));
}

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDAnimationPlayState).c_str(),
          STRING_TYPE)) {
    return false;
  }
  return AnimationParserUtils::ParserLepusStringToCSSValue(
      key, input, output, configs, &ToAnimationPlayStateType,
      CSSValuePattern::ENUM);
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDAnimationPlayState] = &Handle; }

}  // namespace AnimationPlayStateHandler

}  // namespace tasm
}  // namespace lynx
