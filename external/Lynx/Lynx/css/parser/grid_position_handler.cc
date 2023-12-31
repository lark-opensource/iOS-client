// Copyright 2021 The Lynx Authors. All rights reserved.
#include "css/parser/grid_position_handler.h"

#include <string>

#include "base/string/string_utils.h"
#include "css/unit_handler.h"
#include "lepus/string_util.h"

namespace lynx {
namespace tasm {

namespace GridPositionHandler {
constexpr int32_t kAutoValue = 0;
constexpr const char* kAuto = "auto";
// "span"
constexpr int32_t kSpanStrSize = 4;
constexpr const char* kSpan = "span";

HANDLER_IMPL() {
  if (!input.IsString()) {
    return false;
  }

  std::string str = input.String()->c_str();
  if (str.find(kAuto) != std::string::npos) {
    output[key] = CSSValue(lepus::Value(kAutoValue), CSSValuePattern::NUMBER);
    return true;
  }

  std::string::size_type span_pos = str.find(kSpan);
  if (span_pos != std::string::npos) {
    lepus::Value value =
        lepus::Value(atoi(str.substr(span_pos + kSpanStrSize).c_str()));
    if (key == kPropertyIDGridColumnStart || key == kPropertyIDGridColumnEnd) {
      UnitHandler::Process(kPropertyIDGridColumnSpan, value, output, configs);
    } else {
      UnitHandler::Process(kPropertyIDGridRowSpan, value, output, configs);
    }
  } else {
    output[key] =
        CSSValue(lepus::Value(atoi(str.c_str())), CSSValuePattern::NUMBER);
  }
  return true;
}

HANDLER_REGISTER_IMPL() {
  array[kPropertyIDGridColumnStart] = &Handle;
  array[kPropertyIDGridColumnEnd] = &Handle;
  array[kPropertyIDGridRowStart] = &Handle;
  array[kPropertyIDGridRowEnd] = &Handle;
}

}  // namespace GridPositionHandler
}  // namespace tasm
}  // namespace lynx
