// Copyright 2019 The Lynx Authors. All rights reserved.

#include "css/parser/bool_handler.h"

#include "base/debug/lynx_assert.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace BoolHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(input.IsString() || input.IsBool(),
                               configs.enable_css_strict_mode, TYPE_MUST_BE,
                               BOOL_TYPE, STRING_OR_BOOL_TYPE)) {
    return false;
  }
  bool ret = false;
  if (input.IsBool()) {
    ret = input.Bool();
  } else if (input.IsString()) {
    auto& str = input.String()->str();
    if (str == "true" || str == "True" || str == "YES") {
      ret = true;
    } else if (str == "false" || str == "False" || str == "NO") {
      ret = false;
    } else {
      if (!UnitHandler::CSSWarning(
              false, configs.enable_css_strict_mode, FORMAT_ERROR,
              CSSProperty::GetPropertyName(key).c_str(), str.c_str())) {
        return false;
      }
    }
  }
  output[key] = CSSValue(lepus::Value(ret), CSSValuePattern::BOOLEAN);
  return true;
}

HANDLER_REGISTER_IMPL() {
  // AUTO INSERT, DON'T CHANGE IT!
  array[kPropertyIDImplicitAnimation] = &Handle;
  array[kPropertyIDRelativeLayoutOnce] = &Handle;
  // AUTO INSERT END, DON'T CHANGE IT!
}

}  // namespace BoolHandler
}  // namespace tasm
}  // namespace lynx
