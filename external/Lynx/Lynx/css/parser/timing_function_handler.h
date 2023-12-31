// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_PARSER_TIMING_FUNCTION_HANDLER_H_
#define LYNX_CSS_PARSER_TIMING_FUNCTION_HANDLER_H_

#include <string>

#include "css/parser/handler_defines.h"

namespace lynx {
namespace tasm {
namespace TimingFunctionHandler {

HANDLER_REGISTER_DECLARE();
bool IsValidTimingFunction(const std::string& maybe_timing_func);
bool Process(const lepus::Value& input, CSSValue& css_value,
             const CSSParserConfigs& configs);

}  // namespace TimingFunctionHandler
}  // namespace tasm

}  // namespace lynx

#endif  // LYNX_CSS_PARSER_TIMING_FUNCTION_HANDLER_H_
