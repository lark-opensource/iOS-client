// Copyright 2017 The Lynx Authors. All rights reserved.

#include "starlight/style/computed_css_style.h"

#include <cmath>
#include <utility>

#include "base/compiler_specific.h"
#include "base/debug/error_code.h"
#include "base/debug/lynx_assert.h"
#include "base/string/string_number_convert.h"
#include "base/string/string_utils.h"
#include "css/css_debug_msg.h"
#include "css_type.h"
#include "lepus/array.h"
#include "lepus/table.h"
#include "starlight/layout/box_info.h"
#include "starlight/style/css_style_utils.h"
#include "starlight/style/default_css_style.h"

namespace lynx {

using base::FloatsEqual;

namespace starlight {

using CSSValuePattern = tasm::CSSValuePattern;

const ComputedCSSStyle::StyleFuncMap& ComputedCSSStyle::FuncMap() {
  static base::NoDestructor<ComputedCSSStyle::StyleFuncMap> func_map_{{
#define DECLARE_PROPERTY_SETTER(name, c, value) \
  {tasm::kPropertyID##name, &ComputedCSSStyle::Set##name},
      FOREACH_ALL_PROPERTY(DECLARE_PROPERTY_SETTER)
#undef DECLARE_PROPERTY_SETTER
  }};
  return *func_map_;
}

const ComputedCSSStyle::StyleGetterFuncMap& ComputedCSSStyle::GetterFuncMap() {
  static base::NoDestructor<ComputedCSSStyle::StyleGetterFuncMap>
      getter_func_map_{{
#define DECLARE_PLATFORM_PROPERTY_GETTER(name) \
  {tasm::kPropertyID##name, &ComputedCSSStyle::name##ToLepus},
          FOREACH_PLATFORM_PROPERTY(DECLARE_PLATFORM_PROPERTY_GETTER)
#undef DECLARE_PLATFORM_PROPERTY_GETTER
#undef FOREACH_PLATFORM_PROPERTY
      }};
  return *getter_func_map_;
}

const ComputedCSSStyle::StyleInheritFuncMap&
ComputedCSSStyle::InheritFuncMap() {
  static base::NoDestructor<ComputedCSSStyle::StyleInheritFuncMap>
      inherit_func_map_{{
#define DECLARE_PLATFORM_PROPERTY_INHERIT_FUNC(name) \
  {tasm::kPropertyID##name, &ComputedCSSStyle::Inherit##name},
          FOREACH_PLATFORM_COMPLEX_INHERITABLE_PROPERTY(
              DECLARE_PLATFORM_PROPERTY_INHERIT_FUNC)
#undef DECLARE_PLATFORM_PROPERTY_INHERIT_FUNC
#undef FOREACH_PLATFORM_COMPLEX_INHERITABLE_PROPERTY
      }};
  return *inherit_func_map_;
}

namespace {
bool CalculateFromBorderWidthStringToFloat(
    const tasm::CSSValue& value, float& result,
    const CssMeasureContext& context, const bool reset,
    bool css_align_with_legacy_w3c, const tasm::CSSParserConfigs& configs) {
  if (reset) {
    result = DEFAULT_CSS_VALUE(css_align_with_legacy_w3c, BORDER);
    return true;
  }

  auto parse_result = CSSStyleUtils::ToLength(value, context, configs);
  if (!parse_result.second || !parse_result.first.IsUnit()) {
    return false;
  }
  result = CSSStyleUtils::GetBorderWidthFromLengthToFloat(parse_result.first);
  return true;
}

bool CalculateCSSValueToFloat(const tasm::CSSValue& value, float& result,
                              const CssMeasureContext& context,
                              const tasm::CSSParserConfigs& configs,
                              bool is_font_relevant = false) {
  auto parse_result =
      CSSStyleUtils::ToLength(value, context, configs, is_font_relevant);
  if (!parse_result.second) {
    return false;
  }

  if (parse_result.first.IsCalc()) {
    // do not support percentage nor fit-content, only the first vector will be
    // used here
    result = CSSStyleUtils::RoundValueToPixelGrid(
        parse_result.first.GetCalcSubLengths()[0].GetRawValue());
  } else {
    // make sure css value is not percentage, vw nor vh
    result =
        CSSStyleUtils::RoundValueToPixelGrid(parse_result.first.GetRawValue());
  }
  return true;
}

lepus::Value ShadowDataToLepus(std::vector<ShadowData> shadows) {
  auto group = lepus::CArray::Create();
  for (const auto& shadow_data : shadows) {
    auto item = lepus::CArray::Create();
    item->push_back(lepus::Value(shadow_data.h_offset));
    item->push_back(lepus::Value(shadow_data.v_offset));
    item->push_back(lepus::Value(shadow_data.blur));
    item->push_back(lepus::Value(shadow_data.spread));
    item->push_back(lepus::Value(static_cast<int>(shadow_data.option)));
    item->push_back(lepus::Value(shadow_data.color));
    group->push_back(lepus::Value(item));
  }
  return lepus::Value(group);
}

static void RadiusLengthToLepus(base::scoped_refptr<lepus::CArray>& array,
                                NLength& p, int screen_width) {
  if (p.IsPercent()) {
    array->push_back(lepus::Value(p.GetRawValue()));
    array->push_back(lepus::Value(
        static_cast<int>(starlight::PlatformLengthUnit::PERCENTAGE)));
  } else {
    // TODO(liyanbo): support vh.
    auto calc_value = NLengthToLayoutUnit(p, LayoutUnit(screen_width));
    array->push_back(lepus::Value(calc_value.ToFloat()));
    array->push_back(
        lepus::Value(static_cast<int>(starlight::PlatformLengthUnit::NUMBER)));
  }
}

bool SetLayoutAnimationTimingFunctionInternal(
    const tasm::CSSValue& value, const bool reset,
    TimingFunctionData& timing_function,
    const tasm::CSSParserConfigs& configs) {
  const lepus::Value& lepus_val = value.GetValue();
  // TimingFunction's input value must be a non-empty array , if not we will
  // reset it.
  bool reset_internal =
      (reset || !lepus_val.IsArray() || lepus_val.Array()->size() <= 0);
  const lepus::Value& param =
      reset_internal ? lepus_val : lepus_val.Array()->get(0);
  return CSSStyleUtils::ComputeTimingFunction(param, reset_internal,
                                              timing_function, configs);
}

bool SetBorderWidthHelper(bool cssAlignWithLegacyW3C,
                          const CssMeasureContext& context, float& width,
                          const tasm::CSSValue& value,
                          const tasm::CSSParserConfigs& configs,
                          const bool reset) {
  float old_value = width;
  if (UNLIKELY(!CalculateFromBorderWidthStringToFloat(
          value, width, context, reset, cssAlignWithLegacyW3C, configs))) {
    return false;
  }
  return width != old_value;
}

bool SetBorderWidthHelper(bool cssAlignWithLegacyW3C, float& width, float value,
                          const tasm::CSSParserConfigs& configs,
                          const bool reset) {
  float old_value = width;
  width = reset ? DEFAULT_CSS_VALUE(cssAlignWithLegacyW3C, BORDER) : value;
  return old_value != width;
}

bool SetBorderRadiusHelper(NLength& radiusX, NLength& radiusY,
                           const lynx::starlight::CssMeasureContext& context,
                           tasm::CSSPropertyID cssID,
                           const tasm::CSSValue& value, const bool reset,
                           const tasm::CSSParserConfigs& configs) {
  if (reset) {
    radiusX = radiusY = DefaultCSSStyle::SL_DEFAULT_RADIUS();
  } else {
    if (!tasm::UnitHandler::CSSWarning(
            value.IsArray(), configs.enable_css_strict_mode, tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(cssID).c_str(),
            tasm::ARRAY_TYPE)) {
      return false;
    }
    auto arr = value.GetValue().Array();
    auto parse_result = CSSStyleUtils::ToLength(
        tasm::CSSValue(arr->get(0),
                       static_cast<CSSValuePattern>(arr->get(1).Number())),
        context, configs);

    if (!tasm::UnitHandler::CSSWarning(
            parse_result.second, configs.enable_css_strict_mode,
            tasm::SET_PROPERTY_ERROR,
            tasm::CSSProperty::GetPropertyName(cssID).c_str())) {
      return false;
    }

    radiusX = std::move(parse_result.first);

    parse_result = CSSStyleUtils::ToLength(
        tasm::CSSValue(arr->get(2),
                       static_cast<CSSValuePattern>(arr->get(3).Number())),
        context, configs);

    if (!tasm::UnitHandler::CSSWarning(
            parse_result.second, configs.enable_css_strict_mode,
            tasm::SET_PROPERTY_ERROR,
            tasm::CSSProperty::GetPropertyName(cssID).c_str())) {
      return false;
    }

    radiusY = std::move(parse_result.first);
  }
  return true;
}

bool SetTransitionHelper(
    std::optional<std::vector<TransitionData>>& transitionData,
    long& (*getMember)(
        std::optional<std::vector<TransitionData>>& transitionData, const int),

    const tasm::CSSValue& value, const bool reset, const char* msg,
    const tasm::CSSParserConfigs& configs) {
  if (reset) {
    if (transitionData) {
      auto sz = transitionData->size();
      for (int i = 0; static_cast<size_t>(i) < sz; ++i) {
        getMember(transitionData, i) = 0;
      }
    }
    return true;
  } else {
    if (!transitionData) {
      transitionData = std::vector<TransitionData>();
      transitionData->push_back(TransitionData());
    }
    if (value.IsNumber()) {
      return CSSStyleUtils::ComputeLongStyle(
          value, reset, getMember(transitionData, 0),
          DefaultCSSStyle::SL_DEFAULT_LONG, msg, configs);
    } else {
      bool changed = false;
      auto arr = value.GetValue().Array();
      for (int i = 0; static_cast<size_t>(i) < arr->size(); i++) {
        if (transitionData->size() <= static_cast<size_t>(i)) {
          transitionData->push_back(TransitionData());
        }
        auto old = getMember(transitionData, i);
        getMember(transitionData, i) = arr->get(i).Number();
        changed |= old != getMember(transitionData, i);
      }
      return changed;
    }
  }
}

lepus_value LayoutAnimationTimingFunctionToLepusHelper(
    const TimingFunctionData& timingFunction) {
  auto array = lepus::CArray::Create();
  array->push_back(lepus::Value(static_cast<int>(timingFunction.timing_func)));
  array->push_back(lepus::Value(static_cast<int>(timingFunction.steps_type)));
  array->push_back(lepus::Value(timingFunction.x1));
  array->push_back(lepus::Value(timingFunction.y1));
  array->push_back(lepus::Value(timingFunction.x2));
  array->push_back(lepus::Value(timingFunction.y2));
  return lepus_value(array);
}

}  // namespace

// Currently, layout unit is equal to default unit used by platform
// On iOS one layout unit equals to one ios point
// On Android one layout unit equals to one physical pixel
double ComputedCSSStyle::PHYSICAL_PIXELS_PER_LAYOUT_UNIT = 0;
float ComputedCSSStyle::LAYOUTS_UNIT_PER_PX = 0;

float ComputedCSSStyle::SAFE_AREA_INSET_TOP_ = 0;
float ComputedCSSStyle::SAFE_AREA_INSET_BOTTOM_ = 0;
float ComputedCSSStyle::SAFE_AREA_INSET_LEFT_ = 0;
float ComputedCSSStyle::SAFE_AREA_INSET_RIGHT_ = 0;

ComputedCSSStyle::ComputedCSSStyle()
    : length_context_(0.f, LAYOUTS_UNIT_PER_PX, PHYSICAL_PIXELS_PER_LAYOUT_UNIT,
                      lynx::tasm::Config::DefaultFontSize(),
                      lynx::tasm::Config::DefaultFontSize(), LayoutUnit(),
                      LayoutUnit()) {
  box_data_.Init();
  flex_data_.Init();
  grid_data_.Init();
  linear_data_.Init();
  relative_data_.Init();
}

ComputedCSSStyle::ComputedCSSStyle(const ComputedCSSStyle& o)
    : length_context_(o.length_context_) {
  box_data_ = o.box_data_;
  flex_data_ = o.flex_data_;
  grid_data_ = o.grid_data_;
  linear_data_ = o.linear_data_;
  relative_data_ = o.relative_data_;
}

void ComputedCSSStyle::Reset() {
  box_data_.Access()->Reset();
  flex_data_.Access()->Reset();
  grid_data_.Access()->Reset();
  linear_data_.Access()->Reset();
  relative_data_.Access()->Reset();
  surround_data_.Reset();

  position_ = DefaultCSSStyle::SL_DEFAULT_POSITION;
  display_ = DefaultCSSStyle::SL_DEFAULT_DISPLAY;
  direction_ = DefaultCSSStyle::SL_DEFAULT_DIRECTION;
  box_sizing_ = DefaultCSSStyle::SL_DEFAULT_BOX_SIZING;

  opacity_ = DefaultCSSStyle::SL_DEFAULT_OPACITY;
  z_index_ = DefaultCSSStyle::SL_DEFAULT_LONG;

  ResetOverflow();

  text_attributes_.reset();
  transform_raw_.reset();
  transform_origin_.reset();
  animation_data_.reset();
  transition_data_.reset();
  layout_animation_data_.reset();
  enter_transition_data_.reset();
  exit_transition_data_.reset();
  pause_transition_data_.reset();
  resume_transition_data_.reset();
  filter_.reset();
  visibility_ = DefaultCSSStyle::SL_DEFAULT_VISIBILITY;
  caret_color_ = DefaultCSSStyle::EMPTY_LEPUS_STRING();
  SetFontSize(tasm::Config::DefaultFontSize(), tasm::Config::DefaultFontSize());
}

bool ComputedCSSStyle::SetValue(tasm::CSSPropertyID id,
                                const tasm::CSSValue& value, bool reset) {
  const auto& funcMap = FuncMap();
  auto iter = funcMap.find(id);
  if (iter == funcMap.end()) {
    LynxWarning(false, LYNX_ERROR_CODE_CSS,
                "SetValue can't find style func id:%d", id);
    return false;
  }
  StyleFunc func = iter->second;
  return (this->*func)(value, reset);
}

void ComputedCSSStyle::ResetValue(tasm::CSSPropertyID id) {
  const auto& funcMap = FuncMap();
  auto iter = funcMap.find(id);
  if (iter == funcMap.end()) {
    LynxWarning(false, LYNX_ERROR_CODE_CSS,
                "ResetValue can't find style func id:%d", id);
    return;
  }
  StyleFunc func = iter->second;
  tasm::CSSValue value;
  (this->*func)(value, true);
}

void ComputedCSSStyle::SetOverflowDefaultVisible(
    bool default_overflow_visible) {
  default_overflow_visible_ = default_overflow_visible;
  ResetOverflow();
}

void ComputedCSSStyle::ResetOverflow() {
  const auto& overflow = default_overflow_visible_ ? OverflowType::kVisible
                                                   : OverflowType::kHidden;
  overflow_ = overflow;
  overflow_x_ = overflow;
  overflow_y_ = overflow;
}

lepus_value ComputedCSSStyle::GetValue(tasm::CSSPropertyID id) {
  const auto& getterFuncMap = GetterFuncMap();
  auto iter = getterFuncMap.find(id);
  if (iter == getterFuncMap.end()) {
    LynxWarning(false, LYNX_ERROR_CODE_CSS,
                "GetValue can't find style getter id:%d", id);
    return lepus::Value();
  }
  StyleGetterFunc func = iter->second;
  return (this->*func)();
}

bool ComputedCSSStyle::InheritValue(tasm::CSSPropertyID id,
                                    const ComputedCSSStyle& from) {
  const auto& inheritFuncMap = InheritFuncMap();
  auto iter = inheritFuncMap.find(id);
  if (iter == inheritFuncMap.end()) {
    LynxWarning(false, LYNX_ERROR_CODE_CSS,
                "Inherit is not supported for style: \"%s\"",
                tasm::CSSProperty::GetPropertyName(id).c_str());
    return false;
  }
  StyleInheritFunc func = iter->second;
  return (this->*func)(from);
}

bool ComputedCSSStyle::DirectionIsReverse(const LayoutConfigs& configs,
                                          AttributesMap& attributes) const {
  auto display = GetDisplay(configs, attributes);
  if (display == DisplayType::kFlex) {
    return flex_data_->flex_direction_ == FlexDirectionType::kColumnReverse ||
           flex_data_->flex_direction_ == FlexDirectionType::kRowReverse;
  } else if (display == DisplayType::kLinear) {
    return linear_data_->linear_orientation_ ==
               LinearOrientationType::kHorizontalReverse ||
           linear_data_->linear_orientation_ ==
               LinearOrientationType::kVerticalReverse ||
           linear_data_->linear_orientation_ ==
               LinearOrientationType::kRowReverse ||
           linear_data_->linear_orientation_ ==
               LinearOrientationType::kColumnReverse;
  }
  return false;
}

bool ComputedCSSStyle::IsRow(const LayoutConfigs& configs,
                             AttributesMap& attributes) const {
  auto display = GetDisplay(configs, attributes);
  if (display == DisplayType::kFlex) {
    return flex_data_->flex_direction_ == FlexDirectionType::kRow ||
           flex_data_->flex_direction_ == FlexDirectionType::kRowReverse;
  } else if (display == DisplayType::kLinear) {
    return (linear_data_->linear_orientation_ ==
            LinearOrientationType::kHorizontal) ||
           (linear_data_->linear_orientation_ ==
            LinearOrientationType::kHorizontalReverse) ||
           (linear_data_->linear_orientation_ == LinearOrientationType::kRow) ||
           (linear_data_->linear_orientation_ ==
            LinearOrientationType::kRowReverse);
  } else if (display_ == DisplayType::kGrid) {
    return (grid_data_->grid_auto_flow_ == GridAutoFlowType::kRow ||
            grid_data_->grid_auto_flow_ == GridAutoFlowType::kRowDense ||
            grid_data_->grid_auto_flow_ == GridAutoFlowType::kDense);
  }
  return true;
}

bool ComputedCSSStyle::IsFlexRow(const LayoutConfigs& configs,
                                 AttributesMap& attributes) const {
  if (GetDisplay(configs, attributes) == DisplayType::kFlex) {
    return flex_data_->flex_direction_ == FlexDirectionType::kRow ||
           flex_data_->flex_direction_ == FlexDirectionType::kRowReverse;
  }
  return false;
}

bool ComputedCSSStyle::IsBorderBox(const LayoutConfigs& configs) const {
  switch (box_sizing_) {
    case BoxSizingType::kBorderBox:
      return true;
    case BoxSizingType::kContentBox:
      return false;
    default:
      return !configs.css_align_with_legacy_w3c_;
  }
}

#define SUPPORTED_LENGTH_PROPERTY(V)                                  \
  V(Width, NLength, box_data_.Access()->width_, WIDTH)                \
  V(Height, NLength, box_data_.Access()->height_, HEIGHT)             \
  V(MinWidth, NLength, box_data_.Access()->min_width_, MIN_WIDTH)     \
  V(MinHeight, NLength, box_data_.Access()->min_height_, MIN_HEIGHT)  \
  V(MaxWidth, NLength, box_data_.Access()->max_width_, MAX_WIDTH)     \
  V(MaxHeight, NLength, box_data_.Access()->max_height_, MAX_HEIGHT)  \
  V(FlexBasis, NLength, flex_data_.Access()->flex_basis_, FLEX_BASIS) \
  V(Left, NLength, surround_data_.left_, FOUR_POSITION)               \
  V(Right, NLength, surround_data_.right_, FOUR_POSITION)             \
  V(Top, NLength, surround_data_.top_, FOUR_POSITION)                 \
  V(Bottom, NLength, surround_data_.bottom_, FOUR_POSITION)           \
  V(PaddingLeft, NLength, surround_data_.padding_left_, PADDING)      \
  V(PaddingRight, NLength, surround_data_.padding_right_, PADDING)    \
  V(PaddingTop, NLength, surround_data_.padding_top_, PADDING)        \
  V(PaddingBottom, NLength, surround_data_.padding_bottom_, PADDING)  \
  V(MarginLeft, NLength, surround_data_.margin_left_, MARGIN)         \
  V(MarginRight, NLength, surround_data_.margin_right_, MARGIN)       \
  V(MarginTop, NLength, surround_data_.margin_top_, MARGIN)           \
  V(MarginBottom, NLength, surround_data_.margin_bottom_, MARGIN)

#define SUPPORTED_ENUM_PROPERTY(V)                                             \
  V(FlexDirection, FlexDirectionType, flex_data_.Access()->flex_direction_,    \
    FLEX_DIRECTION)                                                            \
  V(JustifyContent, JustifyContentType, flex_data_.Access()->justify_content_, \
    JUSTIFY_CONTENT)                                                           \
  V(FlexWrap, FlexWrapType, flex_data_.Access()->flex_wrap_, FLEX_WRAP)        \
  V(AlignItems, FlexAlignType, flex_data_.Access()->align_items_, ALIGN_ITEMS) \
  V(AlignSelf, FlexAlignType, flex_data_.Access()->align_self_, ALIGN_SELF)    \
  V(AlignContent, AlignContentType, flex_data_.Access()->align_content_,       \
    ALIGN_CONTENT)                                                             \
  V(Position, PositionType, position_, POSITION)                               \
  V(Direction, DirectionType, direction_, DIRECTION)                           \
  V(Overflow, OverflowType, overflow_, OVERFLOW)

bool ComputedCSSStyle::SetFlexGrow(const tasm::CSSValue& value,
                                   const bool reset) {
  return CSSStyleUtils::ComputeFloatStyle(
      value, reset, flex_data_.Access()->flex_grow_,
      DefaultCSSStyle::SL_DEFAULT_FLEX_GROW, "flex-grow must be a number!",
      parser_configs_);
}

bool ComputedCSSStyle::SetFlexShrink(const tasm::CSSValue& value,
                                     const bool reset) {
  return CSSStyleUtils::ComputeFloatStyle(
      value, reset, flex_data_.Access()->flex_shrink_,
      DefaultCSSStyle::SL_DEFAULT_FLEX_SHRINK, "flex-shrink must be a number!",
      parser_configs_);
}

bool ComputedCSSStyle::SetOrder(const tasm::CSSValue& value, const bool reset) {
  return CSSStyleUtils::ComputeFloatStyle(
      value, reset, flex_data_.Access()->order_,
      DefaultCSSStyle::SL_DEFAULT_ORDER, "order must be a number!",
      parser_configs_);
}

bool ComputedCSSStyle::SetLinearWeightSum(const tasm::CSSValue& value,
                                          const bool reset) {
  return CSSStyleUtils::ComputeFloatStyle(
      value, reset, linear_data_.Access()->linear_weight_sum_,
      DefaultCSSStyle::SL_DEFAULT_LINEAR_WEIGHT_SUM,
      "linear-weight-sum must be a number!", parser_configs_);
}

bool ComputedCSSStyle::SetLinearWeight(const tasm::CSSValue& value,
                                       const bool reset) {
  return CSSStyleUtils::ComputeFloatStyle(
      value, reset, linear_data_.Access()->linear_weight_,
      DefaultCSSStyle::SL_DEFAULT_LINEAR_WEIGHT,
      "linear-weight must be a number!", parser_configs_);
}

bool ComputedCSSStyle::SetAspectRatio(const tasm::CSSValue& value,
                                      const bool reset) {
  return CSSStyleUtils::ComputeFloatStyle(
      value, reset, box_data_.Access()->aspect_ratio_,
      DefaultCSSStyle::SL_DEFAULT_ASPECT_RATIO,
      "aspect-ratio must be a number!", parser_configs_);
}

bool ComputedCSSStyle::SetBorderLeftWidth(const tasm::CSSValue& value,
                                          const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_,
                                 css_align_with_legacy_w3c_);
  return SetBorderWidthHelper(css_align_with_legacy_w3c_, length_context_,
                              surround_data_.border_data_->width_left, value,
                              parser_configs_, reset);
}

bool ComputedCSSStyle::SetBorderTopWidth(const tasm::CSSValue& value,
                                         const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_,
                                 css_align_with_legacy_w3c_);
  return SetBorderWidthHelper(css_align_with_legacy_w3c_, length_context_,
                              surround_data_.border_data_->width_top, value,
                              parser_configs_, reset);
}

bool ComputedCSSStyle::SetBorderRightWidth(const tasm::CSSValue& value,
                                           const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_,
                                 css_align_with_legacy_w3c_);
  return SetBorderWidthHelper(css_align_with_legacy_w3c_, length_context_,
                              surround_data_.border_data_->width_right, value,
                              parser_configs_, reset);
}

bool ComputedCSSStyle::SetBorderBottomWidth(const tasm::CSSValue& value,
                                            const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_,
                                 css_align_with_legacy_w3c_);
  return SetBorderWidthHelper(css_align_with_legacy_w3c_, length_context_,
                              surround_data_.border_data_->width_bottom, value,
                              parser_configs_, reset);
}

bool ComputedCSSStyle::SetBorder(const tasm::CSSValue& value,
                                 const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetTextStroke(const tasm::CSSValue& value,
                                     const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetTextStrokeColor(const tasm::CSSValue& value,
                                          const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  auto old_value_color = text_attributes_->text_stroke_color;
  if (reset) {
    text_attributes_->text_stroke_color = DefaultCSSStyle::SL_DEFAULT_COLOR;
  } else {
    if (!tasm::UnitHandler::CSSWarning(
            value.IsNumber(), parser_configs_.enable_css_strict_mode,
            tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDTextStrokeColor)
                .c_str(),
            tasm::NUMBER_TYPE)) {
      return false;
    }
    if (value.IsNumber()) {
      text_attributes_->text_stroke_color =
          static_cast<unsigned int>(value.GetValue().Number());
    }
  }
  return old_value_color != text_attributes_->text_stroke_color;
}

bool ComputedCSSStyle::SetTextStrokeWidth(const tasm::CSSValue& value,
                                          const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  auto old_value = text_attributes_->text_stroke_width;
  if (reset) {
    text_attributes_->text_stroke_width = DefaultCSSStyle::SL_DEFAULT_FLOAT;
  } else if (UNLIKELY(!CalculateCSSValueToFloat(
                 value, text_attributes_->text_stroke_width, length_context_,
                 parser_configs_, true))) {
    return false;
  }
  return base::FloatsNotEqual(text_attributes_->text_stroke_width, old_value);
}

bool ComputedCSSStyle::SetBorderTop(const tasm::CSSValue& value,
                                    const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderRight(const tasm::CSSValue& value,
                                      const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderBottom(const tasm::CSSValue& value,
                                       const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetFontScale(float font_scale) {
  if (font_scale == length_context_.font_scale_) {
    return false;
  }
  length_context_.font_scale_ = font_scale;
  return true;
}
bool ComputedCSSStyle::SetBorderLeft(const tasm::CSSValue& value,
                                     const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetMarginInlineStart(const tasm::CSSValue& value,
                                            const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetMarginInlineEnd(const tasm::CSSValue& value,
                                          const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetPaddingInlineStart(const tasm::CSSValue& value,
                                             const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetPaddingInlineEnd(const tasm::CSSValue& value,
                                           const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderInlineStartWidth(const tasm::CSSValue& value,
                                                 const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderInlineEndWidth(const tasm::CSSValue& value,
                                               const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderInlineStartColor(const tasm::CSSValue& value,
                                                 const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderInlineEndColor(const tasm::CSSValue& value,
                                               const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderInlineStartStyle(const tasm::CSSValue& value,
                                                 const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderInlineEndStyle(const tasm::CSSValue& value,
                                               const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderStartStartRadius(const tasm::CSSValue& value,
                                                 const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderEndStartRadius(const tasm::CSSValue& value,
                                               const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderStartEndRadius(const tasm::CSSValue& value,
                                               const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderEndEndRadius(const tasm::CSSValue& value,
                                             const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetRelativeAlignInlineStart(const tasm::CSSValue& value,
                                                   const bool reset) {
  NOTREACHED();
  return false;
}

bool ComputedCSSStyle::SetRelativeAlignInlineEnd(const tasm::CSSValue& value,
                                                 const bool reset) {
  NOTREACHED();
  return false;
}

bool ComputedCSSStyle::SetRelativeInlineStartOf(const tasm::CSSValue& value,
                                                const bool reset) {
  NOTREACHED();
  return false;
}

bool ComputedCSSStyle::SetRelativeInlineEndOf(const tasm::CSSValue& value,
                                              const bool reset) {
  NOTREACHED();
  return false;
}

#define SET_LENGTH_PROPERTY(type_name, length, css_type, default_type)  \
  bool ComputedCSSStyle::Set##type_name(const tasm::CSSValue& value,    \
                                        const bool reset) {             \
    return CSSStyleUtils::ComputeLengthStyle(                           \
        value, reset, length_context_, css_type,                        \
        DefaultCSSStyle::SL_DEFAULT_##default_type(), parser_configs_); \
  }
SUPPORTED_LENGTH_PROPERTY(SET_LENGTH_PROPERTY)
#undef SET_LENGTH_PROPERTY

bool ComputedCSSStyle::SetFlexDirection(const tasm::CSSValue& value,
                                        const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<FlexDirectionType>(
      value, reset, flex_data_.Access()->flex_direction_,
      DefaultCSSStyle::SL_DEFAULT_FLEX_DIRECTION,
      "flex-direction must be a enum!", parser_configs_);
}

bool ComputedCSSStyle::SetJustifyContent(const tasm::CSSValue& value,
                                         const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<JustifyContentType>(
      value, reset, flex_data_.Access()->justify_content_,
      DefaultCSSStyle::SL_DEFAULT_JUSTIFY_CONTENT,
      "justify-content must be a enum!", parser_configs_);
}

bool ComputedCSSStyle::SetFlexWrap(const tasm::CSSValue& value,
                                   const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<FlexWrapType>(
      value, reset, flex_data_.Access()->flex_wrap_,
      DefaultCSSStyle::SL_DEFAULT_FLEX_WRAP, "flex-warp must be a enum!",
      parser_configs_);
}

bool ComputedCSSStyle::SetAlignItems(const tasm::CSSValue& value,
                                     const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<FlexAlignType>(
      value, reset, flex_data_.Access()->align_items_,
      DefaultCSSStyle::SL_DEFAULT_ALIGN_ITEMS, "align-items must be a enum!",
      parser_configs_);
}

bool ComputedCSSStyle::SetAlignSelf(const tasm::CSSValue& value,
                                    const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<FlexAlignType>(
      value, reset, flex_data_.Access()->align_self_,
      DefaultCSSStyle::SL_DEFAULT_ALIGN_SELF, "align-self must be a enum!",
      parser_configs_);
}

bool ComputedCSSStyle::SetAlignContent(const tasm::CSSValue& value,
                                       const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<AlignContentType>(
      value, reset, flex_data_.Access()->align_content_,
      DefaultCSSStyle::SL_DEFAULT_ALIGN_CONTENT,
      "align-content must be a enum!", parser_configs_);
}

bool ComputedCSSStyle::SetPosition(const tasm::CSSValue& value,
                                   const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<PositionType>(
      value, reset, position_, DefaultCSSStyle::SL_DEFAULT_POSITION,
      "position must be a enum!", parser_configs_);
}

bool ComputedCSSStyle::SetDirection(const tasm::CSSValue& value,
                                    const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<DirectionType>(
      value, reset, direction_, DefaultCSSStyle::SL_DEFAULT_DIRECTION,
      "direction must be a enum!", parser_configs_);
}

bool ComputedCSSStyle::SetOverflow(const tasm::CSSValue& value,
                                   const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<OverflowType>(
      value, reset, overflow_, GetDefaultOverflowType(),
      "overflow must be a enum!", parser_configs_);
}

bool ComputedCSSStyle::SetDisplay(const tasm::CSSValue& value,
                                  const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<DisplayType>(
      value, reset, display_, DefaultCSSStyle::SL_DEFAULT_DISPLAY,
      "display must be a enum!", parser_configs_);
}

bool ComputedCSSStyle::SetLinearOrientation(const tasm::CSSValue& value,
                                            const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<LinearOrientationType>(
      value, reset, linear_data_.Access()->linear_orientation_,
      DefaultCSSStyle::SL_DEFAULT_LINEAR_ORIENTATION,
      "linear-orientation must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetLinearDirection(const tasm::CSSValue& value,
                                          const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<LinearOrientationType>(
      value, reset, linear_data_.Access()->linear_orientation_,
      DefaultCSSStyle::SL_DEFAULT_LINEAR_ORIENTATION,
      "linear-direction must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetLinearLayoutGravity(const tasm::CSSValue& value,
                                              const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<LinearLayoutGravityType>(
      value, reset, linear_data_.Access()->linear_layout_gravity_,
      DefaultCSSStyle::SL_DEFAULT_LINEAR_LAYOUT_GRAVITY,
      "linear-layout-gravity must be a enum!", parser_configs_);
}

bool ComputedCSSStyle::SetLinearGravity(const tasm::CSSValue& value,
                                        const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<LinearGravityType>(
      value, reset, linear_data_.Access()->linear_gravity_,
      DefaultCSSStyle::SL_DEFAULT_LINEAR_GRAVITY,
      "linear-gravity must be a enum!", parser_configs_);
}

bool ComputedCSSStyle::SetLinearCrossGravity(const tasm::CSSValue& value,
                                             const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<LinearCrossGravityType>(
      value, reset, linear_data_.Access()->linear_cross_gravity_,
      DefaultCSSStyle::SL_DEFAULT_LINEAR_CROSS_GRAVITY,
      "linear-cross-gravity must be a enum!", parser_configs_);
}

bool ComputedCSSStyle::SetBoxSizing(const tasm::CSSValue& value,
                                    const bool reset) {
  auto old_value = box_sizing_;
  if (reset) {
    box_sizing_ = BoxSizingType::kAuto;
  } else {
    if (!tasm::UnitHandler::CSSWarning(
            value.IsEnum(), parser_configs_.enable_css_strict_mode,
            tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDBoxSizing)
                .c_str(),
            tasm::ENUM_TYPE)) {
      return false;
    }
    box_sizing_ = static_cast<BoxSizingType>(value.GetValue().Number());
  }
  return old_value != box_sizing_;
}

bool ComputedCSSStyle::SetRelativeId(const tasm::CSSValue& value,
                                     const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, relative_data_.Access()->relative_id_,
      DefaultCSSStyle::SL_DEFAULT_RELATIVE_ID, "relative-id must be a int!",
      parser_configs_);
}

bool ComputedCSSStyle::SetRelativeAlignTop(const tasm::CSSValue& value,
                                           const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, relative_data_.Access()->relative_align_top_,
      DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_TOP,
      "relative-align-top must be a int!", parser_configs_);
}

bool ComputedCSSStyle::SetRelativeAlignRight(const tasm::CSSValue& value,
                                             const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, relative_data_.Access()->relative_align_right_,
      DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_RIGHT,
      "relative-align-right must be a int!", parser_configs_);
}

bool ComputedCSSStyle::SetRelativeAlignBottom(const tasm::CSSValue& value,
                                              const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, relative_data_.Access()->relative_align_bottom_,
      DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_BOTTOM,
      "relative-align-bottom must be a int!", parser_configs_);
}

bool ComputedCSSStyle::SetRelativeAlignLeft(const tasm::CSSValue& value,
                                            const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, relative_data_.Access()->relative_align_left_,
      DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_LEFT,
      "relative-align-left must be a int!", parser_configs_);
}

bool ComputedCSSStyle::SetRelativeTopOf(const tasm::CSSValue& value,
                                        const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, relative_data_.Access()->relative_top_of_,
      DefaultCSSStyle::SL_DEFAULT_RELATIVE_TOP_OF,
      "relative-top-of must be a int!", parser_configs_);
}

bool ComputedCSSStyle::SetRelativeRightOf(const tasm::CSSValue& value,
                                          const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, relative_data_.Access()->relative_right_of_,
      DefaultCSSStyle::SL_DEFAULT_RELATIVE_RIGHT_OF,
      "relative-right-of must be a int!", parser_configs_);
}

bool ComputedCSSStyle::SetRelativeBottomOf(const tasm::CSSValue& value,
                                           const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, relative_data_.Access()->relative_bottom_of_,
      DefaultCSSStyle::SL_DEFAULT_RELATIVE_BOTTOM_OF,
      "relative-bottom-of must be a int!", parser_configs_);
}

bool ComputedCSSStyle::SetRelativeLeftOf(const tasm::CSSValue& value,
                                         const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, relative_data_.Access()->relative_left_of_,
      DefaultCSSStyle::SL_DEFAULT_RELATIVE_LEFT_OF,
      "relative-left-of must be a int!", parser_configs_);
}

bool ComputedCSSStyle::SetRelativeLayoutOnce(const tasm::CSSValue& value,
                                             const bool reset) {
  return CSSStyleUtils::ComputeBoolStyle(
      value, reset, relative_data_.Access()->relative_layout_once_,
      DefaultCSSStyle::SL_DEFAULT_RELATIVE_LAYOUT_ONCE,
      "relative-layout-once must be a bool!", parser_configs_);
}

bool ComputedCSSStyle::SetRelativeCenter(const tasm::CSSValue& value,
                                         const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<RelativeCenterType>(
      value, reset, relative_data_.Access()->relative_center_,
      DefaultCSSStyle::SL_DEFAULT_RELATIVE_CENTER,
      "relative-center must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetGridTemplateColumns(const tasm::CSSValue& value,
                                              const bool reset) {
  return CSSStyleUtils::ComputeLengthArrayStyle(
      value, reset, length_context_,
      grid_data_.Access()->grid_template_columns_,
      DefaultCSSStyle::SL_DEFAULT_GRID_TRACK(),
      "grid-template-columns must be an array!", parser_configs_);
}

bool ComputedCSSStyle::SetGridTemplateRows(const tasm::CSSValue& value,
                                           const bool reset) {
  return CSSStyleUtils::ComputeLengthArrayStyle(
      value, reset, length_context_, grid_data_.Access()->grid_template_rows_,
      DefaultCSSStyle::SL_DEFAULT_GRID_TRACK(),
      "grid-template-rows must be an array!", parser_configs_);
}

bool ComputedCSSStyle::SetGridAutoColumns(const tasm::CSSValue& value,
                                          const bool reset) {
  return CSSStyleUtils::ComputeLengthArrayStyle(
      value, reset, length_context_, grid_data_.Access()->grid_auto_columns_,
      DefaultCSSStyle::SL_DEFAULT_GRID_AUTO_TRACK(),
      "grid-auto-columns must be an array!", parser_configs_);
}

bool ComputedCSSStyle::SetGridAutoRows(const tasm::CSSValue& value,
                                       const bool reset) {
  return CSSStyleUtils::ComputeLengthArrayStyle(
      value, reset, length_context_, grid_data_.Access()->grid_auto_rows_,
      DefaultCSSStyle::SL_DEFAULT_GRID_AUTO_TRACK(),
      "grid-auto-rows must be an array!", parser_configs_);
}

bool ComputedCSSStyle::SetGridColumnSpan(const tasm::CSSValue& value,
                                         const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, grid_data_.Access()->grid_column_span_,
      DefaultCSSStyle::SL_DEFAULT_GRID_SPAN, "grid-column-span must be an int!",
      parser_configs_);
}

bool ComputedCSSStyle::SetGridRowSpan(const tasm::CSSValue& value,
                                      const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, grid_data_.Access()->grid_row_span_,
      DefaultCSSStyle::SL_DEFAULT_GRID_SPAN, "grid-row-span must be an int!",
      parser_configs_);
}

bool ComputedCSSStyle::SetGridRowStart(const tasm::CSSValue& value,
                                       const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, grid_data_.Access()->grid_row_start_,
      DefaultCSSStyle::SL_DEFAULT_GRID_ITEM_POSITION,
      "grid-row-start must be an int!", parser_configs_);
}

bool ComputedCSSStyle::SetGridRowEnd(const tasm::CSSValue& value,
                                     const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, grid_data_.Access()->grid_row_end_,
      DefaultCSSStyle::SL_DEFAULT_GRID_ITEM_POSITION,
      "grid-row-end must be an int!", parser_configs_);
}

bool ComputedCSSStyle::SetGridColumnStart(const tasm::CSSValue& value,
                                          const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, grid_data_.Access()->grid_column_start_,
      DefaultCSSStyle::SL_DEFAULT_GRID_ITEM_POSITION,
      "grid-column-start must be an int!", parser_configs_);
}

bool ComputedCSSStyle::SetGridColumnEnd(const tasm::CSSValue& value,
                                        const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, grid_data_.Access()->grid_column_end_,
      DefaultCSSStyle::SL_DEFAULT_GRID_ITEM_POSITION,
      "grid-column-end must be an int!", parser_configs_);
}

bool ComputedCSSStyle::SetGridColumnGap(const tasm::CSSValue& value,
                                        const bool reset) {
  return CSSStyleUtils::ComputeLengthStyle(
      value, reset, length_context_, grid_data_.Access()->grid_column_gap_,
      DefaultCSSStyle::SL_DEFAULT_GRID_GAP(), parser_configs_);
}

bool ComputedCSSStyle::SetGridRowGap(const tasm::CSSValue& value,
                                     const bool reset) {
  return CSSStyleUtils::ComputeLengthStyle(
      value, reset, length_context_, grid_data_.Access()->grid_row_gap_,
      DefaultCSSStyle::SL_DEFAULT_GRID_GAP(), parser_configs_);
}

bool ComputedCSSStyle::SetJustifyItems(const tasm::CSSValue& value,
                                       const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<JustifyType>(
      value, reset, grid_data_.Access()->justify_items_,
      DefaultCSSStyle::SL_DEFAULT_JUSTIFY_ITEMS,
      "justify-items must be a enum!", parser_configs_);
}

bool ComputedCSSStyle::SetJustifySelf(const tasm::CSSValue& value,
                                      const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<JustifyType>(
      value, reset, grid_data_.Access()->justify_self_,
      DefaultCSSStyle::SL_DEFAULT_JUSTIFY_SELF, "justify-self must be a enum!",
      parser_configs_);
}

bool ComputedCSSStyle::SetGridAutoFlow(const tasm::CSSValue& value,
                                       const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<GridAutoFlowType>(
      value, reset, grid_data_.Access()->grid_auto_flow_,
      DefaultCSSStyle::SL_DEFAULT_GRID_AUTO_FLOW,
      "grid-auto-flow must be a enum!", parser_configs_);
}

#define SET_NON_FLOAT_PROPERTY(type_name, enum_type, css_type, default_type) \
  bool ComputedCSSStyle::Set##type_name(const enum_type& value,              \
                                        const bool reset) {                  \
    enum_type old_value = css_type;                                          \
    css_type = reset ? DefaultCSSStyle::SL_DEFAULT_##default_type : value;   \
    return old_value != css_type;                                            \
  }
SUPPORTED_ENUM_PROPERTY(SET_NON_FLOAT_PROPERTY)
#undef SET_NON_FLOAT_PROPERTY

#define SET_NON_FLOAT_PROPERTY2(type_name, enum_type, css_type, default_type) \
  bool ComputedCSSStyle::Set##type_name(const enum_type& value,               \
                                        const bool reset) {                   \
    enum_type old_value = css_type;                                           \
    css_type = reset ? DefaultCSSStyle::SL_DEFAULT_##default_type() : value;  \
    return old_value != css_type;                                             \
  }
SUPPORTED_LENGTH_PROPERTY(SET_NON_FLOAT_PROPERTY2)
#undef SET_NON_FLOAT_PROPERTY

bool ComputedCSSStyle::SetDisplay(const DisplayType& value, const bool reset) {
  DisplayType old_value = display_;
  display_ = reset ? DefaultCSSStyle::SL_DEFAULT_DISPLAY : value;
  return old_value != display_;
}

bool ComputedCSSStyle::SetLinearOrientation(const LinearOrientationType& value,
                                            const bool reset) {
  LinearOrientationType old_value = linear_data_->linear_orientation_;
  linear_data_.Access()->linear_orientation_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_LINEAR_ORIENTATION : value;
  return old_value != linear_data_->linear_orientation_;
}

bool ComputedCSSStyle::SetLinearLayoutGravity(
    const LinearLayoutGravityType& value, const bool reset) {
  LinearLayoutGravityType old_value = linear_data_->linear_layout_gravity_;
  linear_data_.Access()->linear_layout_gravity_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_LINEAR_LAYOUT_GRAVITY : value;
  return old_value != linear_data_->linear_layout_gravity_;
}

bool ComputedCSSStyle::SetLinearGravity(const LinearGravityType& value,
                                        const bool reset) {
  LinearGravityType old_value = linear_data_->linear_gravity_;
  linear_data_.Access()->linear_gravity_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_LINEAR_GRAVITY : value;
  return old_value != linear_data_->linear_gravity_;
}

bool ComputedCSSStyle::SetLinearCrossGravity(
    const LinearCrossGravityType& value, const bool reset) {
  LinearCrossGravityType old_value = linear_data_->linear_cross_gravity_;
  linear_data_.Access()->linear_cross_gravity_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_LINEAR_CROSS_GRAVITY : value;
  return old_value != linear_data_->linear_cross_gravity_;
}

bool ComputedCSSStyle::SetBorderLeftWidth(const float& value,
                                          const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_,
                                 css_align_with_legacy_w3c_);
  return SetBorderWidthHelper(css_align_with_legacy_w3c_,
                              surround_data_.border_data_->width_left, value,
                              parser_configs_, reset);
}

bool ComputedCSSStyle::SetBorderTopWidth(const float& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_,
                                 css_align_with_legacy_w3c_);
  return SetBorderWidthHelper(css_align_with_legacy_w3c_,
                              surround_data_.border_data_->width_top, value,
                              parser_configs_, reset);
}

bool ComputedCSSStyle::SetBorderRightWidth(const float& value,
                                           const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_,
                                 css_align_with_legacy_w3c_);
  return SetBorderWidthHelper(css_align_with_legacy_w3c_,
                              surround_data_.border_data_->width_right, value,
                              parser_configs_, reset);
}

bool ComputedCSSStyle::SetBorderBottomWidth(const float& value,
                                            const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_,
                                 css_align_with_legacy_w3c_);
  return SetBorderWidthHelper(css_align_with_legacy_w3c_,
                              surround_data_.border_data_->width_bottom, value,
                              parser_configs_, reset);
}

bool ComputedCSSStyle::SetFlexShrink(const float& value, const bool reset) {
  float old_value = flex_data_->flex_shrink_;
  flex_data_.Access()->flex_shrink_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_FLEX_SHRINK : value;
  return !FloatsEqual(old_value, flex_data_->flex_shrink_);
}

bool ComputedCSSStyle::SetOrder(const float& value, const bool reset) {
  float old_value = flex_data_->order_;
  flex_data_.Access()->order_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_ORDER : value;
  return !FloatsEqual(old_value, flex_data_->order_);
}

bool ComputedCSSStyle::SetLinearWeightSum(const float& value,
                                          const bool reset) {
  float old_value = linear_data_->linear_weight_sum_;
  linear_data_.Access()->linear_weight_sum_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_LINEAR_WEIGHT_SUM : value;
  return !FloatsEqual(old_value, linear_data_->linear_weight_sum_);
}

bool ComputedCSSStyle::SetLinearWeight(const float& value, const bool reset) {
  float old_value = linear_data_->linear_weight_;
  linear_data_.Access()->linear_weight_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_LINEAR_WEIGHT : value;
  return !FloatsEqual(old_value, linear_data_->linear_weight_);
}

bool ComputedCSSStyle::SetAspectRatio(const float& value, const bool reset) {
  float old_value = box_data_->aspect_ratio_;
  box_data_.Access()->aspect_ratio_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_ASPECT_RATIO : value;
  return !FloatsEqual(old_value, box_data_->aspect_ratio_);
}

bool ComputedCSSStyle::SetRelativeId(const int& value, const bool reset) {
  int old_value = relative_data_->relative_id_;
  relative_data_.Access()->relative_id_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_RELATIVE_ID : value;
  return old_value != relative_data_->relative_id_;
}

bool ComputedCSSStyle::SetRelativeAlignTop(const int& value, const bool reset) {
  int old_value = relative_data_->relative_align_top_;
  relative_data_.Access()->relative_align_top_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_TOP : value;
  return old_value != relative_data_->relative_align_top_;
}

bool ComputedCSSStyle::SetRelativeAlignRight(const int& value,
                                             const bool reset) {
  int old_value = relative_data_->relative_align_right_;
  relative_data_.Access()->relative_align_right_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_RIGHT : value;
  return old_value != relative_data_->relative_align_right_;
}

bool ComputedCSSStyle::SetRelativeAlignBottom(const int& value,
                                              const bool reset) {
  int old_value = relative_data_->relative_align_bottom_;
  relative_data_.Access()->relative_align_bottom_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_BOTTOM : value;
  return old_value != relative_data_->relative_align_bottom_;
}

bool ComputedCSSStyle::SetRelativeAlignLeft(const int& value,
                                            const bool reset) {
  int old_value = relative_data_->relative_align_left_;
  relative_data_.Access()->relative_align_left_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_LEFT : value;
  return old_value != relative_data_->relative_align_left_;
}

bool ComputedCSSStyle::SetRelativeTopOf(const int& value, const bool reset) {
  int old_value = relative_data_->relative_top_of_;
  relative_data_.Access()->relative_top_of_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_RELATIVE_TOP_OF : value;
  return old_value != relative_data_->relative_top_of_;
}

bool ComputedCSSStyle::SetRelativeRightOf(const int& value, const bool reset) {
  int old_value = relative_data_->relative_right_of_;
  relative_data_.Access()->relative_right_of_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_RELATIVE_RIGHT_OF : value;
  return old_value != relative_data_->relative_right_of_;
}

bool ComputedCSSStyle::SetRelativeBottomOf(const int& value, const bool reset) {
  int old_value = relative_data_->relative_bottom_of_;
  relative_data_.Access()->relative_bottom_of_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_RELATIVE_BOTTOM_OF : value;
  return old_value != relative_data_->relative_bottom_of_;
}

bool ComputedCSSStyle::SetRelativeLeftOf(const int& value, const bool reset) {
  int old_value = relative_data_->relative_left_of_;
  relative_data_.Access()->relative_left_of_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_RELATIVE_LEFT_OF : value;
  return old_value != relative_data_->relative_left_of_;
}

bool ComputedCSSStyle::SetRelativeLayoutOnce(const bool& value,
                                             const bool reset) {
  bool old_value = relative_data_->relative_layout_once_;
  relative_data_.Access()->relative_layout_once_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_RELATIVE_LAYOUT_ONCE : value;
  return old_value != relative_data_->relative_layout_once_;
}

bool ComputedCSSStyle::SetRelativeCenter(
    const lynx::starlight::RelativeCenterType& value, const bool reset) {
  RelativeCenterType old_value = relative_data_->relative_center_;
  relative_data_.Access()->relative_center_ =
      reset ? DefaultCSSStyle::SL_DEFAULT_RELATIVE_CENTER : value;
  return old_value != relative_data_->relative_center_;
}

bool ComputedCSSStyle::SetFlex(const tasm::CSSValue& value, const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetFlexFlow(const tasm::CSSValue& value,
                                   const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetPadding(const tasm::CSSValue& value,
                                  const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetMargin(const tasm::CSSValue& value,
                                 const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}
bool ComputedCSSStyle::SetInsetInlineStart(const tasm::CSSValue& value,
                                           const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetInsetInlineEnd(const tasm::CSSValue& value,
                                         const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBorderWidth(const tasm::CSSValue& value,
                                      const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

// setter

// deprecated. Here is only a Placeholder.
bool ComputedCSSStyle::SetImplicitAnimation(const tasm::CSSValue& value,
                                            const bool reset) {
  return false;
}

bool ComputedCSSStyle::SetOpacity(const tasm::CSSValue& value,
                                  const bool reset) {
  return CSSStyleUtils::ComputeFloatStyle(
      value, reset, opacity_, DefaultCSSStyle::SL_DEFAULT_OPACITY,
      "opacity must be a float!", parser_configs_);
}

bool ComputedCSSStyle::SetOverflowX(const tasm::CSSValue& value,
                                    const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<OverflowType>(
      value, reset, overflow_x_, GetDefaultOverflowType(),
      "overflow-x must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetOverflowY(const tasm::CSSValue& value,
                                    const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<OverflowType>(
      value, reset, overflow_y_, GetDefaultOverflowType(),
      "overflow-y must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetFontSize(const tasm::CSSValue& value,
                                   const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  auto old_value = text_attributes_->font_size;
  if (reset) {
    text_attributes_->font_size = tasm::Config::DefaultFontSize();
  } else {
    text_attributes_->font_size = length_context_.cur_node_font_size_;
  }
  return base::FloatsNotEqual(text_attributes_->font_size, old_value);
}

bool ComputedCSSStyle::SetLineHeight(const tasm::CSSValue& value,
                                     const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  auto old_value = text_attributes_->computed_line_height;
  if (reset) {
    text_attributes_->computed_line_height =
        DefaultCSSStyle::SL_DEFAULT_LINE_HEIGHT;
    text_attributes_->line_height_factor =
        DefaultCSSStyle::SL_DEFAULT_LINE_HEIGHT_FACTOR;
  } else {
    if (value.IsNumber() || value.IsPercent()) {
      auto old_factor = text_attributes_->line_height_factor;
      text_attributes_->line_height_factor =
          value.GetValue().Number() / (value.IsPercent() ? 100 : 1);
      text_attributes_->computed_line_height =
          text_attributes_->line_height_factor *
          length_context_.cur_node_font_size_;
      // Either the computed line height or the line height factor changes may
      // affect how the line height behaves.
      return base::FloatsNotEqual(text_attributes_->computed_line_height,
                                  old_value) ||
             base::FloatsNotEqual(old_factor,
                                  text_attributes_->computed_line_height);
    } else {
      if (UNLIKELY(!CalculateCSSValueToFloat(
              value, text_attributes_->computed_line_height, length_context_,
              parser_configs_, true))) {
        return false;
      }
      text_attributes_->line_height_factor =
          DefaultCSSStyle::SL_DEFAULT_LINE_HEIGHT_FACTOR;
      return base::FloatsNotEqual(text_attributes_->computed_line_height,
                                  old_value);
    }
  }
  return false;
}

bool ComputedCSSStyle::SetPerspective(const tasm::CSSValue& value,
                                      const bool reset) {
  CSSStyleUtils::PrepareOptional(perspective_data_);
  auto old_value = perspective_data_;
  if (reset) {
    perspective_data_.reset();
  } else {
    auto length =
        CSSStyleUtils::ToLength(value, length_context_, parser_configs_);
    if (length.second) {
      perspective_data_->length_ = length.first;
      perspective_data_->pattern_ = value.GetPattern();
    }
  }
  return !(old_value == perspective_data_);
}

bool ComputedCSSStyle::SetLetterSpacing(const tasm::CSSValue& value,
                                        const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  auto old_value = text_attributes_->letter_spacing;
  if (reset) {
    text_attributes_->letter_spacing =
        DefaultCSSStyle::SL_DEFAULT_LETTER_SPACING;
  } else if (UNLIKELY(!CalculateCSSValueToFloat(
                 value, text_attributes_->letter_spacing, length_context_,
                 parser_configs_, true))) {
    return false;
  }
  return base::FloatsNotEqual(text_attributes_->letter_spacing, old_value);
}
// transform

bool ComputedCSSStyle::SetTransform(const tasm::CSSValue& value,
                                    const bool reset) {
  return CSSStyleUtils::ComputeTransform(value, reset, transform_raw_,
                                         length_context_, parser_configs_);
}

bool ComputedCSSStyle::SetTransformOrigin(const tasm::CSSValue& value,
                                          const bool reset) {
  auto old_value = transform_origin_
                       ? *transform_origin_
                       : DefaultCSSStyle::SL_DEFAULT_TRANSFORM_ORIGIN();
  if (reset) {
    transform_origin_.reset();
  } else {
    if (!tasm::UnitHandler::CSSWarning(
            value.IsArray(), parser_configs_.enable_css_strict_mode,
            tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDTransformOrigin)
                .c_str(),
            tasm::ARRAY_TYPE)) {
      return false;
    }
    auto arr = value.GetValue().Array();
    if (!tasm::UnitHandler::CSSWarning(
            arr->size() >= 2, parser_configs_.enable_css_strict_mode,
            tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDTransformOrigin)
                .c_str(),
            tasm::ARRAY_TYPE)) {
      return false;
    }
    CSSStyleUtils::PrepareOptional(transform_origin_);
    auto parse_result_x = CSSStyleUtils::ToLength(
        tasm::CSSValue(
            arr->get(TransformOriginData::INDEX_X),
            static_cast<CSSValuePattern>(
                arr->get(TransformOriginData::INDEX_X_UNIT).Number())),
        length_context_, parser_configs_);
    if (parse_result_x.second) {
      transform_origin_->x = parse_result_x.first;
    }
    if (arr->size() == 4) {
      auto parse_result_y = CSSStyleUtils::ToLength(
          tasm::CSSValue(
              arr->get(TransformOriginData::INDEX_Y),
              static_cast<CSSValuePattern>(
                  arr->get(TransformOriginData::INDEX_Y_UNIT).Number())),
          length_context_, parser_configs_);
      if (parse_result_y.second) {
        transform_origin_->y = parse_result_y.first;
      }
    }
  }
  return !(old_value == transform_origin_);
}

// animation
bool ComputedCSSStyle::SetAnimation(const tasm::CSSValue& value,
                                    const bool reset) {
  auto old_value = animation_data_;
  if (reset) {
    animation_data_.reset();
  } else {
    if (!tasm::UnitHandler::CSSWarning(
            value.IsArray() || value.IsMap(),
            parser_configs_.enable_css_strict_mode, tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDAnimation)
                .c_str(),
            tasm::ARRAY_OR_MAP_TYPE)) {
      return false;
    }
    if (!animation_data_) {
      animation_data_ = std::vector<AnimationData>();
    }
    animation_data_->clear();
    if (value.IsArray()) {
      auto group = value.GetValue().Array();
      for (size_t i = 0; i < group->size(); i++) {
        if (animation_data_->size() < i + 1) {
          animation_data_->push_back(AnimationData());
        }
        CSSStyleUtils::ComputeAnimation(group->get(i), animation_data_->at(i),
                                        "animation must is invalid.",
                                        parser_configs_);
      }
    } else {
      animation_data_->push_back(AnimationData());
      CSSStyleUtils::ComputeAnimation(
          value.GetValue(), animation_data_->front(),
          "animation must is invalid.", parser_configs_);
    }
  }
  return old_value != animation_data_;
}

bool ComputedCSSStyle::SetAnimationName(const tasm::CSSValue& value,
                                        const bool reset) {
  auto reset_func = [](AnimationData& anim) {
    anim.name = DefaultCSSStyle::EMPTY_LEPUS_STRING();
  };
  auto compute_func = [this](const lepus::Value& value, AnimationData& anim,
                             bool reset) -> bool {
    return CSSStyleUtils::ComputeStringStyle(
        tasm::CSSValue(value, CSSValuePattern::STRING), reset, anim.name,
        DefaultCSSStyle::EMPTY_LEPUS_STRING(),
        "animation-name must be a string!", this->parser_configs_);
  };
  return CSSStyleUtils::SetAnimationProperty(
      animation_data_, value, reset_func, compute_func, reset, parser_configs_);
}

bool ComputedCSSStyle::SetAnimationTimingFunction(const tasm::CSSValue& value,
                                                  const bool reset) {
  auto reset_func = [](AnimationData& anim) { anim.timing_func.Reset(); };
  auto compute_func = [this](const lepus::Value& value, AnimationData& anim,
                             bool reset) -> bool {
    return CSSStyleUtils::ComputeTimingFunction(value, reset, anim.timing_func,
                                                this->parser_configs_);
  };
  return CSSStyleUtils::SetAnimationProperty(
      animation_data_, value, reset_func, compute_func, reset, parser_configs_);
}

bool ComputedCSSStyle::SetAnimationIterationCount(const tasm::CSSValue& value,
                                                  const bool reset) {
  auto reset_func = [](AnimationData& anim) { anim.iteration_count = 1; };
  auto compute_func = [this](const lepus::Value& value, AnimationData& anim,
                             bool reset) -> bool {
    return CSSStyleUtils::ComputeIntStyle(
        tasm::CSSValue(value, CSSValuePattern::NUMBER), reset,
        anim.iteration_count, 0, "animation-iteration-count must be a number!",
        this->parser_configs_);
  };
  return CSSStyleUtils::SetAnimationProperty(
      animation_data_, value, reset_func, compute_func, reset, parser_configs_);
}

bool ComputedCSSStyle::SetAnimationDuration(const tasm::CSSValue& value,
                                            const bool reset) {
  auto reset_func = [](AnimationData& anim) {
    anim.duration = DefaultCSSStyle::SL_DEFAULT_LONG;
  };
  auto compute_func = [this](const lepus::Value& value, AnimationData& anim,
                             bool reset) -> bool {
    return CSSStyleUtils::ComputeLongStyle(
        tasm::CSSValue(value, CSSValuePattern::NUMBER), reset, anim.duration,
        DefaultCSSStyle::SL_DEFAULT_LONG, "animation-duration must be a long!",
        this->parser_configs_);
  };
  return CSSStyleUtils::SetAnimationProperty(
      animation_data_, value, reset_func, compute_func, reset, parser_configs_);
}

bool ComputedCSSStyle::SetAnimationFillMode(const tasm::CSSValue& value,
                                            const bool reset) {
  auto reset_func = [](AnimationData& anim) {
    anim.fill_mode = AnimationFillModeType::kNone;
  };
  auto compute_func = [this](const lepus::Value& value, AnimationData& anim,
                             bool reset) -> bool {
    return CSSStyleUtils::ComputeEnumStyle<AnimationFillModeType>(
        tasm::CSSValue(value, CSSValuePattern::ENUM), reset, anim.fill_mode,
        AnimationFillModeType::kNone, "animation-fill-mode must be a string!",
        this->parser_configs_);
  };
  return CSSStyleUtils::SetAnimationProperty(
      animation_data_, value, reset_func, compute_func, reset, parser_configs_);
}

bool ComputedCSSStyle::SetAnimationDelay(const tasm::CSSValue& value,
                                         const bool reset) {
  auto reset_func = [](AnimationData& anim) {
    anim.delay = DefaultCSSStyle::SL_DEFAULT_LONG;
  };
  auto compute_func = [this](const lepus::Value& value, AnimationData& anim,
                             bool reset) -> bool {
    return CSSStyleUtils::ComputeLongStyle(
        tasm::CSSValue(value, CSSValuePattern::NUMBER), reset, anim.delay,
        DefaultCSSStyle::SL_DEFAULT_LONG, "animation-delay must be a float!",
        this->parser_configs_);
  };
  return CSSStyleUtils::SetAnimationProperty(
      animation_data_, value, reset_func, compute_func, reset, parser_configs_);
}

bool ComputedCSSStyle::SetAnimationDirection(const tasm::CSSValue& value,
                                             const bool reset) {
  auto reset_func = [](AnimationData& anim) {
    anim.direction = AnimationDirectionType::kNormal;
  };
  auto compute_func = [this](const lepus::Value& value, AnimationData& anim,
                             bool reset) -> bool {
    return CSSStyleUtils::ComputeEnumStyle<AnimationDirectionType>(
        tasm::CSSValue(value, CSSValuePattern::ENUM), reset, anim.direction,
        AnimationDirectionType::kNormal, "animation-direction must be a !",
        this->parser_configs_);
  };
  return CSSStyleUtils::SetAnimationProperty(
      animation_data_, value, reset_func, compute_func, reset, parser_configs_);
}

bool ComputedCSSStyle::SetAnimationPlayState(const tasm::CSSValue& value,
                                             const bool reset) {
  auto reset_func = [](AnimationData& anim) {
    anim.play_state = AnimationPlayStateType::kRunning;
  };
  auto compute_func = [this](const lepus::Value& value, AnimationData& anim,
                             bool reset) -> bool {
    return CSSStyleUtils::ComputeEnumStyle<AnimationPlayStateType>(
        tasm::CSSValue(value, CSSValuePattern::ENUM), reset, anim.play_state,
        AnimationPlayStateType::kRunning,
        "animation-play-state must be a enum!", this->parser_configs_);
  };
  return CSSStyleUtils::SetAnimationProperty(
      animation_data_, value, reset_func, compute_func, reset, parser_configs_);
}

// layout animation

bool ComputedCSSStyle::SetLayoutAnimationCreateDelay(
    const tasm::CSSValue& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(layout_animation_data_);
  return CSSStyleUtils::ComputeLongStyle(
      value, reset, layout_animation_data_->create_ani.delay,
      DefaultCSSStyle::SL_DEFAULT_LONG,
      "layout-animation-create-delay must be a number!", parser_configs_);
}

bool ComputedCSSStyle::SetLayoutAnimationCreateDuration(
    const tasm::CSSValue& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(layout_animation_data_);
  return CSSStyleUtils::ComputeLongStyle(
      value, reset, layout_animation_data_->create_ani.duration,
      DefaultCSSStyle::SL_DEFAULT_LONG,
      "layout-animation-create-duration must be a number!", parser_configs_);
}

bool ComputedCSSStyle::SetLayoutAnimationCreateProperty(
    const tasm::CSSValue& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(layout_animation_data_);
  return CSSStyleUtils::ComputeEnumStyle<starlight::AnimationPropertyType>(
      value, reset, layout_animation_data_->create_ani.property,
      starlight::AnimationPropertyType::kOpacity,
      "layout-animation-create-property must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetLayoutAnimationCreateTimingFunction(
    const tasm::CSSValue& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(layout_animation_data_);
  return SetLayoutAnimationTimingFunctionInternal(
      value, reset, layout_animation_data_->create_ani.timing_function,
      parser_configs_);
}

bool ComputedCSSStyle::SetLayoutAnimationUpdateDelay(
    const tasm::CSSValue& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(layout_animation_data_);
  return CSSStyleUtils::ComputeLongStyle(
      value, reset, layout_animation_data_->update_ani.delay,
      DefaultCSSStyle::SL_DEFAULT_LONG,
      "layout-animation-update-delay must be a number!", parser_configs_);
}

bool ComputedCSSStyle::SetLayoutAnimationUpdateDuration(
    const tasm::CSSValue& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(layout_animation_data_);
  return CSSStyleUtils::ComputeLongStyle(
      value, reset, layout_animation_data_->update_ani.duration,
      DefaultCSSStyle::SL_DEFAULT_LONG,
      "layout-animation-update-duration must be a number!", parser_configs_);
}

bool ComputedCSSStyle::SetLayoutAnimationUpdateTimingFunction(
    const tasm::CSSValue& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(layout_animation_data_);
  return SetLayoutAnimationTimingFunctionInternal(
      value, reset, layout_animation_data_->update_ani.timing_function,
      parser_configs_);
}

bool ComputedCSSStyle::SetLayoutAnimationDeleteDuration(
    const tasm::CSSValue& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(layout_animation_data_);
  return CSSStyleUtils::ComputeLongStyle(
      value, reset, layout_animation_data_->delete_ani.duration,
      DefaultCSSStyle::SL_DEFAULT_LONG,
      "layout-animation-delete-duration must be a number!", parser_configs_);
}

bool ComputedCSSStyle::SetLayoutAnimationDeleteDelay(
    const tasm::CSSValue& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(layout_animation_data_);
  return CSSStyleUtils::ComputeLongStyle(
      value, reset, layout_animation_data_->delete_ani.delay,
      DefaultCSSStyle::SL_DEFAULT_LONG,
      "layout-animation-delete-delay must be a number!", parser_configs_);
}

bool ComputedCSSStyle::SetLayoutAnimationDeleteProperty(
    const tasm::CSSValue& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(layout_animation_data_);
  return CSSStyleUtils::ComputeEnumStyle<starlight::AnimationPropertyType>(
      value, reset, layout_animation_data_->delete_ani.property,
      starlight::AnimationPropertyType::kOpacity,
      "layout-animation-delete-property must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetLayoutAnimationDeleteTimingFunction(
    const tasm::CSSValue& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(layout_animation_data_);
  return SetLayoutAnimationTimingFunctionInternal(
      value, reset, layout_animation_data_->delete_ani.timing_function,
      parser_configs_);
}

// transition animation
bool ComputedCSSStyle::SetTransition(const tasm::CSSValue& value,
                                     const bool reset) {
  auto old_value = transition_data_;
  if (reset) {
    transition_data_.reset();
  } else {
    if (!tasm::UnitHandler::CSSWarning(
            value.IsArray(), parser_configs_.enable_css_strict_mode,
            tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDTransition)
                .c_str(),
            tasm::ARRAY_TYPE)) {
      return false;
    }
    if (!transition_data_) {
      transition_data_ = std::vector<TransitionData>();
    }
    transition_data_->clear();
    auto group = value.GetValue().Array();
    for (size_t i = 0; i < group->size(); i++) {
      if (transition_data_->size() < i + 1) {
        transition_data_->push_back(TransitionData());
      }
      auto dict = group->get(i).Table();
      (*transition_data_)[i].property = static_cast<AnimationPropertyType>(
          dict->GetValue("property").Number());
      (*transition_data_)[i].duration = dict->GetValue("duration").Number();
      if (dict->Contains("timing")) {
        DCHECK(dict->GetValue("timing").IsArray());
        CSSStyleUtils::ComputeTimingFunction(
            dict->GetValue("timing").Array()->get(0), reset,
            (*transition_data_)[i].timing_func, parser_configs_);
      }
      if (dict->Contains("delay")) {
        (*transition_data_)[i].delay = dict->GetValue("delay").Number();
      }
    }
  }
  return old_value != transition_data_;
}

bool ComputedCSSStyle::SetTransitionDuration(const tasm::CSSValue& value,
                                             const bool reset) {
  return SetTransitionHelper(
      transition_data_,
      [](std::optional<std::vector<TransitionData>>& transitionData,
         const int idx) -> long& { return (*transitionData)[idx].duration; },
      value, reset, "transition-duration must be a long!", parser_configs_);
}

bool ComputedCSSStyle::SetTransitionProperty(const tasm::CSSValue& value,
                                             const bool reset) {
  if (reset) {
    if (transition_data_) {
      transition_data_->clear();
    }
    // no use.
    return true;
  } else {
    if (!transition_data_) {
      transition_data_ = std::vector<TransitionData>();
      transition_data_->push_back(TransitionData());
    }
    if (value.IsArray()) {
      bool changed = false;
      auto arr = value.GetValue().Array();
      for (size_t i = 0; i < arr->size(); i++) {
        if (transition_data_->size() <= i) {
          transition_data_->push_back(TransitionData());
        }
        auto old = (*transition_data_)[i].property;
        (*transition_data_)[i].property =
            static_cast<AnimationPropertyType>(arr->get(i).Number());
        changed |= old != (*transition_data_)[i].property;
      }
      return changed;
    } else if (value.IsEnum()) {
      return CSSStyleUtils::ComputeEnumStyle<AnimationPropertyType>(
          value, reset, (*transition_data_)[0].property,
          AnimationPropertyType::kAll, "transition-property must be an enum!",
          parser_configs_);
    } else {
      return tasm::UnitHandler::CSSWarning(
          false, parser_configs_.enable_css_strict_mode,
          "transition property format error!");
    }
  }
}

bool ComputedCSSStyle::SetTransitionTimingFunction(const tasm::CSSValue& value,
                                                   const bool reset) {
  auto reset_func = [](TransitionData& anim) { anim.timing_func.Reset(); };
  auto compute_func = [this](const lepus::Value& value, TransitionData& anim,
                             bool reset) -> bool {
    return CSSStyleUtils::ComputeTimingFunction(value, reset, anim.timing_func,
                                                this->parser_configs_);
  };
  return CSSStyleUtils::SetAnimationProperty(transition_data_, value,
                                             reset_func, compute_func, reset,
                                             parser_configs_);
}

bool ComputedCSSStyle::SetTransitionDelay(const tasm::CSSValue& value,
                                          const bool reset) {
  return SetTransitionHelper(
      transition_data_,
      [](std::optional<std::vector<TransitionData>>& transitionData,
         const int idx) -> long& { return (*transitionData)[idx].delay; },
      value, reset, "transition-delay must be a long!", parser_configs_);
}

bool ComputedCSSStyle::SetEnterTransitionName(const lynx::tasm::CSSValue& value,
                                              bool reset) {
  return CSSStyleUtils::ComputeHeroAnimation(
      value, reset, enter_transition_data_,
      "enter-transition-name must is invalid.", parser_configs_);
}

bool ComputedCSSStyle::SetExitTransitionName(lynx::tasm::CSSValue const& value,
                                             bool reset) {
  return CSSStyleUtils::ComputeHeroAnimation(
      value, reset, exit_transition_data_,
      "exit-transition-name must is invalid.", parser_configs_);
}

bool ComputedCSSStyle::SetPauseTransitionName(lynx::tasm::CSSValue const& value,
                                              bool reset) {
  return CSSStyleUtils::ComputeHeroAnimation(
      value, reset, pause_transition_data_,
      "pause-transition-name must is invalid.", parser_configs_);
}

bool ComputedCSSStyle::SetResumeTransitionName(
    lynx::tasm::CSSValue const& value, bool reset) {
  return CSSStyleUtils::ComputeHeroAnimation(
      value, reset, resume_transition_data_,
      "resume-transition-name must is invalid.", parser_configs_);
}

bool ComputedCSSStyle::SetLineSpacing(const tasm::CSSValue& value,
                                      const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  auto old_value = text_attributes_->line_spacing;
  if (reset) {
    text_attributes_->line_spacing = DefaultCSSStyle::SL_DEFAULT_LINE_SPACING;
  } else if (UNLIKELY(!CalculateCSSValueToFloat(
                 value, text_attributes_->line_spacing, length_context_,
                 parser_configs_, true))) {
    return false;
  }
  return base::FloatsNotEqual(text_attributes_->line_spacing, old_value);
}

bool ComputedCSSStyle::SetColor(const tasm::CSSValue& value, const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  auto old_value_color = text_attributes_->color;
  auto old_value_gradient = text_attributes_->text_gradient;
  if (reset) {
    text_attributes_->color = DefaultCSSStyle::SL_DEFAULT_TEXT_COLOR;
    text_attributes_->text_gradient = DefaultCSSStyle::EMPTY_LEPUS_VALUE();
  } else {
    if (!tasm::UnitHandler::CSSWarning(
            value.IsNumber() || value.IsArray(),
            parser_configs_.enable_css_strict_mode, tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDColor).c_str(),
            tasm::ARRAY_OR_NUMBER_TYPE)) {
      return false;
    }
    if (value.IsNumber()) {
      text_attributes_->color =
          static_cast<uint32_t>(value.GetValue().Number());
      text_attributes_->text_gradient = DefaultCSSStyle::EMPTY_LEPUS_VALUE();
    } else {
      text_attributes_->color = DefaultCSSStyle::SL_DEFAULT_TEXT_COLOR;
      text_attributes_->text_gradient = value.GetValue();
    }
  }
  return old_value_color != text_attributes_->color ||
         old_value_gradient != text_attributes_->text_gradient;
}

bool ComputedCSSStyle::SetBackground(const tasm::CSSValue& value,
                                     const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetBackgroundColor(const tasm::CSSValue& value,
                                          const bool reset) {
  CSSStyleUtils::PrepareOptional(background_data_);
  return CSSStyleUtils::ComputeUIntStyle(
      value, reset, background_data_->color, DefaultCSSStyle::SL_DEFAULT_COLOR,
      "background-color must be a number!", parser_configs_);
}

bool ComputedCSSStyle::SetBackgroundImage(const tasm::CSSValue& value,
                                          const bool reset) {
  CSSStyleUtils::PrepareOptional(background_data_);
  auto old_value = background_data_->image;
  background_data_->image_count = DefaultCSSStyle::SL_DEFAULT_LONG;
  background_data_->image = lepus::Value();
  if (!reset) {
    if (!tasm::UnitHandler::CSSWarning(
            value.IsArray(), parser_configs_.enable_css_strict_mode,
            tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDBackgroundImage)
                .c_str(),
            tasm::ARRAY_TYPE)) {
      return false;
    }
    auto array = value.GetValue().Array();
    for (size_t i = 0; i < array->size(); i++) {
      const auto& img = array->get(i);
      if (img.IsNumber()) {
        ++background_data_->image_count;
      }
    }
    background_data_->image = value.GetValue();
  }
  return old_value != background_data_->image;
}

bool ComputedCSSStyle::SetBackgroundSize(const tasm::CSSValue& value,
                                         const bool reset) {
  CSSStyleUtils::PrepareOptional(background_data_);
  auto old_value = background_data_->size;
  background_data_->size.clear();
  if (!reset) {
    if (!tasm::UnitHandler::CSSWarning(
            value.IsArray(), parser_configs_.enable_css_strict_mode,
            tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDBackgroundSize)
                .c_str(),
            tasm::ARRAY_TYPE)) {
      return false;
    }
    for (size_t i = 0; i != value.GetValue().Array()->size(); ++i) {
      auto array = value.GetValue().Array()->get(i).Array();
      auto pattern = static_cast<uint32_t>(array->get(0).Number());
      background_data_->size.emplace_back(
          NLength((CSSStyleUtils::ToLength(
                       tasm::CSSValue(array->get(1),
                                      static_cast<CSSValuePattern>(pattern)),
                       length_context_, parser_configs_))
                      .first));
      pattern = static_cast<uint32_t>(array->get(2).Number());
      background_data_->size.emplace_back(
          NLength((CSSStyleUtils::ToLength(
                       tasm::CSSValue(array->get(3),
                                      static_cast<CSSValuePattern>(pattern)),
                       length_context_, parser_configs_))
                      .first));
    }
  }
  return old_value != background_data_->size;
}

bool ComputedCSSStyle::SetBackgroundClip(const lynx::tasm::CSSValue& value,
                                         bool reset) {
  CSSStyleUtils::PrepareOptional(background_data_);
  auto old_value = background_data_->clip;
  background_data_->clip.clear();
  if (!reset) {
    if (!tasm::UnitHandler::CSSWarning(
            value.IsArray(), parser_configs_.enable_css_strict_mode,
            tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDBackgroundClip)
                .c_str(),
            tasm::ARRAY_TYPE)) {
      return false;
    }
    auto clip_arr = value.GetValue().Array();
    for (size_t i = 0; i < clip_arr->size(); i++) {
      auto clip_type = static_cast<uint32_t>(clip_arr->get(i).Number());
      background_data_->clip.emplace_back(
          static_cast<BackgroundClipType>(clip_type));
    }
  }
  return old_value != background_data_->clip;
}

bool ComputedCSSStyle::SetBackgroundPosition(const tasm::CSSValue& value,
                                             const bool reset) {
  CSSStyleUtils::PrepareOptional(background_data_);
  auto old_value = background_data_->position;
  background_data_->position.clear();
  if (!reset) {
    if (!tasm::UnitHandler::CSSWarning(value.IsArray(),
                                       parser_configs_.enable_css_strict_mode,
                                       tasm::TYPE_MUST_BE,
                                       tasm::CSSProperty::GetPropertyName(
                                           tasm::kPropertyIDBackgroundPosition)
                                           .c_str(),
                                       tasm::ARRAY_TYPE)) {
      return false;
    }
    for (size_t i = 0; i != value.GetValue().Array()->size(); ++i) {
      auto array = value.GetValue().Array()->get(i).Array();
      uint32_t pos_x_type = static_cast<uint32_t>(array->get(0).Number());
      uint32_t pos_y_type = static_cast<uint32_t>(array->get(2).Number());
      ;
      // position x
      if (pos_x_type ==
          static_cast<uint32_t>(BackgroundPositionType::kCenter)) {
        background_data_->position.emplace_back(
            NLength::MakePercentageNLength(50.f));
      } else if (pos_x_type ==
                 static_cast<uint32_t>(BackgroundPositionType::kLeft)) {
        background_data_->position.emplace_back(
            NLength::MakePercentageNLength(0.f));
      } else if (pos_x_type ==
                 static_cast<uint32_t>(BackgroundPositionType::kRight)) {
        background_data_->position.emplace_back(
            NLength::MakePercentageNLength(100.f));
      } else {
        auto pattern = static_cast<uint32_t>(array->get(0).Number());
        background_data_->position.emplace_back(
            NLength(CSSStyleUtils::ToLength(
                        tasm::CSSValue{array->get(1),
                                       static_cast<CSSValuePattern>(pattern)},
                        length_context_, parser_configs_)
                        .first));
      }

      // position y
      if (pos_y_type ==
          static_cast<uint32_t>(BackgroundPositionType::kCenter)) {
        background_data_->position.emplace_back(
            NLength::MakePercentageNLength(50.f));
      } else if (pos_y_type ==
                 static_cast<uint32_t>(BackgroundPositionType::kTop)) {
        background_data_->position.emplace_back(
            NLength::MakePercentageNLength(0.f));
      } else if (pos_y_type ==
                 static_cast<uint32_t>(BackgroundPositionType::kBottom)) {
        background_data_->position.emplace_back(
            NLength::MakePercentageNLength(100.f));
      } else {
        auto pattern = static_cast<uint32_t>(array->get(2).Number());
        background_data_->position.emplace_back(
            NLength(CSSStyleUtils::ToLength(
                        tasm::CSSValue{array->get(3),
                                       static_cast<CSSValuePattern>(pattern)},
                        length_context_, parser_configs_)
                        .first));
      }
    }
  }
  return old_value != background_data_->position;
}

bool ComputedCSSStyle::SetBackgroundRepeat(const tasm::CSSValue& value,
                                           const bool reset) {
  CSSStyleUtils::PrepareOptional(background_data_);
  auto old_value = background_data_->repeat;
  background_data_->repeat.clear();
  if (!reset) {
    if (!tasm::UnitHandler::CSSWarning(value.IsArray(),
                                       parser_configs_.enable_css_strict_mode,
                                       tasm::TYPE_MUST_BE,
                                       tasm::CSSProperty::GetPropertyName(
                                           tasm::kPropertyIDBackgroundRepeat)
                                           .c_str(),
                                       tasm::ARRAY_TYPE)) {
      return false;
    }
    auto repeat_arr = value.GetValue().Array();
    for (size_t i = 0; i < repeat_arr->size(); i++) {
      auto repeat_type =
          static_cast<uint32_t>(repeat_arr->get(i).Array()->get(0).Number());
      background_data_->repeat.emplace_back(
          static_cast<BackgroundRepeatType>(repeat_type));
      repeat_type =
          static_cast<uint32_t>(repeat_arr->get(i).Array()->get(1).Number());
      background_data_->repeat.emplace_back(
          static_cast<BackgroundRepeatType>(repeat_type));
    }
  }
  return old_value != background_data_->repeat;
}

bool ComputedCSSStyle::SetBackgroundOrigin(const tasm::CSSValue& value,
                                           const bool reset) {
  CSSStyleUtils::PrepareOptional(background_data_);
  auto old_value = background_data_->origin;
  background_data_->origin.clear();
  if (!reset) {
    if (!tasm::UnitHandler::CSSWarning(value.IsArray(),
                                       parser_configs_.enable_css_strict_mode,
                                       tasm::TYPE_MUST_BE,
                                       tasm::CSSProperty::GetPropertyName(
                                           tasm::kPropertyIDBackgroundOrigin)
                                           .c_str(),
                                       tasm::ARRAY_TYPE)) {
      return false;
    }
    auto origin_arr = value.GetValue().Array();
    for (size_t i = 0; i < origin_arr->size(); i++) {
      auto origin_type = static_cast<uint32_t>(origin_arr->get(i).Number());
      background_data_->origin.emplace_back(
          static_cast<BackgroundOriginType>(origin_type));
    }
  }
  return old_value != background_data_->origin;
}

bool ComputedCSSStyle::SetMaskImage(const tasm::CSSValue& value,
                                    const bool reset) {
  lepus::Value origin = mask_image_;
  mask_image_ = value.GetValue();
  if (reset) {
    mask_image_ = lepus::Value();
  }
  return origin != mask_image_;
}

bool ComputedCSSStyle::SetFilter(const tasm::CSSValue& value,
                                 const bool reset) {
  if (!value.IsArray()) {
    // CSSParser enabled, only grayscale supported.
    auto last_filter = filter_;
    if (reset) {
      filter_.reset();
    } else {
      CSSStyleUtils::PrepareOptional(filter_);
      (*filter_).type = FilterType::kGrayscale;
      (*filter_).amount =
          NLength::MakePercentageNLength(value.GetValue().Number() * 100);
    }
    return last_filter != filter_;
  }

  return CSSStyleUtils::ComputeFilter(value, reset, filter_, length_context_,
                                      parser_configs_);
}

bool ComputedCSSStyle::SetBorderTopColor(const tasm::CSSValue& value,
                                         const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_);
  return CSSStyleUtils::ComputeUIntStyle(
      value, reset, surround_data_.border_data_->color_top,
      DefaultCSSStyle::SL_DEFAULT_BORDER_COLOR,
      "border-top-color must be a number", parser_configs_);
}

bool ComputedCSSStyle::SetBorderRightColor(const tasm::CSSValue& value,
                                           const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_);
  return CSSStyleUtils::ComputeUIntStyle(
      value, reset, surround_data_.border_data_->color_right,
      DefaultCSSStyle::SL_DEFAULT_BORDER_COLOR,
      "border-right-color must be a number", parser_configs_);
}

bool ComputedCSSStyle::SetBorderBottomColor(const tasm::CSSValue& value,
                                            const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_);
  return CSSStyleUtils::ComputeUIntStyle(
      value, reset, surround_data_.border_data_->color_bottom,
      DefaultCSSStyle::SL_DEFAULT_BORDER_COLOR,
      "border-bottom-color must be a number", parser_configs_);
}

bool ComputedCSSStyle::SetBorderLeftColor(const tasm::CSSValue& value,
                                          const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_);
  return CSSStyleUtils::ComputeUIntStyle(
      value, reset, surround_data_.border_data_->color_left,
      DefaultCSSStyle::SL_DEFAULT_BORDER_COLOR,
      "border-left-color must be a number", parser_configs_);
}

