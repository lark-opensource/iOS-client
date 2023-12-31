// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_CSS_STYLE_UTILS_H_
#define LYNX_STARLIGHT_STYLE_CSS_STYLE_UTILS_H_

#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "css/css_fragment.h"
#include "css/css_property.h"
#include "css/css_value.h"
#include "lepus/array.h"
#include "starlight/style/css_type.h"
#include "starlight/types/layout_unit.h"

#if !BUILD_LEPUS
#include "css/css_font_face_token.h"
#include "css/css_keyframes_token.h"
#include "css/parser/css_parser_configs.h"
#include "starlight/style/shadow_data.h"
#include "tasm/react/painting_context.h"
#endif

namespace lynx {
namespace tasm {
class LayoutContext;
class LynxEnvConfig;
}  // namespace tasm
namespace starlight {

struct AnimationData;
struct TimingFunctionData;
struct TransformRawData;
struct TransitionData;
struct FilterData;

class CssMeasureContext;
class NLength;

class CSSStyleUtils {
 public:
#if !BUILD_LEPUS
  static std::pair<NLength, bool> ToLength(
      const tasm::CSSValue& value, const CssMeasureContext& context,
      const tasm::CSSParserConfigs& configs, bool is_font_relevant = false);

  static std::optional<float> ResolveFontSize(
      const tasm::CSSValue& value, const tasm::LynxEnvConfig& config,
      const starlight::LayoutUnit& vw_base,
      const starlight::LayoutUnit& vh_base, double cur_node_font_size,
      double root_node_font_size, const tasm::CSSParserConfigs& configs);

  static float RoundValueToPixelGrid(const float value);

  // Only air element is using this method now. After air element completes the
  // optimization that flush keyframes by names, this method can be removed.
  static lepus::Value ResolveCSSKeyframes(
      const tasm::CSSKeyframesTokenMap& frames,
      const CssMeasureContext& context, const tasm::CSSParserConfigs& configs);

  //  The first parameter names can be string type or array type of lepus value
  static lepus::Value ResolveCSSKeyframesByNames(
      const lepus::Value& names, const tasm::CSSKeyframesTokenMap& frames,
      const CssMeasureContext& context, const tasm::CSSParserConfigs& configs);

  static bool ComputeBoolStyle(const tasm::CSSValue& value, const bool reset,
                               bool& dest, const bool default_value,
                               const char* msg,
                               const tasm::CSSParserConfigs& configs);
  static bool ComputeFloatStyle(const tasm::CSSValue& value, const bool reset,
                                float& dest, const float default_value,
                                const char* msg,
                                const tasm::CSSParserConfigs& configs);

  static bool ComputeIntStyle(const tasm::CSSValue& value, const bool reset,
                              int& dest, const int default_value,
                              const char* msg,
                              const tasm::CSSParserConfigs& configs);
  static bool ComputeLengthStyle(const tasm::CSSValue& value, const bool reset,
                                 const CssMeasureContext& context,
                                 NLength& dest, const NLength& default_value,
                                 const tasm::CSSParserConfigs& configs);
  static bool ComputeLengthArrayStyle(const tasm::CSSValue& value,
                                      const bool reset,
                                      const CssMeasureContext& context,
                                      std::vector<NLength>& dest,
                                      const std::vector<NLength>& default_value,
                                      const char* msg,
                                      const tasm::CSSParserConfigs& configs);
  template <typename T>
  static bool ComputeEnumStyle(const tasm::CSSValue& value, bool reset, T& dest,
                               const T default_value, const char* msg,
                               const tasm::CSSParserConfigs& configs) {
    auto old_value = dest;
    if (reset) {
      dest = default_value;
    } else {
      if (!tasm::UnitHandler::CSSWarning(value.IsEnum(),
                                         configs.enable_css_strict_mode, msg)) {
        return false;
      }
      dest = (T)value.GetValue().Number();
    }
    return old_value != dest;
  }

  template <typename T>
  static inline void PrepareOptional(std::optional<T>& optional) {
    if (!optional) {
      optional = T();
    }
  }

  template <typename T>
  static inline void PrepareOptional(std::optional<T>& optional,
                                     bool css_align_with_legacy_w3c) {
    if (!optional) {
      optional = T(css_align_with_legacy_w3c);
    }
  }

  static bool CalculateLength(const tasm::CSSValue& value, float& result,
                              const CssMeasureContext& context,
                              const tasm::CSSParserConfigs& configs);

  static void ConvertCSSValueToNumber(const tasm::CSSValue& value,
                                      float& result, PlatformLengthUnit& unit,
                                      const CssMeasureContext& context,
                                      const tasm::CSSParserConfigs& configs);

  static void ConvertNLengthToNumber(const NLength& length, float& result,
                                     PlatformLengthUnit& unit);

  static bool ComputeUIntStyle(const tasm::CSSValue& value, const bool reset,
                               unsigned int& dest,
                               const unsigned int default_value,
                               const char* msg,
                               const tasm::CSSParserConfigs& configs);
  static bool ComputeShadowStyle(const tasm::CSSValue& value, const bool reset,
                                 std::optional<std::vector<ShadowData>>& shadow,
                                 const CssMeasureContext& context,
                                 const tasm::CSSParserConfigs& configs);

