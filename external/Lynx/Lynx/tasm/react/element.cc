// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/react/element.h"

#include <algorithm>
#include <memory>

#include "animation/animation_delegate.h"
#include "base/compiler_specific.h"
#include "base/lynx_env.h"
#include "base/path_utils.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "css/css_color.h"
#include "css/css_keyframes_token.h"
#include "css/css_property.h"
#include "css/parser/length_handler.h"
#include "css/unit_handler.h"
#include "jsbridge/bindings/java_script_element.h"
#include "lepus/array.h"
#include "lepus/table.h"
#include "starlight/style/css_type.h"
#include "starlight/style/default_css_style.h"
#include "tasm/list_component_info.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/page_proxy.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/radon/node_selector.h"
#include "tasm/radon/radon_component.h"
#include "tasm/react/element_manager.h"

namespace lynx {
namespace tasm {

InspectorAttribute::InspectorAttribute()
    : style_root_(nullptr),
      doc_(nullptr),
      style_(nullptr),
      style_value_(nullptr),
      shadow_root_(nullptr),
      slot_(nullptr),
      slot_component_(nullptr),
      plug_(nullptr) {}

Element::Element(const lepus::String& tag, ElementManager* manager)
    : tag_(tag),
      catalyzer_(manager->catalyzer()),
      config_flatten_(manager->GetPageFlatten()),
      font_size_(Config::DefaultFontSize()),
      root_font_size_(Config::DefaultFontSize()),
      styles_manager_(this, manager->GetDynamicCSSConfigs()),
      id_(manager->GenerateElementID()),
      platform_css_style_(std::make_unique<starlight::ComputedCSSStyle>(
          *manager->platform_computed_css())),
      element_manager_(manager) {
  config_enable_layout_only_ = manager->GetEnableLayoutOnly();
  enable_component_layout_only_ = manager->GetEnableComponentLayoutOnly();

  const auto& env_config = manager->GetLynxEnvConfig();

  layout_node_ = std::make_shared<LayoutNode>(
      impl_id(), manager->GetLayoutConfigs(), env_config,
      *element_manager_->layout_computed_css());
  platform_css_style_->SetScreenWidth(env_config.ScreenWidth());
  platform_css_style_->SetViewportHeight(env_config.ViewportHeight());
  platform_css_style_->SetViewportWidth(env_config.ViewportWidth());
  platform_css_style_->SetCssAlignLegacyWithW3c(
      manager->GetLayoutConfigs().css_align_with_legacy_w3c_);
  platform_css_style_->SetFontScaleOnlyEffectiveOnSp(
      manager->GetLynxEnvConfig().FontScaleSpOnly());

  layout_node_->SetTag(tag_);
}

void Element::SetObserver(const std::shared_ptr<UIImplObserver>& observer) {
  observer_ = observer;
}

std::vector<float> Element::ScrollBy(float width, float height) {
  return catalyzer_->ScrollBy(impl_id(), width, height);
}

std::vector<float> Element::GetRectToLynxView() {
  return catalyzer_->GetRectToLynxView(this);
}

void Element::Invoke(
    const std::string& method, const lepus::Value& params,
    const std::function<void(int32_t code, const lepus::Value& data)>&
        callback) {
  return catalyzer_->Invoke(impl_id(), method, params, callback);
}

const EventMap& Element::event_map() {
  if (data_model()) {
    return data_model()->static_events();
  }
  static base::NoDestructor<EventMap> kEmptyEventMap;
  return *kEmptyEventMap;
}

const EventMap& Element::lepus_event_map() {
  if (data_model()) {
    return data_model()->lepus_events();
  }
  static base::NoDestructor<EventMap> kEmptyLepusEventMap;
  return *kEmptyLepusEventMap;
}

const EventMap& Element::global_bind_event_map() {
  if (data_model()) {
    return data_model()->global_bind_events();
  }
  static base::NoDestructor<EventMap> kEmptyGlobalBindEventMap;
  return *kEmptyGlobalBindEventMap.get();
}

void Element::UpdateLayout(float left, float top, float width, float height,
                           const std::array<float, 4>& paddings,
                           const std::array<float, 4>& margins,
                           const std::array<float, 4>& borders,
                           const std::array<float, 4>* sticky_positions,
                           float max_height) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Element::UpdateLayout");
  // TODO: only leaf node need to update border padding
  frame_changed_ = true;
  top_ = top;
  left_ = left;
  width_ = width;
  height_ = height;
  paddings_ = paddings;
  margins_ = margins;
  borders_ = borders;
  if (sticky_positions != nullptr) {
    sticky_positions_ = *sticky_positions;
  }
  MarkSubtreeNeedUpdate();
  NotifyElementSizeUpdatedToAnimation();
}

void Element::OnAnimatedNodeReady() {
  // TODO(linxs): use OnNodeReady to replace it!
  if (!is_layout_only_) {
    painting_context()->OnAnimatedNodeReady(impl_id());
  }
}

void Element::ConsumeTransitionStylesInAdvance(const StyleMap& styles,
                                               bool force_reset) {
  for (unsigned int id =
           static_cast<unsigned int>(CSSPropertyID::kPropertyIDTransition);
       id <= static_cast<unsigned int>(
                 CSSPropertyID::kPropertyIDTransitionTimingFunction);
       ++id) {
    auto style = styles.find(static_cast<CSSPropertyID>(id));
    if (style == styles.end()) {
      continue;
    }
    if (force_reset) {
      ResetTransitionStylesInAdvanceInternal(style->first);
    } else {
      ConsumeTransitionStylesInAdvanceInternal(style->first, style->second);
    }
  }
  SetDataToNativeTransitionAnimator();
}

void Element::SetStyleInternal(CSSPropertyID css_id,
                               const tasm::CSSValue& value, bool force_update) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, ELEMENT_SET_STYLE_INTERNAL);
  // font-size has be handled, just ignore it.
  if (css_id == kPropertyIDFontSize) {
    return;
  }

  // record style for animator
  {
    // Since the previous element styles cannot be accessed in element, we
    // need to record some necessary styles which New Animator transition needs.
    // TODO(wujintian): We only need to record layout-only properties, while
    // other properties can be accessed through ComputedCSSStyle.
    RecordElementPreviousStyle(css_id, value);
  }

  // check layout only related styles
  bool is_layout_only = LayoutNode::IsLayoutOnly(css_id);
  if (is_layout_only) {
    // Currently, for better performance, only support LayoutOnly styles for
    // viewport changing
    CheckViewportUnit(css_id, value);
  }

  bool need_layout = is_layout_only || LayoutNode::IsLayoutWanted(css_id);
  if (need_layout) {
    // Check fixed&sticky before layout only
    bool is_fixed_before = is_fixed_;
    CheckFixedSticky(css_id, value);
    fixed_changed_ = (is_fixed_before != is_fixed_);

    // check base line
    CheckBaseline(css_id, value);
    element_manager_->UpdateLayoutNodeStyle(layout_node_, css_id, value);
  }

  if (is_layout_only) {
    return;
  }

  // if the style is not layout only, it shall be resolved to prop_bundle

  // overflow is special: if overflow is visible can be treated as layout only
  // prop!
  if (css_id == kPropertyIDOverflow || css_id == kPropertyIDOverflowX ||
      css_id == kPropertyIDOverflowY) {
    CheckOverflow(css_id, value);
    // take care: overflow:visible is allowed to be layout only
    if (overflow() != OVERFLOW_XY) {
      has_layout_only_props_ = false;
    }
  } else {
    // such style is not layout only
    has_layout_only_props_ = false;

    // do special check for transition, keyframe, z-index,etc.
    if (!(CheckTransitionProps(css_id) || CheckKeyframeProps(css_id) ||
          CheckZIndexProps(css_id, false))) {
#if OS_ANDROID
      // check flatten flag for Android platform if needed
      // FIXME(linxs): only Android need to check below props for flatten.
      // Normally, it's better to move below checks to Android platform side,
      // but checking in C++ size has a better performance
      CheckHasOpacityProps(css_id, false);
      CheckHasNonFlattenCSSProps(css_id);
#endif
    }
    // FIXME(wujintian): a workaround for using onAnimatedNodeReady for
    // RadonElement, need to be removed!
    CheckAnimateProps(css_id);
  }

  // resolve style and push to prop_bundle
  ResolveStyleValue(css_id, value, force_update);
}

