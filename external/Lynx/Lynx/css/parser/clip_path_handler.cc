// Copyright 2023. The Lynx Authors. All rights reserved.

#include "clip_path_handler.h"

#include <string>

#include "css/unit_handler.h"
#include "css_string_parser.h"

namespace lynx {
namespace tasm {
namespace ClipPathHandler {
HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDClipPath).c_str(),
          STRING_TYPE)) {
    return false;
  }
  const char* str = input.String()->c_str();
  CSSStringParser parser{str, static_cast<uint32_t>(strlen(str)), configs};
  lepus::Value result = parser.ParseClipPath();
  if (!UnitHandler::CSSWarning(
          result.IsArray(), configs.enable_css_strict_mode,
          "clip path format error or function not implemented.")) {
    return false;
  }
  output[key] = CSSValue(result, CSSValuePattern::ARRAY);
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDClipPath] = &Handle; }
}  // namespace ClipPathHandler
}  // namespace tasm
}  // namespace lynx
