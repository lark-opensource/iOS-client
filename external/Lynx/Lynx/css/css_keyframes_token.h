// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_CSS_KEYFRAMES_TOKEN_H_
#define LYNX_CSS_CSS_KEYFRAMES_TOKEN_H_

#include <memory>
#include <string>
#include <unordered_map>

#include "base/debug/lynx_assert.h"
#include "base/string/string_utils.h"
#include "css/css_parser_token.h"
#include "css/unit_handler.h"
#include "tasm/compile_options.h"

namespace lynx {

namespace starlight {
class CSSStyleUtils;
}  // namespace starlight

namespace tasm {

#ifdef BUILD_LEPUS
typedef std::unordered_map<std::string, std::shared_ptr<StyleMap>>
    CSSKeyframesMap;
typedef std::unordered_map<std::string, std::shared_ptr<RawStyleMap>>
    CSSRawKeyframesMap;
#else
typedef std::unordered_map<float, std::shared_ptr<StyleMap>> CSSKeyframesMap;
typedef std::unordered_map<float, std::shared_ptr<RawStyleMap>>
    CSSRawKeyframesMap;
#endif

class CSSKeyframesToken {
 public:
#ifdef BUILD_LEPUS
  CSSKeyframesToken(const rapidjson::Value& value, const std::string& file,
                    const CompileOptions& compile_options);
  static bool IsCSSKeyframesToken(const rapidjson::Value& value);
  static std::string GetCSSKeyframesTokenName(const rapidjson::Value& value);
#else
  CSSKeyframesToken(const CSSParserConfigs& parser_configs)
      : parser_configs_(parser_configs) {}
#endif
  ~CSSKeyframesToken() {}

  void SetKeyframeStyles(CSSKeyframesMap style) { styles_ = style; }
  void SetRawKeyframeStyles(CSSRawKeyframesMap raw_style) {
    raw_styles_ = raw_style;
  }

  static float ParseKeyStr(std::string key_text,
                           bool enableCSSStrictMode = false) {
    float key = 0;
    if (key_text == "from") {
      key = 0;
    } else if (key_text == "to") {
      key = 1;
    } else {
      key = atoi(key_text.c_str()) / 100.0;
    }
    if (key > 1 || key < 0) {
      UnitHandler::CSSWarning(false, enableCSSStrictMode,
                              "key frames must >=0 && <=0. error input:%s",
                              key_text.c_str());
      return 0;
    }
    return key;
  }

  CSSKeyframesMap& GetKeyframes() {
    if (!raw_styles_.empty()) {
      for (auto keyframe = raw_styles_.begin(); keyframe != raw_styles_.end();
           keyframe++) {
        auto key = keyframe->first;
        StyleMap* temp_map = styles_[key].get();
        if (temp_map == nullptr) {
          continue;
        }
        auto& raw_style_map = keyframe->second;
        for (auto style : *raw_style_map) {
          UnitHandler::Process(style.first, style.second, *temp_map,
                               parser_configs_);
        }
      }
      raw_styles_.clear();
    }
    return styles_;
  }

  bool HasKeyframesResolved() const { return has_key_frames_resolved_; }

  void MarkKeyframesHasBeenResolved() { has_key_frames_resolved_ = true; }

 private:
  // for decode css.
  friend class LynxBinaryBaseCSSReader;

  CSSKeyframesMap styles_;
  CSSRawKeyframesMap raw_styles_;
  const CSSParserConfigs parser_configs_;
  // indicated the keyframes has been resolved or not
  bool has_key_frames_resolved_{false};

#ifdef BUILD_LEPUS
  void ParseName(const rapidjson::Value& value);
  void ParseStyles(const rapidjson::Value& value);
  void ConvertToCSSAttrsMap(const rapidjson::Value& value, StyleMap& css_map);
  std::string file_;
  const CompileOptions compile_options_;
#endif
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_KEYFRAMES_TOKEN_H_
