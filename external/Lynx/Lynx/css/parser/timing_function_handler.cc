// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/timing_function_handler.h"

#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/unit_handler.h"
#include "lepus/array.h"
#include "lepus/string_util.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace tasm {
namespace TimingFunctionHandler {
using starlight::StepsType;
using starlight::TimingFunctionType;

CSSValue ToTimingFunction(std::string& str, bool enable_strict_mode) {
  CSSValue css_value;
  TimingFunctionType type;
  if (str == "linear") {
    type = TimingFunctionType::kLinear;
    css_value.SetValue(lepus::Value(static_cast<int>(type)));
    css_value.SetPattern(CSSValuePattern::ENUM);
  } else if (str == "ease-in") {
    type = TimingFunctionType::kEaseIn;
    css_value.SetValue(lepus::Value(static_cast<int>(type)));
    css_value.SetPattern(CSSValuePattern::ENUM);
  } else if (str == "ease-out") {
    type = TimingFunctionType::kEaseOut;
    css_value.SetValue(lepus::Value(static_cast<int>(type)));
    css_value.SetPattern(CSSValuePattern::ENUM);
  } else if (str == "ease-in-ease-out" || str == "ease" ||
             str == "ease-in-out") {
    type = TimingFunctionType::kEaseInEaseOut;
    css_value.SetValue(lepus::Value(static_cast<int>(type)));
    css_value.SetPattern(CSSValuePattern::ENUM);
  } else if (lepus::BeginsWith(str, "square-bezier")) {
    auto arr = lepus::CArray::Create();
    std::vector<std::string> ret;
    auto success = base::ConvertParenthesesStringToVector(str, ret);
    if (success && ret.size() == 2) {
      arr->push_back(
          lepus::Value(static_cast<int>(TimingFunctionType::kSquareBezier)));
      arr->push_back(lepus::Value(atof(ret[0].c_str())));
      arr->push_back(lepus::Value(atof(ret[1].c_str())));
      css_value.SetValue(lepus::Value(arr));
      css_value.SetPattern(CSSValuePattern::ARRAY);
    } else {
      UnitHandler::CSSWarning(false, enable_strict_mode, FORMAT_ERROR,
                              SQUARE_BEZIER, str.c_str());
    }
  } else if (lepus::BeginsWith(str, "cubic-bezier")) {
    auto arr = lepus::CArray::Create();
    std::vector<std::string> ret;
    auto success = base::ConvertParenthesesStringToVector(str, ret);
    if (success && ret.size() == 4) {
      arr->push_back(
          lepus::Value(static_cast<int>(TimingFunctionType::kCubicBezier)));
      arr->push_back(lepus::Value(atof(ret[0].c_str())));
      arr->push_back(lepus::Value(atof(ret[1].c_str())));
      arr->push_back(lepus::Value(atof(ret[2].c_str())));
      arr->push_back(lepus::Value(atof(ret[3].c_str())));
      css_value.SetValue(lepus::Value(arr));
      css_value.SetPattern(CSSValuePattern::ARRAY);
    } else {
      UnitHandler::CSSWarning(false, enable_strict_mode, FORMAT_ERROR,
                              CUBIC_BEZIER, str.c_str());
    }
  } else if (str == "step-start" || str == "step-end") {
    auto arr = lepus::CArray::Create();
    auto s_type = StepsType::kInvalid;
    if (str == "step-start") {
      s_type = StepsType::kStart;
    } else {
      s_type = StepsType::kEnd;
    }
    arr->push_back(lepus::Value(static_cast<int>(TimingFunctionType::kSteps)));
    arr->push_back(lepus::Value(1));
    arr->push_back(lepus::Value(static_cast<int>(s_type)));
    css_value.SetValue(lepus::Value(arr));
    css_value.SetPattern(CSSValuePattern::ARRAY);
  } else if (lepus::BeginsWith(str, "steps")) {
    auto arr = lepus::CArray::Create();
    std::vector<std::string> ret;
    auto success = base::ConvertParenthesesStringToVector(str, ret);
    if (success && ret.size() == 2) {
      arr->push_back(
          lepus::Value(static_cast<int>(TimingFunctionType::kSteps)));
      arr->push_back(lepus::Value(atoi(ret[0].c_str())));
      auto s_type_str = ret[1];
      auto s_type = StepsType::kInvalid;
      if (s_type_str == "start" || s_type_str == "jump-start") {
        s_type = StepsType::kStart;
      } else if (s_type_str == "end" || s_type_str == "jump-end") {
        s_type = StepsType::kEnd;
      } else if (s_type_str == "jump-both") {
        s_type = StepsType::kJumpBoth;
      } else if (s_type_str == "jump-none") {
        s_type = StepsType::kJumpNone;
      } else {
        UnitHandler::CSSWarning(false, enable_strict_mode, FORMAT_ERROR,
                                STEP_VALUE, str.c_str());
      }
      arr->push_back(lepus::Value(static_cast<int>(s_type)));
      css_value.SetValue(lepus::Value(arr));
      css_value.SetPattern(CSSValuePattern::ARRAY);
    }
  } else {
    UnitHandler::CSSWarning(
        false, enable_strict_mode, TYPE_UNSUPPORTED,
        CSSProperty::GetPropertyName(kPropertyIDAnimationTimingFunction)
            .c_str(),
        str.c_str());
  }
  return css_value;
}

bool IsValidTimingFunction(const std::string& str) {
  return str == "linear" || str == "step-start" || str == "step-end" ||
         lepus::BeginsWith(str, "ease") || lepus::BeginsWith(str, "square") ||
         lepus::BeginsWith(str, "cubic") || lepus::BeginsWith(str, "steps");
}

bool Process(const lepus::Value& input, CSSValue& css_value,
             const CSSParserConfigs& configs) {
  if (!UnitHandler::CSSWarning(input.IsString(), configs.enable_css_strict_mode,
                               TYPE_MUST_BE, TIMING_FUNCTION, STRING_TYPE)) {
    return false;
  }
  auto& str = input.String()->str();
  std::vector<std::string> result = base::SplitStringIgnoreBracket(str, ',');
  if (result.size() == 0) {
    return false;
  }
  auto arr = lepus::CArray::Create();
  for (auto& item : result) {
    CSSValue value = ToTimingFunction(item, configs.enable_css_strict_mode);
    if (value.IsEnum() || value.IsArray()) {
      arr->push_back(value.GetValue());
    } else {
      return false;
    }
  }
  // In order to support multi-timingFunction parse, we always wrap it in a
  // array even if there is only one timing function.
  css_value.SetValue(lepus::Value(arr));
  css_value.SetPattern(CSSValuePattern::ARRAY);

  return true;
}

HANDLER_IMPL() {
  CSSValue css_value;
  auto success = Process(input, css_value, configs);
  if (!UnitHandler::CSSWarning(
          success, configs.enable_css_strict_mode, FORMAT_ERROR,
          CSSProperty::GetPropertyName(key).c_str(), input.String()->c_str())) {
    return false;
  }
  output[key] = css_value;
  return success;
}

HANDLER_REGISTER_IMPL() {
  // AUTO INSERT, DON'T CHANGE IT!
  array[kPropertyIDAnimationTimingFunction] = &Handle;
  array[kPropertyIDLayoutAnimationCreateTimingFunction] = &Handle;
  array[kPropertyIDLayoutAnimationDeleteTimingFunction] = &Handle;
  array[kPropertyIDLayoutAnimationUpdateTimingFunction] = &Handle;
  array[kPropertyIDTransitionTimingFunction] = &Handle;
  // AUTO INSERT END, DON'T CHANGE IT!
}
}  // namespace TimingFunctionHandler
}  // namespace tasm
}  // namespace lynx
