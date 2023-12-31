//  Copyright 2023 The Lynx Authors. All rights reserved.

#include "css/parser/text_stroke_handler.h"

#include <string>
#include <vector>

#include "base/string/string_utils.h"
#include "css/css_color.h"
#include "css/parser/color_handler.h"
#include "css/unit_handler.h"
#include "css_string_parser.h"
#include "starlight/style/css_style_utils.h"

namespace lynx {
namespace tasm {
namespace TextStrokeHandler {
HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDTextStroke).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto& str = input.String()->str();
  std::vector<std::string> text_stroke_props;
  base::SplitStringBySpaceOutOfBrackets(str, text_stroke_props);
  CSSValue color;
  for (const auto& prop : text_stroke_props) {
    if (ColorHandler::Process(lepus::Value(prop), color)) {
      output[kPropertyIDTextStrokeColor] = color;
    } else {
      UnitHandler::Process(kPropertyIDTextStrokeWidth,
                           lepus::Value(prop.c_str()), output, configs);
    }
  }
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDTextStroke] = &Handle; }
}  // namespace TextStrokeHandler
}  // namespace tasm
}  // namespace lynx
