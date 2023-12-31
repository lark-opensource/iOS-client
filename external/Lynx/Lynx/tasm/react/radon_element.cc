// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/react/radon_element.h"

#include "tasm/page_proxy.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/radon/node_selector.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_list_node.h"
#include "tasm/react/element_manager.h"

namespace lynx {
namespace tasm {

RadonElement::RadonElement(const lepus::String& tag, AttributeHolder* node,
                           ElementManager* manager)
    : Element(tag, manager) {
  if (node) {
    SetAttributeHolder(node);
  }

  const auto& env_config = manager->GetLynxEnvConfig();
  if (Config::DefaultFontScale() != env_config.FontScale()) {
    root_font_size_ = font_size_ = env_config.PageDefaultFontSize();
    computed_css_style()->SetFontScale(env_config.FontScale());
    SetComputedFontSize(tasm::CSSValue(), font_size_, root_font_size_, true);
    manager->UpdateLayoutNodeFontSize(layout_node(), font_size_,
                                      root_font_size_);
  }
  styles_manager_.SetInitialResolvingStatus(GenerateRootPropertyStatus());
  if (tag_ == "view" || tag_ == "component") {
    layout_node()->slnode()->GetCSSMutableStyle()->SetOverflowDefaultVisible(
        manager->GetDefaultOverflowVisible());
    computed_css_style()->SetOverflowDefaultVisible(
        manager->GetDefaultOverflowVisible());
    overflow_ =
        manager->GetDefaultOverflowVisible() ? OVERFLOW_XY : OVERFLOW_HIDDEN;
  }
  if (tag_ == "text" || tag_ == "x-text") {
    layout_node()->slnode()->GetCSSMutableStyle()->SetOverflowDefaultVisible(
        manager->GetDefaultTextOverflow());
    computed_css_style()->SetOverflowDefaultVisible(
        manager->GetDefaultTextOverflow());
    overflow_ =
        manager->GetDefaultTextOverflow() ? OVERFLOW_XY : OVERFLOW_HIDDEN;
  }

  styles_manager_.SetViewportSizeWhenInitialize(env_config);
}

RadonElement::~RadonElement() {
  element_manager()->NotifyElementDestroy(this);
  element_manager_->EraseGlobalBindElementId(global_bind_event_map(),
                                             impl_id());
  element_manager_->node_manager()->Erase(impl_id());
  // remove this element from parent and children.
  auto* parent = static_cast<RadonElement*>(parent_);
  if (parent) {
    int32_t index = parent->IndexOf(this);
    parent->RemoveNode(this, index);
  }
  for (auto& child : children_) {
    auto* child_element = static_cast<RadonElement*>(child);
    if (child_element) {
      child_element->set_parent(nullptr);
      if (child_element->IsPseudoNode()) {
        delete child_element;
      }
    }
  }
}

ListNode* RadonElement::GetListNode() {
  auto* node = static_cast<RadonNode*>(data_model());
  if (node && node->NodeType() == RadonNodeType::kRadonListNode) {
    return static_cast<RadonListNode*>(node);
  }
  return nullptr;
}

bool RadonElement::InComponent() const {
  if (data_model()) {
    return static_cast<RadonNode*>(data_model())->InComponent();
  }
  return false;
}

void RadonElement::OnRenderFailed() {
  if (data_model()) {
    static_cast<RadonNode*>(data_model())->OnRenderFailed();
  }
}

Element* RadonElement::GetParentComponentElement() const {
  auto* node = static_cast<RadonNode*>(data_model());
  RadonComponent* comp = node->component();

  Element* element = const_cast<RadonElement*>(this);
  if (element->GetPageElementEnabled() && comp->IsRadonPage()) {
    return static_cast<RadonNode*>(comp->radon_children_[0].get())->element();
  } else {
    return comp->element();
  }
}

void RadonElement::SetAttributeHolder(AttributeHolder* data_model) {
  if (!data_model) return;
  data_model_ = data_model;

  is_component_ = static_cast<RadonNode*>(data_model)->IsRadonComponent();
}

void RadonElement::SetNativeProps(const lepus::Value& args) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, ELEMENT_SET_NATIVE_PROPS);
  if (!args.IsTable()) {
    LOGE("SetNativeProps's param must be a Table!");
    return;
  }

