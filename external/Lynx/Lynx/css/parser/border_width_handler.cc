// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/border_width_handler.h"

#include "base/debug/lynx_assert.h"
#include "css/parser/length_handler.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace BorderWidthHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString() || input.IsNumber(), configs.enable_css_strict_mode,
          TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDBorderWidth).c_str(),
          STRING_OR_NUMBER_TYPE)) {
    return false;
  }
  lepus::Value maybeValue = input;
  if (input.Type() == lepus::Value_String) {
    auto str = input.String()->str();
    if (str == "thin") {
      maybeValue = lepus::Value(lepus::StringImpl::Create("1px"));
    } else if (str == "medium") {
      maybeValue = lepus::Value(lepus::StringImpl::Create("3px"));
    } else if (str == "thick") {
      maybeValue = lepus::Value(lepus::StringImpl::Create("5px"));
    }
  }
  return LengthHandler::Handle(key, maybeValue, output, configs);
}

HANDLER_REGISTER_IMPL() {
  // AUTO INSERT, DON'T CHANGE IT!
  array[kPropertyIDBorderLeftWidth] = &Handle;
  array[kPropertyIDBorderRightWidth] = &Handle;
  array[kPropertyIDBorderTopWidth] = &Handle;
  array[kPropertyIDBorderBottomWidth] = &Handle;
  array[kPropertyIDOutlineWidth] = &Handle;
  array[kPropertyIDBorderInlineStartWidth] = &Handle;
  array[kPropertyIDBorderInlineEndWidth] = &Handle;
  array[kPropertyIDTextStrokeWidth] = &Handle;
  // AUTO INSERT END, DON'T CHANGE IT!
}

}  // namespace BorderWidthHandler
}  // namespace tasm
}  // namespace lynx
