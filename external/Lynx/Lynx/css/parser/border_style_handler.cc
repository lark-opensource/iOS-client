// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/border_style_handler.h"

#include "base/debug/lynx_assert.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace BorderStyleHandler {

using starlight::BorderStyleType;

bool ToBorderStyleType(const std::string& str, BorderStyleType& result) {
  if (str == "solid") {
    result = BorderStyleType::kSolid;
  } else if (str == "dashed") {
    result = BorderStyleType::kDashed;
  } else if (str == "dotted") {
    result = BorderStyleType::kDotted;
  } else if (str == "double") {
    result = BorderStyleType::kDouble;
  } else if (str == "groove") {
    result = BorderStyleType::kGroove;
  } else if (str == "ridge") {
    result = BorderStyleType::kRidge;
  } else if (str == "inset") {
    result = BorderStyleType::kInset;
  } else if (str == "outset") {
    result = BorderStyleType::kOutset;
  } else if (str == "hidden") {
    result = BorderStyleType::kHide;
  } else if (str == "none") {
    result = BorderStyleType::kNone;
  } else {
    return false;
  }
  return true;
}

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDBorderStyle).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  BorderStyleType type = BorderStyleType::kUndefined;
  if (!ToBorderStyleType(str, type)) {
    if (!UnitHandler::CSSWarning(
            false, configs.enable_css_strict_mode, TYPE_UNSUPPORTED,
            CSSProperty::GetPropertyName(kPropertyIDBorderStyle).c_str(),
            str.c_str())) {
      return false;
    }
  }
  output[key] =
      CSSValue(lepus::Value(static_cast<int>(type)), CSSValuePattern::ENUM);
  return true;
}

HANDLER_REGISTER_IMPL() {
  // AUTO INSERT, DON'T CHANGE IT!
  array[kPropertyIDBorderLeftStyle] = &Handle;
  array[kPropertyIDBorderRightStyle] = &Handle;
  array[kPropertyIDBorderTopStyle] = &Handle;
  array[kPropertyIDBorderBottomStyle] = &Handle;
  array[kPropertyIDOutlineStyle] = &Handle;
  array[kPropertyIDBorderInlineStartStyle] = &Handle;
  array[kPropertyIDBorderInlineEndStyle] = &Handle;
  // AUTO INSERT END, DON'T CHANGE IT!
}

}  // namespace BorderStyleHandler
}  // namespace tasm
}  // namespace lynx