bool ComputedCSSStyle::SetBorderTopStyle(const tasm::CSSValue& value,
                                         const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_,
                                 css_align_with_legacy_w3c_);
  return CSSStyleUtils::ComputeEnumStyle<BorderStyleType>(
      value, reset, surround_data_.border_data_->style_top,
      DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE),
      "border-top-style must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetBorderRightStyle(const tasm::CSSValue& value,
                                           const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_,
                                 css_align_with_legacy_w3c_);
  return CSSStyleUtils::ComputeEnumStyle<BorderStyleType>(
      value, reset, surround_data_.border_data_->style_right,
      DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE),
      "border-right-style must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetBorderBottomStyle(const tasm::CSSValue& value,
                                            const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_,
                                 css_align_with_legacy_w3c_);
  return CSSStyleUtils::ComputeEnumStyle<BorderStyleType>(
      value, reset, surround_data_.border_data_->style_bottom,
      DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE),
      "border-bottom-style must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetBorderLeftStyle(const tasm::CSSValue& value,
                                          const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_,
                                 css_align_with_legacy_w3c_);
  return CSSStyleUtils::ComputeEnumStyle<BorderStyleType>(
      value, reset, surround_data_.border_data_->style_left,
      DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE),
      "border-left-style must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetOutlineColor(const lynx::tasm::CSSValue& value,
                                       bool reset) {
  CSSStyleUtils::PrepareOptional(outline_);
  return CSSStyleUtils::ComputeUIntStyle(
      value, reset, outline_->color, DefaultCSSStyle::SL_DEFAULT_OUTLINE_COLOR,
      "outline-color must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetOutlineStyle(const lynx::tasm::CSSValue& value,
                                       bool reset) {
  CSSStyleUtils::PrepareOptional(outline_);
  return CSSStyleUtils::ComputeEnumStyle(
      value, reset, outline_->style,
      DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE),
      "outline-style must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetOutlineWidth(const lynx::tasm::CSSValue& value,
                                       bool reset) {
  CSSStyleUtils::PrepareOptional(outline_);
  float old_value = outline_->width;
  if (reset) {
    outline_->width = DefaultCSSStyle::SL_DEFAULT_FLOAT;
  } else {
    if (UNLIKELY(!CSSStyleUtils::CalculateLength(
            value, outline_->width, length_context_, parser_configs_))) {
      return false;
    }
  }
  return base::FloatsNotEqual(old_value, outline_->width);
}

bool ComputedCSSStyle::SetVisibility(const tasm::CSSValue& value,
                                     const bool reset) {
  return CSSStyleUtils::ComputeEnumStyle<VisibilityType>(
      value, reset, visibility_, DefaultCSSStyle::SL_DEFAULT_VISIBILITY,
      "visibility must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetBoxShadow(const tasm::CSSValue& value,
                                    const bool reset) {
  return CSSStyleUtils::ComputeShadowStyle(value, reset, box_shadow_,
                                           length_context_, parser_configs_);
}

bool ComputedCSSStyle::SetBorderColor(const tasm::CSSValue& value,
                                      const bool reset) {
  return tasm::UnitHandler::CSSWarning(false,
                                       parser_configs_.enable_css_strict_mode,
                                       "Set Border Color will never be called");
}

bool ComputedCSSStyle::SetFontFamily(const tasm::CSSValue& value,
                                     const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  return CSSStyleUtils::ComputeStringStyle(
      value, reset, text_attributes_->font_family,
      DefaultCSSStyle::EMPTY_LEPUS_STRING(), "font family must be a string!",
      parser_configs_);
}

bool ComputedCSSStyle::SetCaretColor(const lynx::tasm::CSSValue& value,
                                     bool reset) {
  return CSSStyleUtils::ComputeStringStyle(
      value, reset, caret_color_, DefaultCSSStyle::EMPTY_LEPUS_STRING(),
      "caret-color must be a string!", parser_configs_);
}

bool ComputedCSSStyle::SetTextShadow(const tasm::CSSValue& value,
                                     const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  return CSSStyleUtils::ComputeShadowStyle(value, reset,
                                           text_attributes_->text_shadow,
                                           length_context_, parser_configs_);
}

bool ComputedCSSStyle::SetWhiteSpace(const tasm::CSSValue& value,
                                     const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  return CSSStyleUtils::ComputeEnumStyle<WhiteSpaceType>(
      value, reset, text_attributes_->white_space,
      DefaultCSSStyle::SL_DEFAULT_WHITE_SPACE, "white-space must be an enum!",
      parser_configs_);
}

bool ComputedCSSStyle::SetFontWeight(const tasm::CSSValue& value,
                                     const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  return CSSStyleUtils::ComputeEnumStyle<starlight::FontWeightType>(
      value, reset, text_attributes_->font_weight,
      DefaultCSSStyle::SL_DEFAULT_FONT_WEIGHT, "font weight must be an enum!",
      parser_configs_);
}

bool ComputedCSSStyle::SetWordBreak(const tasm::CSSValue& value,
                                    const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  return CSSStyleUtils::ComputeEnumStyle<WordBreakType>(
      value, reset, text_attributes_->word_break,
      DefaultCSSStyle::SL_DEFAULT_WORD_BREAK, "word-break must be an enum!",
      parser_configs_);
}

bool ComputedCSSStyle::SetFontStyle(const tasm::CSSValue& value,
                                    const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  return CSSStyleUtils::ComputeEnumStyle<starlight::FontStyleType>(
      value, reset, text_attributes_->font_style,
      DefaultCSSStyle::SL_DEFAULT_FONT_STYLE, "font style must be an enum!",
      parser_configs_);
}

bool ComputedCSSStyle::SetTextAlign(const tasm::CSSValue& value,
                                    const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  return CSSStyleUtils::ComputeEnumStyle<starlight::TextAlignType>(
      value, reset, text_attributes_->text_align,
      DefaultCSSStyle::SL_DEFAULT_TEXT_ALIGN, "text align must be an enum!",
      parser_configs_);
}

bool ComputedCSSStyle::SetTextOverflow(const tasm::CSSValue& value,
                                       const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  return CSSStyleUtils::ComputeEnumStyle<starlight::TextOverflowType>(
      value, reset, text_attributes_->text_overflow,
      DefaultCSSStyle::SL_DEFAULT_TEXT_OVERFLOW,
      "text overflow must be an enum!", parser_configs_);
}

bool ComputedCSSStyle::SetTextDecoration(const tasm::CSSValue& value,
                                         const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  int old_flags = static_cast<int>(TextDecorationType::kNone);
  int old_color = text_attributes_->text_decoration_color;
  if (text_attributes_->underline_decoration) {
    old_flags |= static_cast<int>(TextDecorationType::kUnderLine);
  }
  if (text_attributes_->line_through_decoration) {
    old_flags |= static_cast<int>(TextDecorationType::kLineThrough);
  }
  if (text_attributes_->text_decoration_style) {
    old_flags |= static_cast<int>(text_attributes_->text_decoration_style);
  }
  int new_flags = 0;
  int new_color = 0;
  if (reset) {
    text_attributes_->underline_decoration =
        DefaultCSSStyle::SL_DEFAULT_BOOLEAN;
    text_attributes_->line_through_decoration =
        DefaultCSSStyle::SL_DEFAULT_BOOLEAN;
    text_attributes_->text_decoration_style =
        static_cast<unsigned int>(TextDecorationType::kSolid);
    text_attributes_->text_decoration_color = 0;
  } else {
    text_attributes_->underline_decoration =
        DefaultCSSStyle::SL_DEFAULT_BOOLEAN;
    text_attributes_->line_through_decoration =
        DefaultCSSStyle::SL_DEFAULT_BOOLEAN;
    text_attributes_->text_decoration_style =
        static_cast<unsigned int>(TextDecorationType::kSolid);
    text_attributes_->text_decoration_color = 0;
    auto result = value.GetValue().Array();
    for (size_t i = 0; i < result->size(); i++) {
      int decoration = static_cast<int>(result->get(i).Number());
      if (decoration & static_cast<int>(TextDecorationType::kColor)) {
        new_color = text_attributes_->text_decoration_color =
            static_cast<uint32_t>(result->get(i + 1).Number());
        i++;
        continue;
      }
      if (decoration & static_cast<int>(TextDecorationType::kUnderLine)) {
        text_attributes_->underline_decoration = true;
      } else if (decoration &
                 static_cast<int>(TextDecorationType::kLineThrough)) {
        text_attributes_->line_through_decoration = true;
      } else if (decoration) {
        text_attributes_->text_decoration_style = decoration;
      }
      new_flags |= decoration;
    }
  }
  return (old_flags != new_flags) || (old_color != new_color);
}

bool ComputedCSSStyle::SetTextDecorationColor(const tasm::CSSValue& value,
                                              const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  auto old_value_color = text_attributes_->decoration_color;
  if (reset) {
    text_attributes_->decoration_color = DefaultCSSStyle::SL_DEFAULT_COLOR;
  } else {
    if (!tasm::UnitHandler::CSSWarning(value.IsNumber(),
                                       parser_configs_.enable_css_strict_mode,
                                       tasm::TYPE_MUST_BE,
                                       tasm::CSSProperty::GetPropertyName(
                                           tasm::kPropertyIDTextDecorationColor)
                                           .c_str(),
                                       tasm::NUMBER_TYPE)) {
      return false;
    }
    if (value.IsNumber()) {
      text_attributes_->decoration_color =
          static_cast<unsigned int>(value.GetValue().Number());
    }
  }
  return old_value_color != text_attributes_->decoration_color;
}

bool ComputedCSSStyle::SetZIndex(const tasm::CSSValue& value,
                                 const bool reset) {
  return CSSStyleUtils::ComputeIntStyle(
      value, reset, z_index_, 0, "z-index must be a number!", parser_configs_);
}

bool ComputedCSSStyle::SetBorderRadius(const tasm::CSSValue& value,
                                       const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_);
  auto old_value = surround_data_.border_data_;
  if (reset) {
    surround_data_.border_data_->radius_x_top_left =
        DefaultCSSStyle::SL_DEFAULT_RADIUS();
    surround_data_.border_data_->radius_y_top_left =
        DefaultCSSStyle::SL_DEFAULT_RADIUS();
    surround_data_.border_data_->radius_x_top_right =
        DefaultCSSStyle::SL_DEFAULT_RADIUS();
    surround_data_.border_data_->radius_y_top_right =
        DefaultCSSStyle::SL_DEFAULT_RADIUS();
    surround_data_.border_data_->radius_x_bottom_left =
        DefaultCSSStyle::SL_DEFAULT_RADIUS();
    surround_data_.border_data_->radius_y_bottom_left =
        DefaultCSSStyle::SL_DEFAULT_RADIUS();
    surround_data_.border_data_->radius_x_bottom_right =
        DefaultCSSStyle::SL_DEFAULT_RADIUS();
    surround_data_.border_data_->radius_y_bottom_right =
        DefaultCSSStyle::SL_DEFAULT_RADIUS();
  } else {
    if (!tasm::UnitHandler::CSSWarning(
            value.IsArray(), parser_configs_.enable_css_strict_mode,
            tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDBorderRadius)
                .c_str(),
            tasm::ARRAY_TYPE)) {
      return false;
    }
    auto container = value.GetValue().Array();
    for (int i = 0; i < 4; i++) {
      auto parse_result = CSSStyleUtils::ToLength(
          tasm::CSSValue(
              container->get(i * 4),
              static_cast<CSSValuePattern>(container->get(i * 4 + 1).Number())),
          length_context_, parser_configs_);

      if (!tasm::UnitHandler::CSSWarning(
              parse_result.second, parser_configs_.enable_css_strict_mode,
              tasm::SET_PROPERTY_ERROR,
              tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDBorderRadius)
                  .c_str())) {
        return false;
      }
      if (i == 0) {
        surround_data_.border_data_->radius_x_top_left =
            std::move(parse_result.first);
      } else if (i == 1) {
        surround_data_.border_data_->radius_x_top_right =
            std::move(parse_result.first);
      } else if (i == 2) {
        surround_data_.border_data_->radius_x_bottom_right =
            std::move(parse_result.first);
      } else if (i == 3) {
        surround_data_.border_data_->radius_x_bottom_left =
            std::move(parse_result.first);
      }

      parse_result = CSSStyleUtils::ToLength(
          tasm::CSSValue(
              container->get(i * 4 + 2),
              static_cast<CSSValuePattern>(container->get(i * 4 + 3).Number())),
          length_context_, parser_configs_);

      if (!tasm::UnitHandler::CSSWarning(
              parse_result.second, parser_configs_.enable_css_strict_mode,
              tasm::SET_PROPERTY_ERROR,
              tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDBorderRadius)
                  .c_str())) {
        return false;
      }
      if (i == 0) {
        surround_data_.border_data_->radius_y_top_left =
            std::move(parse_result.first);
      } else if (i == 1) {
        surround_data_.border_data_->radius_y_top_right =
            std::move(parse_result.first);
      } else if (i == 2) {
        surround_data_.border_data_->radius_y_bottom_right =
            std::move(parse_result.first);
      } else if (i == 3) {
        surround_data_.border_data_->radius_y_bottom_left =
            std::move(parse_result.first);
      }
    }
  }
  return old_value->radius_x_top_left !=
             surround_data_.border_data_->radius_x_top_left ||
         old_value->radius_y_top_left !=
             surround_data_.border_data_->radius_y_top_left ||
         old_value->radius_x_top_right !=
             surround_data_.border_data_->radius_x_top_right ||
         old_value->radius_y_top_right !=
             surround_data_.border_data_->radius_y_top_right ||
         old_value->radius_x_bottom_left !=
             surround_data_.border_data_->radius_x_bottom_left ||
         old_value->radius_y_bottom_left !=
             surround_data_.border_data_->radius_y_bottom_left ||
         old_value->radius_x_bottom_right !=
             surround_data_.border_data_->radius_x_bottom_right ||
         old_value->radius_y_bottom_right !=
             surround_data_.border_data_->radius_y_bottom_right;
}

