// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_CSS_PARSER_TOKEN_H_
#define LYNX_CSS_CSS_PARSER_TOKEN_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "base/base_export.h"
#include "css/css_property.h"
#include "css/css_sheet.h"
#include "css/css_value.h"
#include "css/unit_handler.h"
#include "lepus/value-inl.h"
#include "tasm/compile_options.h"

#ifdef BUILD_LEPUS  // BUILD_LEPUS macro is defined by buildlepus package.
#include "lepus/json_parser.h"
#include "third_party/rapidjson/document.h"
#endif

namespace lynx {
namespace tasm {

class CSSParseToken {
 public:
#ifdef BUILD_LEPUS
  CSSParseToken(const rapidjson::Value& style, std::string& rule,
                const std::string& path,
                const rapidjson::Value& style_variables,
                const CompileOptions& compile_options);
#endif

  CSSParseToken(const CSSParserConfigs& parser_configs)
      : parser_configs_(parser_configs) {}
  ~CSSParseToken() {}

  std::vector<std::shared_ptr<CSSSheet>>& GetSheets() { return sheets_; }
  const std::shared_ptr<CSSSheet>& TargetSheet() const {
    return sheets_.back();
  }
  BASE_EXPORT_FOR_DEVTOOL const StyleMap& GetAttribute();
  const CSSVariableMap& GetStyleVariables() { return style_variables; }
  void SetAttribute(CSSPropertyID id, const CSSValue& value) {
    attributes_[id] = value;
  }
  void SetAttribute(StyleMap& attributes) { attributes_ = attributes; }

  BASE_EXPORT_FOR_DEVTOOL const RawParsedStyleMap& GetRawParsedAttribute();

  static void SplitRules(const std::string& str, const std::string& pattern,
                         std::vector<std::string>& des);
  bool IsPseudoStyleToken() const;
  bool IsGlobalPseudoStyleToken() const;
  bool IsCascadeSelectorStyleToken() const;
  int GetStyleTokenType() const;
  void MarkAsTouchPseudoToken();
  bool IsTouchPseudoToken() const;

 private:
  // for serialize/desrialize
  friend class TemplateBinaryWriter;
  friend class TemplateBinaryReader;
  friend class TemplateBinaryReaderSSR;
  friend class LynxBinaryBaseCSSReader;

  std::vector<std::shared_ptr<CSSSheet>> sheets_;
  StyleMap attributes_;
  RawStyleMap raw_attributes_;
  RawParsedStyleMap raw_parsed_attributes_;
  CSSVariableMap style_variables;
  const CSSParserConfigs parser_configs_;
  bool is_touch_pseudo_{false};

#ifdef BUILD_LEPUS
  void ParseAttributes(const rapidjson::Value& value);
  void ParseStyleVariables(const rapidjson::Value& value);
  std::string path_;

  void SplitSelector(std::string& select);
  void HandlePseudoSelector(std::string& select);
  const CompileOptions compile_options_;
#endif

  std::shared_ptr<CSSSheet> CreatSheet(const std::string& name,
                                       std::shared_ptr<CSSSheet> parent_sheet);
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_PARSER_TOKEN_H_
