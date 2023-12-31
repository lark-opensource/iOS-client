// Copyright 2021 The Lynx Authors. All rights reserved.
#include "css/css_variable_handler.h"

#include <unordered_map>

namespace lynx {
namespace tasm {

bool CSSVariableHandler::HandleCSSVariables(StyleMap& map,
                                            AttributeHolder* holder,
                                            const CSSParserConfigs& configs) {
  if (map.empty()) {
    return false;
  }
  std::unordered_map<CSSPropertyID, lepus::String> temp_map;
  bool has_variables = false;
  for (const auto& iter : map) {
    if (iter.second.GetValueType() == CSSValueType::VARIABLE) {
      has_variables = true;
      lepus::Value value_expr = iter.second.GetValue();
      lepus::String property = iter.second.GetDefaultValue();
      if (value_expr.IsString()) {
        property = FormatStringWithRule(value_expr.String()->c_str(), holder,
                                        property);
      }
      temp_map.insert({iter.first, property});
    }
  }
  holder->SetHasCssVariables(has_variables);

  auto it = temp_map.begin();
  while (it != temp_map.end()) {
    map.erase(it->first);
    UnitHandler::Process(it->first, lepus::Value(it->second.c_str()), map,
                         configs);
    it++;
  }
  return true;
}

//    "The food taste {{ feeling }} !"
//    => rule: {{"feeling", "delicious"}}
//    => result: "The food taste delicious !"
std::string CSSVariableHandler::FormatStringWithRule(
    const std::string& format, AttributeHolder* holder,
    lepus::String& default_props) {
  std::stringstream ss;
  std::string maybe_key;
  int brace_start = -1;
  int brace_end = -1;
  int pre_brace_end = 0;
  for (int i = 0; static_cast<size_t>(i) < format.size(); ++i) {
    char c = format[i];
    switch (c) {
      case '{':
        brace_start = i;
        break;
      case '}':
        brace_end = brace_start != -1 ? i : -1;
        break;
      default:
        break;
    }
    if (brace_start != -1 && brace_end != -1) {
      ss.write(&format[pre_brace_end], brace_start - pre_brace_end - 1);
      maybe_key =
          std::string(&format[brace_start + 1], brace_end - brace_start - 1);
      lepus::String value = FindSuitableProperty(maybe_key, holder);
      if (value.empty()) {
        value = default_props;
      }

      if (enable_fiber_arch_) {
        // In FiberArch, relating node with it's related css variables for
        // optimization.
        holder->AddCSSVariableRelated(maybe_key, value);
      }

      ss << value.c_str();
      // move by 2 because of "}}"
      pre_brace_end = brace_end + 2;
      brace_start = -1;
      brace_end = -1;
    }
  }
  if (static_cast<size_t>(pre_brace_end) < format.size()) {
    ss.write(&format[pre_brace_end], format.size() - pre_brace_end);
  }
  return ss.str();
}

lepus::String CSSVariableHandler::FindSuitableProperty(
    const std::string& key, AttributeHolder* holder) {
  const AttributeHolder* base = holder;
  while (base != nullptr) {
    lepus::String css_var_value = base->GetCSSVariableValue(key);
    if (css_var_value.empty()) {
      base = base->HolderParent();
    } else {
      return css_var_value;
    }
  }
  return lepus::String();
}
}  // namespace tasm
}  // namespace lynx
