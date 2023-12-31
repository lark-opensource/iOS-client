// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_CSS_FONT_FACE_TOKEN_H_
#define LYNX_CSS_CSS_FONT_FACE_TOKEN_H_

#include <string>
#include <unordered_map>

#include "css/css_parser_token.h"

#define CSS_BINARY_FONT_FACE_TYPE 0x01

namespace lynx {
namespace tasm {

typedef std::unordered_map<std::string, std::string> CSSFontFaceAttrsMap;

class CSSFontFaceToken {
 public:
#ifdef BUILD_LEPUS
  CSSFontFaceToken(const rapidjson::Value& value, const std::string& file);
  static bool IsCSSFontFaceToken(const rapidjson::Value& value);
  static std::string GetCSSFontFaceTokenKey(const rapidjson::Value& value);
#endif
  ~CSSFontFaceToken() {}
  void addAttribute(const std::string& name, const std::string& val);
  const std::string& getKey() const { return font_family_; }
  const CSSFontFaceAttrsMap& getAttrMap() const { return attrs_; }

 private:
  // for serialize/desrialize
  friend class TemplateBinaryWriter;
  friend class TemplateBinaryReader;
  friend class TemplateBinaryReaderSSR;
  friend class LynxBinaryBaseCSSReader;

  std::string font_family_;
  CSSFontFaceAttrsMap attrs_;

  CSSFontFaceToken() {}

  void parseSrc();
#ifdef BUILD_LEPUS
  void ParseStyle(const rapidjson::Value& value);
  std::string file_;
#endif
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_FONT_FACE_TOKEN_H_
