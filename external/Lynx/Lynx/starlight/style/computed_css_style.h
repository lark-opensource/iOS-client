// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_COMPUTED_CSS_STYLE_H_
#define LYNX_STARLIGHT_STYLE_COMPUTED_CSS_STYLE_H_

#include <errno.h>
#include <stdlib.h>
#include <tasm/config.h>

#include <string>
#include <unordered_map>
#include <vector>

#include "base/ref_counted.h"
#include "base/string/string_utils.h"
#include "css/css_property.h"
#include "starlight/style/animation_data.h"
#include "starlight/style/background_data.h"
#include "starlight/style/box_data.h"
#include "starlight/style/css_style_utils.h"
#include "starlight/style/data_ref.h"
#include "starlight/style/default_css_style.h"
#include "starlight/style/filter_data.h"
#include "starlight/style/flex_data.h"
#include "starlight/style/grid_data.h"
#include "starlight/style/layout_animation_data.h"
#include "starlight/style/linear_data.h"
#include "starlight/style/outline_data.h"
#include "starlight/style/perspective_data.h"
#include "starlight/style/relative_data.h"
#include "starlight/style/shadow_data.h"
#include "starlight/style/surround_data.h"
#include "starlight/style/text_attributes.h"
#include "starlight/style/transform_origin_data.h"
#include "starlight/style/transform_raw_data.h"
#include "starlight/style/transition_data.h"
#include "starlight/types/layout_types.h"
#include "starlight/types/measure_context.h"

namespace lynx {
namespace starlight {
/** CSSStyle存储了所有CSS Property的Specified Value.
 * Specified Value(指定值)是所有CSS属性被设置时指定的值, 包括px, %,
 * auto等和各种枚举属性. 所有的CSS Property被分组*/

class ComputedCSSStyle {
 public:
  ComputedCSSStyle();
  ComputedCSSStyle(const ComputedCSSStyle& o);
  ~ComputedCSSStyle() = default;

  bool SetValue(tasm::CSSPropertyID id, const tasm::CSSValue& value,
                bool reset = false);
  bool DirectionIsReverse(const LayoutConfigs& configs,
                          AttributesMap& attributes) const;
  bool IsRow(const LayoutConfigs& configs, AttributesMap& attributes) const;
  bool IsFlexRow(const LayoutConfigs& configs, AttributesMap& attributes) const;
  bool IsBorderBox(const LayoutConfigs& configs) const;
  double FontSize() const { return length_context_.cur_node_font_size_; }
  bool IsRtl() const { return direction_ == DirectionType::kRtl; }
  bool IsLynxRtl() const { return direction_ == DirectionType::kLynxRtl; }
  bool IsAnyRtl() const { return IsRtl() || IsLynxRtl(); }

  void SetScreenWidth(float screen_width) {
    length_context_.screen_width_ = screen_width;
  }

  bool SetFontScale(float font_scale);

  void SetFontScaleOnlyEffectiveOnSp(bool on_sp) {
    length_context_.font_scale_sp_only_ = on_sp;
  }

  void SetViewportWidth(const LayoutUnit& width) {
    length_context_.viewport_width_ = width;
  }

  void SetViewportHeight(const LayoutUnit& height) {
    length_context_.viewport_height_ = height;
  }

  bool SetFontSize(double cur_node_font_size, double root_node_font_size) {
    if (length_context_.cur_node_font_size_ == cur_node_font_size &&
        length_context_.root_node_font_size_ == root_node_font_size) {
      return false;
    }
    length_context_.cur_node_font_size_ = cur_node_font_size;
    length_context_.root_node_font_size_ = root_node_font_size;
    return true;
  }

  const CssMeasureContext& GetMeasureContext() { return length_context_; }

  void Reset();
  void ResetValue(tasm::CSSPropertyID id);
  void SetOverflowDefaultVisible(bool default_overflow_visible);
  OverflowType GetDefaultOverflowType() const {
    return default_overflow_visible_ ? OverflowType::kVisible
                                     : OverflowType::kHidden;
  }
  lepus_value GetValue(tasm::CSSPropertyID id);
  bool InheritValue(tasm::CSSPropertyID id, const ComputedCSSStyle& from);

  // style getter

