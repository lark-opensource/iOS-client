// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_CSS_DECODER_H_
#define LYNX_CSS_CSS_DECODER_H_

#include <string>

#include "css/css_property.h"
#include "css/css_value.h"
#include "starlight/style/css_type.h"

namespace lynx {
namespace tasm {

class CSSDecoder {
 public:
  static std::string CSSValueToString(const lynx::tasm::CSSPropertyID id,
                                      const lynx::tasm::CSSValue& value);
  static std::string CSSValueEnumToString(const lynx::tasm::CSSPropertyID id,
                                          const lynx::tasm::CSSValue& value);

  static std::string CSSValueNumberToString(const lynx::tasm::CSSPropertyID id,
                                            const lynx::tasm::CSSValue& value);

  static std::string CSSValueArrayToString(const lynx::tasm::CSSPropertyID id,
                                           const lynx::tasm::CSSValue& value);

  static std::string ToFlexAlignType(lynx::starlight::FlexAlignType type);

  static std::string ToLengthType(lynx::starlight::LengthValueType type);

  static std::string ToOverflowType(lynx::starlight::OverflowType type);

  static std::string ToTimingFunctionType(
      lynx::starlight::TimingFunctionType type);

  static std::string ToAnimationPropertyType(
      lynx::starlight::AnimationPropertyType type);

  static std::string ToBorderStyleType(lynx::starlight::BorderStyleType type);

  static std::string ToTransformType(lynx::starlight::TransformType type);

  static std::string ToShadowOption(lynx::starlight::ShadowOption option);

  // clang-format off
// AUTO INSERT, DON'T CHANGE IT!
  static std::string ToPositionType(lynx::starlight::PositionType type);

  static std::string ToBoxSizingType(lynx::starlight::BoxSizingType type);

  static std::string ToDisplayType(lynx::starlight::DisplayType type);

  static std::string ToWhiteSpaceType(lynx::starlight::WhiteSpaceType type);

  static std::string ToTextAlignType(lynx::starlight::TextAlignType type);

  static std::string ToTextOverflowType(lynx::starlight::TextOverflowType type);

  static std::string ToFontWeightType(lynx::starlight::FontWeightType type);

  static std::string ToFlexDirectionType(lynx::starlight::FlexDirectionType type);

  static std::string ToFlexWrapType(lynx::starlight::FlexWrapType type);

  static std::string ToAlignContentType(lynx::starlight::AlignContentType type);

  static std::string ToJustifyContentType(lynx::starlight::JustifyContentType type);

  static std::string ToFontStyleType(lynx::starlight::FontStyleType type);

  static std::string ToAnimationDirectionType(lynx::starlight::AnimationDirectionType type);

  static std::string ToAnimationFillModeType(lynx::starlight::AnimationFillModeType type);

  static std::string ToAnimationPlayStateType(lynx::starlight::AnimationPlayStateType type);

  static std::string ToLinearOrientationType(lynx::starlight::LinearOrientationType type);

  static std::string ToLinearGravityType(lynx::starlight::LinearGravityType type);

  static std::string ToLinearLayoutGravityType(lynx::starlight::LinearLayoutGravityType type);

  static std::string ToVisibilityType(lynx::starlight::VisibilityType type);

  static std::string ToWordBreakType(lynx::starlight::WordBreakType type);

  static std::string ToDirectionType(lynx::starlight::DirectionType type);

  static std::string ToRelativeCenterType(lynx::starlight::RelativeCenterType type);

  static std::string ToLinearCrossGravityType(lynx::starlight::LinearCrossGravityType type);

// AUTO INSERT END, DON'T CHANGE IT!
  // clang-format on
  static std::string ToRgbaFromColorValue(const std::string& color_value);

  static std::string ToRgbaFromRgbaValue(const std::string& r,
                                         const std::string& g,
                                         const std::string& b,
                                         const std::string& a);

  static std::string ToPxValue(double px_value);

  static std::string ToJustifyType(lynx::starlight::JustifyType type);
  static std::string ToGridAutoFlowType(lynx::starlight::GridAutoFlowType type);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_DECODER_H_