bool ComputedCSSStyle::SetBorderTopLeftRadius(const tasm::CSSValue& value,
                                              const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_);
  auto old_value = surround_data_.border_data_;

  return SetBorderRadiusHelper(surround_data_.border_data_->radius_x_top_left,
                               surround_data_.border_data_->radius_y_top_left,
                               length_context_,
                               tasm::kPropertyIDBorderTopLeftRadius, value,
                               reset, parser_configs_) &&
         (old_value->radius_x_top_left !=
              surround_data_.border_data_->radius_x_top_left ||
          old_value->radius_y_top_left !=
              surround_data_.border_data_->radius_y_top_left);
}

bool ComputedCSSStyle::SetBorderTopRightRadius(const tasm::CSSValue& value,
                                               const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_);
  auto old_value = surround_data_.border_data_;

  return SetBorderRadiusHelper(surround_data_.border_data_->radius_x_top_right,
                               surround_data_.border_data_->radius_y_top_right,
                               length_context_,
                               tasm::kPropertyIDBorderTopRightRadius, value,
                               reset, parser_configs_) &&
         (old_value->radius_x_top_right !=
              surround_data_.border_data_->radius_x_top_right ||
          old_value->radius_y_top_right !=
              surround_data_.border_data_->radius_y_top_right);
}