bool Element::IsSetBaselineOnView(CSSPropertyID id,
                                  const tasm::CSSValue& value) {
  return (id == kPropertyIDAlignItems || id == kPropertyIDAlignSelf) &&
         (value.IsEnum() &&
          value.GetValue().Int32() ==
              static_cast<int32_t>(starlight::FlexAlignType::kBaseline));
}

bool Element::IsSetBaselineOnInlineView(CSSPropertyID id,
                                        const tasm::CSSValue& value) {
  return id == kPropertyIDVerticalAlign && tag_ == "view" &&
         value.GetValue().Array().Get()->get(0).Int32() ==
             static_cast<int32_t>(starlight::VerticalAlignType::kBaseline);
}

void Element::CheckHasInlineContainer(Element* parent) {
  bool is_parent_inline_container = parent && parent->layout_node() &&
                                    !parent->layout_node()->is_common() &&
                                    !parent->layout_node()->is_list();
  if (layout_node()) {
    layout_node()->SetParentIsInlineContainer(is_parent_inline_container);
  }
  if (is_parent_inline_container) {
    has_layout_only_props_ = false;
  }
}

void Element::ResetStyleInternal(CSSPropertyID css_id) {
  // Since the previous element styles cannot be accessed in element, we
  // need to record some necessary styles which New Animator transition needs.
  // TODO(wujintian): We only need to record layout-only properties, while other
  // properties can be accessed through ComputedCSSStyle.
  ResetElementPreviousStyle(css_id);

  bool is_layout_only = LayoutNode::IsLayoutOnly(css_id);
  bool need_layout = is_layout_only || LayoutNode::IsLayoutWanted(css_id);
  if (need_layout) {
    element_manager_->ResetLayoutNodeStyle(layout_node_, css_id);
  }
  if (css_id == kPropertyIDPosition) {
    is_sticky_ = is_fixed_ = false;
  }
  if (is_layout_only) {
    return;
  }
  has_layout_only_props_ = false;
  computed_css_style()->ResetValue(css_id);
  CheckZIndexProps(css_id, true);
  CheckHasOpacityProps(css_id, true);
  CheckAnimateProps(css_id);
  CheckTransitionProps(css_id);
  CheckKeyframeProps(css_id);
  // The properties of transition and keyframe no need to be pushed to bundle
  // separately here. Those properties will be pushed to bundle together
  // later.
  if (!(CheckTransitionProps(css_id) || CheckKeyframeProps(css_id))) {
    ResetProp(CSSProperty::GetPropertyName(css_id).c_str());
  }
}

