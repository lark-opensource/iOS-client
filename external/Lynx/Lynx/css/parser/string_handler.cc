// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/string_handler.h"

#include "base/debug/lynx_assert.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace StringHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(input.IsString(), configs.enable_css_strict_mode,
                               "id:%d value must be string.", key)) {
    return false;
  }
  output[key] = CSSValue(input);
  return true;
}

HANDLER_REGISTER_IMPL() {
  // AUTO INSERT, DON'T CHANGE IT!
  array[kPropertyIDFontFamily] = &Handle;
  array[kPropertyIDAdaptFontSize] = &Handle;
  array[kPropertyIDContent] = &Handle;
  array[kPropertyIDCaretColor] = &Handle;
  // AUTO INSERT END, DON'T CHANGE IT!
}

}  // namespace StringHandler
}  // namespace tasm
}  // namespace lynx