  // BoxData
  const NLength& GetWidth() const { return box_data_->width_; }
  const NLength& GetHeight() const { return box_data_->height_; }
  const NLength& GetMinWidth() const { return box_data_->min_width_; }
  const NLength& GetMaxWidth() const { return box_data_->max_width_; }
  const NLength& GetMinHeight() const { return box_data_->min_height_; }
  const NLength& GetMaxHeight() const { return box_data_->max_height_; }
  float GetAspectRatio() const { return box_data_->aspect_ratio_; }

// FlexData
#define STYLE_GET_FLEX_PROPERTY(return_value, func_name, property_name) \
  return_value Get##func_name() const { return flex_data_->property_name; }
  STYLE_GET_FLEX_PROPERTY(float, FlexGrow, flex_grow_)
  STYLE_GET_FLEX_PROPERTY(float, FlexShrink, flex_shrink_)
  STYLE_GET_FLEX_PROPERTY(NLength, FlexBasis, flex_basis_)
  STYLE_GET_FLEX_PROPERTY(FlexDirectionType, FlexDirection, flex_direction_)
  STYLE_GET_FLEX_PROPERTY(FlexWrapType, FlexWrap, flex_wrap_)
  STYLE_GET_FLEX_PROPERTY(JustifyContentType, JustifyContent, justify_content_)
  STYLE_GET_FLEX_PROPERTY(FlexAlignType, AlignItems, align_items_)
  STYLE_GET_FLEX_PROPERTY(FlexAlignType, AlignSelf, align_self_)
  STYLE_GET_FLEX_PROPERTY(AlignContentType, AlignContent, align_content_);
  STYLE_GET_FLEX_PROPERTY(float, Order, order_)
#undef STYLE_GET_FLEX_PROPERTY

  // LinearData
  LinearOrientationType GetLinearOrientation() const {
    return linear_data_->linear_orientation_;
  }
  LinearLayoutGravityType GetLinearLayoutGravity() const {
    return linear_data_->linear_layout_gravity_;
  }
  LinearGravityType GetLinearGravity() const {
    return linear_data_->linear_gravity_;
  }

  LinearCrossGravityType GetLinearCrossGravity() const {
    return linear_data_->linear_cross_gravity_;
  }

  float GetLinearWeightSum() const { return linear_data_->linear_weight_sum_; }
  float GetLinearWeight() const { return linear_data_->linear_weight_; }

  // RelativeData
  int GetRelativeId() const { return relative_data_->relative_id_; }
  int GetRelativeAlignTop() const {
    return relative_data_->relative_align_top_;
  }
  int GetRelativeAlignRight() const {
    return relative_data_->relative_align_right_;
  }
  int GetRelativeAlignBottom() const {
    return relative_data_->relative_align_bottom_;
  }
  int GetRelativeAlignLeft() const {
    return relative_data_->relative_align_left_;
  }
  int GetRelativeTopOf() const { return relative_data_->relative_top_of_; }
  int GetRelativeRightOf() const { return relative_data_->relative_right_of_; }
  int GetRelativeBottomOf() const {
    return relative_data_->relative_bottom_of_;
  }
  int GetRelativeLeftOf() const { return relative_data_->relative_left_of_; }
  bool GetRelativeLayoutOnce() const {
    return relative_data_->relative_layout_once_;
  }
  RelativeCenterType GetRelativeCenter() const {
    return relative_data_->relative_center_;
  }

  int32_t GetGridColumnStart() const { return grid_data_->grid_column_start_; }
  int32_t GetGridColumnEnd() const { return grid_data_->grid_column_end_; }
  int32_t GetGridRowStart() const { return grid_data_->grid_row_start_; }
  int32_t GetGridRowEnd() const { return grid_data_->grid_row_end_; }
  int32_t GetGridColumnSpan() const { return grid_data_->grid_column_span_; }
  int32_t GetGridRowSpan() const { return grid_data_->grid_row_span_; }
  const std::vector<NLength>& GetGridTemplateColumns() const {
    return grid_data_->grid_template_columns_;
  }
  const std::vector<NLength>& GetGridTemplateRows() const {
    return grid_data_->grid_template_rows_;
  }
  const std::vector<NLength>& GetGridAutoColumns() const {
    return grid_data_->grid_auto_columns_;
  }
  const std::vector<NLength>& GetGridAutoRows() const {
    return grid_data_->grid_auto_rows_;
  }
  const NLength& GetGridColumnGap() const {
    return grid_data_->grid_column_gap_;
  }
  const NLength& GetGridRowGap() const { return grid_data_->grid_row_gap_; }
  GridAutoFlowType GetGridAutoFlow() const {
    return grid_data_->grid_auto_flow_;
  }
  JustifyType GetJustifySelfType() const { return grid_data_->justify_self_; }
  JustifyType GetJustifyItemsType() const { return grid_data_->justify_items_; }

