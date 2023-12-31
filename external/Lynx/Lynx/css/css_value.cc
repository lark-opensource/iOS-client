// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/css_value.h"

#include "lepus/json_parser.h"

namespace lynx {
namespace tasm {

std::string CSSValue::AsJsonString() const {
  return lepus::lepusValueToString(value_);
}

bool CSSValue::AsBool() const { return value_.Bool(); }

}  // namespace tasm
}  // namespace lynx
