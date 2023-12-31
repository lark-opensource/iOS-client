// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/air/air_element/air_element.h"

#include <utility>

#include "base/lynx_env.h"
#include "base/string/string_number_convert.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "css/css_keyframes_token.h"
#include "lepus/array.h"
#include "lepus/table.h"
#include "starlight/layout/layout_object.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/page_proxy.h"
#include "tasm/react/element_manager.h"
#include "tasm/value_utils.h"

namespace lynx {
namespace tasm {

namespace {
// compute array:[value , pattern , value , pattern]，need to compute px.
// eg:border-radius , padding , margin
//      "property_id": {
//        "value": [
//          width_value,
//          width_value_pattern,
//          height_value,
//          height_value_pattern
//        ],
//        "pattern": 14
//      }
constexpr static const int32_t kItemGap = 2;
constexpr static int32_t kInvalidIndex = -1;
constexpr static float kRpxRatio = 750.0f;
}  // namespace

AirElement::AirElement(AirElementType type, ElementManager *manager,
                       const lepus::String &tag, uint32_t lepus_id, int32_t id)
    : element_type_(type),
      tag_(tag),
      catalyzer_(manager->catalyzer()),
      dirty_(kDirtyCreated),
      lepus_id_(lepus_id),
      air_element_manager_(manager) {
  id_ = id > 0 ? id : manager->GenerateElementID();
  // page config switch for enabling layout-only ability
  config_enable_layout_only_ = manager->GetEnableLayoutOnly();
  config_flatten_ = manager->GetPageFlatten();
  layout_node_ = std::make_shared<LayoutNode>(
      id_, manager->GetLayoutConfigs(), manager->GetLynxEnvConfig(),
      *air_element_manager_->layout_computed_css());
  layout_node_->SetTag(tag_);
}

AirElement::AirElement(const AirElement &node,
                       std::unordered_map<AirElement *, AirElement *> &map)
    : element_type_(node.element_type_),
      tag_(node.tag_),
      catalyzer_(node.catalyzer_),
      has_layout_only_props_(node.has_layout_only_props_),
      dirty_(kDirtyCreated),
      lepus_id_(node.lepus_id_),
      air_element_manager_(node.air_element_manager_) {
  id_ = air_element_manager_->GenerateElementID();
  layout_node_ = std::make_shared<LayoutNode>(
      id_, air_element_manager_->GetLayoutConfigs(),
      air_element_manager_->GetLynxEnvConfig(),
      *air_element_manager_->layout_computed_css());
  layout_node_->SetTag(tag_);
  if (!is_virtual_node()) {
    PreparePropBundleIfNeed();
  }
  for (const auto &static_event : node.static_events_) {
    SetEventHandler(
        static_event.second->name(),
        this->SetEvent(static_event.second->type(), static_event.second->name(),
                       static_event.second->function()));
  }
}

void AirElement::MergeHigherPriorityCSSStyle(StyleMap &primary,
                                             const StyleMap &higher) {
  for (const auto &it : higher) {
    primary[it.first] = it.second;
  }
}

bool AirElement::ResolveKeyframesMap(CSSPropertyID id,
                                     const lepus::Value &keyframes_map) {
  if (id == kPropertyIDAnimationName && keyframes_map.IsTable()) {
    // decode keyframe map, for example
    // {"translateX-ani":{
    //    "0"(string to float) : {"transform"(string) :
    //    "translateX(0)"(string)}, "1" : {"transform"(string) :
    //    "translateX(50px)"(string)},
    // }}
    ForEachLepusValue(keyframes_map, [this](const lepus::Value &keyframe_name,
                                            const lepus::Value &keyframe_dic) {
      starlight::CSSStyleUtils::UpdateCSSKeyframes(
          keyframes_map_, keyframe_name.String()->str(), keyframe_dic,
          air_element_manager_->GetCSSParserConfigs());
    });
    return true;
  }
  return false;
}

void AirElement::PushKeyframesToPlatform() {
  if (!keyframes_map_.empty()) {
    auto lepus_keyframes = starlight::CSSStyleUtils::ResolveCSSKeyframes(
        keyframes_map_, computed_css_style()->GetMeasureContext(),
        air_element_manager_->GetCSSParserConfigs());
    if (!lepus_keyframes.IsTable()) {
      return;
    }
    auto bundle = PropBundle::Create();
    bundle->SetProps("keyframes", lepus_keyframes);
    painting_context()->SetKeyframes(bundle.get());
    keyframes_map_.clear();
  }
}

AirElement *AirElement::GetParentComponent() const {
  AirElement *parent_node = air_parent_;
  while (parent_node != nullptr) {
    if (parent_node->is_component() || parent_node->is_page()) {
      return parent_node;
    }
    parent_node = parent_node->air_parent_;
  }
  return nullptr;
}

/// used by touch_event_handle mainly
bool AirElement::InComponent() const {
  auto parent = GetParentComponent();
  if (parent) {
    return !(parent->is_page());
  }
  return false;
}

void AirElement::InsertNode(AirElement *child, bool from_virtual_child) {
  if (child != this) {
    if (!from_virtual_child) {
      InsertAirNode(child);
    }
    if (child->is_virtual_node()) {
      child->set_parent(this);
      return;
    }
    size_t index = FindInsertIndex(children_, child);
    AddChildAt(child, index);
    dirty_ |= kDirtyTree;
    child->dirty_ |= kDirtyTree;
  }
}

void AirElement::InsertNodeIndex(AirElement *child, size_t index) {
  if (!this->layout_node_->is_common() && !child->layout_node_->is_common()) {
    air_element_manager_->InsertLayoutNode(layout_node_, child->layout_node_,
                                           static_cast<int>(index));
  } else {
    layout_node_->InsertNode(child->layout_node_, static_cast<int>(index));
  }

  element_container()->AttachChildToTargetContainer(GetChildAt(index));
}

void AirElement::InsertNodeBefore(AirElement *child,
                                  const AirElement *reference_child) {
  if (child->is_virtual_node()) {
    // for virtual_node, only save the parent's ptr
    child->set_parent(this);
    return;
  }
  auto index = IndexOf(reference_child);
  if (index >= static_cast<int>(children_.size())) {
    return;
  }
  AddChildAt(child, index);
  dirty_ |= kDirtyTree;
  child->dirty_ |= kDirtyTree;
}

void AirElement::InsertNodeAfterIndex(AirElement *child, int &index) {
  dirty_ |= kDirtyTree;
  child->dirty_ |= kDirtyTree;
  if (!child->is_virtual_node()) {
    ++index;
    AddChildAt(child, index);
  } else {
    child->set_parent(this);
    for (auto air_child : child->air_children_) {
      InsertNodeAfterIndex(air_child.get(), index);
    }
  }
}

void AirElement::InsertNodeAtBottom(AirElement *child) {
  int index = kInvalidIndex;
  if (!children_.empty()) {
    index = static_cast<int>(children_.size() - 1);
  }
  InsertNodeAfterIndex(child, index);
}

void AirElement::InsertAirNode(AirElement *child) {
  if (child != this) {
    size_t index = FindInsertIndex(air_children_, child);
    AddAirChildAt(child, index);
  }
}

AirElement *AirElement::LastNonVirtualNode() {
  AirElement *result = nullptr;
  if (!is_virtual_node()) {
    return this;
  }
  for (auto it = air_children_.rbegin(); it != air_children_.rend(); ++it) {
    if (!(*it)->is_virtual_node()) {
      result = (*it).get();
    } else {
      result = (*it)->LastNonVirtualNode();
    }
    if (result != nullptr) {
      return result;
    }
  }
  return nullptr;
}

void AirElement::RemoveNode(AirElement *child, bool destroy) {
  child->has_been_removed_ = true;
  if (child->is_virtual_node()) {
    child->RemoveAllNodes(destroy);
    if (destroy) {
      element_manager()->air_node_manager()->Erase(child->impl_id());
      element_manager()->air_node_manager()->EraseLepusId(child->GetLepusId(),
                                                          child);
    }
    RemoveAirNode(child);
    dirty_ |= kDirtyTree;
    return;
  }
  if (child->is_component()) {
    child->OnElementRemoved();
  }
  auto index = IndexOf(child);
  if (index != kInvalidIndex) {
    child->RemoveAllNodes();
    RemoveNode(child, index, destroy);
    RemoveAirNode(child);
    dirty_ |= kDirtyTree;
  }
}

void AirElement::RemoveAllNodes(bool destroy) {
  for (auto const &child : SharedAirElementVector(air_children_)) {
    RemoveNode(child.get(), destroy);
  }

  if (destroy) {
    air_children_.erase(air_children_.begin(), air_children_.end());
  }
}

void AirElement::RemoveAirNode(AirElement *child) {
  auto index = IndexOfAirChild(child);
  RemoveAirNode(child, index);
}

void AirElement::SetAttribute(const lepus::String &key,
                              const lepus::Value &value) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirSetAttribute");
  // check flatten prop and update config_flatten_
  CheckFlattenProp(key, value);
  PushToPropsBundle(key, value);
}

void AirElement::ComputeCSSStyle(CSSPropertyID id, tasm::CSSValue &css_value) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirComputeCSSStyle");
  if (!air_computed_css_style_.Process(id, css_value.GetPattern(),
                                       css_value.GetValue())) {
    // if air_computed_css_style_ can't resolve the css_id, handle it by
    // computed_css_style
    computed_css_style()->SetValue(id, css_value);
    css_value.SetValue(computed_css_style()->GetValue(id));
  }
}

