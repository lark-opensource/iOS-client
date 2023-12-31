// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_DEFAULT_CSS_STYLE_H_
#define LYNX_STARLIGHT_STYLE_DEFAULT_CSS_STYLE_H_

#include <vector>

#include "base/no_destructor.h"
#include "css/css_color.h"
#include "lepus/array.h"
#include "starlight/style/animation_data.h"
#include "starlight/style/box_data.h"
#include "starlight/style/css_type.h"
#include "starlight/style/flex_data.h"
#include "starlight/style/linear_data.h"
#include "starlight/style/relative_data.h"
#include "starlight/style/shadow_data.h"
#include "starlight/style/transform_origin_data.h"

#define CSS_UNDEFINED 0x7FFFFFF
static constexpr float UNDEFINED = 10E20;

#define DEFAULT_CSS_FUNC(type, name)            \
  (type ? DefaultCSSStyle::W3C_DEFAULT_##name() \
        : DefaultCSSStyle::SL_DEFAULT_##name())

#define DEFAULT_CSS_VALUE(type, name)         \
  (type ? DefaultCSSStyle::W3C_DEFAULT_##name \
        : DefaultCSSStyle::SL_DEFAULT_##name)

namespace lynx {
namespace starlight {

// static const NLength SL_DEFAULT_WIDTH = NLength::MakeAutoNLength();
// static const NLength SL_DEFAULT_HEIGHT = NLength::MakeAutoNLength();
// static const NLength SL_DEFAULT_MIN_WIDTH =
//     NLength::MakeUnitNLength(kDefaultMinSize);
// static const NLength SL_DEFAULT_MAX_WIDTH =
//     NLength::MakeUnitNLength(kDefaultMaxSize);
// static const NLength SL_DEFAULT_MIN_HEIGHT =
//     NLength::MakeUnitNLength(kDefaultMinSize);
// static const NLength SL_DEFAULT_MAX_HEIGHT =
//     NLength::MakeUnitNLength(kDefaultMaxSize);
// static const NLength SL_DEFAULT_FLEX_BASIS = NLength::MakeAutoNLength();
// static const NLength SL_DEFAULT_FOUR_POSITION = NLength::MakeAutoNLength();
// static const NLength SL_DEFAULT_PADDING = NLength::MakeUnitNLength(0.0f);
// static const NLength SL_DEFAULT_MARGIN = NLength::MakeUnitNLength(0.0f);
// static const NLength SL_DEFAULT_BORDER = NLength::MakeUnitNLength(0.0f);
// static const NLength SL_DEFAULT_RADIUS = NLength::MakeUnitNLength(0.0f);
// static lepus::String EMPTY_LEPUS_STRING = lepus::String("");
// static lepus::Value EMPTY_LEPUS_VALUE = lepus::Value();
// static TransformOriginData SL_DEFAULT_TRANSFORM_ORIGIN =
// TransformOriginData(); static AnimationData SL_DEFAULT_ANIMATION =
// AnimationData(); static std::vector<ShadowData> SL_DEFAULT_BOX_SHADOW =
// std::vector<ShadowData>();
struct DefaultCSSStyle {
  static constexpr int SL_DEFAULT_RELATIVE_ID = -1;
  static constexpr int SL_DEFAULT_RELATIVE_ALIGN_TOP = -1;
  static constexpr int SL_DEFAULT_RELATIVE_ALIGN_RIGHT = -1;
  static constexpr int SL_DEFAULT_RELATIVE_ALIGN_BOTTOM = -1;
  static constexpr int SL_DEFAULT_RELATIVE_ALIGN_LEFT = -1;
  static constexpr int SL_DEFAULT_RELATIVE_TOP_OF = -1;
  static constexpr int SL_DEFAULT_RELATIVE_RIGHT_OF = -1;
  static constexpr int SL_DEFAULT_RELATIVE_BOTTOM_OF = -1;
  static constexpr int SL_DEFAULT_RELATIVE_LEFT_OF = -1;
  static constexpr int SL_DEFAULT_TEXT_MAX_LINE = -1;
  static constexpr int SL_DEFAULT_TEXT_MAX_LENGTH = -1;

  static constexpr int32_t SL_DEFAULT_GRID_SPAN = 1;
  static constexpr int32_t SL_DEFAULT_GRID_ITEM_POSITION = 0;

  static constexpr float kDefaultMinSize = 0.f;
  static constexpr float kDefaultMaxSize = static_cast<float>(CSS_UNDEFINED);
  static constexpr float SL_DEFAULT_FLEX_GROW = 0.0f;
  static constexpr float SL_DEFAULT_FLEX_SHRINK = 1.0f;
  static constexpr float SL_DEFAULT_ORDER = 0.0f;
  static constexpr float SL_DEFAULT_LINEAR_WEIGHT_SUM = 0.0f;
  static constexpr float SL_DEFAULT_LINEAR_WEIGHT = 0.0f;
  static constexpr float SL_DEFAULT_ASPECT_RATIO = -1.0f;
  static constexpr float SL_DEFAULT_BORDER_RADIUS = 0.0f;
  static constexpr float SL_DEFAULT_LINE_HEIGHT = -1.0f;
  static constexpr float SL_DEFAULT_LINE_HEIGHT_FACTOR = -1.0f;
  static constexpr float SL_DEFAULT_LETTER_SPACING = -1.0f;
  static constexpr float SL_DEFAULT_LINE_SPACING = -1.0f;
  static constexpr float SL_DEFAULT_FLOAT = 0.0f;
  static constexpr float SL_DEFAULT_OPACITY = 1.0f;
  static constexpr float SL_DEFAULT_FILTER_GRAY = -1.0f;

  static constexpr long SL_DEFAULT_LONG = 0;

  // TODO(liyanbo): move this into css_color.
  static constexpr unsigned int SL_DEFAULT_COLOR = tasm::CSSColor::Transparent;
  static constexpr unsigned int SL_DEFAULT_BORDER_COLOR = tasm::CSSColor::Black;
  static constexpr unsigned int SL_DEFAULT_OUTLINE_COLOR =
      tasm::CSSColor::Black;
  static constexpr unsigned int SL_DEFAULT_SHADOW_COLOR = tasm::CSSColor::Black;
  static constexpr unsigned int SL_DEFAULT_TEXT_COLOR = tasm::CSSColor::Black;
  static constexpr unsigned int SL_DEFAULT_TEXT_BACKGROUND_COLOR =
      tasm::CSSColor::White;

  static constexpr bool SL_DEFAULT_RELATIVE_LAYOUT_ONCE = true;
  static constexpr bool SL_DEFAULT_BOOLEAN = false;

  static constexpr FlexDirectionType SL_DEFAULT_FLEX_DIRECTION =
      FlexDirectionType::kRow;
  static constexpr FlexWrapType SL_DEFAULT_FLEX_WRAP = FlexWrapType::kNowrap;
  static constexpr JustifyContentType SL_DEFAULT_JUSTIFY_CONTENT =
      JustifyContentType::kStretch;
  static constexpr FlexAlignType SL_DEFAULT_ALIGN_ITEMS =
      FlexAlignType::kStretch;
  static constexpr FlexAlignType SL_DEFAULT_ALIGN_SELF = FlexAlignType::kAuto;
  static constexpr AlignContentType SL_DEFAULT_ALIGN_CONTENT =
      AlignContentType::kStretch;
  static constexpr FontWeightType SL_DEFAULT_FONT_WEIGHT =
      FontWeightType::kNormal;
  static constexpr FontStyleType SL_DEFAULT_FONT_STYLE = FontStyleType::kNormal;
  static constexpr TextAlignType SL_DEFAULT_TEXT_ALIGN = TextAlignType::kStart;
  static constexpr TextOverflowType SL_DEFAULT_TEXT_OVERFLOW =
      TextOverflowType::kClip;
  static constexpr DisplayType SL_DEFAULT_DISPLAY = DisplayType::kAuto;
  static constexpr PositionType SL_DEFAULT_POSITION = PositionType::kRelative;
  static constexpr OverflowType SL_DEFAULT_OVERFLOW = OverflowType::kHidden;
  static constexpr DirectionType SL_DEFAULT_DIRECTION = DirectionType::kNormal;
  static constexpr WhiteSpaceType SL_DEFAULT_WHITE_SPACE =
      WhiteSpaceType::kNormal;
  static constexpr WordBreakType SL_DEFAULT_WORD_BREAK = WordBreakType::kNormal;
  static constexpr LinearOrientationType SL_DEFAULT_LINEAR_ORIENTATION =
      LinearOrientationType::kVertical;
  static constexpr LinearLayoutGravityType SL_DEFAULT_LINEAR_LAYOUT_GRAVITY =
      LinearLayoutGravityType::kNone;
  static constexpr LinearGravityType SL_DEFAULT_LINEAR_GRAVITY =
      LinearGravityType::kNone;
  static constexpr LinearCrossGravityType SL_DEFAULT_LINEAR_CROSS_GRAVITY =
      LinearCrossGravityType::kNone;
  static constexpr RelativeCenterType SL_DEFAULT_RELATIVE_CENTER =
      RelativeCenterType::kNone;
  static constexpr BorderStyleType SL_DEFAULT_BORDER_STYLE =
      BorderStyleType::kSolid;
  static constexpr BorderStyleType SL_DEFAULT_OUTLINE_STYLE =
      BorderStyleType::kNone;
  static constexpr VisibilityType SL_DEFAULT_VISIBILITY =
      VisibilityType::kVisible;
  static constexpr VerticalAlignType SL_DEFAULT_VERTICAL_ALIGN =
      VerticalAlignType::kDefault;
  static constexpr BoxSizingType SL_DEFAULT_BOX_SIZING = BoxSizingType::kAuto;
  static constexpr JustifyType SL_DEFAULT_JUSTIFY_SELF = JustifyType::kAuto;
  static constexpr JustifyType SL_DEFAULT_JUSTIFY_ITEMS = JustifyType::kStretch;
  static constexpr GridAutoFlowType SL_DEFAULT_GRID_AUTO_FLOW =
      GridAutoFlowType::kRow;

  static const NLength& SL_DEFAULT_AUTO_LENGTH() {
    static base::NoDestructor<NLength> l{NLength::MakeAutoNLength()};
    return *l;
  }

  static const NLength& SL_DEFAULT_ZEROLENGTH() {
    static base::NoDestructor<NLength> l{NLength::MakeUnitNLength(0.0f)};
    return *l;
  }

  static const NLength SL_DEFAULT_WIDTH() { return SL_DEFAULT_AUTO_LENGTH(); }

  static const NLength SL_DEFAULT_HEIGHT() { return SL_DEFAULT_AUTO_LENGTH(); }

  static const NLength SL_DEFAULT_MIN_WIDTH() {
    static base::NoDestructor<NLength> l{
        NLength::MakeUnitNLength(kDefaultMinSize)};
    return *l;
  }

  static const NLength SL_DEFAULT_MAX_WIDTH() {
    static base::NoDestructor<NLength> l{
        NLength::MakeUnitNLength(kDefaultMaxSize)};
    return *l;
  }

  static const NLength SL_DEFAULT_MIN_HEIGHT() {
    static base::NoDestructor<NLength> l{
        NLength::MakeUnitNLength(kDefaultMinSize)};
    return *l;
  }

  static const NLength SL_DEFAULT_MAX_HEIGHT() {
    static base::NoDestructor<NLength> l{
        NLength::MakeUnitNLength(kDefaultMaxSize)};
    return *l;
  }
  static const NLength SL_DEFAULT_FLEX_BASIS() {
    return SL_DEFAULT_AUTO_LENGTH();
  }

  static const NLength SL_DEFAULT_FOUR_POSITION() {
    return SL_DEFAULT_AUTO_LENGTH();
  }

  static const NLength SL_DEFAULT_PADDING() { return SL_DEFAULT_ZEROLENGTH(); }

  static const NLength SL_DEFAULT_MARGIN() { return SL_DEFAULT_ZEROLENGTH(); }

  static constexpr float SL_DEFAULT_BORDER = 0.f;

  static const NLength SL_DEFAULT_RADIUS() { return SL_DEFAULT_ZEROLENGTH(); }

  static const NLength SL_DEFAULT_GRID_GAP() { return SL_DEFAULT_ZEROLENGTH(); }

  static lepus::String EMPTY_LEPUS_STRING() {
    static base::NoDestructor<lepus::String> l{lepus::String("")};
    return *l;
  }

  static lepus::Value EMPTY_LEPUS_VALUE() {
    static base::NoDestructor<lepus::Value> l{lepus::Value()};
    return *l;
  }

  static TransformOriginData SL_DEFAULT_TRANSFORM_ORIGIN() {
    static base::NoDestructor<TransformOriginData> l{TransformOriginData()};
    return *l;
  }

  static AnimationData SL_DEFAULT_ANIMATION() {
    static base::NoDestructor<AnimationData> l{AnimationData()};
    return *l;
  }

  static std::vector<ShadowData> SL_DEFAULT_BOX_SHADOW() {
    static base::NoDestructor<std::vector<ShadowData>> l{
        std::vector<ShadowData>()};
    return *l;
  }

  static std::vector<NLength> SL_DEFAULT_GRID_AUTO_TRACK() {
    static base::NoDestructor<std::vector<NLength>> l{
        std::vector<NLength>{NLength::MakeAutoNLength()}};
    return *l;
  }

  static std::vector<NLength> SL_DEFAULT_GRID_TRACK() {
    static base::NoDestructor<std::vector<NLength>> l{std::vector<NLength>()};
    return *l;
  }

  static constexpr BorderStyleType W3C_DEFAULT_BORDER_STYLE =
      BorderStyleType::kNone;
  static constexpr float W3C_DEFAULT_BORDER =
      static_cast<float>(BorderWidthType::kMedium);
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_DEFAULT_CSS_STYLE_H_
