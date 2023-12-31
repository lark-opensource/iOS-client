// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_PARSER_ANIMATION_PROPERTY_HANDLER_H_
#define LYNX_CSS_PARSER_ANIMATION_PROPERTY_HANDLER_H_

#include "css/parser/handler_defines.h"

namespace lynx {
namespace tasm {
namespace AnimationPropertyHandler {

HANDLER_REGISTER_DECLARE();

bool Process(const lepus::Value& input, CSSValue& css_value,
             const CSSParserConfigs& configs);

}  // namespace AnimationPropertyHandler
}  // namespace tasm

}  // namespace lynx

#endif  // LYNX_CSS_PARSER_ANIMATION_PROPERTY_HANDLER_H_
