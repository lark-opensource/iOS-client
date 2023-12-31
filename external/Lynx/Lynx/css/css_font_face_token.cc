// Copyright 2019 The Lynx Authors. All rights reserved.

#include "css/css_font_face_token.h"

#define TYPE "type"
#define FONTFACE_RULE "FontFaceRule"
#define STYLE "style"
#define FONT_FAMILY "font-family"
#define SRC "src"
#define LOCAL_PREFIX "local("
#define URL_PREFIX "url("
#define SURFIX ")"

/*
 * {
 *  "type":"FontFaceRule",
 *  "style": [
 *    {
 *      "name": "font-family",
 *      "value": "\"Bitstream Vera Serif Bold\"",
 *      "keyLoc": {
 *        "column": 12,
 *        "line": 7
 *      },
 *      "valLoc": {
 *        "column": 19,
 *        "line": 7
 *      },
 *    }
 *  ]
 * }
 */
// parse for mini token

namespace lynx {
namespace tasm {

inline static std::string _innerTrTrim(const std::string& str) {
  static const std::string chs = "' \t\v\r\n\"";
  size_t first = str.find_first_not_of(chs);
  size_t last = str.find_last_not_of(chs);
  return str.substr(first, (last - first + 1));
}

void CSSFontFaceToken::addAttribute(const std::string& name,
                                    const std::string& val) {
  std::string newName = _innerTrTrim(name);
  std::string newVal = _innerTrTrim(val);
  if (name == FONT_FAMILY) {
    font_family_ = newVal;
  }
  attrs_[newName] = newVal;
}

#ifdef BUILD_LEPUS

CSSFontFaceToken::CSSFontFaceToken(const rapidjson::Value& value,
                                   const std::string& file)
    : file_(file) {
  font_family_ = GetCSSFontFaceTokenKey(value);
  if (font_family_.empty()) {
    return;
  }
  const rapidjson::Value& style_value = value[STYLE];
  auto iterate = [this](const rapidjson::Value& name,
                        const rapidjson::Value& value) {
    attrs_[name.GetString()] = value["value"].GetString();
  };

  if (style_value.IsObject()) {
    for (auto itr = style_value.MemberBegin(); itr != style_value.MemberEnd();
         ++itr) {
      iterate(itr->name, itr->value);
    }
  } else if (style_value.IsArray()) {
    for (const auto& value : style_value.GetArray()) {
      iterate(value["name"], value);
    }
  }
}

bool CSSFontFaceToken::IsCSSFontFaceToken(const rapidjson::Value& value) {
  return value.HasMember(TYPE) &&
         std::string(FONTFACE_RULE).compare(value[TYPE].GetString()) == 0;
}

std::string CSSFontFaceToken::GetCSSFontFaceTokenKey(
    const rapidjson::Value& value) {
  constexpr static const char* kName = "name";
  constexpr static const char* kValue = "value";
  if (value.HasMember(TYPE) &&
      std::string(FONTFACE_RULE).compare(value[TYPE].GetString()) == 0) {
    if (value.HasMember(STYLE)) {
      const rapidjson::Value& style_value = value[STYLE];
      if (style_value.IsObject() && style_value.HasMember(FONT_FAMILY)) {
        return style_value[FONT_FAMILY][kValue].GetString();
      } else if (style_value.IsArray()) {
        for (const auto& attribute : style_value.GetArray()) {
          if (attribute.IsObject() && attribute.HasMember(kName) &&
              attribute.HasMember(kValue)) {
            if (std::string(FONT_FAMILY)
                    .compare(attribute[kName].GetString()) == 0) {
              return attribute[kValue].GetString();
            }
          }
        }
      }
    }
  }

  return "";
}

#endif

}  // namespace tasm
}  // namespace lynx