// If the new animator is activated and this element has been created before,
// we need to reset the transition styles in advance. Additionally, the
// transition manager should verify each property to decide whether to
// intercept the reset. Therefore, we break down the operations related to the
// transition reset process into three steps:
// 1. We check whether we need to reset transition styles in advance.
// 2. If these styles have been reset beforehand, we can skip the transition
// styles in the later steps.
// 3. We review each property to determine whether the reset should be
// intercepted.
void Element::ResetStyle(const std::vector<CSSPropertyID>& css_names) {
  if (css_names.empty()) {
    return;
  }

  bool should_consume_trans_styles_in_advance =
      ShouldConsumeTransitionStylesInAdvance();
  // #1. Check whether we need to reset transition styles in advance.
  if (should_consume_trans_styles_in_advance) {
    ResetTransitionStylesInAdvance(css_names);
  }

  for (auto& css_id : css_names) {
    // record styles, used for worklet
    styles_.erase(css_id);

    // TODO: zhixuan
    if (css_id == kPropertyIDFontSize) {
      ResetFontSize();
      continue;
    } else if (css_id == kPropertyIDDirection) {
      styles_manager_.UpdateDirectionStyle(CSSValue::Empty());
    } else if (css_id == kPropertyIDPosition) {
      is_fixed_ = false;
      // #2. If these transition styles have been reset beforehand, skip them
      // here.
    } else if (should_consume_trans_styles_in_advance &&
               CSSProperty::IsTransitionProps(css_id)) {
      continue;
    }
    // #3. Review each property to determine whether the reset should be
    // intercepted.
    if (css_transition_manager_ && css_transition_manager_->ConsumeCSSProperty(
                                       css_id, CSSValue::Empty())) {
      return;
    }
    StylesManager().AdoptStyle(css_id, CSSValue::Empty());
  }
}

void Element::ResetTransitionStylesInAdvance(
    const std::vector<CSSPropertyID>& css_names) {
  for (auto& css_id : css_names) {
    if (CSSProperty::IsTransitionProps(css_id)) {
      ResetTransitionStylesInAdvanceInternal(css_id);
    }
  }
  SetDataToNativeTransitionAnimator();
}

void Element::SetAttribute(const lepus::String& key,
                           const lepus::Value& value) {
  CheckFlattenProp(key, value);
  CheckEventProp(key, value);
  CheckHasPlaceholder(key, value);
  CheckHasNonFlattenAttr(key, value);
  CheckHasUserInteractionEnabled(key, value);
  CheckTriggerGlobalEvent(key, value);
  CheckGlobalBindTarget(key, value);
  CheckNewAnimatorAttr(key, value);
  PreparePropBundleIfNeed();

  // Any attribute will cause has_layout_only_props_ = false
  has_layout_only_props_ = false;

  // record attributes, used for worklet
  attributes_.Table()->SetValue(key, value);

  StyleMap attr_styles;
  // FIXME(liyanbo): Compatible with old logic.support: <text
  // text-overflow="ellipsis"></text>
  // remove when front change this style of writing.
  if (key.IsEqual("text-overflow")) {
    tasm::UnitHandler::Process(kPropertyIDTextOverflow, value, attr_styles,
                               element_manager_->GetCSSParserConfigs());
  } else {
    prop_bundle_->SetProps(key.c_str(), value);
  }

  if (key.IsEquals("scroll-x") && value.String()->IsEqual("true")) {
    attr_styles.insert_or_assign(
        kPropertyIDLinearOrientation,
        CSSValue::MakeEnum(
            static_cast<int>(starlight::LinearOrientationType::kHorizontal)));
    element_manager_->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
  } else if (key.IsEquals("scroll-y") && value.String()->IsEqual("true")) {
    attr_styles.insert_or_assign(
        kPropertyIDLinearOrientation,
        CSSValue::MakeEnum(
            static_cast<int>(starlight::LinearOrientationType::kVertical)));
    element_manager_->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
  } else if (key.IsEquals("scroll-x-reverse") &&
             value.String()->IsEqual("true")) {
    attr_styles.insert_or_assign(
        kPropertyIDLinearOrientation,
        CSSValue::MakeEnum(static_cast<int>(
            starlight::LinearOrientationType::kHorizontalReverse)));
    element_manager_->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
  } else if (key.IsEquals("scroll-y-reverse") &&
             value.String()->IsEqual("true")) {
    attr_styles.insert_or_assign(
        kPropertyIDLinearOrientation,
        CSSValue::MakeEnum(static_cast<int>(
            starlight::LinearOrientationType::kVerticalReverse)));
    element_manager_->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
  } else if (key.IsEqual("column-count")) {
    element_manager_->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kColumnCount, value);
  } else if (key.IsEqual(ListComponentInfo::kListCompType)) {
    element_manager_->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kListCompType, value);
  }
  SetStyle(attr_styles);
}