void AirElement::Destroy() {
  // Layout only destroy recursively
  if (!IsLayoutOnly()) {
    painting_context()->DestroyPaintingNode(
        parent() ? parent()->impl_id() : kInvalidIndex, impl_id(), 0);
  } else {
    for (int i = static_cast<int>(GetChildCount()) - 1; i >= 0; --i) {
      GetChildAt(i)->Destroy();
    }
  }
  if (parent()) {
    parent()->RemoveNode(this);
  }
}

void AirElement::MarkPlatformNodeDestroyedRecursively() {
  has_painting_node_ = false;
  // All descent UI will be deleted recursively in platform side, should mark it
  // recursively
  for (size_t i = 0; i < GetChildCount(); ++i) {
    auto child = GetChildAt(i);
    child->MarkPlatformNodeDestroyedRecursively();
    child->Destroy();
    if (child->parent() == this) {
      child->parent_ = nullptr;
    }
  }
  children_.clear();
}

void AirElement::RemoveNode(AirElement *child, unsigned int index,
                            bool destroy) {
  if (index >= children_.size()) {
    return;
  }
  bool destroy_platform_node = destroy && child->HasPaintingNode();
  if (!this->layout_node_->is_common() && !child->layout_node_->is_common()) {
    element_manager()->RemoveLayoutNode(layout_node_, child->layout_node_);
  } else {
    int layout_index = GetIndexForChildLayoutNode(child->layout_node_);
    if (layout_index >= 0) {
      layout_node_->RemoveNode(child->layout_node_, layout_index);
    }
  }
  if (destroy_platform_node) {
    element_manager()->DestroyLayoutNode(child->layout_node_);
  }
  if (child->HasPaintingNode()) {
    child->element_container()->RemoveSelf(destroy_platform_node);
  }
  if (destroy_platform_node) {
    child->MarkPlatformNodeDestroyedRecursively();
  }
  RemoveChildAt(index);
  if (destroy) {
    element_manager()->air_node_manager()->Erase(child->impl_id());
    element_manager()->air_node_manager()->EraseLepusId(child->GetLepusId(),
                                                        child);
  }
}

