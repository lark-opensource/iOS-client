// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_UNIT_HANDLER_H_
#define LYNX_CSS_UNIT_HANDLER_H_

#include <array>
#include <cctype>
#include <cmath>
#include <string>

#include "base/base_export.h"
#include "base/debug/lynx_assert.h"
#include "css/css_debug_msg.h"
#include "css/css_property.h"
#include "css/parser/css_parser_configs.h"
#include "css/parser/handler_defines.h"

namespace lynx {
namespace tasm {

class UnitHandler {
 public:
  // only for NoDestructor.
  UnitHandler();

  static bool CSSWarning(bool expression, bool enableCSSStrictMode,
                         const char* fmt...);

  static void CSSUnreachable(bool enableCSSStrictMode, const char* fmt...);

  BASE_EXPORT_FOR_DEVTOOL static bool Process(const CSSPropertyID key,
                                              const lepus::Value& input,
                                              StyleMap& output,
                                              const CSSParserConfigs& configs);
  static StyleMap Process(const CSSPropertyID key, const lepus::Value& input,
                          const CSSParserConfigs& configs);

 private:
  static UnitHandler& Instance();

  std::array<pHandlerFunc, kCSSPropertyCount> interceptors_;
};
}  // namespace tasm

}  // namespace lynx

#endif  // LYNX_CSS_UNIT_HANDLER_H_
