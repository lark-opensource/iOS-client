// Copyright 2019 The Lynx Authors. All rights reserved.

#include "css/parser/background_shorthand_handler.h"

#include <string>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/parser/css_string_parser.h"
#include "css/unit_handler.h"
#include "lepus/array.h"

namespace lynx {
namespace tasm {
namespace BackgroundShorthandHandler {
using starlight::BackgroundOriginType;
using starlight::BackgroundRepeatType;

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDBackground).c_str(),
          STRING_TYPE)) {
    return false;
  }
  std::string str = input.String()->str();
  CSSStringParser parser{str.c_str(), static_cast<uint32_t>(str.size()),
                         configs};
  parser.SetIsLegacyParser(configs.enable_legacy_parser);
  auto background = parser.ParseBackground().GetValue().Array();
  output[kPropertyIDBackgroundColor] =
      CSSValue(lepus::Value(background->get(0)), CSSValuePattern::NUMBER);
  output[kPropertyIDBackgroundImage] =
      CSSValue(lepus::Value(background->get(1)), CSSValuePattern::ARRAY);
  // FIXME: to make parser and background compatible with old version
  if (background->size() == 7) {
    output[kPropertyIDBackgroundPosition] =
        CSSValue(lepus::Value(background->get(2)), CSSValuePattern::ARRAY);
    output[kPropertyIDBackgroundSize] =
        CSSValue(lepus::Value(background->get(3)), CSSValuePattern::ARRAY);
    output[kPropertyIDBackgroundRepeat] =
        CSSValue(lepus::Value(background->get(4)), CSSValuePattern::ARRAY);
    output[kPropertyIDBackgroundOrigin] =
        CSSValue(lepus::Value(background->get(5)), CSSValuePattern::ARRAY);
    output[kPropertyIDBackgroundClip] =
        CSSValue(lepus::Value(background->get(6)), CSSValuePattern::ARRAY);
  }
  return true;
}
HANDLER_REGISTER_IMPL() { array[kPropertyIDBackground] = &Handle; }
}  // namespace BackgroundShorthandHandler
}  // namespace tasm
}  // namespace lynx