void AirElement::RemoveAirNode(AirElement *child, unsigned int index,
                               bool destroy) {
  if (index >= air_children_.size()) {
    return;
  }
  RemoveAirChildAt(index);
}

void AirElement::UpdateLayout(float left, float top, float width, float height,
                              const std::array<float, 4> &paddings,
                              const std::array<float, 4> &margins,
                              const std::array<float, 4> &borders,
                              const std::array<float, 4> *sticky_positions,
                              float max_height) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirElement::UpdateLayout");
  frame_changed_ = true;
  top_ = top;
  left_ = left;
  width_ = width;
  height_ = height;
  paddings_ = paddings;
  margins_ = margins;
  borders_ = borders;
}

/// for radon mode
void AirElement::PushDynamicNode(AirElement *node) {
  dynamic_nodes_.push_back(node);
}

AirElement *AirElement::GetDynamicNode(uint32_t index,
                                       uint32_t lepus_id) const {
  if (index >= dynamic_nodes_.size()) {
    LOGF("GetDynamicNode overflow. node_index "
         << lepus_id << " index: " << index
         << " dynamic_nodes_.size(): " << dynamic_nodes_.size());
  }
  auto *node = dynamic_nodes_[index];
  if (node->GetLepusId() != lepus_id) {
    LOGF("GetDynamicNode indices not equal. target node index "
         << lepus_id << " but got: " << node->GetLepusId());
  }
  return node;
}

void AirElement::UpdateUIChildrenCountInParent(int delta) {
  if (IsLayoutOnly()) {
    AirElement *parent = parent_;
    while (parent) {
      parent->ui_children_count += delta;
      if (!parent->IsLayoutOnly()) {
        break;
      }
      parent = static_cast<AirElement *>(parent->parent());
    }
  }
}

// element tree
void AirElement::AddChildAt(AirElement *child, size_t index) {
  children_.insert(
      children_.begin() + index,
      air_element_manager_->air_node_manager()->Get(child->impl_id()));
  child->parent_ = this;
}

AirElement *AirElement::RemoveChildAt(size_t index) {
  if (index < children_.size()) {
    AirElement *removed = children_[index].get();
    children_.erase(children_.begin() + index);
    removed->parent_ = nullptr;
    return removed;
  }
  return nullptr;
}

int AirElement::IndexOf(const AirElement *child) {
  for (size_t index = 0; index != children_.size(); ++index) {
    if (children_[index].get() == child) {
      return static_cast<int>(index);
    }
  }
  return kInvalidIndex;
}

void AirElement::AddAirChildAt(AirElement *child, size_t index) {
  air_children_.insert(
      air_children_.begin() + index,
      air_element_manager_->air_node_manager()->Get(child->impl_id()));
  child->air_parent_ = this;
}

AirElement *AirElement::RemoveAirChildAt(size_t index) {
  if (index < air_children_.size()) {
    auto removed = air_children_[index];
    air_children_.erase(air_children_.begin() + index);
    removed->air_parent_ = nullptr;
    return removed.get();
  }
  return nullptr;
}

int AirElement::IndexOfAirChild(AirElement *child) {
  if (child == nullptr) {
    return kInvalidIndex;
  }
  for (size_t index = 0; index < air_children_.size(); ++index) {
    if (air_children_[index].get() == child) {
      return static_cast<int>(index);
    }
  }
  return kInvalidIndex;
}

