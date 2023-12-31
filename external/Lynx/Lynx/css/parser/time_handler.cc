// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/time_handler.h"

#include <string>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/unit_handler.h"
#include "lepus/array.h"

namespace lynx {
namespace tasm {
namespace TimeHandler {

double toMills(std::string& str) {
  double num = 0;
  if (base::EndsWith(str, "ms")) {
    num = atof(str.c_str());
  } else if (base::EndsWith(str, "s")) {
    num = atof(str.c_str()) * 1000;
  } else {
    num = atof(str.c_str());
  }
  return num;
}

bool Process(const lepus::Value& input, CSSValue& css_value,
             const CSSParserConfigs& configs) {
  if (!UnitHandler::CSSWarning(input.IsNumber() || input.IsString(),
                               configs.enable_css_strict_mode, TYPE_MUST_BE,
                               TIME_VALUE, STRING_OR_NUMBER_TYPE)) {
    return false;
  }
  // default unit is ms.
  if (input.IsNumber()) {
    double num = 0;
    num = input.Number();
    css_value.SetValue(lepus::Value(num));
    css_value.SetPattern(CSSValuePattern::NUMBER);
  } else {
    auto str = input.String()->str();
    if (str.find(',') != std::string::npos) {
      std::vector<std::string> result;
      base::SplitString(str, ',', result);
      auto arr = lepus::CArray::Create();
      for (auto& i : result) {
        arr->push_back(lepus::Value(toMills(i)));
      }
      css_value.SetValue(lepus::Value(arr));
      css_value.SetPattern(CSSValuePattern::ARRAY);
    } else {
      css_value.SetValue(lepus::Value(toMills(str)));
      css_value.SetPattern(CSSValuePattern::NUMBER);
    }
  }
  return true;
}

HANDLER_IMPL() {
  CSSValue css_value;
  if (!UnitHandler::CSSWarning(Process(input, css_value, configs),
                               configs.enable_css_strict_mode, TYPE_UNSUPPORTED,
                               CSSProperty::GetPropertyName(key).c_str(),
                               input.String()->c_str())) {
    return false;
  }
  output[key] = css_value;
  return true;
}

HANDLER_REGISTER_IMPL() {
  // AUTO INSERT, DON'T CHANGE IT!
  array[kPropertyIDAnimationDuration] = &Handle;
  array[kPropertyIDAnimationDelay] = &Handle;
  array[kPropertyIDLayoutAnimationCreateDuration] = &Handle;
  array[kPropertyIDLayoutAnimationCreateDelay] = &Handle;
  array[kPropertyIDLayoutAnimationDeleteDuration] = &Handle;
  array[kPropertyIDLayoutAnimationDeleteDelay] = &Handle;
  array[kPropertyIDLayoutAnimationUpdateDuration] = &Handle;
  array[kPropertyIDLayoutAnimationUpdateDelay] = &Handle;
  array[kPropertyIDTransitionDuration] = &Handle;
  array[kPropertyIDTransitionDelay] = &Handle;
  // AUTO INSERT END, DON'T CHANGE IT!
}

}  // namespace TimeHandler
}  // namespace tasm
}  // namespace lynx
