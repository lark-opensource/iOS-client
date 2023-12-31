// Copyright 2021 The Lynx Authors. All rights reserved.

#include "css/parser/mask_image_handler.h"

#include "base/debug/lynx_assert.h"
#include "css/parser/css_string_parser.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace MaskImageHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDMaskImage).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  CSSStringParser parser(str.c_str(), static_cast<int>(str.size()), configs);
  output[key] = parser.ParseGradient();
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDMaskImage] = &Handle; }

}  // namespace MaskImageHandler
}  // namespace tasm
}  // namespace lynx