  // SurroundData
  NLength GetLeft() const { return surround_data_.left_; }
  NLength GetRight() const { return surround_data_.right_; }
  NLength GetTop() const { return surround_data_.top_; }
  NLength GetBottom() const { return surround_data_.bottom_; }
  NLength GetPaddingLeft() const { return surround_data_.padding_left_; }
  NLength GetPaddingRight() const { return surround_data_.padding_right_; }
  NLength GetPaddingTop() const { return surround_data_.padding_top_; }
  NLength GetPaddingBottom() const { return surround_data_.padding_bottom_; }
  NLength GetMarginLeft() const { return surround_data_.margin_left_; }
  NLength GetMarginRight() const { return surround_data_.margin_right_; }
  NLength GetMarginTop() const { return surround_data_.margin_top_; }
  NLength GetMarginBottom() const { return surround_data_.margin_bottom_; }

  BorderStyleType GetBorderLeftStyle() const {
    return surround_data_.border_data_
               ? surround_data_.border_data_->style_left
               : DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE);
  }
  BorderStyleType GetBorderRightStyle() const {
    return surround_data_.border_data_
               ? surround_data_.border_data_->style_right
               : DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE);
  }
  BorderStyleType GetBorderTopStyle() const {
    return surround_data_.border_data_
               ? surround_data_.border_data_->style_top
               : DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE);
  }
  BorderStyleType GetBorderBottomStyle() const {
    return surround_data_.border_data_
               ? surround_data_.border_data_->style_bottom
               : DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE);
  }

  // BorderWidth
  float GetBorderLeftWidth() const {
    return surround_data_.border_data_
               ? surround_data_.border_data_->width_left
               : DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER);
  }
  float GetBorderTopWidth() const {
    return surround_data_.border_data_
               ? surround_data_.border_data_->width_top
               : DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER);
  }
  float GetBorderRightWidth() const {
    return surround_data_.border_data_
               ? surround_data_.border_data_->width_right
               : DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER);
  }
  float GetBorderBottomWidth() const {
    return surround_data_.border_data_
               ? surround_data_.border_data_->width_bottom
               : DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER);
  }

  float GetBorderWidthHorizontal() const {
    return GetBorderLeftWidth() + GetBorderRightWidth();
  }
  float GetBorderWidthVertical() const {
    return GetBorderTopWidth() + GetBorderBottomWidth();
  }

  float GetBorderFinalLeftWidth() const {
    return GetBorderFinalWidth(GetBorderLeftWidth(), GetBorderLeftStyle());
  }
  float GetBorderFinalTopWidth() const {
    return GetBorderFinalWidth(GetBorderTopWidth(), GetBorderTopStyle());
  }
  float GetBorderFinalRightWidth() const {
    return GetBorderFinalWidth(GetBorderRightWidth(), GetBorderRightStyle());
  }
  float GetBorderFinalBottomWidth() const {
    return GetBorderFinalWidth(GetBorderBottomWidth(), GetBorderBottomStyle());
  }

  float GetBorderFinalWidthHorizontal() const {
    return GetBorderFinalLeftWidth() + GetBorderFinalRightWidth();
  }
  float GetBorderFinalWidthVertical() const {
    return GetBorderFinalTopWidth() + GetBorderFinalBottomWidth();
  }

  float GetListMainAxisGap() const {
    return CSSStyleUtils::RoundValueToPixelGrid(
        list_main_axis_gap_.GetRawValue());
  }

  float GetListCrossAxisGap() const {
    return CSSStyleUtils::RoundValueToPixelGrid(
        list_cross_axis_gap_.GetRawValue());
  }

  DisplayType GetDisplay(const LayoutConfigs& configs,
                         AttributesMap& attributes) const;

  PositionType GetPosition() const { return position_; }

  OverflowType GetOverflow() const { return overflow_; }

  bool HasAnimation() const { return animation_data_.has_value(); }

  std::vector<AnimationData>& animation_data() {
    CSSStyleUtils::PrepareOptional(animation_data_);
    return *animation_data_;
  }

  bool HasTransform() const { return transform_raw_.has_value(); }

  bool HasTransformOrigin() const { return transform_origin_.has_value(); }

  bool HasTransition() const { return transition_data_.has_value(); }

  std::vector<TransitionData>& transition_data() {
    CSSStyleUtils::PrepareOptional(transition_data_);
    return *transition_data_;
  }

  void SetCssAlignLegacyWithW3c(bool value) {
    css_align_with_legacy_w3c_ = value;
  }

  void SetCSSParserConfigs(const tasm::CSSParserConfigs& configs) {
    parser_configs_ = configs;
  }

  int GetZIndex() const { return z_index_; }

  bool HasOpacity() const { return base::FloatsNotEqual(opacity_, 1.0f); }

