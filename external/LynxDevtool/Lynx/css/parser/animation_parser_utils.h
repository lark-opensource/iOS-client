// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_PARSER_ANIMATION_PARSER_UTILS_H_
#define LYNX_CSS_PARSER_ANIMATION_PARSER_UTILS_H_

#include <string>

#include "css/parser/handler_defines.h"

namespace lynx {
namespace tasm {
class AnimationParserUtils {
  using ParserFunc = lepus::Value (*)(const std::string& str,
                                      const CSSParserConfigs& configs);

 public:
  static bool ParserLepusStringToCSSValue(CSSPropertyID key,
                                          const lepus::Value& input,
                                          StyleMap& output,
                                          const CSSParserConfigs& configs,
                                          ParserFunc parser,
                                          CSSValuePattern pattern);
};
}  // namespace tasm

}  // namespace lynx

#endif  // LYNX_CSS_PARSER_ANIMATION_PARSER_UTILS_H_
