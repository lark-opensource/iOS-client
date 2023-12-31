// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/border_handler.h"

#include <string>
#include <vector>

#include "base/string/string_utils.h"
#include "css/css_color.h"
#include "css/parser/border_style_handler.h"
#include "css/unit_handler.h"
#include "starlight/style/css_style_utils.h"

namespace lynx {
namespace tasm {
namespace BorderHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDBorder).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto& str = input.String()->str();
  std::vector<std::string> border_props;
  base::SplitStringBySpaceOutOfBrackets(str, border_props);
  starlight::BorderStyleType style;
  CSSColor color;
  for (const auto& prop : border_props) {
    if (CSSColor::Parse(prop, color)) {
      UnitHandler::Process(kPropertyIDBorderColor, lepus::Value(prop.c_str()),
                           output, configs);
    } else if (BorderStyleHandler::ToBorderStyleType(prop, style)) {
      UnitHandler::Process(kPropertyIDBorderStyle, lepus::Value(prop.c_str()),
                           output, configs);
    } else {
      UnitHandler::Process(kPropertyIDBorderWidth, lepus::Value(prop.c_str()),
                           output, configs);
    }
  }
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDBorder] = &Handle; }

}  // namespace BorderHandler
}  // namespace tasm
}  // namespace lynx