void Element::ResetAttribute(const lepus::String& key) {
  CheckFlattenProp(key);
  CheckGlobalBindTarget(key);
  has_layout_only_props_ = false;

  // record attributes, used for worklet
  attributes_.Table()->Erase(key);

  ResetProp(key.c_str());
}

void Element::SetDataSet(const tasm::DataMap& data) {
  PreparePropBundleIfNeed();
  constexpr const static char* sDataSetKey = "dataset";
  lepus::Value datas_val(lepus::Dictionary::Create());
  for (const auto& pair : data) {
    datas_val.SetProperty(pair.first, pair.second);
  }
  prop_bundle_->SetProps(sDataSetKey, datas_val);
}

void Element::SetKeyframesByNames(const lepus::Value& names,
                                  const CSSKeyframesTokenMap& keyframes) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Element::SetKeyframesByNames");
  auto lepus_keyframes = starlight::CSSStyleUtils::ResolveCSSKeyframesByNames(
      names, keyframes, computed_css_style()->GetMeasureContext(),
      element_manager()->GetCSSParserConfigs());
  if (!lepus_keyframes.IsTable()) {
    return;
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Element::PushKeyframesToBundle");
  auto bundle = PropBundle::Create();
  bundle->SetProps("keyframes", lepus_keyframes);
  painting_context()->SetKeyframes(bundle.get());
}

void Element::SetFontFaces(const CSSFontFaceTokenMap& fontFaces) {
#if ENABLE_RENDERKIT
  painting_context()->SetFontFaces(fontFaces);
#else
  element_manager_->SetFontFaces(fontFaces);
#endif
}

void Element::SetProp(const char* key, const lepus::Value& value) {
  PreparePropBundleIfNeed();
  prop_bundle_->SetProps(key, value);
}

void Element::ResetProp(const char* key) {
  PreparePropBundleIfNeed();
  prop_bundle_->SetNullProps(key);
}

// TODO: just so easy?
void Element::SetEventHandler(const lepus::String& name,
                              EventHandler* handler) {
  PreparePropBundleIfNeed();
  prop_bundle_->SetEventHandler(*handler);
  if (handler->name().IsEquals("attach") ||
      handler->name().IsEquals("detach")) {
    has_event_listener_ = true;
  }
  has_layout_only_props_ = false;
}

void Element::ResetEventHandlers() {
  if (prop_bundle_ != nullptr) {
    prop_bundle_->ResetEventHandler();
  }
  has_event_listener_ = false;
}

void Element::CreateElementContainer(bool platform_is_flatten) {
  element_container_ = std::make_unique<ElementContainer>(this);
  if (IsLayoutOnly()) return;
  painting_context()->CreatePaintingNode(id_, prop_bundle_.get(),
                                         platform_is_flatten);
}

void Element::UpdateElement() {
  if (!IsLayoutOnly()) {
    painting_context()->UpdatePaintingNode(impl_id(), TendToFlatten(),
                                           prop_bundle_.get());
  } else if (!CanBeLayoutOnly()) {
    // Is layout only and can not be layout only
    element_container()->TransitionToNativeView();
  }
  element_container()->StyleChanged();
}

void Element::Animate(const lepus::Value& args) {
  if (!args.IsArrayOrJSArray()) {
    LOGE("Element::Animate's para must be array");
    return;
  }
  if (args.GetLength() < 2) {
    LOGE("Element::Animate's para size must >= 2");
    return;
  }
  const auto& op = static_cast<piper::JavaScriptElement::AnimationOperation>(
      args.GetProperty(0).Int32());
  const auto& name = args.GetProperty(1).String()->str();
  StyleMap styles;
  auto& parser_configs = element_manager()->GetCSSParserConfigs();
  switch (op) {
    case piper::JavaScriptElement::AnimationOperation::START: {
      if (args.GetLength() != 4) {
        LOGE("When start Element::Animate, the para size must be 4");
        return;
      }
      starlight::CSSStyleUtils::UpdateCSSKeyframes(
          keyframes_map_, name, args.GetProperty(2), parser_configs);
      lepus::Value lepus_name = lepus::Value(name.c_str());
      if (!enable_new_animator()) {
        SetKeyframesByNames(lepus_name, keyframes_map_);
      }
      UnitHandler::Process(kPropertyIDAnimationName, lepus_name, styles,
                           parser_configs);
      UnitHandler::Process(kPropertyIDAnimationPlayState,
                           lepus::Value("running"), styles, parser_configs);
      const auto& table = args.GetProperty(3).Table();
      for (auto& [key, value] : *table) {
        const auto& id = CSSProperty::GetTimingOptionsPropertyID(key);
        if (id == kPropertyEnd) {
          continue;
        }
        if (id == kPropertyIDAnimationIterationCount && value.IsNumber()) {
          if (isinf(value.Number()) == 1) {
            value = lepus::Value("infinite");
          } else {
            value = lepus::Value(std::to_string(value.Number()).c_str());
          }
        }
        UnitHandler::Process(id, value, styles, parser_configs);
      }
      break;
    }
    case piper::JavaScriptElement::AnimationOperation::PAUSE:
      UnitHandler::Process(kPropertyIDAnimationPlayState,
                           lepus::Value("paused"), styles, parser_configs);
      break;
    case piper::JavaScriptElement::AnimationOperation::PLAY:
      UnitHandler::Process(kPropertyIDAnimationPlayState,
                           lepus::Value("running"), styles, parser_configs);
      break;
    case piper::JavaScriptElement::AnimationOperation::CANCEL: {
      UnitHandler::Process(kPropertyIDAnimationPlayState,
                           lepus::Value("running"), styles, parser_configs);
      std::vector<CSSPropertyID> reset_names{kPropertyIDAnimationDuration,
                                             kPropertyIDAnimationDelay,
                                             kPropertyIDAnimationIterationCount,
                                             kPropertyIDAnimationFillMode,
                                             kPropertyIDAnimationTimingFunction,
                                             kPropertyIDAnimationDirection,
                                             kPropertyIDAnimationName};
      ResetStyle(reset_names);
      break;
    }
    default:
      break;
  }
  SetStyle(styles);
  element_manager_->OnFinishUpdateProps(this);
  PipelineOptions options;
  OnPatchFinish(options);
}

