// Copyright 2021 The Lynx Authors. All rights reserved.
#include "css/parser/animation_parser_utils.h"

#include <vector>

#include "base/string/string_utils.h"
#include "lepus/array.h"

namespace lynx {
namespace tasm {

bool AnimationParserUtils::ParserLepusStringToCSSValue(
    CSSPropertyID key, const lepus::Value& input, StyleMap& output,
    const CSSParserConfigs& configs,
    lepus::Value (*parser)(const std::string& str,
                           const CSSParserConfigs& configs),
    CSSValuePattern pattern) {
  auto str = input.String()->str();
  auto itor = remove_if(str.begin(), str.end(), ::isspace);
  str.erase(itor, str.end());
  if (str.find(',') != std::string::npos) {
    std::vector<std::string> result;
    base::SplitString(str, ',', result);
    auto arr = lepus::CArray::Create();
    for (auto& item : result) {
      arr->push_back(parser(item, configs));
    }
    output[key] = CSSValue(lepus::Value(arr), CSSValuePattern::ARRAY);
  } else {
    output[key] = CSSValue(parser(str, configs), pattern);
  }
  return true;
}

}  // namespace tasm
}  // namespace lynx
