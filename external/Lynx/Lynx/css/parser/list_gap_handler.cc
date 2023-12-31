// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/list_gap_handler.h"

#include "base/debug/lynx_assert.h"
#include "css/parser/length_handler.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace ListGapHandler {

HANDLER_IMPL() {
  CSSValue css_value;
  if (!UnitHandler::CSSWarning(
          LengthHandler::Process(input, css_value, configs),
          configs.enable_css_strict_mode, TYPE_UNSUPPORTED,
          CSSProperty::GetPropertyName(key).c_str(), input.String()->c_str())) {
    return false;
  }

  CSSValuePattern css_value_pattern = css_value.GetPattern();
  if (!(css_value_pattern == CSSValuePattern::PX ||
        css_value_pattern == CSSValuePattern::RPX ||
        css_value_pattern == CSSValuePattern::PPX ||
        css_value_pattern == CSSValuePattern::REM ||
        css_value_pattern == CSSValuePattern::EM)) {
    return false;
  }
  output[key] = css_value;
  return true;
}

HANDLER_REGISTER_IMPL() {
  array[kPropertyIDListCrossAxisGap] = &Handle;
  array[kPropertyIDListMainAxisGap] = &Handle;
}

}  // namespace ListGapHandler
}  // namespace tasm
}  // namespace lynx