  static bool ComputeTransform(
      const tasm::CSSValue& value, bool reset,
      std::optional<std::vector<TransformRawData>>& raw,
      const CssMeasureContext& context, const tasm::CSSParserConfigs& configs);

  static lepus_value TransformToLepus(
      std::optional<std::vector<TransformRawData>> items);

  static bool ComputeFilter(const tasm::CSSValue& value, bool reset,
                            std::optional<FilterData>& filter,
                            const CssMeasureContext,
                            const tasm::CSSParserConfigs& configs);

  static lepus_value FilterToLepus(std::optional<FilterData> filter);

  static bool ComputeStringStyle(const tasm::CSSValue& value, const bool reset,
                                 lepus::String& dest,
                                 const lepus::String& default_value,
                                 const char* msg,
                                 const tasm::CSSParserConfigs& configs);
  static bool ComputeTimingFunction(const lepus::Value& value, const bool reset,
                                    TimingFunctionData& timing_function,
                                    const tasm::CSSParserConfigs& configs);
  static bool ComputeLongStyle(const tasm::CSSValue& value, const bool reset,
                               long& dest, const long default_value,
                               const char* msg,
                               const tasm::CSSParserConfigs& configs);

  template <typename T, typename F0, typename F1>
  static bool SetAnimationProperty(std::optional<std::vector<T>>& anim,
                                   const tasm::CSSValue& value,
                                   F0 const& reset_func, F1 const& compute_func,
                                   const bool reset,
                                   const tasm::CSSParserConfigs& configs) {
    CSSStyleUtils::PrepareOptional(anim);
    if (reset) {
      for (auto& it : *anim) {
        reset_func(it);
      }
      if (anim->empty()) {
        anim->push_back(T());
      }
      return true;
    } else {
      if (anim->empty()) {
        anim->push_back(T());
      }
      if (!tasm::UnitHandler::CSSWarning(
              value.IsEnum() || value.IsNumber() || value.IsString() ||
                  value.IsArray(),
              configs.enable_css_strict_mode,
              "AnimationProperty CSSValue must be : enum, number, "
              "string, array!")) {
        return false;
      }
      bool changed = false;
      if (value.IsArray()) {
        auto arr = value.GetValue().Array();
        for (size_t i = 0; i < arr->size(); i++) {
          if (anim->size() < i + 1) {
            anim->push_back(T());
          }
          changed |= compute_func(arr->get(i), (*anim)[i], reset);
        }
      } else {
        changed = compute_func(value.GetValue(), (*anim).front(), reset);
      }
      return changed;
    }
  }

  static bool ComputeHeroAnimation(const tasm::CSSValue& value,
                                   const bool reset,
                                   std::optional<AnimationData>& anim,
                                   const char* msg,
                                   const tasm::CSSParserConfigs& configs);
  static bool ComputeAnimation(const lepus::Value& value, AnimationData& anim,
                               const char* msg,
                               const tasm::CSSParserConfigs& configs);
  static lepus_value AnimationDataToLepus(AnimationData& anim);

  static std::shared_ptr<tasm::StyleMap> ProcessCSSAttrsMap(
      const lepus::Value& value, const tasm::CSSParserConfigs& configs);
  static void UpdateCSSKeyframes(tasm::CSSKeyframesTokenMap& keyframes_map,
                                 const std::string& name,
                                 const lepus::Value& keyframes,
                                 const tasm::CSSParserConfigs& configs);
  static float GetBorderWidthFromLengthToFloat(const NLength& value);

  static void AddLengthToArray(const base::scoped_refptr<lepus::CArray>& array,
                               const NLength& pos);
  static void ComputeBasicShapeEllipse(
      const base::scoped_refptr<lepus::CArray>& raw, bool reset,
      base::scoped_refptr<lepus::CArray>& out, const CssMeasureContext& context,
      const tasm::CSSParserConfigs& configs);
  static void ComputeBasicShapeCircle(
      const base::scoped_refptr<lepus::CArray>& raw, bool reset,
      base::scoped_refptr<lepus::CArray>& out, const CssMeasureContext& context,
      const tasm::CSSParserConfigs& configs);
  static void ComputeBasicShapePath(
      const base::scoped_refptr<lepus::CArray>& raw, bool reset,
      base::scoped_refptr<lepus::CArray>& out);
  static void ComputeSuperEllipse(const base::scoped_refptr<lepus::CArray>& raw,
                                  bool reset,
                                  base::scoped_refptr<lepus::CArray>& out,
                                  const CssMeasureContext& context,
                                  const tasm::CSSParserConfigs& configs);
  static void ComputeBasicShapeInset(
      const base::scoped_refptr<lepus::CArray>& raw, bool reset,
      const base::scoped_refptr<lepus::CArray>& dst,
      const CssMeasureContext& context, const tasm::CSSParserConfigs& configs);

#endif  // !BUILD_LEPUS

  static bool IsBorderLengthLegal(std::string value);

 private:
#if !BUILD_LEPUS
  static lepus::Value ResolveCSSKeyframesStyle(
      tasm::StyleMap* attrs, const CssMeasureContext& context,
      const tasm::CSSParserConfigs& configs);
  static lepus::Value ResolveCSSKeyframesToken(
      tasm::CSSKeyframesToken* token, const CssMeasureContext& context,
      const tasm::CSSParserConfigs& configs);
#endif  // !BUILD_LEPUS
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_CSS_STYLE_UTILS_H_
