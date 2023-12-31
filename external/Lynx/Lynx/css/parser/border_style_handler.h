// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_PARSER_BORDER_STYLE_HANDLER_H_
#define LYNX_CSS_PARSER_BORDER_STYLE_HANDLER_H_

#include <string>

#include "css/parser/handler_defines.h"

namespace lynx {
namespace tasm {
namespace BorderStyleHandler {

bool ToBorderStyleType(const std::string& str,
                       starlight::BorderStyleType& result);

HANDLER_REGISTER_DECLARE();

}  // namespace BorderStyleHandler
}  // namespace tasm

}  // namespace lynx

#endif  // LYNX_CSS_PARSER_BORDER_STYLE_HANDLER_H_
