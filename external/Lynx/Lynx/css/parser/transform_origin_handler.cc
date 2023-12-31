// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/transform_origin_handler.h"

#include <cmath>
#include <string>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/parser/length_handler.h"
#include "css/unit_handler.h"
#include "lepus/array.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace tasm {
namespace TransformOriginHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDTransformOrigin).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  str = base::TrimString(str);
  base::ReplaceMultiSpaceWithOne(str);
  std::vector<std::string> vec;
  char sep = ' ';
  if (str.find(',') != std::string::npos) {
    sep = ',';
  }
  base::SplitString(str, sep, vec);
  if (!UnitHandler::CSSWarning(
          vec.size() == 2, configs.enable_css_strict_mode, FORMAT_ERROR,
          CSSProperty::GetPropertyName(kPropertyIDTransformOrigin).c_str(),
          str.c_str())) {
    return false;
  }
  auto arr = lepus::CArray::Create();
  for (size_t i = 0; i < vec.size(); i++) {
    auto& item = vec[i];
    if (i == 0) {
      if (item == "left") {
        item = "0%";
      } else if (item == "right") {
        item = "100%";
      }
    } else if (i == 1) {
      if (item == "top") {
        item = "0%";
      } else if (item == "bottom") {
        item = "100%";
      }
    }
    if (item == "center") {
      item = "50%";
    }
    CSSValue len;
    if (!UnitHandler::CSSWarning(
            LengthHandler::Process(lepus::Value(vec[i].c_str()), len, configs),
            configs.enable_css_strict_mode, FORMAT_ERROR,
            CSSProperty::GetPropertyName(key).c_str(), str.c_str())) {
      return false;
    }
    arr->push_back(len.GetValue());
    arr->push_back(lepus::Value(static_cast<int>(len.GetPattern())));
  }
  output[key] = CSSValue(lepus::Value(arr), CSSValuePattern::ARRAY);
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDTransformOrigin] = &Handle; }

}  // namespace TransformOriginHandler
}  // namespace tasm
}  // namespace lynx
