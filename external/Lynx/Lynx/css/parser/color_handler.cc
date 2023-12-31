// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/color_handler.h"

#include <string>

#include "css/css_color.h"
#include "css/parser/css_string_parser.h"
#include "css/unit_handler.h"
#include "starlight/style/css_style_utils.h"

namespace lynx {
namespace tasm {
namespace ColorHandler {

bool Process(const lepus::Value& input, CSSValue& css_value) {
  if (!input.IsString()) {
    return false;
  }

  CSSColor color;
  if (CSSColor::Parse(input.String()->str(), color)) {
    // the color cast will convert RBGA to ARGB value in hex
    css_value.SetValue(lepus::Value(color.Cast()));
    css_value.SetPattern(CSSValuePattern::NUMBER);
    return true;
  }
  return false;
}

HANDLER_IMPL() {
  if (key == kPropertyIDColor) {
    std::string s = input.String()->str();
    CSSStringParser parser{s.c_str(), static_cast<uint32_t>(s.size()), configs};
    output[key] = parser.ParseTextColor();
    return true;
  }
  CSSValue css_value;
  if (!UnitHandler::CSSWarning(Process(input, css_value),
                               configs.enable_css_strict_mode, FORMAT_ERROR,
                               CSSProperty::GetPropertyName(key).c_str(),
                               input.String()->c_str())) {
    return false;
  }
  output[key] = css_value;
  return true;
}

HANDLER_REGISTER_IMPL() {
  // AUTO INSERT, DON'T CHANGE IT!
  array[kPropertyIDBackgroundColor] = &Handle;
  array[kPropertyIDBorderLeftColor] = &Handle;
  array[kPropertyIDBorderRightColor] = &Handle;
  array[kPropertyIDBorderTopColor] = &Handle;
  array[kPropertyIDBorderBottomColor] = &Handle;
  array[kPropertyIDColor] = &Handle;
  array[kPropertyIDOutlineColor] = &Handle;
  array[kPropertyIDTextDecorationColor] = &Handle;
  array[kPropertyIDBorderInlineStartColor] = &Handle;
  array[kPropertyIDBorderInlineEndColor] = &Handle;
  array[kPropertyIDTextStrokeColor] = &Handle;
  // AUTO INSERT END, DON'T CHANGE IT!
}

}  // namespace ColorHandler
}  // namespace tasm
}  // namespace lynx