void Element::PreparePropBundleIfNeed() {
  if (!prop_bundle_) {
    prop_bundle_ = PropBundle::Create();
    prop_bundle_->set_tag(tag_);
  }
}

void Element::ResetPropBundle() {
  if (prop_bundle_) {
    pre_prop_bundle_ = prop_bundle_;
    prop_bundle_ = nullptr;
  }
}

void Element::PushToBundle(CSSPropertyID id) {
  PreparePropBundleIfNeed();
  lepus_value style_value = computed_css_style()->GetValue(id);
  auto property_name = CSSProperty::GetPropertyName(id).c_str();
  switch (style_value.Type()) {
    case lepus::Value_Int32:
    case lepus::Value_Int64:
      prop_bundle_->SetProps(property_name,
                             static_cast<int>(style_value.Number()));
      break;
    case lepus::Value_UInt32:
    case lepus::Value_UInt64:
      prop_bundle_->SetProps(property_name,
                             static_cast<unsigned int>(style_value.Number()));
      break;
    case lepus::Value_Double:
      prop_bundle_->SetProps(property_name, style_value.Number());
      break;
    case lepus::Value_Bool:
      prop_bundle_->SetProps(property_name, style_value.Bool());
      break;
    case lepus::Value_String:
      prop_bundle_->SetProps(property_name, style_value.String()->c_str());
      break;
    case lepus::Value_Array:
    case lepus::Value_Table:
      prop_bundle_->SetProps(property_name, style_value);
      break;
    case lepus::Value_Nil:
      prop_bundle_->SetNullProps(property_name);
      break;
    default:
      LynxWarning(false, LYNX_ERROR_CODE_ASSET, "ResolveStyleValue");
      break;
  }
}

bool Element::DisableFlattenWithOpacity() {
  return has_opacity_ && !tag_.IsEquals("text") && !tag_.IsEquals("image");
}

bool Element::TendToFlatten() {
  return config_flatten_ && !has_event_listener_ && !has_event_prop_ &&
         !has_animate_props_ && !has_transition_props_ &&
         !has_keyframe_props_ && !has_non_flatten_attrs_ &&
         !has_user_interaction_enabled_ && !DisableFlattenWithOpacity() &&
         !has_z_props_;
}

void Element::SetFontSize(const tasm::CSSValue* value) {
  styles_manager_.UpdateFontSizeStyle(value);
}

void Element::SetComputedFontSize(const tasm::CSSValue& value, double font_size,
                                  double root_font_size, bool force_update) {
  font_size_ = font_size;
  root_font_size_ = root_font_size;
  computed_css_style()->SetFontSize(font_size, root_font_size);
  element_manager_->UpdateLayoutNodeFontSize(layout_node_, font_size,
                                             root_font_size);
  if (!value.IsEmpty() || force_update) {
    ResolveStyleValue(kPropertyIDFontSize, value, force_update);
  }
}

void Element::ResetFontSize() {
  auto empty = CSSValue::Empty();
  styles_manager_.UpdateFontSizeStyle(&empty);
}

void Element::ResetFontSizeInternalLegacy() {
  font_size_ = element_manager()->GetLynxEnvConfig().PageDefaultFontSize();
  element_manager_->UpdateLayoutNodeFontSize(
      layout_node_, font_size_, catalyzer_->get_root()->FontSize());
  PreparePropBundleIfNeed();
  computed_css_style()->ResetValue(kPropertyIDFontSize);
  prop_bundle_->SetProps(
      CSSProperty::GetPropertyName(CSSPropertyID::kPropertyIDFontSize).c_str(),
      font_size_);
}

bool Element::CheckFlattenProp(const lepus::String& key,
                               const lepus::Value& value) {
  if (key.IsEquals("flatten")) {
    if ((value.IsString() && value.String()->str() == "false") ||
        (value.IsBool() && !value.Bool())) {
      config_flatten_ = false;
      return true;
    }
    config_flatten_ = true;
    return true;
  }
  return false;
}