AirElement *AirElement::GetChildAt(size_t index) const {
  if (index >= children_.size()) {
    return nullptr;
  }
  return children_[index].get();
}

void AirElement::SetStyle(CSSPropertyID id, tasm::CSSValue &value) {
  // After CSS Diff&Merge is completed, the entry method for processing css
  // properties. Including four types:
  // 1. animation
  // 2. layoutOnly: set to starlight
  // 3. layoutWanted: set to starlight & set to platform
  // 4. other:set to platform
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirSetStyle");
  // Handle animation properties
  if (UNLIKELY(ResolveKeyframesMap(id, value.GetValue()))) {
    has_animate_props_ = true;
    return;
  }
  // The LayoutOnly css property only needs to be set to starlight
  if (LayoutNode::IsLayoutOnly(id)) {
    layout_node_->ConsumeStyle(id, value);
    dirty_ |= kDirtyStyle;
    // The LayoutWanted css property needs to be set to starlight, and also
    // needs to be set to the platform.
  } else if (LayoutNode::IsLayoutWanted(id)) {
    layout_node_->ConsumeStyle(id, value);
    dirty_ |= kDirtyStyle;
    ComputeCSSStyle(id, value);
    // set to the platform
    PushToPropsBundle(CSSProperty::GetPropertyName(id), value.GetValue());
  } else {
    // Other css properties only need to be set to the platform layer
    ComputeCSSStyle(id, value);
    PushToPropsBundle(CSSProperty::GetPropertyName(id), value.GetValue());
  }
}

void AirElement::ResetStyle(CSSPropertyID id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirResetStyle");
  bool is_layout_only = LayoutNode::IsLayoutOnly(id);
  if (is_layout_only || LayoutNode::IsLayoutWanted(id)) {
    air_element_manager_->ResetLayoutNodeStyle(layout_node_, id);
  }
  dirty_ |= kDirtyStyle;
  if (is_layout_only) {
    return;
  }
  has_layout_only_props_ = false;
  prop_bundle_->SetNullProps(CSSProperty::GetPropertyName(id).c_str());
}

starlight::ComputedCSSStyle *AirElement::computed_css_style() {
  if (!platform_css_style_ && air_element_manager_) {
    platform_css_style_ = std::make_unique<starlight::ComputedCSSStyle>(
        *air_element_manager_->platform_computed_css());
    const auto &env_config = air_element_manager_->GetLynxEnvConfig();
    platform_css_style_->SetScreenWidth(env_config.ScreenWidth());
    platform_css_style_->SetViewportHeight(env_config.ViewportHeight());
    platform_css_style_->SetViewportWidth(env_config.ViewportWidth());
    platform_css_style_->SetCssAlignLegacyWithW3c(
        air_element_manager_->GetLayoutConfigs().css_align_with_legacy_w3c_);
    platform_css_style_->SetFontScaleOnlyEffectiveOnSp(
        air_element_manager_->GetLynxEnvConfig().FontScaleSpOnly());
  }
  return platform_css_style_.get();
}

void AirElement::CheckHasAnimateProps(CSSPropertyID id) {
  if (!has_animate_props_) {
    has_animate_props_ =
        (id >= CSSPropertyID::kPropertyIDTransform &&
         id <= CSSPropertyID::kPropertyIDAnimationPlayState) ||
        (id >= CSSPropertyID::kPropertyIDLayoutAnimationCreateDuration &&
         id <= CSSPropertyID::kPropertyIDLayoutAnimationUpdateDelay) ||
        (id >= CSSPropertyID::kPropertyIDTransition &&
         id <= CSSPropertyID::kPropertyIDTransitionDuration) ||
        (id == CSSPropertyID::kPropertyIDTransformOrigin);
  }
}

// TODO(renpengcheng): change to OnNodeReady in release/3.0
void AirElement::OnAnimatedNodeReady() {
  painting_context()->OnAnimatedNodeReady(impl_id());
}

// event handler
void AirElement::SetEventHandler(const lepus::String &name,
                                 EventHandler *handler) {
  PreparePropBundleIfNeed();
  prop_bundle_->SetEventHandler(*handler);
  has_layout_only_props_ = false;
}

void AirElement::ResetEventHandlers() {
  if (prop_bundle_ != nullptr) {
    prop_bundle_->ResetEventHandler();
  }
}

size_t AirElement::GetUIChildrenCount() const {
  size_t ret = 0;
  for (auto current : children_) {
    if (current->IsLayoutOnly()) {
      ret += current->GetUIChildrenCount();
    } else {
      ret++;
    }
  }
  return ret;
}

size_t AirElement::GetUIIndexForChild(AirElement *child) const {
  int index = 0;
  bool found = false;
  for (auto it : children_) {
    auto current = it;
    if (child == current.get()) {
      found = true;
      break;
    }
    index += (current->IsLayoutOnly() ? current->GetUIChildrenCount() : 1);
  }
  if (!found) {
    LOGE("air_element can not found:" + tag_.str());
    // Child id was not a child of parent id
    // TODO(renpengcheng):redbox error
    DCHECK(false);
  }
  return index;
}

