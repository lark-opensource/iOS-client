// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/number_handler.h"

#include "base/debug/lynx_assert.h"
#include "base/string/string_number_convert.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace NumberHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(input.IsString() || input.IsNumber(),
                               configs.enable_css_strict_mode, TYPE_MUST_BE,
                               FLOAT_TYPE, STRING_OR_NUMBER_TYPE)) {
    return false;
  }
  double num = 0;
  if (input.IsNumber()) {
    num = input.Number();
  } else {
    auto& str = input.String()->str();
    if (str == "infinite") {
      num = 10E8;
    } else {
      if (!UnitHandler::CSSWarning(
              base::StringToDouble(str, num, true),
              configs.enable_css_strict_mode, TYPE_UNSUPPORTED,
              CSSProperty::GetPropertyName(key).c_str(), str.c_str())) {
        return false;
      }
    }
  }
  output[key] = CSSValue(lepus::Value(num), CSSValuePattern::NUMBER);
  return true;
}

HANDLER_REGISTER_IMPL() {
  // AUTO INSERT, DON'T CHANGE IT!
  array[kPropertyIDOpacity] = &Handle;
  array[kPropertyIDFlexGrow] = &Handle;
  array[kPropertyIDFlexShrink] = &Handle;
  array[kPropertyIDOrder] = &Handle;
  array[kPropertyIDLinearWeightSum] = &Handle;
  array[kPropertyIDLinearWeight] = &Handle;
  array[kPropertyIDRelativeId] = &Handle;
  array[kPropertyIDRelativeTopOf] = &Handle;
  array[kPropertyIDRelativeRightOf] = &Handle;
  array[kPropertyIDRelativeBottomOf] = &Handle;
  array[kPropertyIDRelativeLeftOf] = &Handle;
  array[kPropertyIDZIndex] = &Handle;
  array[kPropertyIDRelativeInlineStartOf] = &Handle;
  array[kPropertyIDRelativeInlineEndOf] = &Handle;
  array[kPropertyIDGridColumnSpan] = &Handle;
  array[kPropertyIDGridRowSpan] = &Handle;
  // AUTO INSERT END, DON'T CHANGE IT!
}

}  // namespace NumberHandler
}  // namespace tasm
}  // namespace lynx