bool Element::CheckEventProp(const lepus::String& key,
                             const lepus::Value& value) {
  constexpr const static char* kNativeInteractionEnabled =
      "native-interaction-enabled";
  // if set native-interaction-enabled="{{false}}", the element must not be
  // flatten.
  if (key.IsEqual(kNativeInteractionEnabled)) {
    if (value.IsBool() && !value.Bool()) {
      has_event_prop_ = true;
    }
  }
  return true;
}

void Element::CheckOverflow(CSSPropertyID id, const tasm::CSSValue& value) {
#define CHECK_OVERFLOW_VAL(mask)                            \
  if ((starlight::OverflowType)value.GetValue().Number() == \
      starlight::OverflowType::kVisible) {                  \
    overflow_ |= (mask);                                    \
  } else {                                                  \
    overflow_ &= ~(mask);                                   \
  }

  switch (id) {
    case CSSPropertyID::kPropertyIDOverflow:
      CHECK_OVERFLOW_VAL(0x03)
      break;
    case CSSPropertyID::kPropertyIDOverflowX:
      CHECK_OVERFLOW_VAL(0x01)
      break;
    case CSSPropertyID::kPropertyIDOverflowY:
      CHECK_OVERFLOW_VAL(0x02)
      break;
    default:
      break;
  }
}

void Element::CheckHasPlaceholder(const lepus::String& key,
                                  const lepus::Value& value) {
  if (key.str() == "placeholder") {
    has_placeholder_ = !value.String()->empty();
  }
}

void Element::CheckHasNonFlattenAttr(const lepus::String& key,
                                     const lepus::Value& value) {
  if (has_non_flatten_attrs_) return;
  if (key.str() == "name" || key.str() == "clip-radius" ||
      key.str() == "overlap" || key.str() == "enter-transition-name" ||
      key.str() == "exit-transition-name" ||
      key.str() == "pause-transition-name" ||
      key.str() == "resume-transition-name" || key.str() == "exposure-scene" ||
      key.str() == "exposure-id") {
    // TODO(songshourui.null): When set exposure prop, the ui must not be
    // flatten, since the flattenUI exposure rect may be not correct. Will
    // remove the exposure prop when fix flattenUI exposure rect's bug.
    has_non_flatten_attrs_ = true;
  }
}

void Element::CheckHasUserInteractionEnabled(const lynx::lepus::String& key,
                                             const lynx::lepus::Value& value) {
  if (key.str() == "user-interaction-enabled" ||
      key.str() == "native-interaction-enabled") {
    has_user_interaction_enabled_ = true;
  }
}

void Element::CheckTriggerGlobalEvent(const lynx::lepus::String& key,
                                      const lynx::lepus::Value& value) {
  constexpr char kTriggerGlobalEventAttribute[] = "trigger-global-event";
  if (key.str() == kTriggerGlobalEventAttribute && value.IsBool()) {
    trigger_global_event_ = value.Bool();
  }
}

void Element::CheckGlobalBindTarget(const lynx::lepus::String& key,
                                    const lynx::lepus::Value& value) {
  // check global-target id attribute in order to global-bind event
  if (!value.IsString() || key.str() != "global-target") {
    return;
  }
  // clear target_set_ if set global-target attribute, no matter value is empty
  // or not
  global_bind_target_set_.clear();
  if (value.String()->str().empty()) {
    return;
  }
  constexpr const static char kDelimiter = ',';
  std::vector<std::string> id_targets;
  // multiple id split by comma delimiter
  base::SplitString(base::TrimString(value.String()->str()), kDelimiter,
                    id_targets);
  for (auto& s : id_targets) {
    global_bind_target_set_.insert(base::TrimString(s));
  }
}

void Element::CheckHasOpacityProps(CSSPropertyID id, bool reset) {
  if (UNLIKELY(id == CSSPropertyID::kPropertyIDOpacity)) {
    has_opacity_ = !reset;
  }
}

bool Element::CheckTransitionProps(CSSPropertyID id) {
  if (CSSProperty::IsTransitionProps(id)) {
    has_transition_props_ = true;
    has_non_flatten_attrs_ = true;
    return true;
  }
  return false;
}

bool Element::CheckKeyframeProps(CSSPropertyID id) {
  if (CSSProperty::IsKeyframeProps(id)) {
    has_keyframe_props_ = true;
    has_non_flatten_attrs_ = true;
    return true;
  }
  return false;
}

void Element::CheckHasNonFlattenCSSProps(CSSPropertyID id) {
  if (has_non_flatten_attrs_) {
    // never change has_non_flatten_attrs_ to false again
    return;
  }
  if (id == CSSPropertyID::kPropertyIDFilter || id == kPropertyIDVisibility ||
      id == kPropertyIDClipPath || id == CSSPropertyID::kPropertyIDBoxShadow ||
      id == CSSPropertyID::kPropertyIDTransform ||
      id == CSSPropertyID::kPropertyIDTransformOrigin ||
      (id >= CSSPropertyID::kPropertyIDOutline &&
       id <= CSSPropertyID::kPropertyIDOutlineWidth) ||
      (id >= CSSPropertyID::kPropertyIDLayoutAnimationCreateDuration &&
       id <= CSSPropertyID::kPropertyIDLayoutAnimationUpdateDelay)) {
    has_non_flatten_attrs_ = true;
  }
}