// layout style setter
#define BOTH_SUPPORTED_PROPERTY(V)                \
  V(Width, NLength)                               \
  V(Height, NLength)                              \
  V(MinWidth, NLength)                            \
  V(MinHeight, NLength)                           \
  V(MaxWidth, NLength)                            \
  V(MaxHeight, NLength)                           \
  V(FlexGrow, float)                              \
  V(FlexShrink, float)                            \
  V(FlexBasis, NLength)                           \
  V(FlexDirection, FlexDirectionType)             \
  V(JustifyContent, JustifyContentType)           \
  V(FlexWrap, FlexWrapType)                       \
  V(AlignItems, FlexAlignType)                    \
  V(AlignSelf, FlexAlignType)                     \
  V(AlignContent, AlignContentType)               \
  V(Order, float)                                 \
  V(Left, NLength)                                \
  V(Right, NLength)                               \
  V(Top, NLength)                                 \
  V(Bottom, NLength)                              \
  V(Padding, NLength)                             \
  V(PaddingLeft, NLength)                         \
  V(PaddingRight, NLength)                        \
  V(PaddingTop, NLength)                          \
  V(PaddingBottom, NLength)                       \
  V(Margin, NLength)                              \
  V(MarginLeft, NLength)                          \
  V(MarginRight, NLength)                         \
  V(MarginTop, NLength)                           \
  V(MarginBottom, NLength)                        \
  V(BorderWidth, NLength)                         \
  V(BorderLeftWidth, float)                       \
  V(BorderTopWidth, float)                        \
  V(BorderRightWidth, float)                      \
  V(BorderBottomWidth, float)                     \
  V(Display, DisplayType)                         \
  V(Position, PositionType)                       \
  V(Overflow, OverflowType)                       \
  V(Direction, DirectionType)                     \
  V(BoxSizing, int)                               \
  V(LinearOrientation, LinearOrientationType)     \
  V(LinearWeightSum, float)                       \
  V(LinearWeight, float)                          \
  V(LinearLayoutGravity, LinearLayoutGravityType) \
  V(LinearGravity, LinearGravityType)             \
  V(LinearCrossGravity, LinearCrossGravityType)   \
  V(AspectRatio, float)                           \
  V(RelativeId, int)                              \
  V(RelativeAlignTop, int)                        \
  V(RelativeAlignRight, int)                      \
  V(RelativeAlignBottom, int)                     \
  V(RelativeAlignLeft, int)                       \
  V(RelativeTopOf, int)                           \
  V(RelativeRightOf, int)                         \
  V(RelativeBottomOf, int)                        \
  V(RelativeLeftOf, int)                          \
  V(RelativeLayoutOnce, bool)                     \
  V(RelativeCenter, RelativeCenterType)

#define SET_WITH_PROPERTY(name, type) \
  bool Set##name(const type& value, const bool reset = false);
  BOTH_SUPPORTED_PROPERTY(SET_WITH_PROPERTY)
