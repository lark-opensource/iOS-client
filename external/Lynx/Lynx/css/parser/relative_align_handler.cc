// Copyright 2021 The Lynx Authors. All rights reserved.

#include "css/parser/relative_align_handler.h"

#include "base/debug/lynx_assert.h"
#include "base/string/string_number_convert.h"
#include "css/unit_handler.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace tasm {

namespace {
static constexpr char kRelativeAlignErrorMessage[] =
    "Value of %s must be \"parent\" or a positive number";
}

namespace RelativeAlignHandler {

HANDLER_IMPL() {
  int result = starlight::RelativeAlignType::kNone;

  if (input.IsString()) {
    if (input.String()->str() == "parent") {
      result = starlight::RelativeAlignType::kParent;
    } else {
      if (!UnitHandler::CSSWarning(
              base::StringToInt(input.String()->c_str(), &result, 10),
              configs.enable_css_strict_mode, kRelativeAlignErrorMessage,
              CSSProperty::GetPropertyName(key).c_str())) {
        return false;
      }
    }
  } else if (input.IsNumber()) {
    int number = input.Number();
    if (!UnitHandler::CSSWarning(number > 0, configs.enable_css_strict_mode,
                                 kRelativeAlignErrorMessage,
                                 CSSProperty::GetPropertyName(key).c_str())) {
      return false;
    }
    result = number;
  }
  output[key] = CSSValue(lepus::Value(result), CSSValuePattern::NUMBER);
  return true;
}

HANDLER_REGISTER_IMPL() {
  array[kPropertyIDRelativeAlignTop] = &Handle;
  array[kPropertyIDRelativeAlignBottom] = &Handle;
  array[kPropertyIDRelativeAlignLeft] = &Handle;
  array[kPropertyIDRelativeAlignRight] = &Handle;
  array[kPropertyIDRelativeAlignInlineStart] = &Handle;
  array[kPropertyIDRelativeAlignInlineEnd] = &Handle;
}

}  // namespace RelativeAlignHandler
}  // namespace tasm
}  // namespace lynx
