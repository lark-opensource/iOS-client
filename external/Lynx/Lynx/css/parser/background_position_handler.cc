// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/background_position_handler.h"

#include <string>

#include "base/debug/lynx_assert.h"
#include "css/parser/css_string_parser.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace BackgroundPositionHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDBackgroundPosition).c_str(),
          STRING_TYPE)) {
    return false;
  }
  std::string str = input.String()->str();
  CSSStringParser parser{str.c_str(), static_cast<uint32_t>(str.size()),
                         configs};
  output[key] = parser.ParseBackgroundPosition();
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDBackgroundPosition] = &Handle; }

}  // namespace BackgroundPositionHandler
}  // namespace tasm
}  // namespace lynx
