// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/text_decoration_handler.h"

#include <string>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/unit_handler.h"
#include "css_string_parser.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace tasm {
namespace TextDecorationHandler {

using starlight::TextDecorationType;

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDTextDecoration).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  CSSStringParser parser(str.c_str(), static_cast<int>(str.size()), configs);
  output[key] = parser.ParseTextDecoration();
  if (output[key].IsEmpty()) {
    return false;
  }
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDTextDecoration] = &Handle; }

}  // namespace TextDecorationHandler
}  // namespace tasm
}  // namespace lynx