void AirElement::CreateElementContainer(bool platform_is_flatten) {
  element_container_ = std::make_unique<AirElementContainer>(this);
  if (IsLayoutOnly()) {
    return;
  }
  painting_context()->CreatePaintingNode(id_, prop_bundle_.get(),
                                         platform_is_flatten);
}

void AirElement::FlushProps() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirElement::FlushProps");

  if (!is_page() && !is_virtual_node()) {
    RefreshStyles();
  }
  // When has_animate_props_ was true (maybe animation or transform or
  // transition was included).the operation that dispatches the layoutfinished
  // status of this element's layout-node should be created whther the
  // layout-node is dirty, then SetAnimation or SetTransform will be called
  // correctly.
  layout_node()->MarkIsAnimated(has_animate_props_);
  // Only view and component can be optimized as layout only node
  if (has_layout_only_props_ &&
      !(tag_.IsEquals("view") || tag_.IsEquals("component"))) {
    has_layout_only_props_ = false;
  }
  // Update The root if needed
  if (!has_painting_node_) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirElement::FlushProps::NoPaintingNode");
    if (!prop_bundle_) {
      prop_bundle_ = PropBundle::Create();
    }
    prop_bundle_->set_tag(tag_);
    air_element_manager_->AttachLayoutNode(layout_node_, prop_bundle_.get());
    bool platform_is_flatten = true;
    is_virtual_ = air_element_manager_->IsShadowNodeVirtual(tag_);
    platform_is_flatten = TendToFlatten();

    set_is_layout_only(CanBeLayoutOnly() || is_virtual_);
    CreateElementContainer(platform_is_flatten);
    has_painting_node_ = true;
  } else {
    if (!prop_bundle_) {
      prop_bundle_ = PropBundle::Create();
    }
    prop_bundle_->set_tag(tag_);
    if (!layout_node_->is_common()) {
      air_element_manager_->UpdateLayoutNodeProps(layout_node_, prop_bundle_);
    }
    if (!is_virtual_) {
      if (!IsLayoutOnly()) {
        painting_context()->UpdatePaintingNode(impl_id(), TendToFlatten(),
                                               prop_bundle_.get());
      }
    }
  }
  PushKeyframesToPlatform();
  prop_bundle_ = nullptr;
  dirty_ = 0;
}

void AirElement::FlushRecursively() {
  if (is_virtual_node() && parent_) {
    parent_->FlushRecursively();
    return;
  }
  if (dirty_ > 0 || style_dirty_ > 0 || !has_painting_node_) {
    FlushProps();
  }
  for (size_t i = 0; i < GetChildCount(); ++i) {
    auto *child = GetChildAt(i);
    bool has_flush_recursive = false;
    bool child_has_painting_node = child->has_painting_node_;
    if (child->dirty_ > 0 || child->style_dirty_ > 0 ||
        !child_has_painting_node) {
      child->FlushProps();
    }
    if (child->IsLayoutOnly()) {
      child->FlushRecursively();
      has_flush_recursive = true;
    }
    if (!child_has_painting_node || child->has_been_removed_) {
      InsertNodeIndex(child, i);
      child->has_been_removed_ = false;
    }
    if (!(child->layout_node_->parent())) {
      // In case the order of multiple flushes is not as expected, insert again
      // to ensure that the nodes are correct.
      InsertNodeIndex(child, i);
    }
    if (!has_flush_recursive) {
      child->FlushRecursively();
    }
  }
}

void AirElement::PreparePropBundleIfNeed() {
  if (!prop_bundle_) {
    prop_bundle_ = PropBundle::Create();
    prop_bundle_->set_tag(tag_);
  }
}

bool AirElement::TendToFlatten() const {
  return config_flatten_ && support_flatten_ && !has_animate_props_;
}

PaintingContext *AirElement::painting_context() {
  return catalyzer_->painting_context();
}

lepus::Value AirElement::GetData() {
  AirElement *component = GetParentComponent();
  if (component) {
    return component->GetData();
  }
  return lepus::Value();
}

lepus::Value AirElement::GetProperties() {
  AirElement *component = GetParentComponent();
  if (component->is_component()) {
    return component->GetProperties();
  }
  return lepus::Value();
}

bool AirElement::CheckFlattenProp(const lepus::String &key,
                                  const lepus::Value &value) {
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

void AirElement::SetClasses(const lepus::Value &class_names) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirElement::SetClasses");
  //<view class = ''>
  if (class_names.IsEmpty()) {
    classes_.clear();
    style_dirty_ |= Selector::kCLASS;
    return;
  }

  auto class_names_str = class_names.String();
  std::vector<std::string> class_name_vec;
  base::SplitString(class_names_str->str(), ' ', class_name_vec);

  if (classes_.size() != class_name_vec.size()) {
    style_dirty_ |= Selector::kCLASS;
  } else {
    for (auto &class_name : class_name_vec) {
      bool need_mark_style_dirty =
          !(style_dirty_ & Selector::kCLASS) && !class_name.empty() &&
          std::find(classes_.begin(), classes_.end(), class_name) ==
              classes_.end();
      if (need_mark_style_dirty) {
        style_dirty_ |= Selector::kCLASS;
        break;
      }
    }
  }
  if (style_dirty_ & Selector::kCLASS) {
    classes_.swap(class_name_vec);
  }
}