bool Element::CheckZIndexProps(CSSPropertyID id, bool reset) {
  if (!GetEnableZIndex()) return false;
  if (UNLIKELY(id == CSSPropertyID::kPropertyIDZIndex)) {
    has_z_props_ = !reset;
    // Need to trigger layout and update the position
    MarkLayoutDirty();
    frame_changed_ = true;
    MarkSubtreeNeedUpdate();
    return true;
  }
  return false;
}

void Element::CheckFixedSticky(CSSPropertyID id, const tasm::CSSValue& value) {
  if (id == kPropertyIDPosition) {
    auto type = value.GetEnum<starlight::PositionType>();
    is_fixed_ = type == starlight::PositionType::kFixed;
    is_sticky_ = type == starlight::PositionType::kSticky;
  }
}

bool Element::IsStackingContextNode() {
  if (!GetEnableZIndex()) return false;
  return element_manager()->root() == this || has_z_props_ || is_fixed_ ||
         computed_css_style()->HasTransform() ||
         computed_css_style()->HasOpacity();
}

PaintingContext* Element::painting_context() {
  return catalyzer_->painting_context();
}

void Element::MarkLayoutDirty() {
  element_manager_->MarkLayoutDirty(layout_node_);
}

PropertiesResolvingStatus Element::GenerateRootPropertyStatus() const {
  PropertiesResolvingStatus status;
  const auto& env_config = element_manager_->GetLynxEnvConfig();
  status.page_status_.root_font_size_ = env_config.PageDefaultFontSize();
  status.computed_font_size_ = env_config.PageDefaultFontSize();
  status.page_status_.font_scale_ = env_config.FontScale();
  status.page_status_.screen_width_ = env_config.ScreenWidth();
  status.page_status_.viewport_width_ = env_config.ViewportWidth();
  status.page_status_.viewport_height_ = env_config.ViewportHeight();
  return status;
}

void Element::PreparePropsBundleForDynamicCSS() {
  DCHECK(parent() == nullptr);
  TRACE_EVENT(LYNX_TRACE_CATEGORY, ELEMENT_UPDATE_DYNAMIC_CSS);
  const auto& env_config = element_manager_->GetLynxEnvConfig();
  computed_css_style()->SetScreenWidth(env_config.ScreenWidth());
  computed_css_style()->SetFontScale(env_config.FontScale());

  computed_css_style()->SetViewportWidth(env_config.ViewportWidth());
  computed_css_style()->SetViewportHeight(env_config.ViewportHeight());

  PropertiesResolvingStatus status = GenerateRootPropertyStatus();
  styles_manager_.UpdateWithResolvingStatus(status);
}

void Element::MarkSubtreeNeedUpdate() {
  if (!subtree_need_update_) {
    subtree_need_update_ = true;
    if (parent_) {
      parent_->MarkSubtreeNeedUpdate();
    }
  }
}

void Element::NotifyElementSizeUpdatedToAnimation() {
  if (css_keyframe_manager_) {
    css_keyframe_manager_->NotifyElementSizeUpdated();
  }
  if (css_transition_manager_) {
    css_transition_manager_->NotifyElementSizeUpdated();
  }
}

void Element::SetPlaceHolderStyles(const PseudoPlaceHolderStyles& styles) {
  styles_manager_.SetPlaceHolderStyle(styles);
}

void Element::SetPlaceHolderStylesInternal(
    const PseudoPlaceHolderStyles& styles) {
  lynx::base::scoped_refptr<lepus::Dictionary> dict =
      lepus::Dictionary::Create();
  if (styles.color_) {
    const auto& value = styles.color_->GetValue();
    if (value.IsNumber()) {
      dict->SetValue(kPropertyNameColor, value);
    }
  }

  if (styles.font_size_) {
    const auto result = starlight::CSSStyleUtils::ResolveFontSize(
        *styles.font_size_, element_manager()->GetLynxEnvConfig(),
        element_manager()->GetLynxEnvConfig().ViewportWidth(),
        element_manager()->GetLynxEnvConfig().ViewportHeight(), font_size_,
        root_font_size_, element_manager()->GetCSSParserConfigs());
    if (result.has_value()) {
      dict->SetValue(kPropertyNameFontSize, lepus_value(*result));
    }
  }
  if (styles.font_weight_) {
    const auto& value = styles.font_weight_->GetValue();
    if (value.IsNumber()) {
      dict->SetValue(kPropertyNameFontWeight, value);
    }
  }
  if (styles.font_family_) {
    const auto& value = styles.font_family_->GetValue();
    if (value.IsString()) {
      dict->SetValue(kPropertyNameFontFamily, value);
    }
  }
  SetProp("placeholder-style", lepus::Value(dict));
}

bool Element::GetEnableZIndex() { return element_manager_->GetEnableZIndex(); }

