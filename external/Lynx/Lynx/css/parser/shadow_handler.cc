// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/shadow_handler.h"

#include <string>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/css_color.h"
#include "css/parser/length_handler.h"
#include "css/unit_handler.h"
#include "lepus/array.h"
#include "lepus/table.h"

namespace lynx {
namespace tasm {

namespace {
bool HandleOption(std::string& str, starlight::ShadowOption& option) {
  if (str == "inset") {
    option = starlight::ShadowOption::kInset;
    return true;
  } else if (str == "inherit") {
    option = starlight::ShadowOption::kInherit;
    return true;
  } else if (str == "initial") {
    option = starlight::ShadowOption::kInitial;
    return true;
  }
  return false;
}

const std::vector<std::string>& PropsIndex() {
  static const std::vector<std::string> props_index = {"h_offset", "v_offset",
                                                       "blur", "spread"};
  return props_index;
}

}  // namespace
namespace ShadowHandler {

/* See box-shadow's specification.
  https://developer.mozilla.org/docs/Web/CSS/box-shadow Currently supported
  format:
  // no shadow
  box-shadow: none;
  // offset-x | offset-y | color
  box-shadow: 60px -16px teal;
  // offset-x | offset-y | blur-radius | color
  box-shadow: 10px 5px 5px black;
  // offset-x | offset-y | blur-radius | spread-radius | color
  box-shadow: 2px 2px 2px 1px rgba(0, 0, 0, 0.2);
  // other :
  support more seperated by ,
  support inset keyword anywhere
*/
HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString(), configs.enable_css_strict_mode, TYPE_MUST_BE,
          CSSProperty::GetPropertyName(key).c_str(), STRING_TYPE)) {
    return false;
  }
  auto str = input.String()->str();
  auto ret = lepus::CArray::Create();
  CSSColor maybeColor;
  starlight::ShadowOption maybeOption;
  CSSValue tmp_css_value;
  if (str.find_last_of(";") == str.length() - 1) {
    // this string can cause ios crash:
    // `text-shadow: 0 .005rem .01rem ;`
    // because this string will split into [text-shadow:, 0, .005rem, .01rem, ;]
    // on ios this will cause props_index index overflow exception
    // remove last double quotes
    str.erase(str.length() - 1);
  }

  base::ReplaceMultiSpaceWithOne(str);
  auto groups = base::SplitStringIgnoreBracket(str, ',');
  for (const auto& group : groups) {
    auto props = base::SplitStringIgnoreBracket(group, ' ');
    if (!UnitHandler::CSSWarning(props.size() > 0,
                                 configs.enable_css_strict_mode, EMPTY_ERROR,
                                 CSSProperty::GetPropertyName(key).c_str())) {
      return false;
    }

    auto dict = lepus::Dictionary::Create();
    if (props[0] == "none") {
      dict->SetValue("enable", lepus::Value(false));
      ret->push_back(lepus::Value(dict));
      break;
    }

    dict->SetValue("enable", lepus::Value(true));
    if (!UnitHandler::CSSWarning(
            props.size() > 1, configs.enable_css_strict_mode,
            "%s must set h-shadow and v-shadow:%s",
            CSSProperty::GetPropertyName(key).c_str(), str.c_str())) {
      return false;
    }

    int prop_idx = 0;
    for (auto& prop : props) {
      if (HandleOption(prop, maybeOption)) {
        dict->SetValue("option", lepus::Value(static_cast<int>(maybeOption)));
      } else if (CSSColor::Parse(prop, maybeColor)) {
        dict->SetValue("color", lepus::Value(maybeColor.Cast()));
      } else {
        auto arr = lepus::CArray::Create();
        if (!UnitHandler::CSSWarning(
                LengthHandler::Process(lepus::Value(prop.c_str()),
                                       tmp_css_value, configs),
                configs.enable_css_strict_mode, FORMAT_ERROR,
                CSSProperty::GetPropertyName(key).c_str(), str.c_str())) {
          return false;
        }
        if (static_cast<size_t>(prop_idx) >= PropsIndex().size()) {
          // take case wrong shadow values
          break;
        }
        arr->push_back(tmp_css_value.GetValue());
        arr->push_back(
            lepus::Value(static_cast<int>(tmp_css_value.GetPattern())));
        dict->SetValue(PropsIndex()[prop_idx++], lepus::Value(arr));
      }
    }
    ret->push_back(lepus::Value(dict));
  }

  output[key] = CSSValue(lepus::Value(ret), CSSValuePattern::ARRAY);
  return true;
}

HANDLER_REGISTER_IMPL() {
  array[kPropertyIDTextShadow] = &Handle;
  array[kPropertyIDBoxShadow] = &Handle;
}

}  // namespace ShadowHandler
}  // namespace tasm
}  // namespace lynx
