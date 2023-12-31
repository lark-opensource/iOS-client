// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_CSS_PARSER_H_
#define LYNX_CSS_CSS_PARSER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "css/css_parser_token.h"
#include "css/ng/selector/lynx_css_parser_selector.h"
#include "css/shared_css_fragment.h"
#include "tasm/compile_options.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace tasm {

class CSSParser {
 public:
  CSSParser(const CompileOptions &compile_options);

  bool Parse(const rapidjson::Value &value);

  bool ParseCSSForFiber(const rapidjson::Value &css_map,
                        const rapidjson::Value &css_source);

  ~CSSParser() {}

  static void MergeCSSParseToken(std::shared_ptr<CSSParseToken> &originToken,
                                 std::shared_ptr<CSSParseToken> &newToken);

  // Parse result
  const std::unordered_map<std::string, SharedCSSFragment *> &fragments() {
    return fragments_;
  }

 private:
  // Parse ttss file
  bool ParseOtherTTSS(const rapidjson::Value &value);
  void ParseAppTTSS(const rapidjson::Value &value);

  void ParseCSS(const rapidjson::Value &value, const std::string &path);
  void ParseCSS(const rapidjson::Value &value, const std::string &path,
                const std::vector<int32_t> &dependent_css_list,
                int32_t fragment_id);
  void ParseCSSTokens(CSSParserTokenMap &css, const rapidjson::Value &value,
                      const std::string &path);

  void ParseCSSTokensNew(
      std::vector<LynxCSSSelectorTuple> &selector_tuple_lists,
      CSSParserTokenMap &css, const rapidjson::Value &value,
      const std::string &path);

  void ParseCSSKeyframes(CSSKeyframesTokenMap &keyframes,
                         const rapidjson::Value &value,
                         const std::string &path);
  void ParseCSSFontFace(CSSFontFaceTokenMap &fontfaces,
                        const rapidjson::Value &value, const std::string &path);

  // For fiber
  void ParseCSS(const rapidjson::Value &map, const rapidjson::Value &id,
                const rapidjson::Value &source);

  std::vector<std::unique_ptr<SharedCSSFragment>> shared_css_fragments_;

  std::unordered_map<std::string, SharedCSSFragment *> fragments_;
  const CompileOptions &compile_options_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_PARSER_H_
