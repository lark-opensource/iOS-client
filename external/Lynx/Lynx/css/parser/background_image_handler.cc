// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/background_image_handler.h"

#include "base/debug/lynx_assert.h"
#include "css/parser/css_string_parser.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace BackgroundImageHandler {

using starlight::BackgroundImageType;

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDBackgroundImage).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  CSSStringParser parser(str.c_str(), static_cast<int>(str.size()), configs);
  output[key] = parser.ParseBackgroundImage();
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDBackgroundImage] = &Handle; }

}  // namespace BackgroundImageHandler
}  // namespace tasm
}  // namespace lynx
