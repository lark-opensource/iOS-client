// Copyright 2021 The Lynx Authors. All rights reserved.
#include "css/parser/cursor_handler.h"

#include "base/debug/lynx_assert.h"
#include "css/parser/css_string_parser.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace CursorHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDCursor).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  CSSStringParser parser(str.c_str(), static_cast<int>(str.size()), configs);
  output[key] = parser.ParseCursor();
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDCursor] = &Handle; }

}  // namespace CursorHandler
}  // namespace tasm
}  // namespace lynx
