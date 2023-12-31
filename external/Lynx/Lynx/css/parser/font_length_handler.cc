// Copyright 2019 The Lynx Authors. All rights reserved.

#include "css/parser/font_length_handler.h"

#include "base/debug/lynx_assert.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace FontLengthHandler {
static constexpr float UNDEFINED = 10E20;

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(input.IsString() || input.IsNumber(),
                               configs.enable_css_strict_mode, TYPE_MUST_BE,
                               CSSProperty::GetPropertyName(key).c_str(),
                               STRING_OR_NUMBER_TYPE)) {
    return false;
  }
  lepus::Value maybeValue = input;
  if (input.Type() == lepus::Value_String) {
    auto str = input.String()->str();
    if (str == "normal") {
      maybeValue = lepus::Value(lepus::Value(UNDEFINED));
    }
  }
  return LengthHandler::Handle(key, maybeValue, output, configs);
}

HANDLER_REGISTER_IMPL() {
  // AUTO INSERT, DON'T CHANGE IT!
  array[kPropertyIDLineHeight] = &Handle;
  array[kPropertyIDLetterSpacing] = &Handle;
  array[kPropertyIDLineSpacing] = &Handle;
  // AUTO INSERT END, DON'T CHANGE IT!
}
}  // namespace FontLengthHandler
}  // namespace tasm
}  // namespace lynx