#undef SET_WITH_PROPERTY
#undef BOTH_SUPPORTED_PROPERTY

  static double PHYSICAL_PIXELS_PER_LAYOUT_UNIT;
  static float LAYOUTS_UNIT_PER_PX;

  static float SAFE_AREA_INSET_TOP_;
  static float SAFE_AREA_INSET_BOTTOM_;
  static float SAFE_AREA_INSET_LEFT_;
  static float SAFE_AREA_INSET_RIGHT_;

 private:
  using StyleFunc = bool (ComputedCSSStyle::*)(const tasm::CSSValue&,
                                               const bool reset);
  using StyleFuncMap = std::unordered_map<tasm::CSSPropertyID, StyleFunc>;
  using StyleGetterFunc = lepus_value (ComputedCSSStyle::*)();
  using StyleGetterFuncMap =
      std::unordered_map<tasm::CSSPropertyID, StyleGetterFunc>;
  using StyleInheritFunc = bool (ComputedCSSStyle::*)(const ComputedCSSStyle&);
  using StyleInheritFuncMap =
      std::unordered_map<tasm::CSSPropertyID, StyleInheritFunc>;

  const StyleFuncMap& FuncMap();
  const StyleGetterFuncMap& GetterFuncMap();
  const StyleInheritFuncMap& InheritFuncMap();

  // calc style parameters.
  CssMeasureContext length_context_;
  bool default_overflow_visible_ = false;

  /***************** css style property ***************************/

  int z_index_{DefaultCSSStyle::SL_DEFAULT_LONG};
  float opacity_{DefaultCSSStyle::SL_DEFAULT_OPACITY};
  BoxSizingType box_sizing_{DefaultCSSStyle::SL_DEFAULT_BOX_SIZING};
  DisplayType display_{DefaultCSSStyle::SL_DEFAULT_DISPLAY};
  PositionType position_{DefaultCSSStyle::SL_DEFAULT_POSITION};
  DirectionType direction_{DefaultCSSStyle::SL_DEFAULT_DIRECTION};
  OverflowType overflow_{DefaultCSSStyle::SL_DEFAULT_OVERFLOW};
  OverflowType overflow_x_{DefaultCSSStyle::SL_DEFAULT_OVERFLOW};
  OverflowType overflow_y_{DefaultCSSStyle::SL_DEFAULT_OVERFLOW};
  VisibilityType visibility_{DefaultCSSStyle::SL_DEFAULT_VISIBILITY};

  DataRef<BoxData> box_data_;
  DataRef<FlexData> flex_data_;
  DataRef<GridData> grid_data_;
  DataRef<LinearData> linear_data_;
  DataRef<RelativeData> relative_data_;
  SurroundData surround_data_;

  std::optional<AnimationData> enter_transition_data_;
  std::optional<AnimationData> exit_transition_data_;
  std::optional<AnimationData> pause_transition_data_;
  std::optional<AnimationData> resume_transition_data_;
  std::optional<BackgroundData> background_data_;
  std::optional<LayoutAnimationData> layout_animation_data_;
  std::optional<OutLineData> outline_;
  std::optional<std::vector<AnimationData>> animation_data_;
  std::optional<std::vector<TransformRawData>> transform_raw_;
  std::optional<std::vector<TransitionData>> transition_data_;
  std::optional<std::vector<ShadowData>> box_shadow_;
  std::optional<TextAttributes> text_attributes_;
  std::optional<TransformOriginData> transform_origin_;
  lepus::Value mask_image_{DefaultCSSStyle::EMPTY_LEPUS_VALUE()};
  std::optional<FilterData> filter_;
  std::optional<PerspectiveData> perspective_data_;
  // [type, [url, x, y], type, keyword ]
  std::optional<lepus_value> cursor_;
  // clip-path array [type, args..]
  base::scoped_refptr<lepus::CArray> clip_path_{nullptr};

  // this should not in css. But here is only compact old version.
  lepus::String caret_color_{DefaultCSSStyle::EMPTY_LEPUS_STRING()};
  lepus::String adapt_font_size_{DefaultCSSStyle::EMPTY_LEPUS_STRING()};
  lepus::String content_{DefaultCSSStyle::EMPTY_LEPUS_STRING()};

  // a 'list-version' grid-row-gap & grid-column-gap
  NLength list_main_axis_gap_{DefaultCSSStyle::SL_DEFAULT_ZEROLENGTH()};
  NLength list_cross_axis_gap_{DefaultCSSStyle::SL_DEFAULT_ZEROLENGTH()};
  /************ css style property end ***************************/

  bool css_align_with_legacy_w3c_ = false;

  tasm::CSSParserConfigs parser_configs_;

  void ResetOverflow();

// style setter by CSSValue
#define SET_WITH_CSS_VALUE(name, css_name, default_value) \
  bool Set##name(const tasm::CSSValue& value, const bool reset = false);
  FOREACH_ALL_PROPERTY(SET_WITH_CSS_VALUE)
#undef SET_WITH_CSS_VALUE

