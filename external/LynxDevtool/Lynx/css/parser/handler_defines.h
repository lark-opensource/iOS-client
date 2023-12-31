// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_PARSER_HANDLER_DEFINES_H_
#define LYNX_CSS_PARSER_HANDLER_DEFINES_H_

#include <array>

#include "css/css_property.h"
#include "css/parser/css_parser_configs.h"
#include "lepus/value.h"

#define HANDLER_REGISTER_DECLARE() \
  void Register(std::array<pHandlerFunc, kCSSPropertyCount> &array)

#define HANDLER_REGISTER_IMPL() \
  void Register(std::array<pHandlerFunc, kCSSPropertyCount> &array)

#define HANDLER_IMPL()                                                        \
  bool Handle(CSSPropertyID key, const lepus::Value &input, StyleMap &output, \
              const CSSParserConfigs &configs)

namespace lynx {
namespace tasm {

using pHandlerFunc = bool (*)(CSSPropertyID key, const lepus::Value &input,
                              StyleMap &output,
                              const CSSParserConfigs &configs);
}  // namespace tasm

}  // namespace lynx

#endif  // LYNX_CSS_PARSER_HANDLER_DEFINES_H_
