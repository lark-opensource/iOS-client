// Copyright 2021 The Lynx Authors. All rights reserved.

#include "css/parser/filter_handler.h"

#include <scoped_allocator>
#include <string>

#include "base/debug/lynx_assert.h"
#include "css/parser/css_string_parser.h"
#include "css/unit_handler.h"
#include "length_handler.h"
#include "lepus/array.h"

namespace lynx {
namespace tasm {
namespace FilterHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDFilter).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  auto arr = lepus::CArray::Create();
  double value = -1;
  auto start = str.find("(");
  auto end = str.rfind(")");
  if (start == str.npos || end == str.npos || start >= end || start == 0) {
    if (!UnitHandler::CSSWarning(
            false, configs.enable_css_strict_mode, FORMAT_ERROR,
            CSSProperty::GetPropertyName(kPropertyIDFilter).c_str(),
            str.c_str())) {
      return false;
    }
  }
  std::string function_name = str.substr(0, start);
  std::string param = str.substr(start + 1, end - start - 1);

  starlight::FilterType function_type = starlight::FilterType::kNone;

  if (function_name == "grayscale") {
    function_type = starlight::FilterType::kGrayscale;
  } else if (function_name == "blur") {
    function_type = starlight::FilterType::kBlur;
  }

  switch (function_type) {
    case starlight::FilterType::kNone:
      arr->push_back(
          lepus::Value(static_cast<int>(starlight::FilterType::kNone)));
      break;
    case starlight::FilterType::kGrayscale:
      value = atof(param.c_str());
      arr->push_back(
          lepus::Value(static_cast<int>(starlight::FilterType::kGrayscale)));
      arr->push_back(lepus::Value(value));
      arr->push_back(lepus::Value(static_cast<int>(CSSValuePattern::PERCENT)));
      break;
    case starlight::FilterType::kBlur:
      arr->push_back(
          lepus::Value(static_cast<int>(starlight::FilterType::kBlur)));
      // parse radius, <length> param.
      CSSValue css_value;
      LengthHandler::Process(lepus::Value(param.c_str()), css_value, configs);
      arr->push_back(css_value.GetValue());
      arr->push_back(lepus::Value(static_cast<int>(css_value.GetPattern())));
      break;
  }

  output[key] = CSSValue(lepus::Value(arr), CSSValuePattern::ARRAY);
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDFilter] = &Handle; }

}  // namespace FilterHandler
}  // namespace tasm
}  // namespace lynx