// platform style getter
#define FOREACH_PLATFORM_PROPERTY(V)     \
  V(Opacity)                             \
  V(Position)                            \
  V(Overflow)                            \
  V(OverflowX)                           \
  V(OverflowY)                           \
  V(FontSize)                            \
  V(LineHeight)                          \
  V(LetterSpacing)                       \
  V(LineSpacing)                         \
  V(Color)                               \
  V(Background)                          \
  V(BackgroundClip)                      \
  V(BackgroundColor)                     \
  V(BackgroundImage)                     \
  V(BackgroundOrigin)                    \
  V(BackgroundPosition)                  \
  V(BackgroundRepeat)                    \
  V(BackgroundSize)                      \
  V(MaskImage)                           \
  V(Filter)                              \
  V(BorderLeftColor)                     \
  V(BorderRightColor)                    \
  V(BorderTopColor)                      \
  V(BorderBottomColor)                   \
  V(BorderLeftWidth)                     \
  V(BorderRightWidth)                    \
  V(BorderTopWidth)                      \
  V(BorderBottomWidth)                   \
  V(Transform)                           \
  V(TransformOrigin)                     \
  V(Animation)                           \
  V(AnimationName)                       \
  V(AnimationDuration)                   \
  V(AnimationTimingFunction)             \
  V(AnimationDelay)                      \
  V(AnimationIterationCount)             \
  V(AnimationDirection)                  \
  V(AnimationFillMode)                   \
  V(AnimationPlayState)                  \
  V(LayoutAnimationCreateDuration)       \
  V(LayoutAnimationCreateTimingFunction) \
  V(LayoutAnimationCreateDelay)          \
  V(LayoutAnimationCreateProperty)       \
  V(LayoutAnimationDeleteDuration)       \
  V(LayoutAnimationDeleteTimingFunction) \
  V(LayoutAnimationDeleteDelay)          \
  V(LayoutAnimationDeleteProperty)       \
  V(LayoutAnimationUpdateDuration)       \
  V(LayoutAnimationUpdateTimingFunction) \
  V(LayoutAnimationUpdateDelay)          \
  V(Transition)                          \
  V(TransitionProperty)                  \
  V(TransitionDuration)                  \
  V(TransitionDelay)                     \
  V(TransitionTimingFunction)            \
  V(EnterTransitionName)                 \
  V(ExitTransitionName)                  \
  V(PauseTransitionName)                 \
  V(ResumeTransitionName)                \
  V(Visibility)                          \
  V(BorderLeftStyle)                     \
  V(BorderRightStyle)                    \
  V(BorderTopStyle)                      \
  V(BorderBottomStyle)                   \
  V(OutlineColor)                        \
  V(OutlineStyle)                        \
  V(OutlineWidth)                        \
  V(BoxShadow)                           \
  V(BorderColor)                         \
  V(FontFamily)                          \
  V(CaretColor)                          \
  V(TextShadow)                          \
  V(Direction)                           \
  V(WhiteSpace)                          \
  V(FontWeight)                          \
  V(WordBreak)                           \
  V(FontStyle)                           \
  V(TextAlign)                           \
  V(TextOverflow)                        \
  V(TextDecoration)                      \
  V(TextDecorationColor)                 \
  V(ZIndex)                              \
  V(VerticalAlign)                       \
  V(BorderRadius)                        \
  V(BorderTopLeftRadius)                 \
  V(BorderTopRightRadius)                \
  V(BorderBottomRightRadius)             \
  V(BorderBottomLeftRadius)              \
  V(ListMainAxisGap)                     \
  V(ListCrossAxisGap)                    \
  V(Perspective)                         \
  V(Cursor)                              \
  V(TextIndent)                          \
  V(ClipPath)                            \
  V(TextStroke)                          \
  V(TextStrokeWidth)                     \
  V(TextStrokeColor)
#define GETTER_STYLE_STRING(name) lepus_value name##ToLepus();
  FOREACH_PLATFORM_PROPERTY(GETTER_STYLE_STRING)
#undef GET_WITH_STRING

// style inherit.
#define FOREACH_PLATFORM_COMPLEX_INHERITABLE_PROPERTY(V) \
  V(LineHeight)                                          \
  V(LetterSpacing)                                       \
  V(LineSpacing)

#define INHERIT_CSS_VALUE(name) \
  bool Inherit##name(const ComputedCSSStyle& from);
  FOREACH_PLATFORM_COMPLEX_INHERITABLE_PROPERTY(INHERIT_CSS_VALUE)
#undef INHERIT_CSS_VALUE

 private:
  float GetBorderFinalWidth(float width, BorderStyleType style) const {
    return (style != BorderStyleType::kNone && style != BorderStyleType::kHide)
               ? width
               : 0.f;
  }

};  // ComputedCSSStyle

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_COMPUTED_CSS_STYLE_H_