bool ComputedCSSStyle::SetBorderBottomRightRadius(const tasm::CSSValue& value,
                                                  const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_);
  auto old_value = surround_data_.border_data_;

  return SetBorderRadiusHelper(
             surround_data_.border_data_->radius_x_bottom_right,
             surround_data_.border_data_->radius_y_bottom_right,
             length_context_, tasm::kPropertyIDBorderBottomRightRadius, value,
             reset, parser_configs_) &&
         (old_value->radius_x_bottom_right !=
              surround_data_.border_data_->radius_x_bottom_right ||
          old_value->radius_y_bottom_right !=
              surround_data_.border_data_->radius_y_bottom_right);
}

bool ComputedCSSStyle::SetBorderBottomLeftRadius(const tasm::CSSValue& value,
                                                 const bool reset) {
  CSSStyleUtils::PrepareOptional(surround_data_.border_data_);
  auto old_value = surround_data_.border_data_;

  return SetBorderRadiusHelper(
             surround_data_.border_data_->radius_x_bottom_left,
             surround_data_.border_data_->radius_y_bottom_left, length_context_,
             tasm::kPropertyIDBorderBottomLeftRadius, value, reset,
             parser_configs_) &&
         (old_value->radius_x_bottom_left !=
              surround_data_.border_data_->radius_x_bottom_left ||
          old_value->radius_y_bottom_left !=
              surround_data_.border_data_->radius_y_bottom_left);
}

