// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/parser/flex_handler.h"

#include <string>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/string/string_number_convert.h"
#include "base/string/string_utils.h"
#include "css/unit_handler.h"

namespace lynx {
namespace tasm {
namespace FlexHandler {

bool IsNumber(const std::string &input) {
  int dot_cnt = 0;
  for (size_t i = 0; i != input.size(); ++i) {
    if (input[i] == '.')
      ++dot_cnt;
    else if (input[i] > '9' || input[i] < '0')
      return false;
  }
  return dot_cnt <= 1;
}

HANDLER_IMPL() {
  if (!UnitHandler::CSSWarning(
          input.IsString() || input.IsNumber(), configs.enable_css_strict_mode,
          TYPE_MUST_BE, CSSProperty::GetPropertyName(kPropertyIDFlex).c_str(),
          STRING_OR_NUMBER_TYPE)) {
    return false;
  }
  std::vector<std::string> flex_props = {"0", "1", "auto"};
  StyleMap tmp_output;

  if (input.IsNumber()) {
    if (tasm::UnitHandler::Process(tasm::kPropertyIDFlexGrow,
                                   lepus::Value(input.Double()), tmp_output,
                                   configs) &&
        tasm::UnitHandler::Process(tasm::kPropertyIDFlexShrink, lepus::Value(1),
                                   tmp_output, configs) &&
        tasm::UnitHandler::Process(tasm::kPropertyIDFlexBasis, lepus::Value(0),
                                   tmp_output, configs)) {
      for (auto i : tmp_output) {
        output.emplace(i);
      }
      return true;
    } else {
      if (!UnitHandler::CSSWarning(
              false, configs.enable_css_strict_mode, FORMAT_ERROR,
              CSSProperty::GetPropertyName(kPropertyIDFlex).c_str(),
              input.Number())) {
        return false;
      }
    }
  }

  auto &str = input.String()->str();
  std::vector<std::string> styles;
  base::SplitString(str, ' ', styles);

  if (styles.size() == 1) {
    if (IsNumber(styles[0])) {
      flex_props[0] = styles[0];
      flex_props[2] = "0";
    } else {
      flex_props[2] = styles[0];
    }
  } else if (styles.size() == 2) {
    if (!UnitHandler::CSSWarning(
            (IsNumber(styles[0])), configs.enable_css_strict_mode, TYPE_MUST_BE,
            CSSProperty::GetPropertyName(kPropertyIDFlexGrow).c_str(),
            NUMBER_TYPE)) {
      return false;
    }
    flex_props[0] = styles[0];
    if (IsNumber(styles[1])) {
      flex_props[1] = styles[1];
      flex_props[2] = "0";
    } else {
      flex_props[2] = styles[1];
    }
  } else if (styles.size() == 3) {
    if (!UnitHandler::CSSWarning(
            (IsNumber(styles[0])), configs.enable_css_strict_mode, TYPE_MUST_BE,
            CSSProperty::GetPropertyName(kPropertyIDFlexGrow).c_str(),
            NUMBER_TYPE)) {
      return false;
    }
    if (!UnitHandler::CSSWarning(
            (IsNumber(styles[1])), configs.enable_css_strict_mode, TYPE_MUST_BE,
            CSSProperty::GetPropertyName(kPropertyIDFlexShrink).c_str(),
            NUMBER_TYPE)) {
      return false;
    }
    flex_props[0] = styles[0];
    flex_props[1] = styles[1];
    flex_props[2] = styles[2];
  } else {
    if (!UnitHandler::CSSWarning(
            false, configs.enable_css_strict_mode, FORMAT_ERROR,
            CSSProperty::GetPropertyName(kPropertyIDFlex).c_str(),
            str.c_str())) {
      return false;
    }
  }

  if (tasm::UnitHandler::Process(tasm::kPropertyIDFlexGrow,
                                 lepus::Value(flex_props[0].c_str()),
                                 tmp_output, configs) &&
      tasm::UnitHandler::Process(tasm::kPropertyIDFlexShrink,
                                 lepus::Value(flex_props[1].c_str()),
                                 tmp_output, configs) &&
      tasm::UnitHandler::Process(tasm::kPropertyIDFlexBasis,
                                 lepus::Value(flex_props[2].c_str()),
                                 tmp_output, configs)) {
    for (auto i : tmp_output) {
      output.emplace(i);
    }
    return true;
  } else {
    if (!UnitHandler::CSSWarning(
            false, configs.enable_css_strict_mode, TYPE_UNSUPPORTED,
            CSSProperty::GetPropertyName(kPropertyIDFlex).c_str(),
            str.c_str())) {
      return false;
    }
  }

  return true;
}

HANDLER_REGISTER_IMPL() {
  // AUTO INSERT, DON'T CHANGE IT!
  array[kPropertyIDFlex] = &Handle;
  // AUTO INSERT END, DON'T CHANGE IT!
}

}  // namespace FlexHandler
}  // namespace tasm
}  // namespace lynx