  if (args.Table()->size() <= 0) {
    LOGE("SetNativeProps's param must not be empty!");
    return;
  }
  StyleMap styles;
  for (auto& arg : *(args.Table())) {
    auto id = CSSProperty::GetPropertyID(arg.first);
    if (id != kPropertyEnd) {
      UnitHandler::Process(id, arg.second, styles,
                           element_manager_->GetCSSParserConfigs());
      SetStyle(styles);
      EXEC_EXPR_FOR_INSPECTOR(element_manager()->OnSetNativeProps(
          this, arg.first.str(), arg.second.ToString(), true));
    } else if (arg.first.IsEqual("text") &&
               (tag_.IsEqual("text") || tag_.IsEqual("x-text") ||
                tag_.IsEqual("x-inline-text") || tag_.IsEqual("inline-text")) &&
               children_.size() > 0) {
      // FIXME(linxs): use function to get rawText
      children_[0]->SetAttribute(arg.first, arg.second);
      EXEC_EXPR_FOR_INSPECTOR(element_manager()->OnSetNativeProps(
          children_[0], arg.first.str(), arg.second.ToString(), false));
    } else {
      SetAttribute(arg.first, arg.second);
      EXEC_EXPR_FOR_INSPECTOR(element_manager()->OnSetNativeProps(
          this, arg.first.str(), arg.second.ToString(), false));
    }
  }
  element_manager_->OnFinishUpdateProps(this);
  PipelineOptions options;
  OnPatchFinish(options);
}

void RadonElement::onDataModelSetted(AttributeHolder* old_model,
                                     AttributeHolder* new_model) {
  auto observer = observer_.lock();
  EXEC_EXPR_FOR_INSPECTOR({
    if (observer != nullptr && element_manager_->IsDomTreeEnabled()) {
      observer->OnElementDataModelSetted(
          this, static_cast<AttributeHolder*>(new_model));
    }
  });
}

void RadonElement::InsertNode(RadonElement* child) {
  size_t index = children_.size();
  InsertNode(child, index);
}

void RadonElement::InsertNode(RadonElement* child, size_t index) {
  StylesManager().MarkDirty();
  if (index == 0 && index != children_.size()) {
    RadonElement* first_child = static_cast<RadonElement*>(GetChildAt(0));
    if (first_child && first_child->IsPseudoNode() &&
        first_child->IsBeforeContent())
      index++;
  }
  if (index == children_.size() && children_.size() != 0) {
    RadonElement* last_child =
        static_cast<RadonElement*>(GetChildAt(children_.size() - 1));
    if (last_child && last_child->IsPseudoNode() &&
        last_child->IsAfterContent())
      index--;
  }
  element_manager()->InsertLayoutNode(layout_node(), child->layout_node(),
                                      static_cast<int>(index));
  AddChildAt(child, index);
  if (element_container()) {
    element_container()->AttachChildToTargetContainer(GetChildAt(index));
  }
}

void RadonElement::RemoveNode(RadonElement* child, unsigned int index,
                              bool destroy) {
  if (index >= children_.size()) return;
  bool destroy_platform_node = destroy && child->HasPaintingNode();
  element_manager()->RemoveLayoutNode(layout_node(), child->layout_node(),
                                      index, destroy_platform_node);
  RemoveChildAt(index);
  child->element_container()->RemoveSelf(destroy_platform_node);
  if (destroy_platform_node) child->MarkPlatformNodeDestroyedRecursively();
}

void RadonElement::MoveNode(RadonElement* child, unsigned int from_index,
                            unsigned int to_index) {
  RemoveNode(child, from_index, false);
  InsertNode(child, to_index);
}

void RadonElement::DestroyNode(RadonElement* element) {
  bool destroy_platform_node = element->HasPaintingNode();
  if (destroy_platform_node) {
    element->element_container()->RemoveSelf(destroy_platform_node);
    element->MarkPlatformNodeDestroyedRecursively();
  }
}

