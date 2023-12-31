// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/background_size_handler.h"

#include <string>

#include "base/debug/lynx_assert.h"
#include "css/parser/css_string_parser.h"
#include "css/unit_handler.h"
#include "tasm/config.h"

namespace lynx {
namespace tasm {
namespace BackgroundSizeHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDBackgroundSize).c_str(),
          STRING_TYPE)) {
    return false;
  }
  std::string str = input.String()->str();
  CSSStringParser parser{str.c_str(), static_cast<uint32_t>(str.size()),
                         configs};
  parser.SetIsLegacyParser(configs.enable_legacy_parser);
  output[key] = parser.ParseBackgroundSize();
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDBackgroundSize] = &Handle; }

}  // namespace BackgroundSizeHandler
}  // namespace tasm
}  // namespace lynx
