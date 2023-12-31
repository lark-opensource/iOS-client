// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/vertical_align_handler.h"

#include "base/debug/lynx_assert.h"
#include "css/parser/length_handler.h"
#include "css/unit_handler.h"
#include "lepus/array.h"

namespace lynx {
namespace tasm {
namespace VerticalAlignHandler {

using starlight::VerticalAlignType;

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDVerticalAlign).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  auto array = lepus::CArray::Create();
  VerticalAlignType vertical_align_type = VerticalAlignType::kDefault;
  tasm::CSSValue css_value;
  if (str == "baseline") {
    vertical_align_type = VerticalAlignType::kBaseline;
  } else if (str == "sub") {
    vertical_align_type = VerticalAlignType::kSub;
  } else if (str == "super") {
    vertical_align_type = VerticalAlignType::kSuper;
  } else if (str == "top") {
    vertical_align_type = VerticalAlignType::kTop;
  } else if (str == "text-top") {
    vertical_align_type = VerticalAlignType::kTextTop;
  } else if (str == "middle") {
    vertical_align_type = VerticalAlignType::kMiddle;
  } else if (str == "bottom") {
    vertical_align_type = VerticalAlignType::kBottom;
  } else if (str == "text-bottom") {
    vertical_align_type = VerticalAlignType::kTextBottom;
  } else if (str == "center") {
    vertical_align_type = VerticalAlignType::kCenter;
  } else {
    lepus::Value lepus_value =
        lepus::Value(lepus::StringImpl::Create(str.c_str()));
    if (!lynx::tasm::LengthHandler::Process(lepus_value, css_value, configs)) {
      return false;
    }
    if (str[str.length() - 1] == '%') {
      vertical_align_type = VerticalAlignType::kPercent;
    } else {
      vertical_align_type = VerticalAlignType::kLength;
    }
  }

  array->push_back(lepus::Value(static_cast<int>(vertical_align_type)));
  array->push_back(lepus_value(static_cast<int>(CSSValuePattern::ENUM)));
  array->push_back(css_value.GetValue());
  array->push_back(lepus::Value(static_cast<int32_t>(css_value.GetPattern())));
  output[key] = CSSValue(lepus::Value(array), CSSValuePattern::ARRAY);
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDVerticalAlign] = &Handle; }

}  // namespace VerticalAlignHandler
}  // namespace tasm
}  // namespace lynx