void AirElement::SetIdSelector(const lepus::Value &id_selector) {
  if (id_selector.String()->str() != id_selector_) {
    id_selector_ = id_selector.String()->str();
    style_dirty_ |= Selector::kID;
  }
}

size_t AirElement::FindInsertIndex(const SharedAirElementVector &target,
                                   AirElement *child) {
  // The lepus id of elements in vector are arranged from small to large. Find
  // the first element whose lepus id is greater than the element to be inserted
  // and insert the element in front of it. (In most cases, elements are
  // inserted in order from small to large, so search from the end.)
  size_t index = target.size();
  for (auto iter = target.rbegin(); iter != target.rend(); ++iter) {
    if (child->lepus_id_ < (*iter)->lepus_id_) {
      index--;
    } else {
      break;
    }
  }
  return index;
}

int AirElement::GetIndexForChildLayoutNode(
    const std::shared_ptr<LayoutNode> &child) {
  int index = 0;
  bool found = false;
  for (const auto &node : layout_node_->children()) {
    if (node == child) {
      found = true;
      break;
    }
    ++index;
  }
  if (found) {
    return index;
  }
  return -1;
}

void AirElement::SetInlineStyle(CSSPropertyID id, const CSSValue &value) {
  inline_style_map_[id] = value;
  style_dirty_ |= Selector::kINLINE;
}

void AirElement::DiffStyles(StyleMap &old_map, const StyleMap &new_map,
                            StylePatch &style_patch, bool is_final) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirElement::DiffStyles");
  // Selector has not changed
  if (new_map.empty()) {
    for (auto &old_map_item : old_map) {
      // Delete those css ids that need to be updated in the low priority but
      // need to be reserved in the high priority from the update_map of the
      // patch
      if (style_patch.update_styles_map_.find(old_map_item.first) !=
          style_patch.update_styles_map_.end()) {
        style_patch.update_styles_map_.erase(old_map_item.first);
      }
      // When new_map is empty, all ids in old_map need to be reserved
      style_patch.reserve_styles_map_.insert_or_assign(old_map_item.first,
                                                       old_map_item.second);
    }
  } else {
    for (auto &new_map_item : new_map) {
      auto old_map_iterator = old_map.find(new_map_item.first);
      // Exists in new_map but not in old_map
      if (old_map_iterator == old_map.end() ||
          new_map_item.second != old_map_iterator->second) {
        // Delete those css ids that need to be reserved in low priority but
        // need to be update in high priority from the reserve_set of patch
        if (style_patch.reserve_styles_map_.find(new_map_item.first) !=
            style_patch.reserve_styles_map_.end()) {
          style_patch.reserve_styles_map_.erase(new_map_item.first);
        }
        style_patch.update_styles_map_.insert_or_assign(new_map_item.first,
                                                        new_map_item.second);
        // Delete the css ids that have been processed, and determine which ones
        // need to be reset from the remaining ids
        old_map.erase(old_map_iterator);
      } else {
        // Delete those css ids that need to be updated in the low priority but
        // need to be reserved in the high priority from the update_map of the
        // patch
        if (style_patch.update_styles_map_.find(old_map_iterator->first) !=
            style_patch.update_styles_map_.end()) {
          style_patch.update_styles_map_.erase(old_map_iterator->first);
        }
        // When new_map is empty, all ids in old_map need to be kept
        style_patch.reserve_styles_map_.insert_or_assign(
            old_map_iterator->first, old_map_iterator->second);
        // Delete the css ids that have been processed, and determine which ones
        // need to be reset from the remaining ids
        old_map.erase(old_map_iterator);
      }
    }
    // Determine the id that needs to be reset in this diff
    for (auto &old_map_item : old_map) {
      style_patch.reset_id_set_.insert(old_map_item.first);
    }
  }

  if (is_final) {
    // Handle the id appearing in reserve_map or update_map in reset_set.'reset'
    // has the lowest priority and needs to be removed from reset_set
    std::unordered_set<CSSPropertyID>::iterator iterator =
        style_patch.reset_id_set_.begin();
    while (iterator != style_patch.reset_id_set_.end()) {
      if (style_patch.update_styles_map_.find(*iterator) !=
          style_patch.update_styles_map_.end()) {
        style_patch.reset_id_set_.erase(iterator++);
      } else {
        auto reserve_iterator = style_patch.reserve_styles_map_.find(*iterator);
        if (reserve_iterator != style_patch.reserve_styles_map_.end()) {
          style_patch.update_styles_map_.insert_or_assign(
              *iterator, reserve_iterator->second);
          style_patch.reset_id_set_.erase(iterator++);
          style_patch.reserve_styles_map_.erase(reserve_iterator);
        } else {
          ++iterator;
        }
      }
    }
  }
}