void Element::CheckNewAnimatorAttr(const lepus::String& key,
                                   const lepus::Value& value) {
  if (key.IsEquals("enable-new-animator")) {
    if (value.IsString() && value.String()->str() != "false") {
      enable_new_animator_ = value.String()->str();
#if !OS_IOS  // FIXME(linxs): deprecate using macro
      // currently only specify iOS layout transition
      if (enable_new_animator_ == "iOS") {
        enable_new_animator_.clear();
      }
#endif
      return;
    } else if (value.IsBool() && value.Bool()) {
      enable_new_animator_ = "true";
      return;
    }
    enable_new_animator_.clear();
  }
}

void Element::SetDataToNativeKeyframeAnimator() {
  // keyframe animation
  if (!has_keyframe_props_) {
    return;
  }

  if (!css_keyframe_manager_) {
    css_keyframe_manager_ =
        std::make_unique<animation::CSSKeyframeManager>(this);
  }
  css_keyframe_manager_->SetAnimationDataAndPlay(
      computed_css_style()->animation_data());
}

void Element::SetDataToNativeTransitionAnimator() {
  // transition animation
  if (!has_transition_props_) {
    return;
  }

  if (!css_transition_manager_) {
    css_transition_manager_ =
        std::make_unique<animation::CSSTransitionManager>(this);
  }
  css_transition_manager_->setTransitionData(
      computed_css_style()->transition_data());
  has_transition_props_ = false;
}

bool Element::FlushAnimatedStyle() {
  if (final_animator_map_.empty()) {
    return false;
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Element::FlushAnimatedStyle");
  for (const auto& style : final_animator_map_) {
    auto css_id = style.first;
    const auto& value = style.second;
    if (value != CSSValue::Empty()) {
      SetStyleInternal(css_id, value);
    } else {
      ResetStyleInternal(css_id);
    }
  }
  final_animator_map_.clear();
  return true;
}

void Element::TickAllAnimation(fml::TimePoint& frame_time) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Element::TickAllAnimation");

  if (css_transition_manager_ != nullptr) {
    css_transition_manager_->TickAllAnimation(frame_time);
  }
  if (css_keyframe_manager_ != nullptr) {
    css_keyframe_manager_->TickAllAnimation(frame_time);
  }
  if (FlushAnimatedStyle()) {
    element_manager_->OnFinishUpdateProps(this);
  }
}

void Element::RequestNextFrameTime() {
  element_manager()->RequestNextFrameTime(this);
}

void Element::UpdateFinalStyleMap(const StyleMap& styles) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Element::UpdateFinalStyleMap");
  for (auto& iter : styles) {
    if (final_animator_map_.find(iter.first) != final_animator_map_.end()) {
      final_animator_map_.erase(iter.first);
    }
    final_animator_map_.insert(iter);
  }
}

std::string Element::GetLayoutTree() {
#if ENABLE_ARK_REPLAY
  if (layout_node_ && layout_node_->slnode()) {
    return layout_node_->slnode()->GetLayoutTree();
  }
  return "";
#else
  return "";
#endif
}

bool Element::ShouldConsumeTransitionStylesInAdvance() {
  return (enable_new_animator() && HasPaintingNode());
}

std::optional<CSSValue> Element::GetElementStyle(tasm::CSSPropertyID css_id) {
  if (!data_model()) {
    return std::optional<CSSValue>();
  }
  auto iter = data_model()->cached_styles().find(css_id);
  if (iter == data_model()->cached_styles().end()) {
    return std::optional<CSSValue>();
  }
  return iter->second;
}

// Since the previous element styles cannot be accessed in element, we
// need to record some necessary styles which New Animator transition needs.
// TODO(wujintian): We only need to record layout-only properties, while other
// properties can be accessed through ComputedCSSStyle.
void Element::RecordElementPreviousStyle(CSSPropertyID css_id,
                                         const tasm::CSSValue& value) {
  if (!enable_new_animator()) {
    return;
  }
  if (animation::IsAnimatableProperty(css_id)) {
    animation_previous_styles_[css_id] = value;
  }
}

void Element::ResetElementPreviousStyle(CSSPropertyID css_id) {
  if (!enable_new_animator()) {
    return;
  }
  if (animation::IsAnimatableProperty(css_id)) {
    animation_previous_styles_.erase(css_id);
  }
}

std::optional<CSSValue> Element::GetElementPreviousStyle(
    tasm::CSSPropertyID css_id) {
  auto iter = animation_previous_styles_.find(css_id);
  if (iter == animation_previous_styles_.end()) {
    return std::optional<CSSValue>();
  }
  return iter->second;
}

CSSKeyframesToken* Element::GetCSSKeyframesToken(
    const std::string& animation_name) {
  tasm::CSSFragment* style_sheet = GetRelatedCSSFragment();
  if (style_sheet) {
    return style_sheet->GetKeyframes(animation_name);
  }
  return nullptr;
}

void Element::ResolveAndFlushKeyframes() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Element::ResolveAndFlushKeyframes");
  lepus_value animation_names =
      computed_css_style()->GetValue(kPropertyIDAnimationName);
  CSSFragment* css_fragment = GetRelatedCSSFragment();
  if (!animation_names.IsNil() && css_fragment &&
      !css_fragment->keyframes().empty()) {
    SetKeyframesByNames(animation_names, css_fragment->keyframes());
  }
}

}  // namespace tasm
}  // namespace lynx