void RadonElement::MarkPlatformNodeDestroyedRecursively() {
  has_painting_node_ = false;
  // All descent UI will be deleted recursively in platform side, should mark it
  // recursively
  for (size_t i = 0; i < GetChildCount(); ++i) {
    auto* child = static_cast<RadonElement*>(GetChildAt(i));
    child->MarkPlatformNodeDestroyedRecursively();
    // The z-index child's parent may be different from ui parent
    // and not destroyed
    if (child->HasElementContainer() && child->ZIndex() != 0) {
      child->element_container()->Destroy();
    }
    if (child->parent() == this) {
      child->set_parent(nullptr);
    }
  }
  // clear element's children only in radon or radon compatible mode.
  children_.clear();
}

void RadonElement::UpdateDynamicElementStyle() {
  DCHECK(!parent());
  PreparePropsBundleForDynamicCSS();
  FlushDynamicStyles();
}

void RadonElement::FlushDynamicStyles() {
  // When the element is first created, we will consume the transition data
  // after all styles (including dynamic styles) have been resolved.
  // If the has_transition_props_ is still true here, it means that this element
  // is first created and the transition props do not be consumed ahead. We
  // should consume them here.
  if (has_transition_props_ && enable_new_animator()) {
    SetDataToNativeTransitionAnimator();
  }

  if (prop_bundle_) {
    FlushProps();
  }

  const size_t children_size = children_.size();
  for (size_t i = 0; i < children_size; ++i) {
    auto* node = static_cast<RadonElement*>(GetChildAt(i));
    node->FlushDynamicStyles();
  }
}

int RadonElement::ParentComponentId() const {
  if (data_model()) {
    return static_cast<RadonNode*>(data_model())->ParentComponentId();
  }
  return 0;
}

std::string RadonElement::ParentComponentIdString() const {
  return std::to_string(ParentComponentId());
}

Element* RadonElement::Sibling(int offset) const {
  if (!parent_) return nullptr;
  auto index = static_cast<RadonElement*>(parent_)->IndexOf(this);
  // We know the index can't be -1
  return parent_->GetChildAt(index + offset);
}

void RadonElement::AddChildAt(RadonElement* child, size_t index) {
  children_.insert(children_.begin() + index, child);
  child->set_parent(this);
}

RadonElement* RadonElement::RemoveChildAt(size_t index) {
  auto* removed = static_cast<RadonElement*>(children_[index]);
  children_.erase(children_.begin() + index);
  removed->set_parent(nullptr);
  return removed;
}

int RadonElement::IndexOf(const RadonElement* child) const {
  auto it = std::find(children_.begin(), children_.end(), child);
  if (it != children_.end()) {
    return static_cast<int>(std::distance(children_.begin(), it));
  } else {
    return -1;
  }
}

bool RadonElement::GetPageElementEnabled() {
  EXEC_EXPR_FOR_INSPECTOR({
    if (!data_model()) return false;
    return static_cast<RadonNode*>(data_model())
        ->page_proxy_->GetPageElementEnabled();
  });
  return false;
}

Element* RadonElement::GetChildAt(size_t index) {
  if (index >= children_.size()) {
    return nullptr;
  }
  return children_[index];
}

size_t RadonElement::GetUIIndexForChild(Element* child) {
  int index = 0;
  bool found = false;
  for (auto& it : children_) {
    auto* current = static_cast<RadonElement*>(it);
    if (child == current) {
      found = true;
      break;
    }
    if (current->ZIndex() != 0) {
      continue;
    }
    index += (current->IsLayoutOnly() ? current->GetUIChildrenCount() : 1);
  }
  if (!found) {
    LOGE("element can not found:" + tag_.str());
    // Child id was not a child of parent id
    DCHECK(false);
  }
  return index;
}

size_t RadonElement::GetUIChildrenCount() {
  size_t ret = 0;
  for (auto& it : children_) {
    auto* current = static_cast<RadonElement*>(it);
    if (current->IsLayoutOnly()) {
      ret += current->GetUIChildrenCount();
    } else if (current->ZIndex() == 0) {
      ret++;
    }
  }
  return ret;
}