void AirElement::RefreshStyles() {
  // Diff&merge the css StyleMap corresponding to global, tag, class, id and
  // inline in order to get stylePatch
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirElement::RefreshStyles");
  StylePatch style_patch;
  UpdateStylePatch(Selector::kSTABLE, style_patch);
  UpdateStylePatch(Selector::kCLASS, style_patch);
  UpdateStylePatch(Selector::kID, style_patch);
  UpdateStylePatch(Selector::kINLINE, style_patch);

  // Reset the css props in reset_id_set_
  PreparePropBundleIfNeed();
  if (!style_patch.reset_id_set_.empty()) {
    for (auto css_id : style_patch.reset_id_set_) {
      ResetStyle(css_id);
    }
  }
  // Update the css props in update_styles_map_
  if (!style_patch.update_styles_map_.empty()) {
    for (auto &style : style_patch.update_styles_map_) {
      SetStyle(style.first, style.second);
    }
  }

  inline_style_map_.clear();
  style_dirty_ = 0;
}

void AirElement::UpdateStylePatch(Selector selector,
                                  AirElement::StylePatch &style_patch) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirElement::UpdateStylePatch");
  // first screen & not style_dirty_
  if (!has_painting_node_ && !(style_dirty_ & selector)) {
    return;
  }
  StyleMap selector_styles;
  auto old_selector_styles_iterator = cur_css_styles_.find(selector);
  if (old_selector_styles_iterator == cur_css_styles_.end()) {
    // first screen
    GetStyleMap(selector, selector_styles);
    style_patch.update_styles_map_.insert(selector_styles.begin(),
                                          selector_styles.end());
  } else {
    // Decide whether to get a new styleMap through style_dirty_.
    //'SetClass', 'SetId' and 'SetInlineStyle' will change style_dirty_value
    if (style_dirty_ & selector) {
      GetStyleMap(selector, selector_styles);
    }
    // Diff old styleMap and new styleMap(may be empty)，and update stylePatch
    DiffStyles(old_selector_styles_iterator->second, selector_styles,
               style_patch, selector == Selector::kINLINE);
  }

  if (style_dirty_ & selector) {
    if (selector_styles.empty()) {
      cur_css_styles_.erase(selector);
    } else {
      cur_css_styles_.insert_or_assign(selector, selector_styles);
    }
  }
}
void AirElement::GetStyleMap(Selector selector, StyleMap &result) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "AirElement::GetStyleMap");
  switch (selector) {
    case Selector::kSTABLE:
      GetStableStyleMap(tag_.str(), result);
      break;
    case Selector::kCLASS:
      GetClassStyleMap(classes_, result);
      break;
    case Selector::kID:
      GetIdStyleMap(id_selector_, result);
      break;
    case Selector::kINLINE:
      result = inline_style_map_;
      break;
    default:
      LOGE("invalid css selector");
  }
}

void AirElement::GetStableStyleMap(const std::string &tag_name,
                                   StyleMap &result) {
  if (is_page() || is_component()) {
    static constexpr const char *kGlobal = "*";
    auto iterator = parsed_styles_.find(kGlobal);
    if (iterator != parsed_styles_.end()) {
      result = *(iterator->second);
    }
    if (!tag_name.empty()) {
      StyleMap tag_style_map;
      iterator = parsed_styles_.find(tag_name);
      if (iterator != parsed_styles_.end()) {
        tag_style_map = *(iterator->second);
      }
      MergeHigherPriorityCSSStyle(result, tag_style_map);
    }
  } else {
    AirElement *parent_component = GetParentComponent();
    if (parent_component) {
      parent_component->GetStableStyleMap(tag_name, result);
    }
  }
}

void AirElement::GetClassStyleMap(const ClassVector &class_list,
                                  StyleMap &result) {
  if (is_page() || is_component()) {
    for (const auto &class_name : class_list) {
      auto iterator = parsed_styles_.find("." + class_name);
      if (iterator != parsed_styles_.end()) {
        const auto &class_css_styles = *(iterator->second);
        MergeHigherPriorityCSSStyle(result, class_css_styles);
      }
    }
  } else {
    if (class_list.empty()) {
      return;
    }
    AirElement *parent_component = GetParentComponent();
    if (parent_component) {
      parent_component->GetClassStyleMap(class_list, result);
    }
  }
}

void AirElement::GetIdStyleMap(const std::string &id_name, StyleMap &result) {
  if (is_page() || is_component()) {
    auto iterator = parsed_styles_.find("#" + id_name);
    if (iterator != parsed_styles_.end()) {
      result = *(iterator->second);
    }
  } else {
    if (id_name.empty()) {
      return;
    }
    AirElement *parent_component = GetParentComponent();
    if (parent_component) {
      parent_component->GetIdStyleMap(id_name, result);
    }
  }
}

void AirElement::PushToPropsBundle(const lepus::String &key,
                                   const lepus::Value &value) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PushToPropsBundle");
  PreparePropBundleIfNeed();
  has_layout_only_props_ = false;
  prop_bundle_->SetProps(key.c_str(), value);
  dirty_ |= kDirtyAttr;
}

