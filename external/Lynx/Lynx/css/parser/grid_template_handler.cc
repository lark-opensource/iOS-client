// Copyright 2021 The Lynx Authors. All rights reserved.

#include "css/parser/grid_template_handler.h"

#include <algorithm>
#include <string>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/parser/length_handler.h"
#include "css/unit_handler.h"
#include "lepus/array.h"

namespace lynx {
namespace tasm {
namespace GridTemplateHandler {

// "repeat()" string size.
namespace {
constexpr size_t kRepeatFunMinSize = 8;
constexpr const char* kValueRepeat = "repeat";
constexpr const char* kValueErrorMessage =
    "value must be a string or percentage array:%d";

bool ParserLengthValue(const std::string& len_arr_str,
                       base::scoped_refptr<lepus::CArray> array,
                       const CSSParserConfigs& configs) {
  std::vector<std::string> arr_values;
  base::SplitString(len_arr_str, ' ', arr_values);
  for (const auto& value_str : arr_values) {
    if (value_str.empty()) {
      continue;
    }

    tasm::CSSValue css_value;
    lepus::Value lepus_value =
        lepus::Value(lepus::StringImpl::Create(value_str.c_str()));
    if (!LengthHandler::Process(lepus_value, css_value, configs)) {
      return false;
    }

    array->push_back(css_value.GetValue());
    array->push_back(
        lepus::Value(static_cast<int32_t>(css_value.GetPattern())));
  }

  return true;
}

// parm format:"repeat(size,content);"
bool ResolveRepeatFunc(const std::string& repeat_func,
                       base::scoped_refptr<lepus::CArray> array,
                       const CSSParserConfigs& configs) {
  if (!base::BeginsWith(repeat_func, kValueRepeat)) {
    return false;
  }

  const std::string& content_str = repeat_func.substr(
      kRepeatFunMinSize - 1, repeat_func.size() - kRepeatFunMinSize);
  std::vector<std::string> content_arr;
  base::SplitString(content_str, ',', content_arr);

  if (content_arr.size() != 2) {
    return false;
  }

  int repeat_size = std::max(atoi(content_arr[0].c_str()), 0);
  for (int idx = 0; idx < repeat_size; ++idx) {
    if (!ParserLengthValue(content_arr[1], array, configs)) {
      return false;
    }
  }

  return true;
}
}  // namespace

HANDLER_IMPL() {
  if (!(input.IsString())) {
    return false;
  }

  // resolve repeated
  auto array = lepus::CArray::Create();
  std::string value_str = input.String()->str();
  std::string::size_type value_str_idx = 0;
  std::string::size_type value_str_size = value_str.size();
  while (value_str_idx < value_str_size) {
    std::string::size_type repeat_pos =
        value_str.find(kValueRepeat, value_str_idx);
    std::string::size_type length_end =
        repeat_pos == std::string::npos ? value_str_size : repeat_pos;
    if (!UnitHandler::CSSWarning(
            ParserLengthValue(
                value_str.substr(value_str_idx, length_end - value_str_idx),
                array, configs),
            configs.enable_css_strict_mode, kValueErrorMessage, key)) {
      return false;
    }

    if (repeat_pos != std::string::npos) {
      std::string::size_type repeat_end_pos = value_str.find(")", repeat_pos);
      if (repeat_end_pos == std::string::npos) {
        return false;
      }

      if (!UnitHandler::CSSWarning(
              ResolveRepeatFunc(
                  value_str.substr(repeat_pos, repeat_end_pos - length_end + 1),
                  array, configs),
              configs.enable_css_strict_mode, kValueErrorMessage, key)) {
        return false;
      }
      value_str_idx = repeat_end_pos + 1;
    } else {
      value_str_idx = length_end;
    }
  }

  output[key] = CSSValue(lepus::Value(array), CSSValuePattern::ARRAY);
  return true;
}

HANDLER_REGISTER_IMPL() {
  array[kPropertyIDGridTemplateColumns] = &Handle;
  array[kPropertyIDGridTemplateRows] = &Handle;
  array[kPropertyIDGridAutoColumns] = &Handle;
  array[kPropertyIDGridAutoRows] = &Handle;
}

}  // namespace GridTemplateHandler
}  // namespace tasm
}  // namespace lynx
