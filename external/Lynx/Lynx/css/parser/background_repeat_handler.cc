// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/background_repeat_handler.h"

#include <string>

#include "base/debug/lynx_assert.h"
#include "css/parser/css_string_parser.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace BackgroundRepeatHandler {

using starlight::BackgroundRepeatType;

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDBackgroundRepeat).c_str(),
          STRING_TYPE)) {
    return false;
  }
  std::string str = input.String()->str();
  CSSStringParser parser{str.c_str(), static_cast<uint32_t>(str.size()),
                         configs};
  output[key] = parser.ParseBackgroundRepeat();
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDBackgroundRepeat] = &Handle; }
}  // namespace BackgroundRepeatHandler
}  // namespace tasm
}  // namespace lynx
