// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/line_shorthand_handler.h"

#include <string>
#include <vector>

#include "base/string/string_utils.h"
#include "css/parser/border_style_handler.h"
#include "css/unit_handler.h"
#include "starlight/style/css_style_utils.h"

namespace lynx {
namespace tasm {
namespace LineShorthandHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDBorder).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  std::vector<std::string> border_props;
  base::SplitStringBySpaceOutOfBrackets(str, border_props);
  starlight::BorderStyleType style;
  CSSPropertyID width_id = kPropertyIDBorderTopWidth;
  CSSPropertyID style_id = kPropertyIDBorderTopStyle;
  CSSPropertyID color_id = kPropertyIDBorderTopColor;
  switch (key) {
    case kPropertyIDBorderTop:
      break;
    case kPropertyIDBorderRight:
      width_id = kPropertyIDBorderRightWidth;
      style_id = kPropertyIDBorderRightStyle;
      color_id = kPropertyIDBorderRightColor;
      break;
    case kPropertyIDBorderBottom:
      width_id = kPropertyIDBorderBottomWidth;
      style_id = kPropertyIDBorderBottomStyle;
      color_id = kPropertyIDBorderBottomColor;
      break;
    case kPropertyIDBorderLeft:
      width_id = kPropertyIDBorderLeftWidth;
      style_id = kPropertyIDBorderLeftStyle;
      color_id = kPropertyIDBorderLeftColor;
      break;
    case kPropertyIDOutline:
      width_id = kPropertyIDOutlineWidth;
      style_id = kPropertyIDOutlineStyle;
      color_id = kPropertyIDOutlineColor;
      break;
    default:
      UnitHandler::CSSUnreachable(configs.enable_css_strict_mode,
                                  "BorderCombineInterceptor id unreachable!");
      break;
  }

  for (const auto& prop : border_props) {
    if (starlight::CSSStyleUtils::IsBorderLengthLegal(prop)) {
      UnitHandler::Process(width_id, lepus::Value(prop.c_str()), output,
                           configs);
    } else if (BorderStyleHandler::ToBorderStyleType(prop, style)) {
      UnitHandler::Process(style_id, lepus::Value(prop.c_str()), output,
                           configs);
    } else {
      UnitHandler::Process(color_id, lepus::Value(prop.c_str()), output,
                           configs);
    }
  }
  return true;
}

HANDLER_REGISTER_IMPL() {
  array[kPropertyIDBorderTop] = &Handle;
  array[kPropertyIDBorderRight] = &Handle;
  array[kPropertyIDBorderBottom] = &Handle;
  array[kPropertyIDBorderLeft] = &Handle;
  array[kPropertyIDOutline] = &Handle;
}

}  // namespace LineShorthandHandler
}  // namespace tasm
}  // namespace lynx