bool ComputedCSSStyle::SetBorderStyle(const tasm::CSSValue& value,
                                      const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetAdaptFontSize(const tasm::CSSValue& value,
                                        const bool reset) {
  return CSSStyleUtils::ComputeStringStyle(
      value, reset, adapt_font_size_, DefaultCSSStyle::EMPTY_LEPUS_STRING(),
      "adapt-font-size must be a string!", parser_configs_);
}

bool ComputedCSSStyle::SetOutline(const tasm::CSSValue& value,
                                  const bool reset) {
  return tasm::UnitHandler::CSSWarning(
      false, parser_configs_.enable_css_strict_mode, tasm::CANNOT_REACH_METHOD);
}

bool ComputedCSSStyle::SetVerticalAlign(const tasm::CSSValue& value,
                                        const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  auto old_value_type = text_attributes_->vertical_align;
  auto old_value_length = text_attributes_->vertical_align_length;
  if (reset) {
    text_attributes_->vertical_align =
        DefaultCSSStyle::SL_DEFAULT_VERTICAL_ALIGN;
    text_attributes_->vertical_align_length = DefaultCSSStyle::SL_DEFAULT_FLOAT;
  } else {
    if (!tasm::UnitHandler::CSSWarning(
            value.IsArray(), parser_configs_.enable_css_strict_mode,
            tasm::TYPE_MUST_BE,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDVerticalAlign)
                .c_str(),
            tasm::ARRAY_TYPE)) {
      return false;
    }
    auto arr = value.GetValue().Array();
    if (!tasm::UnitHandler::CSSWarning(
            arr->size() == 4, parser_configs_.enable_css_strict_mode,
            tasm::SIZE_ERROR,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDVerticalAlign)
                .c_str(),
            arr->size())) {
      return false;
    }
    if (!tasm::UnitHandler::CSSWarning(
            static_cast<CSSValuePattern>(arr->get(1).Number()) ==
                CSSValuePattern::ENUM,
            parser_configs_.enable_css_strict_mode, tasm::TYPE_ERROR,
            tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDVerticalAlign)
                .c_str())) {
      return false;
    }
    text_attributes_->vertical_align =
        static_cast<starlight::VerticalAlignType>(arr->get(0).Number());
    if (text_attributes_->vertical_align == VerticalAlignType::kLength) {
      auto pattern = static_cast<tasm::CSSValuePattern>(arr->get(3).Number());
      std::pair<NLength, bool> result =
          CSSStyleUtils::ToLength(tasm::CSSValue(arr->get(2), pattern),
                                  length_context_, parser_configs_);
      if (!tasm::UnitHandler::CSSWarning(
              (result.second && result.first.IsUnit()),
              parser_configs_.enable_css_strict_mode, tasm::TYPE_ERROR,
              tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDVerticalAlign)
                  .c_str())) {
        return false;
      }
      text_attributes_->vertical_align_length = result.first.GetRawValue();
    } else if (text_attributes_->vertical_align ==
               VerticalAlignType::kPercent) {
      if (!tasm::UnitHandler::CSSWarning(
              arr->get(2).IsNumber(), parser_configs_.enable_css_strict_mode,
              tasm::TYPE_ERROR,
              tasm::CSSProperty::GetPropertyName(tasm::kPropertyIDVerticalAlign)
                  .c_str())) {
        return false;
      }
      text_attributes_->vertical_align_length = arr->get(2).Number();
    } else {
      text_attributes_->vertical_align_length = 0.0f;
    }
  }
  return old_value_type != text_attributes_->vertical_align ||
         old_value_length != text_attributes_->vertical_align_length;
}

