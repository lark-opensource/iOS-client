// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/flex_flow_handler.h"

#include <string>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace FlexFlowHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDFlexFlow).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  std::vector<std::string> styles;
  base::SplitString(str, ' ', styles);
  char first_char = styles[0][0];

  if (styles.size() == 1) {
    StyleMap css_values;
    if (first_char == 'r' || first_char == 'c') {
      tasm::UnitHandler::Process(tasm::kPropertyIDFlexDirection,
                                 lepus::Value(styles[0].c_str()), css_values,
                                 configs);
      return true;
    } else if (first_char == 'w' || first_char == 'n') {
      tasm::UnitHandler::Process(tasm::kPropertyIDFlexWrap,
                                 lepus::Value(styles[0].c_str()), css_values,
                                 configs);
      return true;
    } else {
      return false;
    }
  }
  std::string &direction_value = styles[0], wrap_value = styles[1];
  if (first_char == 'r' || first_char == 'c') {
    // do nothing
  } else if (first_char == 'w' || first_char == 'n') {
    direction_value = styles[1];
    wrap_value = styles[0];
  } else {
    return false;
  }
  tasm::UnitHandler::Process(tasm::kPropertyIDFlexDirection,
                             lepus::Value(direction_value.c_str()), output,
                             configs);
  tasm::UnitHandler::Process(tasm::kPropertyIDFlexWrap,
                             lepus::Value(wrap_value.c_str()), output, configs);
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDFlexFlow] = &Handle; }

}  // namespace FlexFlowHandler
}  // namespace tasm
}  // namespace lynx
