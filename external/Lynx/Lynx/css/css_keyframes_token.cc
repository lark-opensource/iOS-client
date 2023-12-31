// Copyright 2019 The Lynx Authors. All rights reserved.

#include "css/css_keyframes_token.h"

#include <utility>

#include "css/unit_handler.h"
#include "lepus/exception.h"
#include "tasm/config.h"

#define TYPE "type"
#define KEYFRAMES_RULE "KeyframesRule"
#define NAME "name"
#define STYLES "styles"
#define KEYTEXT "keyText"
#define STYLE "style"

/*
 *      {
 *           "type": "KeyframesRule",
 *           "name": "mymove",
 *           "styles": [
 *               {
 *                   "keyText": "from",
 *                   "style": [
 *                       {
 *                           "name": "top",
 *                           "value": "0px"
 *                       }
 *                   ]
 *               },
 *              {
 *                   "keyText": "to",
 *                   "style": [
 *                       {
 *                           "name": "top",
 *                           "value": "200px"
 *                       }
 *                   ]
 *               }
 *           ]
 *       }
 */
// parse for mini token

namespace lynx {
namespace tasm {

#ifdef BUILD_LEPUS

CSSKeyframesToken::CSSKeyframesToken(const rapidjson::Value& value,
                                     const std::string& file,
                                     const CompileOptions& compile_options)
    : file_(file), compile_options_(compile_options) {
  if (value.HasMember(TYPE) &&
      std::string(KEYFRAMES_RULE).compare(value[TYPE].GetString()) == 0) {
    if (value.HasMember(STYLES)) {
      ParseStyles(value[STYLES]);
    }
  }
}

std::string CSSKeyframesToken::GetCSSKeyframesTokenName(
    const rapidjson::Value& value) {
  if (value.HasMember(TYPE) &&
      std::string(KEYFRAMES_RULE).compare(value[TYPE].GetString()) == 0) {
    if (value.HasMember(NAME)) {
      return value[NAME]["value"].GetString();
    }
  }
  return "";
}

bool CSSKeyframesToken::IsCSSKeyframesToken(const rapidjson::Value& value) {
  return value.HasMember(TYPE) &&
         std::string(KEYFRAMES_RULE).compare(value[TYPE].GetString()) == 0;
}

void CSSKeyframesToken::ParseStyles(const rapidjson::Value& value) {
  for (rapid_value::ConstValueIterator itr = value.Begin(); itr != value.End();
       ++itr) {
    std::string key_text = (*itr)[KEYTEXT]["value"].GetString();
    std::shared_ptr<StyleMap> css_map(new StyleMap());
    ConvertToCSSAttrsMap((*itr)[STYLE], *css_map);
    styles_.insert(
        std::pair<std::string, std::shared_ptr<StyleMap>>(key_text, css_map));
  }
}

void CSSKeyframesToken::ConvertToCSSAttrsMap(const rapidjson::Value& value,
                                             StyleMap& css_map) {
  auto iterate = [this, &css_map](const rapidjson::Value& name,
                                  const rapidjson::Value& value) {
    CSSPropertyID id = CSSProperty::GetPropertyID(name.GetString());
    if (!CSSProperty::IsPropertyValid(id)) {
      std::stringstream error;
      error << "Error In CSSParse: \"" << name.GetString()
            << "\" is not supported now !";

      const rapidjson::Value& loc = value[rapidjson::Value("keyLoc")];
      throw lepus::ParseException(error.str().c_str(), file_.c_str(), loc);
    }
    if (Config::IsHigherOrEqual(compile_options_.target_sdk_version_,
                                FEATURE_CSS_VALUE_VERSION) &&
        compile_options_.enable_css_parser_) {
      auto configs = CSSParserConfigs::GetCSSParserConfigsByComplierOptions(
          compile_options_);
      UnitHandler::Process(id, lepus::jsonValueTolepusValue(value["value"]),
                           css_map, configs);
    } else {
      css_map.insert(
          {id, CSSValue(lepus::jsonValueTolepusValue(value["value"]))});
    }
  };
  if (value.IsObject()) {
    for (auto itr = value.MemberBegin(); itr != value.MemberEnd(); ++itr) {
      iterate(itr->name, itr->value);
    }
  } else if (value.IsArray()) {
    for (const auto& attribute : value.GetArray()) {
      iterate(attribute["name"], attribute);
    }
  }
}

#endif

}  // namespace tasm
}  // namespace lynx