bool ComputedCSSStyle::SetContent(const tasm::CSSValue& value,
                                  const bool reset) {
  return CSSStyleUtils::ComputeStringStyle(
      value, reset, content_, DefaultCSSStyle::EMPTY_LEPUS_STRING(),
      "content must be a string!", parser_configs_);
}

bool ComputedCSSStyle::SetListMainAxisGap(const tasm::CSSValue& value,
                                          const bool reset) {
  return CSSStyleUtils::ComputeLengthStyle(
      value, reset, length_context_, list_main_axis_gap_,
      DefaultCSSStyle::SL_DEFAULT_ZEROLENGTH(), parser_configs_);
}

bool ComputedCSSStyle::SetListCrossAxisGap(const tasm::CSSValue& value,
                                           const bool reset) {
  return CSSStyleUtils::ComputeLengthStyle(
      value, reset, length_context_, list_cross_axis_gap_,
      DefaultCSSStyle::SL_DEFAULT_ZEROLENGTH(), parser_configs_);
}

bool ComputedCSSStyle::SetClipPath(const tasm::CSSValue& value,
                                   const bool reset) {
  // ref to old array
  base::scoped_refptr<lepus::CArray> last_path = clip_path_;
  clip_path_ = lepus::CArray::Create();

  base::scoped_refptr<lepus::CArray> raw_array;
  BasicShapeType type = BasicShapeType::kUnknown;
  if (reset || !value.IsArray() || value.GetValue().Array()->size() == 0) {
    // if not reset, it means value is invalid and launch warning.
    LynxWarning(reset, LYNX_ERROR_CODE_CSS, "clip-path must be an array")
  } else {
    raw_array = value.GetValue().Array();
    type = static_cast<starlight::BasicShapeType>(raw_array->get(0).Number());
  }

  switch (type) {
    case BasicShapeType::kUnknown:
      // Unknown type, reset the clip-path.
      break;
    case BasicShapeType::kCircle:
      if (raw_array->size() != 7) {
        LOGW("Error in parsing basic shape circle.");
        return false;
      }
      CSSStyleUtils::ComputeBasicShapeCircle(raw_array, reset, clip_path_,
                                             length_context_, parser_configs_);
      break;
    case BasicShapeType::kEllipse:
      if (raw_array->size() != 9) {
        LOGW("Error in parsing basic shape circle.");
        return false;
      }
      CSSStyleUtils::ComputeBasicShapeEllipse(raw_array, reset, clip_path_,
                                              length_context_, parser_configs_);
      break;
    case BasicShapeType::kPath:
      if (raw_array->size() != 2) {
        LOGW("Error in parsing basic shape path.");
        return false;
      }
      CSSStyleUtils::ComputeBasicShapePath(raw_array, reset, clip_path_);
      break;
    case BasicShapeType::kSuperEllipse:
      if (raw_array->size() != 11) {
        LOGW("Error in parsing super ellipse.");
        return false;
      }
      CSSStyleUtils::ComputeSuperEllipse(raw_array, reset, clip_path_,
                                         length_context_, parser_configs_);
      break;
    case BasicShapeType::kInset:
      constexpr int INSET_ARRAY_LENGTH_RECT = 9;
      constexpr int INSET_ARRAY_LENGTH_ROUND = 25;
      constexpr int INSET_ARRAY_LENGTH_SUPER_ELLIPSE = 27;
      if (raw_array->size() != INSET_ARRAY_LENGTH_RECT &&
          raw_array->size() != INSET_ARRAY_LENGTH_ROUND &&
          raw_array->size() != INSET_ARRAY_LENGTH_SUPER_ELLIPSE) {
        LOGW("Error in parsing basic shape inset.");
        return false;
      }
      CSSStyleUtils::ComputeBasicShapeInset(raw_array, reset, clip_path_,
                                            length_context_, parser_configs_);
      break;
  }
  // Check last path equals to current path.
  return last_path.Get() == nullptr || *last_path != *clip_path_;
}