void RadonElement::SetComponentIDPropsIfNeeded() {
  if (!tag_.IsEquals("component")) {
    return;
  }
  // only used in radon

  RadonComponent* comp = static_cast<RadonComponent*>(data_model_);
  prop_bundle_->SetProps("ComponentID", comp->ComponentId());
}

void RadonElement::FlushPropsFirstTimeWithParentElement(Element* parent) {
  CheckHasInlineContainer(parent);

  FlushProps();
}

void RadonElement::FlushProps() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, ELEMENT_FLUSH_PROPS);
  // When element has animation or transform or transition.layoutNode should
  // dispatch layoutFinished status whatever node if is dirty to make animation
  // and transform be called correctly.
  element_manager_->MarkNodeAnimated(layout_node(), has_animate_props_);

  // Only view and component can be optimized as layout only node
  if (has_layout_only_props_ &&
      !(tag_.IsEquals("view") || tag_.IsEquals("component"))) {
    has_layout_only_props_ = false;
  }

  if (tag_.IsEquals("scroll-view") || tag_.IsEqual("list")) {
    element_manager_->UpdateLayoutNodeAttribute(
        layout_node(), starlight::LayoutAttribute::kScroll, lepus::Value(true));
    can_has_layout_only_children_ = false;
  }

  // TODO(liyanbo):refactor setStyle. pre handler some special css styles.
  if (has_transition_props_) {
    if (!enable_new_animator()) {
      PushToBundle(kPropertyIDTransition);
      has_transition_props_ = false;
    }
  }

  if (has_keyframe_props_) {
    if (!enable_new_animator()) {
      ResolveAndFlushKeyframes();
      PushToBundle(kPropertyIDAnimation);
    } else {
      SetDataToNativeKeyframeAnimator();
    }
    has_keyframe_props_ = false;
  }
  // Update The root if needed

  if (!has_painting_node_) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "Catalyzer::FlushProps::NoPaintingNode");
    PreparePropBundleIfNeed();
    SetComponentIDPropsIfNeeded();

    element_manager_->AttachLayoutNode(layout_node(), prop_bundle_.get());
    bool platform_is_flatten = true;
#if ENABLE_RENDERKIT
    is_virtual_ = false;
    platform_is_flatten = !(has_z_props_ || is_fixed_);
#else
    is_virtual_ = element_manager_->IsShadowNodeVirtual(tag_);
    platform_is_flatten = TendToFlatten();
#endif
    bool is_layout_only = CanBeLayoutOnly() || is_virtual_;
    set_is_layout_only(is_layout_only);
    // native layer don't flatten.
    CreateElementContainer(platform_is_flatten);
    has_painting_node_ = true;
  } else {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "Catalyzer::FlushProps::HasPaintingNode");
    PreparePropBundleIfNeed();
    SetComponentIDPropsIfNeeded();
    element_manager_->UpdateLayoutNodeProps(layout_node(), prop_bundle_);
    if (!is_virtual()) {
      UpdateElement();
    }
  }
  ResetPropBundle();
}

bool RadonElement::IsBeforeContent() {
  return pseudo_type_ & CSSSheet::BEFORE_SELECT;
}

bool RadonElement::IsAfterContent() {
  return pseudo_type_ & CSSSheet::AFTER_SELECT;
}

void RadonElement::OnPseudoStatusChanged(PseudoState prev_status,
                                         PseudoState current_status) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonElement::OnPseudoStatusChanged");

  // If data_model() is null or data_model() is not RadonNode, return.
  if (data_model() == nullptr) {
    return;
  }

  RadonNode* node = static_cast<RadonNode*>(data_model());
  node->SetPseudoState(current_status);
}

