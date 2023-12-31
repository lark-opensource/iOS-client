// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/animation_shorthand_handler.h"

#include <string>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/css_property.h"
#include "css/parser/animation_fill_mode_handler.h"
#include "css/parser/animation_play_state_handler.h"
#include "css/parser/timing_function_handler.h"
#include "css/unit_handler.h"
#include "lepus/array.h"
#include "lepus/string_util.h"
#include "lepus/table.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace tasm {
namespace {

constexpr int NAME = 1 << 0;
constexpr int DURATION = 1 << 1;
constexpr int TIMING = 1 << 2;
constexpr int DELAY = 1 << 3;
constexpr int FILL_MODE = 1 << 4;
constexpr int ITERATION_COUNT = 1 << 5;
constexpr int PLAY_STATUS = 1 << 6;
constexpr int DIRECTION = 1 << 7;

bool IsInt(std::string str) {
  for (const auto& character : str) {
    if (!isdigit(character)) {
      return false;
    }
  }
  return true;
}

bool IsValidFillMode(const std::string& str) {
  return str == "none" || str == "forwards" || str == "backwards" ||
         str == "both";
}

bool IsValidPlayState(const std::string& str) {
  return str == "paused" || str == "running";
}

bool IsValidDirection(const std::string& str) {
  return str == "normal" || str == "reverse" || str == "alternate" ||
         str == "alternate-reverse";
}

}  // namespace

namespace AnimationShorthandHandler {

bool Process(const std::string& input, StyleMap& output,
             const CSSParserConfigs& configs) {
  auto ret = base::SplitStringIgnoreBracket(input, ' ');
  output[kPropertyIDAnimationName] = CSSValue(lepus::Value(""));
  output[kPropertyIDAnimationDuration] =
      CSSValue(lepus::Value(0), CSSValuePattern::NUMBER);
  output[kPropertyIDAnimationTimingFunction] = CSSValue(
      lepus::Value(static_cast<int>(starlight::TimingFunctionType::kLinear)),
      CSSValuePattern::ENUM);
  output[kPropertyIDAnimationDelay] =
      CSSValue(lepus::Value(0), CSSValuePattern::NUMBER);
  output[kPropertyIDAnimationIterationCount] =
      CSSValue(lepus::Value(1), CSSValuePattern::NUMBER);
  output[kPropertyIDAnimationDirection] = CSSValue(
      lepus::Value(
          static_cast<int>(starlight::AnimationDirectionType::kNormal)),
      CSSValuePattern::ENUM);
  output[kPropertyIDAnimationFillMode] = CSSValue(
      lepus::Value(static_cast<int>(starlight::AnimationFillModeType::kNone)),
      CSSValuePattern::ENUM);
  output[kPropertyIDAnimationPlayState] = CSSValue(
      lepus::Value(
          static_cast<int>(starlight::AnimationPlayStateType::kRunning)),
      CSSValuePattern::ENUM);

  if (ret.size() == 1 && ret[0] == "none") {
    return true;
  }

  int flag = 0;
  for (const auto& cur_ret : ret) {
    if (cur_ret.empty() || cur_ret == " ") {
      continue;
    }
    auto str_impl = lepus::String(cur_ret).impl();
    if (!(flag & TIMING) &&
        TimingFunctionHandler::IsValidTimingFunction(cur_ret)) {
      UnitHandler::Process(kPropertyIDAnimationTimingFunction,
                           lepus::Value(str_impl), output, configs);
      flag |= TIMING;
      continue;
    }
    if (!(flag & FILL_MODE) && IsValidFillMode(cur_ret)) {
      UnitHandler::Process(kPropertyIDAnimationFillMode, lepus::Value(str_impl),
                           output, configs);
      flag |= FILL_MODE;
      continue;
    }
    if (!(flag & ITERATION_COUNT) &&
        (cur_ret == "infinite" || IsInt(cur_ret))) {
      UnitHandler::Process(kPropertyIDAnimationIterationCount,
                           lepus::Value(str_impl), output, configs);
      flag |= ITERATION_COUNT;
      continue;
    }
    if ((!(flag & DURATION) || !(flag & DELAY)) &&
        (isdigit(cur_ret[0]) || cur_ret[0] == '.') &&
        lepus::EndsWith(cur_ret, "s")) {
      if (!(flag & DURATION)) {
        UnitHandler::Process(kPropertyIDAnimationDuration,
                             lepus::Value(str_impl), output, configs);
        flag |= DURATION;
      } else {
        UnitHandler::Process(kPropertyIDAnimationDelay, lepus::Value(str_impl),
                             output, configs);
        flag |= DELAY;
      }
      continue;
    }
    if (!(flag & PLAY_STATUS) && IsValidPlayState(cur_ret)) {
      UnitHandler::Process(kPropertyIDAnimationPlayState,
                           lepus::Value(str_impl), output, configs);
      flag |= PLAY_STATUS;
      continue;
    }
    if (!(flag & DIRECTION) && IsValidDirection(cur_ret)) {
      UnitHandler::Process(kPropertyIDAnimationDirection,
                           lepus::Value(str_impl), output, configs);
      flag |= DIRECTION;
      continue;
    }
    if (!(flag & NAME)) {
      UnitHandler::Process(kPropertyIDAnimationName, lepus::Value(str_impl),
                           output, configs);
      flag |= NAME;
      continue;
    }
  }

  return true;
}

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(kPropertyIDAnimation).c_str(),
          STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  base::ReplaceMultiSpaceWithOne(str);
  std::vector<std::string> group;

  if (str.find(',') != std::string::npos) {
    group = base::SplitStringIgnoreBracket(str, ',');
  }
  if (group.size() > 1) {
    auto ret_arr = lepus::CArray::Create();
    for (auto& item : group) {
      StyleMap ret_container;
      AnimationShorthandHandler::Process(item, ret_container, configs);
      auto map = lepus::Dictionary::Create();
      for (auto& it : ret_container) {
        map->SetValue(std::to_string(it.first), it.second.GetValue());
      }
      ret_arr->push_back(lepus::Value(map));
    }
    output[key] = CSSValue(lepus::Value(ret_arr), CSSValuePattern::ARRAY);
  } else {
    StyleMap ret_container;
    AnimationShorthandHandler::Process(str, ret_container, configs);
    auto map = lepus::Dictionary::Create();
    for (auto& it : ret_container) {
      map->SetValue(std::to_string(it.first), it.second.GetValue());
    }
    output[key] = CSSValue(lepus::Value(map), CSSValuePattern::MAP);
  }
  return true;
}

HANDLER_REGISTER_IMPL() {
  array[kPropertyIDAnimation] = &Handle;
  array[kPropertyIDEnterTransitionName] = &Handle;
  array[kPropertyIDExitTransitionName] = &Handle;
  array[kPropertyIDPauseTransitionName] = &Handle;
  array[kPropertyIDResumeTransitionName] = &Handle;
}

}  // namespace AnimationShorthandHandler
}  // namespace tasm
}  // namespace lynx