// TODO(liyanbo): this will replace by drawInfo.
// getter

lepus_value ComputedCSSStyle::OpacityToLepus() { return lepus_value(opacity_); }

lepus_value ComputedCSSStyle::PositionToLepus() {
  return lepus_value(static_cast<int>(position_));
}

lepus_value ComputedCSSStyle::OverflowToLepus() {
  return lepus_value(static_cast<int>(overflow_));
}

lepus_value ComputedCSSStyle::OverflowXToLepus() {
  return lepus_value(static_cast<int>(overflow_x_));
}
lepus_value ComputedCSSStyle::OverflowYToLepus() {
  return lepus_value(static_cast<int>(overflow_y_));
}

lepus_value ComputedCSSStyle::FontSizeToLepus() {
  if (text_attributes_) {
    return lepus_value(text_attributes_->font_size);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::LineHeightToLepus() {
  if (text_attributes_) {
    return lepus_value(text_attributes_->computed_line_height);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::PerspectiveToLepus() {
  auto array = lepus::CArray::Create();
  NLength& length = perspective_data_->length_;
  tasm::CSSValuePattern pattern = perspective_data_->pattern_;
  array->push_back(lepus::Value(length.GetRawValue()));
  if (length.IsUnit()) {
    if (pattern == tasm::CSSValuePattern::NUMBER) {
      array->push_back(
          lepus::Value(static_cast<int>(PerspectiveLengthUnit::NUMBER)));
    } else {
      array->push_back(
          lepus::Value(static_cast<int>(PerspectiveLengthUnit::PX)));
    }
  } else {
    array->push_back(
        lepus::Value(static_cast<int>(PerspectiveLengthUnit::DEFAULT)));
  }
  return lepus_value(array);
}

lepus_value ComputedCSSStyle::LetterSpacingToLepus() {
  if (text_attributes_) {
    return lepus_value(static_cast<double>(text_attributes_->letter_spacing));
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::LineSpacingToLepus() {
  if (text_attributes_) {
    return lepus_value(static_cast<double>(text_attributes_->line_spacing));
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::ColorToLepus() {
  if (text_attributes_) {
    if (text_attributes_->text_gradient.IsArray()) {
      return text_attributes_->text_gradient;
    } else {
      return lepus_value(text_attributes_->color);
    }
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BackgroundToLepus() { return lepus_value(); }

lepus_value ComputedCSSStyle::BackgroundColorToLepus() {
  if (background_data_) {
    return lepus_value(background_data_->color);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BackgroundImageToLepus() {
  if (background_data_ && background_data_->image.IsArray()) {
    return background_data_->image;
  } else {
    return lepus::Value{lepus::CArray::Create()};
  }
}

lepus_value ComputedCSSStyle::BackgroundSizeToLepus() {
  if (background_data_ && !background_data_->size.empty()) {
    auto array = lepus::CArray::Create();
    for (const auto& size : background_data_->size) {
      if (size.IsPercent()) {
        array->push_back(lepus::Value{size.GetRawValue() / 100.f});
        array->push_back(lepus::Value(
            static_cast<int>(starlight::PlatformLengthUnit::PERCENTAGE)));
      } else {
        array->push_back(
            lepus::Value{NLengthToLayoutUnit(size, LayoutUnit(0.f)).ToFloat()});
        array->push_back(lepus::Value(
            static_cast<int>(starlight::PlatformLengthUnit::NUMBER)));
      }
    }
    return lepus::Value{array};
  } else {
    return lepus::Value{lepus::CArray::Create()};
  }
}

lepus_value ComputedCSSStyle::BackgroundClipToLepus() {
  if (background_data_ && !background_data_->clip.empty()) {
    auto array = lepus::CArray::Create();
    for (const auto& clip : background_data_->clip) {
      array->push_back(lepus::Value{static_cast<int32_t>(clip)});
    }
    return lepus::Value{array};
  } else {
    return lepus::Value{lepus::CArray::Create()};
  }
}

lepus_value ComputedCSSStyle::BackgroundOriginToLepus() {
  if (background_data_ && !background_data_->origin.empty()) {
    auto array = lepus::CArray::Create();
    for (const auto& origin : background_data_->origin) {
      array->push_back(lepus::Value{static_cast<int32_t>(origin)});
    }
    return lepus::Value{array};
  } else {
    return lepus::Value{lepus::CArray::Create()};
  }
}

lepus_value ComputedCSSStyle::BackgroundPositionToLepus() {
  if (background_data_ && !background_data_->position.empty()) {
    auto array = lepus::CArray::Create();
    for (const auto& pos : background_data_->position) {
      if (pos.IsPercent()) {
        array->push_back(lepus::Value{pos.GetRawValue() / 100.f});
        array->push_back(lepus::Value(
            static_cast<int>(starlight::PlatformLengthUnit::PERCENTAGE)));
      } else if (pos.IsCalc()) {
        auto calcContent = pos.GetCalcSubLengths();
        if (calcContent.size() != 2) {
          if (calcContent[0].IsPercent()) {
            array->push_back(
                lepus::Value{calcContent[0].GetRawValue() / 100.f});
            array->push_back(lepus::Value(
                static_cast<int>(starlight::PlatformLengthUnit::PERCENTAGE)));
          } else {
            array->push_back(lepus::Value{
                NLengthToLayoutUnit(pos, LayoutUnit(0.f)).ToFloat()});
            array->push_back(lepus::Value(
                static_cast<int>(starlight::PlatformLengthUnit::NUMBER)));
          }
        } else {
          auto calcExpress = lepus::CArray::Create();
          for (auto calc : calcContent) {
            if (calc.IsUnit()) {
              calcExpress->push_back(lepus::Value{calc.GetRawValue()});
            }
            if (calc.IsPercent()) {
              calcExpress->push_back(lepus::Value{calc.GetRawValue() / 100.f});
            }
          }
          array->push_back(lepus::Value{calcExpress});
          array->push_back(lepus::Value(
              static_cast<int>(starlight::PlatformLengthUnit::CALC)));
        }
      } else {
        array->push_back(
            lepus::Value{NLengthToLayoutUnit(pos, LayoutUnit(0.f)).ToFloat()});
        array->push_back(lepus::Value(
            static_cast<int>(starlight::PlatformLengthUnit::NUMBER)));
      }
    }
    return lepus::Value{array};
  } else {
    return lepus::Value{lepus::CArray::Create()};
  }
}

lepus_value ComputedCSSStyle::BackgroundRepeatToLepus() {
  if (background_data_ && !background_data_->repeat.empty()) {
    auto array = lepus::CArray::Create();
    for (const auto& repeat : background_data_->repeat) {
      array->push_back(lepus_value{static_cast<int32_t>(repeat)});
    }
    return lepus_value{array};
  } else {
    return lepus::Value{lepus::CArray::Create()};
  }
}

lepus_value ComputedCSSStyle::MaskImageToLepus() { return mask_image_; }

lepus_value ComputedCSSStyle::FilterToLepus() {
  return CSSStyleUtils::FilterToLepus(filter_);
}

lepus_value ComputedCSSStyle::BorderTopColorToLepus() {
  if (surround_data_.border_data_) {
    return lepus_value(surround_data_.border_data_->color_top);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BorderRightColorToLepus() {
  if (surround_data_.border_data_) {
    return lepus_value(surround_data_.border_data_->color_right);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BorderBottomColorToLepus() {
  if (surround_data_.border_data_) {
    return lepus_value(surround_data_.border_data_->color_bottom);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BorderLeftColorToLepus() {
  if (surround_data_.border_data_) {
    return lepus_value(surround_data_.border_data_->color_left);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BorderTopWidthToLepus() {
  return lepus_value(static_cast<double>(GetBorderTopWidth()));
}

lepus_value ComputedCSSStyle::BorderRightWidthToLepus() {
  return lepus_value(static_cast<double>(GetBorderRightWidth()));
}

lepus_value ComputedCSSStyle::BorderBottomWidthToLepus() {
  return lepus_value(static_cast<double>(GetBorderBottomWidth()));
}

lepus_value ComputedCSSStyle::BorderLeftWidthToLepus() {
  return lepus_value(static_cast<double>(GetBorderLeftWidth()));
}

lepus_value ComputedCSSStyle::ListMainAxisGapToLepus() {
  return lepus_value(static_cast<double>(GetListMainAxisGap()));
}

lepus_value ComputedCSSStyle::ListCrossAxisGapToLepus() {
  return lepus_value(static_cast<double>(GetListCrossAxisGap()));
}

lepus_value ComputedCSSStyle::TransformToLepus() {
  if (transform_raw_) {
    return CSSStyleUtils::TransformToLepus(*transform_raw_);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::TransformOriginToLepus() {
  auto array = lepus::CArray::Create();
  {
    float result;
    PlatformLengthUnit unit;
    CSSStyleUtils::ConvertNLengthToNumber(transform_origin_->x, result, unit);
    array->push_back(lepus::Value(result));
    array->push_back(lepus::Value(static_cast<int>(unit)));
  }
  {
    float result;
    PlatformLengthUnit unit;
    CSSStyleUtils::ConvertNLengthToNumber(transform_origin_->y, result, unit);
    array->push_back(lepus::Value(result));
    array->push_back(lepus::Value(static_cast<int>(unit)));
  }
  return lepus_value(array);
}

lepus_value ComputedCSSStyle::AnimationToLepus() {
  if (!animation_data_) {
    return lepus::Value();
  }
  auto array_wrap = lepus::CArray::Create();
  std::for_each(
      animation_data_->begin(), animation_data_->end(),
      [&array_wrap](AnimationData& anim) {
        array_wrap->push_back(CSSStyleUtils::AnimationDataToLepus(anim));
      });
  return lepus_value(array_wrap);
}

lepus_value ComputedCSSStyle::AnimationNameToLepus() {
  if (!animation_data_) {
    return lepus::Value();
  }
  auto array_wrap = lepus::CArray::Create();
  std::for_each(animation_data_->begin(), animation_data_->end(),
                [&array_wrap](AnimationData& anim) {
                  array_wrap->push_back(lepus_value(anim.name.impl()));
                });
  return lepus_value(array_wrap);
}

lepus_value ComputedCSSStyle::AnimationDurationToLepus() {
  DCHECK(animation_data_ && !animation_data_->empty());
  return lepus_value(static_cast<double>(animation_data_->front().duration));
}

lepus_value ComputedCSSStyle::AnimationTimingFunctionToLepus() {
  DCHECK(animation_data_ && !animation_data_->empty());
  auto array = lepus::CArray::Create();
  array->push_back(lepus::Value(
      static_cast<int>(animation_data_->front().timing_func.timing_func)));
  array->push_back(lepus::Value(
      static_cast<int>(animation_data_->front().timing_func.steps_type)));
  array->push_back(lepus::Value(animation_data_->front().timing_func.x1));
  array->push_back(lepus::Value(animation_data_->front().timing_func.y1));
  array->push_back(lepus::Value(animation_data_->front().timing_func.x2));
  array->push_back(lepus::Value(animation_data_->front().timing_func.y2));
  return lepus_value(array);
}

lepus_value ComputedCSSStyle::AnimationDelayToLepus() {
  DCHECK(animation_data_ && !animation_data_->empty());
  return lepus_value(static_cast<double>(animation_data_->front().delay));
}

lepus_value ComputedCSSStyle::AnimationIterationCountToLepus() {
  DCHECK(animation_data_ && !animation_data_->empty());
  return lepus_value(animation_data_->front().iteration_count);
}

lepus_value ComputedCSSStyle::AnimationDirectionToLepus() {
  DCHECK(animation_data_ && !animation_data_->empty());
  return lepus_value(static_cast<int>(animation_data_->front().direction));
}

lepus_value ComputedCSSStyle::AnimationFillModeToLepus() {
  DCHECK(animation_data_ && !animation_data_->empty());
  return lepus_value(static_cast<int>(animation_data_->front().fill_mode));
}

lepus_value ComputedCSSStyle::AnimationPlayStateToLepus() {
  DCHECK(animation_data_ && !animation_data_->empty());
  return lepus_value(static_cast<int>(animation_data_->front().play_state));
}

lepus_value ComputedCSSStyle::LayoutAnimationCreateDurationToLepus() {
  return lepus_value(
      static_cast<double>(layout_animation_data_->create_ani.duration));
}

lepus_value ComputedCSSStyle::LayoutAnimationCreateTimingFunctionToLepus() {
  return LayoutAnimationTimingFunctionToLepusHelper(
      layout_animation_data_->create_ani.timing_function);
}
lepus_value ComputedCSSStyle::LayoutAnimationCreateDelayToLepus() {
  return lepus_value(
      static_cast<double>(layout_animation_data_->create_ani.delay));
}
lepus_value ComputedCSSStyle::LayoutAnimationCreatePropertyToLepus() {
  return lepus_value(
      static_cast<int>(layout_animation_data_->create_ani.property));
}
lepus_value ComputedCSSStyle::LayoutAnimationDeleteDurationToLepus() {
  return lepus_value(
      static_cast<double>(layout_animation_data_->delete_ani.duration));
}
lepus_value ComputedCSSStyle::LayoutAnimationDeleteTimingFunctionToLepus() {
  return LayoutAnimationTimingFunctionToLepusHelper(
      layout_animation_data_->delete_ani.timing_function);
}
lepus_value ComputedCSSStyle::LayoutAnimationDeleteDelayToLepus() {
  return lepus_value(
      static_cast<double>(layout_animation_data_->delete_ani.delay));
}
lepus_value ComputedCSSStyle::LayoutAnimationDeletePropertyToLepus() {
  return lepus_value(
      static_cast<int>(layout_animation_data_->delete_ani.property));
}
lepus_value ComputedCSSStyle::LayoutAnimationUpdateDurationToLepus() {
  return lepus_value(
      static_cast<double>(layout_animation_data_->update_ani.duration));
}
lepus_value ComputedCSSStyle::LayoutAnimationUpdateTimingFunctionToLepus() {
  return LayoutAnimationTimingFunctionToLepusHelper(
      layout_animation_data_->update_ani.timing_function);
}
lepus_value ComputedCSSStyle::LayoutAnimationUpdateDelayToLepus() {
  return lepus_value(
      static_cast<double>(layout_animation_data_->update_ani.delay));
}

lepus_value ComputedCSSStyle::TransitionToLepus() {
  if (!transition_data_) {
    return lepus::Value();
  }
  auto array_wrap = lepus::CArray::Create();
  for (const auto& it : *transition_data_) {
    auto array = lepus::CArray::Create();
    if (it.property == AnimationPropertyType::kNone) {
      return lepus_value();
    }
    array->push_back(lepus::Value(static_cast<int>(it.property)));
    array->push_back(lepus::Value(static_cast<double>(it.duration)));
    array->push_back(
        lepus::Value(static_cast<int>(it.timing_func.timing_func)));
    array->push_back(lepus::Value(static_cast<int>(it.timing_func.steps_type)));
    array->push_back(lepus::Value(static_cast<double>(it.timing_func.x1)));
    array->push_back(lepus::Value(static_cast<double>(it.timing_func.y1)));
    array->push_back(lepus::Value(static_cast<double>(it.timing_func.x2)));
    array->push_back(lepus::Value(static_cast<double>(it.timing_func.y2)));
    array->push_back(lepus::Value(static_cast<double>(it.delay)));
    array_wrap->push_back(lepus::Value(array));
  }
  return lepus::Value(array_wrap);
}

lepus_value ComputedCSSStyle::TransitionPropertyToLepus() {
  tasm::UnitHandler::CSSWarning(false, parser_configs_.enable_css_strict_mode,
                                tasm::CANNOT_REACH_METHOD);
  return lepus_value();
}
lepus_value ComputedCSSStyle::TransitionDurationToLepus() {
  tasm::UnitHandler::CSSWarning(false, parser_configs_.enable_css_strict_mode,
                                tasm::CANNOT_REACH_METHOD);
  return lepus_value();
}
lepus_value ComputedCSSStyle::TransitionDelayToLepus() {
  tasm::UnitHandler::CSSWarning(false, parser_configs_.enable_css_strict_mode,
                                tasm::CANNOT_REACH_METHOD);
  return lepus_value();
}
lepus_value ComputedCSSStyle::TransitionTimingFunctionToLepus() {
  tasm::UnitHandler::CSSWarning(false, parser_configs_.enable_css_strict_mode,
                                tasm::CANNOT_REACH_METHOD);
  return lepus_value();
}

lepus_value ComputedCSSStyle::EnterTransitionNameToLepus() {
  return CSSStyleUtils::AnimationDataToLepus(*enter_transition_data_);
}

lepus_value ComputedCSSStyle::ExitTransitionNameToLepus() {
  return CSSStyleUtils::AnimationDataToLepus(*exit_transition_data_);
}
lepus_value ComputedCSSStyle::PauseTransitionNameToLepus() {
  return CSSStyleUtils::AnimationDataToLepus(*pause_transition_data_);
}

lepus_value ComputedCSSStyle::ResumeTransitionNameToLepus() {
  return CSSStyleUtils::AnimationDataToLepus(*resume_transition_data_);
}

lepus_value ComputedCSSStyle::VisibilityToLepus() {
  return lepus_value(static_cast<int>(visibility_));
}

lepus_value ComputedCSSStyle::BorderTopStyleToLepus() {
  if (surround_data_.border_data_) {
    return lepus_value(
        static_cast<int>(surround_data_.border_data_->style_top));
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BorderRightStyleToLepus() {
  if (surround_data_.border_data_) {
    return lepus_value(
        static_cast<int>(surround_data_.border_data_->style_right));
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BorderBottomStyleToLepus() {
  if (surround_data_.border_data_) {
    return lepus_value(
        static_cast<int>(surround_data_.border_data_->style_bottom));
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BorderLeftStyleToLepus() {
  if (surround_data_.border_data_) {
    return lepus_value(
        static_cast<int>(surround_data_.border_data_->style_left));
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::OutlineColorToLepus() {
  return lepus_value(outline_->color);
}
lepus_value ComputedCSSStyle::OutlineStyleToLepus() {
  return lepus_value(static_cast<int>(outline_->style));
}
lepus_value ComputedCSSStyle::OutlineWidthToLepus() {
  return lepus_value(static_cast<int>(outline_->width));
}

lepus_value ComputedCSSStyle::BorderColorToLepus() { return lepus_value(); }

lepus_value ComputedCSSStyle::FontFamilyToLepus() {
  if (text_attributes_) {
    return lepus_value(text_attributes_->font_family.impl());
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::CaretColorToLepus() {
  return lepus::Value(caret_color_.impl());
}

lepus_value ComputedCSSStyle::DirectionToLepus() {
  return lepus::Value(static_cast<int>(direction_ == DirectionType::kLynxRtl
                                           ? DirectionType::kRtl
                                           : direction_));
}

lepus_value ComputedCSSStyle::WhiteSpaceToLepus() {
  if (text_attributes_) {
    return lepus_value(static_cast<int>(text_attributes_->white_space));
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::WordBreakToLepus() {
  if (text_attributes_) {
    return lepus_value(static_cast<int>(text_attributes_->word_break));
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BoxShadowToLepus() {
  if (box_shadow_) {
    return ShadowDataToLepus(*box_shadow_);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::TextShadowToLepus() {
  if (text_attributes_ && text_attributes_->text_shadow) {
    return ShadowDataToLepus(*text_attributes_->text_shadow);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::FontWeightToLepus() {
  if (text_attributes_) {
    return lepus_value(static_cast<int>(text_attributes_->font_weight));
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::FontStyleToLepus() {
  if (text_attributes_) {
    return lepus_value(static_cast<int>(text_attributes_->font_style));
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::TextAlignToLepus() {
  if (text_attributes_) {
    return lepus_value(static_cast<int>(text_attributes_->text_align));
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::TextOverflowToLepus() {
  if (text_attributes_) {
    return lepus_value(static_cast<int>(text_attributes_->text_overflow));
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::TextDecorationToLepus() {
  if (text_attributes_) {
    auto array = lepus::CArray::Create();
    int flags = 0;
    if (text_attributes_->underline_decoration) {
      flags |= static_cast<int>(TextDecorationType::kUnderLine);
    }
    if (text_attributes_->line_through_decoration) {
      flags |= static_cast<int>(TextDecorationType::kLineThrough);
    }
    array->push_back(lepus_value{static_cast<int32_t>(flags)});
    array->push_back(lepus_value{
        static_cast<int32_t>(text_attributes_->text_decoration_style)});
    // if not set the text-decoration-color, use the color as the default value
    array->push_back(lepus_value(
        static_cast<int32_t>(text_attributes_->text_decoration_color)));
    return lepus_value{array};
  } else {
    return lepus::Value{lepus::CArray::Create()};
  }
}

lepus_value ComputedCSSStyle::TextDecorationColorToLepus() {
  if (text_attributes_) {
    return lepus_value(text_attributes_->decoration_color);
  } else {
    return lepus_value();
  }
}

bool ComputedCSSStyle::InheritLineHeight(const ComputedCSSStyle& from) {
  DCHECK(from.text_attributes_.has_value());

  CSSStyleUtils::PrepareOptional(text_attributes_);
  bool factor_different =
      base::FloatsNotEqual(text_attributes_->line_height_factor,
                           from.text_attributes_->line_height_factor);
  text_attributes_->line_height_factor =
      from.text_attributes_->line_height_factor;

  auto old_computed_value = text_attributes_->computed_line_height;
  if (text_attributes_->line_height_factor !=
      DefaultCSSStyle::SL_DEFAULT_LINE_HEIGHT_FACTOR) {
    // Inherit the factor, when the line height is in factor form.
    text_attributes_->computed_line_height =
        text_attributes_->line_height_factor *
        length_context_.cur_node_font_size_;
  } else {
    text_attributes_->computed_line_height =
        from.text_attributes_->computed_line_height;
  }
  return factor_different ||
         base::FloatsNotEqual(text_attributes_->computed_line_height,
                              old_computed_value);
}

bool ComputedCSSStyle::InheritLineSpacing(const ComputedCSSStyle& from) {
  DCHECK(from.text_attributes_.has_value());
  if (!from.text_attributes_.has_value() ||
      (text_attributes_.has_value() &&
       text_attributes_->line_spacing == from.text_attributes_->line_spacing)) {
    return false;
  }
  CSSStyleUtils::PrepareOptional(text_attributes_);
  text_attributes_->line_spacing = from.text_attributes_->line_spacing;
  return true;
}

bool ComputedCSSStyle::InheritLetterSpacing(const ComputedCSSStyle& from) {
  DCHECK(from.text_attributes_.has_value());
  if (!from.text_attributes_.has_value() ||
      (text_attributes_.has_value() &&
       text_attributes_->letter_spacing ==
           from.text_attributes_->letter_spacing)) {
    return false;
  }
  CSSStyleUtils::PrepareOptional(text_attributes_);
  text_attributes_->letter_spacing = from.text_attributes_->letter_spacing;
  return true;
}

lepus_value ComputedCSSStyle::ZIndexToLepus() { return lepus_value(z_index_); }

lepus_value ComputedCSSStyle::VerticalAlignToLepus() {
  if (text_attributes_) {
    auto arr = lepus::CArray::Create();
    arr->push_back(
        lepus::Value(static_cast<int>(text_attributes_->vertical_align)));
    arr->push_back(lepus::Value(text_attributes_->vertical_align_length));
    return lepus::Value(arr);
  } else {
    return lepus::Value();
  }
}

lepus_value ComputedCSSStyle::BorderRadiusToLepus() {
  if (surround_data_.border_data_) {
    auto container = lepus::CArray::Create();

    RadiusLengthToLepus(container,
                        surround_data_.border_data_->radius_x_top_left,
                        length_context_.screen_width_);
    RadiusLengthToLepus(container,
                        surround_data_.border_data_->radius_y_top_left,
                        length_context_.screen_width_);

    RadiusLengthToLepus(container,
                        surround_data_.border_data_->radius_x_top_right,
                        length_context_.screen_width_);
    RadiusLengthToLepus(container,
                        surround_data_.border_data_->radius_y_top_right,
                        length_context_.screen_width_);

    RadiusLengthToLepus(container,
                        surround_data_.border_data_->radius_x_bottom_right,
                        length_context_.screen_width_);
    RadiusLengthToLepus(container,
                        surround_data_.border_data_->radius_y_bottom_right,
                        length_context_.screen_width_);

    RadiusLengthToLepus(container,
                        surround_data_.border_data_->radius_x_bottom_left,
                        length_context_.screen_width_);
    RadiusLengthToLepus(container,
                        surround_data_.border_data_->radius_y_bottom_left,
                        length_context_.screen_width_);

    return lepus::Value(container);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BorderTopLeftRadiusToLepus() {
  if (surround_data_.border_data_) {
    auto array = lepus::CArray::Create();
    RadiusLengthToLepus(array, surround_data_.border_data_->radius_x_top_left,
                        length_context_.screen_width_);
    RadiusLengthToLepus(array, surround_data_.border_data_->radius_y_top_left,
                        length_context_.screen_width_);
    return lepus::Value(array);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BorderTopRightRadiusToLepus() {
  if (surround_data_.border_data_) {
    auto array = lepus::CArray::Create();
    RadiusLengthToLepus(array, surround_data_.border_data_->radius_x_top_right,
                        length_context_.screen_width_);
    RadiusLengthToLepus(array, surround_data_.border_data_->radius_y_top_right,
                        length_context_.screen_width_);
    return lepus::Value(array);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BorderBottomRightRadiusToLepus() {
  if (surround_data_.border_data_) {
    auto array = lepus::CArray::Create();
    RadiusLengthToLepus(array,
                        surround_data_.border_data_->radius_x_bottom_right,
                        length_context_.screen_width_);
    RadiusLengthToLepus(array,
                        surround_data_.border_data_->radius_y_bottom_right,
                        length_context_.screen_width_);
    return lepus::Value(array);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::BorderBottomLeftRadiusToLepus() {
  if (surround_data_.border_data_) {
    auto array = lepus::CArray::Create();
    RadiusLengthToLepus(array,
                        surround_data_.border_data_->radius_x_bottom_left,
                        length_context_.screen_width_);
    RadiusLengthToLepus(array,
                        surround_data_.border_data_->radius_y_bottom_left,
                        length_context_.screen_width_);
    return lepus::Value(array);
  } else {
    return lepus_value();
  }
}

DisplayType ComputedCSSStyle::GetDisplay(const LayoutConfigs& configs,
                                         AttributesMap& attributes) const {
  const auto scroll = attributes.find(LayoutAttribute::kScroll);
  if (scroll != attributes.end() && scroll->second.IsBool() &&
      scroll->second.Bool() && display_ != DisplayType::kNone) {
    return DisplayType::kLinear;
  }

  if (display_ == DisplayType::kAuto) {
    if (!configs.css_align_with_legacy_w3c_ &&
        !configs.default_display_linear_) {
      return DisplayType::kFlex;
    } else {
      *(const_cast<DisplayType*>(&display_)) = DisplayType::kLinear;
      return DisplayType::kLinear;
    }
  } else if (display_ == DisplayType::kBlock) {
    if (!configs.css_align_with_legacy_w3c_) {
      LOGW("Unexpected display type:" << (int)display_
                                      << "!! Fall back to default display.");
      return DisplayType::kFlex;
    } else {
      return DisplayType::kLinear;
    }
  }
  return display_;
}

bool ComputedCSSStyle::SetCursor(const tasm::CSSValue& value,
                                 const bool reset) {
  auto old_value = cursor_;
  if (reset) {
    cursor_.reset();
    return true;
  } else {
    CSSStyleUtils::PrepareOptional(cursor_);
    cursor_ = value.GetValue();
    return old_value != cursor_;
  }
}

lepus_value ComputedCSSStyle::CursorToLepus() {
  if (cursor_ && cursor_->IsArray()) {
    return *cursor_;
  } else {
    return lepus_value();
  }
}

bool ComputedCSSStyle::SetTextIndent(const tasm::CSSValue& value,
                                     const bool reset) {
  CSSStyleUtils::PrepareOptional(text_attributes_);
  if (reset) {
    text_attributes_->text_indent = DefaultCSSStyle::SL_DEFAULT_ZEROLENGTH();
    return true;
  } else {
    auto old_value = text_attributes_->text_indent;
    auto ret = CSSStyleUtils::ToLength(value, length_context_, parser_configs_);
    if (!ret.second) {
      return false;
    }
    text_attributes_->text_indent = ret.first;
    return old_value != text_attributes_->text_indent;
  }
}

lepus_value ComputedCSSStyle::TextIndentToLepus() {
  if (text_attributes_) {
    auto array = lepus::CArray::Create();
    if (text_attributes_->text_indent.IsPercent()) {
      array->push_back(
          lepus::Value(text_attributes_->text_indent.GetRawValue() / 100.f));
      array->push_back(lepus::Value(
          static_cast<int>(starlight::PlatformLengthUnit::PERCENTAGE)));
    } else {
      auto calc_value =
          NLengthToLayoutUnit(text_attributes_->text_indent,
                              LayoutUnit(length_context_.screen_width_));
      array->push_back(lepus::Value(calc_value.ToFloat()));
      array->push_back(lepus::Value(
          static_cast<int>(starlight::PlatformLengthUnit::NUMBER)));
    }
    return lepus_value(array);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::TextStrokeToLepus() {
  // Parse failed or reset, return an empty array.
  return lepus_value();
}

lepus_value ComputedCSSStyle::TextStrokeColorToLepus() {
  if (text_attributes_) {
    return lepus_value(text_attributes_->text_stroke_color);
  } else {
    return lepus_value();
  }
}

lepus_value ComputedCSSStyle::TextStrokeWidthToLepus() {
  if (text_attributes_) {
    return lepus_value(text_attributes_->text_stroke_width);
  } else {
    return lepus_value();
  }
}

lepus::Value ComputedCSSStyle::ClipPathToLepus() {
  // Parse failed or reset, return an empty array.
  return clip_path_.Get() ? lepus::Value(clip_path_)
                          : lepus::Value(lepus::CArray::Create());
}
}  // namespace starlight
}  // namespace lynx
