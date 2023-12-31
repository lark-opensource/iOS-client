// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/transition_shorthand_handler.h"

#include <string>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/parser/animation_property_handler.h"
#include "css/parser/time_handler.h"
#include "css/parser/timing_function_handler.h"
#include "css/unit_handler.h"
#include "lepus/array.h"
#include "lepus/string_util.h"
#include "lepus/table.h"

namespace lynx {
namespace tasm {
namespace TransitionShorthandHandler {

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDTransition).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  auto res = lepus::CArray::Create();
  bool success;
  std::vector<std::string> group = base::SplitStringIgnoreBracket(str, ',');
  for (auto item : group) {
    std::vector<std::string> ret = base::SplitStringIgnoreBracket(item, ' ');
    if (ret.empty() || (ret.size() == 1 && ret[0] != "none")) {
      LOGE("transition format error:" << item);
      continue;
    }
    auto dict = lepus::Dictionary::Create();
    // The sign to mark the time property is 'delay' or not ('duration').
    bool is_delay = false;
    for (size_t i = 0; i < ret.size(); i++) {
      auto str_impl = lepus::String(ret[i]).impl();
      if (i == 0) {
        CSSValue maybe_property;
        success = AnimationPropertyHandler::Process(lepus::Value(str_impl),
                                                    maybe_property, configs);
        if (!UnitHandler::CSSWarning(
                success, configs.enable_css_strict_mode, FORMAT_ERROR,
                CSSProperty::GetPropertyName(kPropertyIDTransitionProperty)
                    .c_str(),
                str_impl->c_str())) {
          return false;
        }
        dict->SetValue("property",
                       lepus::Value(maybe_property.GetValue().Number()));
      } else {
        if (TimingFunctionHandler::IsValidTimingFunction(ret[i])) {
          CSSValue maybe_timing_func;
          if (!UnitHandler::CSSWarning(
                  TimingFunctionHandler::Process(lepus::Value(str_impl),
                                                 maybe_timing_func, configs),
                  configs.enable_css_strict_mode, FORMAT_ERROR,
                  CSSProperty::GetPropertyName(key).c_str(), str.c_str())) {
            return false;
          }
          dict->SetValue("timing", maybe_timing_func.GetValue());
        } else if (base::EndsWith(ret[i], "s")) {
          CSSPropertyID css_property_id;
          CSSValue maybe_duration_or_delay;
          success = TimeHandler::Process(lepus::Value(str_impl),
                                         maybe_duration_or_delay, configs);
          if (!is_delay) {
            is_delay = true;
            css_property_id = kPropertyIDTransitionDuration;
          } else {
            css_property_id = kPropertyIDTransitionDelay;
          }
          if (!UnitHandler::CSSWarning(
                  success, configs.enable_css_strict_mode, FORMAT_ERROR,
                  CSSProperty::GetPropertyName(css_property_id).c_str(),
                  str_impl->c_str())) {
            return false;
          }
          std::string property =
              (css_property_id == kPropertyIDTransitionDuration) ? "duration"
                                                                 : "delay";
          dict->SetValue(
              property,
              lepus::Value(maybe_duration_or_delay.GetValue().Number()));
        }
      }
    }
    res->push_back(lepus::Value(dict));
  }
  if (!UnitHandler::CSSWarning(
          res->size() != 0, configs.enable_css_strict_mode, FORMAT_ERROR,
          CSSProperty::GetPropertyName(kPropertyIDTransition).c_str(),
          str.c_str())) {
    return false;
  }
  output[key] = CSSValue(lepus::Value(res), CSSValuePattern::ARRAY);
  return true;
}

HANDLER_REGISTER_IMPL() { array[kPropertyIDTransition] = &Handle; }

}  // namespace TransitionShorthandHandler
}  // namespace tasm
}  // namespace lynx
