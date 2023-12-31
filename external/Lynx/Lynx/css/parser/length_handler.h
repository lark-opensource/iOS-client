// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_PARSER_LENGTH_HANDLER_H_
#define LYNX_CSS_PARSER_LENGTH_HANDLER_H_

#include "css/parser/handler_defines.h"

namespace lynx {
namespace tasm {
namespace LengthHandler {

HANDLER_REGISTER_DECLARE();
bool Handle(CSSPropertyID key, const lepus::Value &input, StyleMap &output,
            const CSSParserConfigs &configs);
// help parse length css
bool Process(const lepus::Value &input, CSSValue &css_value,
             const CSSParserConfigs &configs);

}  // namespace LengthHandler
}  // namespace tasm

}  // namespace lynx

#endif  // LYNX_CSS_PARSER_LENGTH_HANDLER_H_