bool AirElement::AirComputedCSSStyle::Process(CSSPropertyID css_property_id,
                                              CSSValuePattern pattern,
                                              lepus::Value &value) {
  // css property related to animation was transfer to computed_css_style
  if (CSSProperty::IsTransitionProps(css_property_id) ||
      CSSProperty::IsKeyframeProps(css_property_id) ||
      CSSPropertyID::kPropertyIDTransform == css_property_id ||
      CSSPropertyID::kPropertyIDTransformOrigin == css_property_id ||
      CSSPropertyID::kPropertyIDVerticalAlign == css_property_id) {
    return false;
  }
  bool pattern_process_result = ProcessWithPattern(pattern, value);
  bool id_process_result = ProcessWithID(css_property_id, pattern, value);
  return pattern_process_result || id_process_result;
}

bool AirElement::AirComputedCSSStyle::ProcessWithPattern(
    CSSValuePattern attr_pattern, lepus::Value &attr_value) {
  // compute with density when pattern is px. eg:fontSize
  if (attr_pattern == CSSValuePattern::PX) {
    attr_value.SetNumber(attr_value.Number() * Config::Density());
    return true;
  } else if (attr_pattern == CSSValuePattern::RPX) {
    attr_value.SetNumber(attr_value.Number() * Config::Width() / kRpxRatio);
    // compute array:[value , pattern , value , pattern]，need to compute px.
    // eg:border-radius , padding , margin
    //      "property_id": {
    //        "value": [
    //          width_value,
    //          width_value_pattern,
    //          height_value,
    //          height_value_pattern
    //        ],
    //        "pattern": 14
    //      }
    return true;
  } else if (attr_pattern == CSSValuePattern::ARRAY) {
    // copy array and handle the copy，every item is copyable in array
    // value type under lepusVM and lepusNG differs, should use compatible api
    base::scoped_refptr<lepus::CArray> result_attr_c_array =
        lepus::CArray::Create();
    const size_t attr_value_length =
        static_cast<size_t>(attr_value.GetLength());
    for (size_t i = 0; i < attr_value_length; i += kItemGap) {
      if (i + 1 == attr_value_length) {
        break;
      }
      lepus::Value attr_value_in_array = attr_value.GetProperty(i);
      lepus::Value pattern_value_in_array = attr_value.GetProperty(i + 1);
      CSSValuePattern convert_pattern =
          static_cast<CSSValuePattern>(pattern_value_in_array.Number());
      // recursive processing
      ProcessWithPattern(convert_pattern, attr_value_in_array);
      // push to copy array
      result_attr_c_array->push_back(attr_value_in_array);
      result_attr_c_array->push_back(pattern_value_in_array);
    }
    attr_value.SetArray(result_attr_c_array);
    return true;
  }
  return false;
}

bool AirElement::AirComputedCSSStyle::ProcessWithID(
    CSSPropertyID css_property_id, CSSValuePattern pattern,
    lepus::Value &result_value) {
  // compute color: convert lepus value from int64_t to uint32_t , because
  // lepus js number always int64_t
  if (css_property_id == CSSPropertyID::kPropertyIDBackgroundColor ||
      css_property_id == CSSPropertyID::kPropertyIDColor ||
      (css_property_id >= CSSPropertyID::kPropertyIDBorderLeftColor &&
       css_property_id <= CSSPropertyID::kPropertyIDBorderBottomColor)) {
    // color should cast to int32
    if (result_value.IsInt64()) {
      result_value.SetNumber(static_cast<uint32_t>(result_value.Int64()));
    }
    return true;
  } else if (css_property_id == CSSPropertyID::kPropertyIDBorderTopLeftRadius ||
             css_property_id ==
                 CSSPropertyID::kPropertyIDBorderTopRightRadius ||
             css_property_id == kPropertyIDBorderBottomRightRadius ||
             css_property_id == kPropertyIDBorderBottomLeftRadius) {
    if (pattern == CSSValuePattern::ARRAY) {
      // value type under lepusVM and lepusNG differs, should use compatible api
      const size_t result_value_length =
          static_cast<size_t>(result_value.GetLength());
      for (size_t i = 0; i < result_value_length; i += kItemGap) {
        if (i + 1 == result_value_length) {
          break;
        }
        const lepus::Value &pattern_value_in_array =
            result_value.GetProperty(i + 1);
        CSSValuePattern convert_pattern =
            static_cast<CSSValuePattern>(pattern_value_in_array.Number());
        // change pattern to PlatformLengthUnit
        if (convert_pattern == CSSValuePattern::PERCENT) {
          result_value.SetProperty(
              i + 1, lepus::Value(static_cast<double>(
                         starlight::PlatformLengthUnit::PERCENTAGE)));
        } else {
          result_value.SetProperty(i + 1,
                                   lepus::Value(static_cast<double>(
                                       starlight::PlatformLengthUnit::NUMBER)));
        }
      }
      return true;
    }
  }
  return false;
}

}  // namespace tasm
}  // namespace lynx