// If new animator is enabled and this element has been created before, we
// should consume transition styles in advance. Also transition manager needs to
// verify every property to determine whether to intercept this update.
// Therefore, the operations related to Transition in the SetStyle process are
// divided into three steps:
// 1. Consume all transition styles in advance if needed.
// 2. Skip all transition styles in the later process if they have been consume
// in advance.
// 3. Check every property to determine whether to intercept this update.
void RadonElement::SetStyle(const StyleMap& styles) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, ELEMENT_SET_STYLE);
  if (styles.empty()) {
    return;
  }
  // set font-size first.Other css may use this to calc rem or em.
  auto it = styles.find(CSSPropertyID::kPropertyIDFontSize);
  if (it != styles.end()) {
    SetFontSize(&(it->second));
  } else {
    SetFontSize(nullptr);
  }

  // Set rtl flag and lynx-rtl flag.
  it = styles.find(CSSPropertyID::kPropertyIDDirection);
  if (it != styles.end()) {
    SetDirection(it->second);
  }

  bool should_consume_trans_styles_in_advance =
      ShouldConsumeTransitionStylesInAdvance();
  // #1. Consume all transition styles in advance.
  if (should_consume_trans_styles_in_advance) {
    ConsumeTransitionStylesInAdvance(styles);
  }

  for (const auto& style : styles) {
    // record styles, used for worklet
    styles_[style.first] = style.second;

    // #2. Skip all transition styles in the later process if they have been
    // consume in advance.
    if (style.first == kPropertyIDFontSize ||
        style.first == kPropertyIDDirection ||
        (should_consume_trans_styles_in_advance &&
         CSSProperty::IsTransitionProps(style.first))) {
      continue;
    }
    // #3. Check every property to determine whether to intercept this update.
    if (css_transition_manager_ && css_transition_manager_->ConsumeCSSProperty(
                                       style.first, style.second)) {
      continue;
    }
    styles_manager_.AdoptStyle(style.first, style.second);
  }
}

void RadonElement::ConsumeTransitionStylesInAdvanceInternal(
    CSSPropertyID css_id, const tasm::CSSValue& value) {
  // record styles, used for worklet
  styles_[css_id] = value;
  styles_manager_.AdoptStyle(css_id, value);
}

void RadonElement::ResetTransitionStylesInAdvanceInternal(
    CSSPropertyID css_id) {
  // record styles, used for worklet
  styles_.erase(css_id);
  StylesManager().AdoptStyle(css_id, CSSValue::Empty());
}

void RadonElement::ResolveStyleValue(CSSPropertyID id,
                                     const tasm::CSSValue& value,
                                     bool force_update) {
  if (computed_css_style()->SetValue(id, value) || force_update) {
    // The props of transition and keyframe no need to be pushed to bundle here.
    // Those props will be pushed to bundle separately later.
    if (!(CheckTransitionProps(id) || CheckKeyframeProps(id))) {
      PushToBundle(id);
    }
  }
}

void RadonElement::CheckBaseline(CSSPropertyID css_id, CSSValue value) {
  if (IsSetBaselineOnView(css_id, value) ||
      IsSetBaselineOnInlineView(css_id, value)) {
    this->element_manager()->SetLayoutHasBaseline(true);
  }
}

// TODO(wujintian): CheckAnimateProps shall be removed later, use onNodeReady to
// replace onAnimatedNodeReady!
void RadonElement::CheckAnimateProps(CSSPropertyID id) {
  if (has_animate_props_) {
    return;
  }
  has_animate_props_ =
      (id >= CSSPropertyID::kPropertyIDTransform &&
       id <= CSSPropertyID::kPropertyIDAnimationPlayState) ||
      (id >= CSSPropertyID::kPropertyIDLayoutAnimationCreateDuration &&
       id <= CSSPropertyID::kPropertyIDLayoutAnimationUpdateDelay) ||
      (id >= CSSPropertyID::kPropertyIDTransition &&
       id <= CSSPropertyID::kPropertyIDTransitionDuration) ||
      (id == CSSPropertyID::kPropertyIDTransformOrigin);
}

void RadonElement::OnPatchFinish(const PipelineOptions& option) {
  element_manager_->OnPatchFinish(option);
}

CSSFragment* RadonElement::GetRelatedCSSFragment() {
  if (data_model_) {
    return data_model_->ParentStyleSheet();
  }
  return nullptr;
}

}  // namespace tasm
}  // namespace lynx
