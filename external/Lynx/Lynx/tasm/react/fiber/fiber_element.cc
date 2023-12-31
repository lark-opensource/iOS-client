// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/react/fiber/fiber_element.h"

#include <algorithm>
#include <memory>
#include <string>
#include <utility>
#include <vector>

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
#include "lepus/lepus_string.h"
#include "lepus/table.h"
#include "starlight/layout/layout_object.h"
#include "starlight/style/default_css_style.h"
#include "tasm/list_component_info.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/page_proxy.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/radon/node_selector.h"
#include "tasm/react/element_manager.h"
#include "tasm/react/fiber/component_element.h"
#include "tasm/react/fiber/image_element.h"
#include "tasm/react/fiber/list_element.h"
#include "tasm/react/fiber/none_element.h"
#include "tasm/react/fiber/raw_text_element.h"
#include "tasm/react/fiber/scroll_element.h"
#include "tasm/react/fiber/text_element.h"
#include "tasm/react/fiber/view_element.h"
#include "tasm/react/fiber/wrapper_element.h"
#include "tasm/value_utils.h"

namespace lynx {
namespace tasm {

base::scoped_refptr<FiberElement> FiberElement::FromElementInfo(
    int64_t parent_component_id, ElementManager *manager,
    const ElementInfo &info) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FromElementInfo");
  base::scoped_refptr<FiberElement> res;
  switch (info.tag_enum_) {
    case ELEMENT_VIEW:
      res = manager->CreateFiberView();
      break;
    case ELEMENT_IMAGE:
      constexpr const static char *kImage = "image";
      res = manager->CreateFiberImage(kImage);
      break;
    case ELEMENT_TEXT:
      constexpr const static char *kText = "text";
      res = manager->CreateFiberText(kText);
      break;
    case ELEMENT_RAW_TEXT:
      res = manager->CreateFiberRawText();
      break;
    case ELEMENT_SCROLL_VIEW:
      constexpr const static char *kScrollView = "scroll-view";
      res = manager->CreateFiberScrollView(kScrollView);
      break;
    case ELEMENT_LIST:
      constexpr const static char *kList = "list";
      res = manager->CreateFiberList(nullptr, kList, lepus::Value(),
                                     lepus::Value());
      break;
    case ELEMENT_NONE:
      res = manager->CreateFiberNoneElement();
      break;
    case ELEMENT_WRAPPER:
      res = manager->CreateFiberWrapperElement();
      break;
    default:
      res = manager->CreateFiberNode(info.tag_.c_str());
  }

  res->SetParentComponentUniqueIdForFiber(parent_component_id);

  // set id selector
  if (!info.id_selector_.empty()) {
    res->SetIdSelector(info.id_selector_);
  }

  // set class selector
  for (const auto &class_name : info.class_selector_) {
    res->SetClass(class_name.c_str());
  }

  // set inline style
  for (const auto &pair : info.inline_styles_) {
    res->SetStyle(static_cast<CSSPropertyID>(pair.first),
                  lepus::Value(pair.second.c_str()));
  }

  // set js event
  for (const auto &event : info.events_) {
    res->SetJSEventHandler(event.name_.c_str(), event.type_.c_str(),
                           event.value_.c_str());
  }

  // set parsed style
  if (info.has_parser_style_) {
    res->SetParsedStyle(info.parser_style_map_, info.config_);
  }

  // set attributes
  for (const auto &pair : info.attrs_) {
    res->SetAttribute(pair.first.c_str(), pair.second);
  }

  // set dataset
  res->SetDataset(info.data_set_);

  // construct children
  for (const auto &c : info.children_) {
    res->InsertNode(FromElementInfo(parent_component_id, manager, *c));
  }

  // set config
  res->SetConfig(info.config_);
  return res;
}

lepus::Value FiberElement::FromTemplateInfo(int64_t parent_component_id,
                                            ElementManager *manager,
                                            const ElementTemplateInfo &info) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FromTemplateInfo");
  auto res = lepus::Dictionary::Create();
  auto element_ary = lepus::CArray::Create();
  auto dirty_elements = lepus::Dictionary::Create();

  for (const auto &element_info : info.elements_) {
    auto element_node =
        FromElementInfo(parent_component_id, manager, *element_info);
    element_ary->push_back(lepus::Value(element_node));
  }

  constexpr const static char *kElements = "elements";
  res->SetValue(kElements, lepus::Value(element_ary));

  constexpr const static char *kDirtyElements = "dirtyElements";
  res->SetValue(kDirtyElements, lepus::Value(dirty_elements));

  return lepus::Value(res);
}

FiberElement::FiberElement(ElementManager *manager, const lepus::String &tag)
    : FiberElement(manager, tag, INVALID_CSS_ID) {}

FiberElement::FiberElement(ElementManager *manager, const lepus::String &tag,
                           int32_t css_id)
    : Element(tag, manager),
      data_model_(std::make_unique<AttributeHolder>(this)),
      dirty_(kDirtyCreated),
      node_manager_(manager->node_manager()),
      css_id_(css_id) {
  data_model_->set_tag(tag);
  manager->node_manager()->Record(id_, this);
}

FiberElement::~FiberElement() {
  if (!will_destroy_) {
    element_manager()->NotifyElementDestroy(this);
    DestroyPlatformNode();
    node_manager_->Erase(id_);
  }
}

void FiberElement::SetDefaultOverflow(bool visible) {
  layout_node()->slnode()->GetCSSMutableStyle()->SetOverflowDefaultVisible(
      visible);
  computed_css_style()->SetOverflowDefaultVisible(visible);
  overflow_ = visible ? OVERFLOW_XY : OVERFLOW_HIDDEN;
}

void FiberElement::RequireFlush() {
  if (flush_required_) {
    return;
  }
  flush_required_ = true;
  auto *parent = static_cast<FiberElement *>(parent_);
  if (parent && !parent->flush_required_) {
    parent->RequireFlush();
  }
}

void FiberElement::RequireDynamicStyleUpdate() {
  // Use dynamic_style_update_required_ to indicate if needs to do dynamic style
  // update
  if (dynamic_style_update_required_) {
    return;
  }
  dynamic_style_update_required_ = true;
  auto *parent = static_cast<FiberElement *>(parent_);
  if (parent && !parent->dynamic_style_update_required_) {
    parent->RequireDynamicStyleUpdate();
  }
}

ListNode *FiberElement::GetListNode() {
  if (is_list()) {
    return static_cast<ListElement *>(this);
  }
  return nullptr;
}

Element *FiberElement::GetParentComponentElement() const {
  if (!parent_component_element_) {
    parent_component_element_ =
        static_cast<FiberElement *>(element_manager_->node_manager()->Get(
            static_cast<int>(parent_component_unique_id_)));
  }
  return parent_component_element_;
}

CSSFragment *FiberElement::GetRelatedCSSFragment() {
  if (css_id_ != INVALID_CSS_ID) {
    if (!style_sheet_) {
      if (!fragment_ && css_style_sheet_manager_) {
        fragment_ =
            css_style_sheet_manager_->GetCSSStyleSheetForComponent(css_id_);
      }
      style_sheet_ = std::make_shared<CSSFragmentDecorator>(fragment_);
    }
    return style_sheet_.get();
  } else {
    auto *parent_component = GetParentComponentElement();
    if (parent_component) {
      return static_cast<ComponentElement *>(parent_component)
          ->GetCSSFragment();
    } else {
      return nullptr;
    }
  }
}

void FiberElement::UpdateCurrentFlushOption(ActionOption &option) {
  option.inherited_styles_ = &inherited_styles_;
  option.reset_inherited_ids_ = &reset_inherited_ids_;
  option.children_propagate_inherited_styles_flag_ =
      children_propagate_inherited_styles_flag_;
}

void FiberElement::ReplaceElements(
    const std::deque<base::scoped_refptr<FiberElement>> &inserted,
    const std::deque<base::scoped_refptr<FiberElement>> &removed) {
  if (removed.empty()) {
    for (const auto &child : inserted) {
      InsertNodeBeforeInternal(child, nullptr);
    }
    return;
  }

  // 1. Make sure remove first.
  // 2. Get ref = remove.back.next_sibling.
  // 3. And exec InsertNodeBeforeInternal(child, ref).
  auto *ref_before = removed.back().Get();
  FiberElement *ref = nullptr;

  if (ref_before != nullptr) {
    ref = static_cast<FiberElement *>(ref_before->next_sibling());
  } else {
    LOGE(
        "Error may occur in FiberElement::ReplaceElements, since ref before "
        "must not be nullptr");
  }

  for (const auto &child : removed) {
    RemoveNode(child);
  }
  if (!inserted.empty()) {
    for (const auto &child : inserted) {
      InsertNodeBeforeInternal(child, ref);
    }
  }
}

void FiberElement::InsertNode(const base::scoped_refptr<FiberElement> &child) {
  // ref_node:nullptr: means to append this node to the end
  InsertNodeBeforeInternal(child, nullptr);
}

void FiberElement::InsertNode(const base::scoped_refptr<FiberElement> &child,
                              int index) {
  if (index >= static_cast<int>(scoped_children_.size())) {
    LOGE("[FiberElement] InsertNode index is out of bounds, index:"
         << index << ",size:" << scoped_children_.size());
    return;
  }
  auto *ref = scoped_children_[index].Get();
  InsertNodeBeforeInternal(child, ref);
}

void FiberElement::InsertNodeBeforeInternal(
    const base::scoped_refptr<FiberElement> &child, FiberElement *ref_node) {
  int index = -1;
  if (ref_node) {
    index = IndexOf(ref_node);
    if (index >= static_cast<int>(scoped_children_.size()) || index < 0) {
      LOGE("[Fiber] can not find the ref node:" << ref_node);
      return;
    }
  }
  // FIXME(linxs): use linked element to reduce the Element index calculation
  AddChildAt(child, index);

  // the insert Action should be inserted to Child, should make sure the child
  // has been flushed
  action_list_.emplace_back(Action::kInsertChildAct);
  action_param_list_.emplace_back(Action::kInsertChildAct, this, child, index,
                                  ref_node);

  MarkDirty(kDirtyTree);
  child->MarkDirty(kDirtyTree);  // why need this?
}

void FiberElement::InsertNodeBefore(
    const base::scoped_refptr<FiberElement> &child,
    const base::scoped_refptr<FiberElement> &reference_child) {
  InsertNodeBeforeInternal(child, reference_child.Get());
}

void FiberElement::RemoveNode(const base::scoped_refptr<FiberElement> &child) {
  // FIXME(linxs): to use linked node to avoid the index calculation asap!
  int index = IndexOf(child.Get());
  if (index >= static_cast<int>(scoped_children_.size()) || index < 0) {
    LOGE("FiberElement RemoveNode got wrong child index!!");
    return;
  }

  // the Remove Action should be inserted to Parent, due to child has been
  // removed from element tree here
  action_list_.emplace_back(Action::kRemoveChildAct);
  action_param_list_.emplace_back(Action::kRemoveChildAct, this, child, index,
                                  nullptr);

  // take care: NotifyNodeRemoved after removeAction inserted!
  OnNodeRemoved(child.Get());
  NotifyNodeRemoved(this, child.Get());

  FiberElement *removed = scoped_children_[index].Get();
  scoped_children_.erase(scoped_children_.begin() + index);
  removed->set_parent(nullptr);

  MarkDirty(kDirtyTree);
}

void FiberElement::NotifyNodeInserted(FiberElement *insertion_point,
                                      FiberElement *node) {
  node->InsertedInto(insertion_point);

  for (const auto &child : node->scoped_children_) {
    if (child->is_raw_text()) {
      continue;
    }
    NotifyNodeInserted(insertion_point, child.Get());
  }
}

void FiberElement::NotifyNodeRemoved(FiberElement *insertion_point,
                                     FiberElement *node) {
  node->RemovedFrom(insertion_point);

  for (const auto &child : node->scoped_children_) {
    if (child->is_raw_text()) {
      continue;
    }
    child->NotifyNodeRemoved(insertion_point, child.Get());
  }
}

void FiberElement::RemovedFrom(FiberElement *insertion_point) {
  // We need to handle the intergenerational node which has zIndex or fixed,
  // they may be inserted to difference parent in UI/layout tree instead of dom
  // parent If the removed node's parent is the insertion_point, no need to do
  // any special action
  if ((parent() != insertion_point) && (ZIndex() != 0 || is_fixed_)) {
    insertion_point->action_param_list_.emplace_back(
        Action::kRemoveIntergenerationAct, insertion_point, this, 0, nullptr);
    MarkDirty(kDirtyReAttachContainer);
  }
}

void FiberElement::DestroyPlatformNode() {
  if (element_container() && has_painting_node_) {
    element_container()->Destroy();
  }
  if (has_platform_layout_node_) {
    // FIXME(linxs): any other case has platform layout nodes??
    element_manager()->DestroyLayoutNode(layout_node_);
  }
  has_painting_node_ = false;
  has_platform_layout_node_ = false;
  // FIXME(linxs): take care, currently Destoy() for platform ui and layout node
  // will destroy children recursively!!
  MarkPlatformNodeDestroyedRecursively();
}

void FiberElement::SetClass(const lepus::String &clazz) {
  data_model_->SetClass(clazz);
  css_related_changed_ = true;
  MarkDirty(kDirtyStyle);
}

void FiberElement::RemoveAllClass() {
  data_model_->RemoveAllClass();
  css_related_changed_ = true;
  MarkDirty(kDirtyStyle);
}

void FiberElement::SetStyle(CSSPropertyID id, const lepus::Value &value) {
  current_raw_inline_styles_.insert({id, value});
  MarkDirty(kDirtyStyle);

  // Only exec the following expr when ENABLE_INSPECTOR, such that devtool can
  // get element's inline style.
  EXEC_EXPR_FOR_INSPECTOR({
    if (lynx::base::LynxEnv::GetInstance().IsDomTreeEnabled()) {
      data_model()->SetInlineStyle(id, value.String(),
                                   element_manager_->GetCSSParserConfigs());
    }
  });
}

void FiberElement::RemoveAllInlineStyles() {
  // Only exec the following expr when ENABLE_INSPECTOR, such that devtool can
  // get element's inline style.
  EXEC_EXPR_FOR_INSPECTOR({
    if (lynx::base::LynxEnv::GetInstance().IsDomTreeEnabled()) {
      for (const auto &pair : updated_inline_parsed_styles_) {
        const static lepus::String kNull = lepus::String("");
        data_model()->SetInlineStyle(pair.first, kNull,
                                     element_manager_->GetCSSParserConfigs());
      }
    }
  });

  updated_inline_parsed_styles_.clear();
  current_raw_inline_styles_.clear();
  MarkDirty(kDirtyStyle);
}

void FiberElement::SetAttribute(const lepus::String &key,
                                const lepus::Value &value) {
  // if value IsEmpty, means the attribute is reset to delete

  // TODO(WUJINTIAN): Use ID checking and replace string matching here to
  // improve efficiency.
  CheckNewAnimatorAttr(key, value);

  if (!value.IsEmpty()) {
    updated_attr_map_[key] = value;
    data_model_->SetStaticAttribute(key, value);
  } else {
    reset_attr_vec_.emplace_back(key);
    data_model_->RemoveAttribute(key);
  }
  MarkDirty(kDirtyAttr);

  // Only exec the following expr when ENABLE_INSPECTOR, such that devtool can
  // get element's attribute.
  EXEC_EXPR_FOR_INSPECTOR({
    if (lynx::base::LynxEnv::GetInstance().IsDomTreeEnabled()) {
      data_model()->SetDynamicAttribute(key, value);
    }
  });
}

void FiberElement::SetIdSelector(const lepus::String &idSelector) {
  updated_attr_map_[lepus::String(AttributeHolder::kIdSelectorAttrName)] =
      lepus::Value(idSelector.impl());
  const auto &old_id = data_model_->idSelector().str();
  data_model_->SetIdSelector(idSelector);
  if (CheckHasInvalidationForId(old_id, idSelector.str()) ||
      CheckHasIdMapInCSSFragment()) {
    MarkDirty(kDirtyAttr | kDirtyStyle);
    css_related_changed_ = true;
  } else {
    MarkDirty(kDirtyAttr);
  }

  // Only exec the following expr when ENABLE_INSPECTOR, such that devtool can
  // get element's id selector.
  EXEC_EXPR_FOR_INSPECTOR({
    if (lynx::base::LynxEnv::GetInstance().IsDomTreeEnabled()) {
      data_model()->SetDynamicAttribute(
          lepus::String(AttributeHolder::kIdSelectorAttrName),
          lepus::Value(idSelector.impl()));
    }
  });
}

bool FiberElement::CheckHasIdMapInCSSFragment() {
  auto *css_fragment = GetRelatedCSSFragment();
  // resolve styles from css fragment
  if (css_fragment && css_fragment->HasIdSelector()) {
    return true;
  }

  return false;
}

static bool DiffStyleImpl(StyleMap &old_map, StyleMap &new_map,
                          StyleMap &update_styles) {
  if (new_map.empty()) {
    return false;
  }
  // When the first screen is rendered, old_map must be empty, so there is no
  // need to perform the following for loop.
  if (old_map.empty()) {
    update_styles = new_map;
    return true;
  }
  update_styles.reserve(old_map.size() + new_map.size());
  bool need_update = false;
  // iterate all styles in new_map
  for (const auto &[key, value] : new_map) {
    // try to find the corresponding style in old_map
    auto it_old_map = old_map.find(key);
    // if r does not exist in lhs, r is a new style to add
    // if r exist in lhs but with different value, update it
    if (it_old_map == old_map.end() || value != it_old_map->second) {
      need_update = true;
      update_styles.insert_or_assign(key, value);
    }
    // erase old property which is already in new_map, then the remaining
    // properties in old_map need to be removed
    if (it_old_map != old_map.end()) {
      old_map.erase(it_old_map);
    }
  }
  return need_update;
}

void FiberElement::PrepareForCreateOrUpdate(ActionOption &option) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::PrepareForCreateOrUpdate");
  bool need_update = false;
  StyleMap parsed_styles;
  std::vector<CSSPropertyID> reset_style_ids;
  if (dirty_ & kDirtyStyle) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleStyle");

    RefreshStyle(parsed_styles, reset_style_ids);

    dirty_ &= ~kDirtyStyle;
  }

  // process inherit related
  // quick check if any id in reset_style_ids is in parent inherited styles
  if (IsCSSInheritanceEnabled()) {
    for (auto it = reset_style_ids.begin(); it != reset_style_ids.end();) {
      // do not reset style if it's parent inherited_styles contains it
      const auto &parent_inherited_styles = *(option.inherited_styles_);
      if (parent_inherited_styles.find(*it) != parent_inherited_styles.end()) {
        // we need to mark flag to do self recalculation for inherited styles,
        // if the style is updated instead of reset
        MarkNeedPropagateInheritedProperties();
        it = reset_style_ids.erase(it);
      } else {
        ++it;
      }
    }
  }

  if (dirty_ & kDirtyPropagateInherited) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandlePropagateInherited");
    // comes here means parent propagates this change
    // there are two status:
    // 1. parent inherited style deleted; 2.parent inherited style changed;
    // #1 parent inherited style deleted
    if (option.reset_inherited_ids_) {
      for (const auto reset_id : *(option.reset_inherited_ids_)) {
        auto it = parsed_styles_map_.find(reset_id);
        if (it == parsed_styles_map_.end()) {
          if (std::find(reset_style_ids.begin(), reset_style_ids.end(),
                        reset_id) == reset_style_ids.end()) {
            reset_style_ids.push_back(reset_id);
          }
        }
      }
    }

    // #2.parent inherited style changed
    //  merge the inherited styles, but they have lower priority
    if (option.inherited_styles_) {
      updated_inherited_styles_.clear();
      for (auto &pair : *(option.inherited_styles_)) {
        auto it = parsed_styles_map_.find(pair.first);
        if (it == parsed_styles_map_.end()) {
          updated_inherited_styles_[pair.first] = pair.second;
          parsed_styles[pair.first] = pair.second;
          need_update = true;
        }
      }
    }
    dirty_ &= ~kDirtyPropagateInherited;
  }

  // process reset before update styles

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
  bool should_consume_trans_styles_in_advance =
      ShouldConsumeTransitionStylesInAdvance();
  // #1. Check whether we need to reset transition styles in advance.
  if (should_consume_trans_styles_in_advance) {
    ResetTransitionStylesInAdvance(reset_style_ids);
  }
  for (const auto &id : reset_style_ids) {
    // #2. If these transition styles have been reset beforehand, skip them
    // here.
    if (should_consume_trans_styles_in_advance &&
        CSSProperty::IsTransitionProps(id)) {
      continue;
    }
    // #3. Review each property to determine whether the reset should be
    // intercepted.
    if (css_transition_manager_ &&
        css_transition_manager_->ConsumeCSSProperty(id, CSSValue::Empty())) {
      continue;
    }
    ResetStyleInternal(id);
    need_update = true;
  }

  // process direction：rtl/lynx-rtl firstly
  // FIXME(linxs): maybe can put setFontSize here ?
  if (IsDirectionChangedEnabled()) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleDirectionChanged");
    // case 1: direction changed, trigger to re calculate all direction related
    // styles case 2: only direction related style updated, just do rtl for this
    // style
    auto it = parsed_styles.find(CSSPropertyID::kPropertyIDDirection);
    if (it != parsed_styles.end()) {
      auto new_direction =
          static_cast<starlight::DirectionType>(it->second.GetValue().Number());
      if (new_direction != direction_) {
        direction_changed_ = true;
        // reset all direction related styles firstly before do full direction
        // change
        for (const auto &direction_pair : current_direction_related_styles_) {
          auto [tran_css_id, css_value, is_logic] = direction_pair.second;
          ResetCSSValue(tran_css_id);
          pending_updated_direction_related_styles_[direction_pair.first] = {
              css_value, is_logic};
        }
        current_direction_related_styles_.clear();
        DynamicCSSStylesManager::UpdateDirectionAwareDefaultStyles(
            this, new_direction);
        direction_ = new_direction;
        SetStyleInternal(kPropertyIDDirection, it->second);
      }
    }
  }

  // set updated Styles to element in the end
  if (!parsed_styles.empty()) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleSetStyle");
    // if kDirtyPropagateInherited, need to delay to SetStyle in inherit process
    SetStyle(parsed_styles);
    need_update = true;
  }

  // direction change: we always handle direction change after all styles
  // resolved
  if (!pending_updated_direction_related_styles_.empty()) {
    for (const auto &style_pair : pending_updated_direction_related_styles_) {
      TryDoDirectionRelatedCSSChange(style_pair.first, style_pair.second.first,
                                     style_pair.second.second);
    }
    pending_updated_direction_related_styles_.clear();
  }

  // keyframe props
  if (has_keyframe_props_) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleKeyFrameProps");
    if (!enable_new_animator()) {
      ResolveAndFlushKeyframes();
      PushToBundle(kPropertyIDAnimation);
    } else {
      SetDataToNativeKeyframeAnimator();
    }
    has_keyframe_props_ = false;
    need_update = true;
  }

  if (has_transition_props_) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleTransitionProps");
    if (!enable_new_animator()) {
      PushToBundle(kPropertyIDTransition);
    } else {
      SetDataToNativeTransitionAnimator();
    }
    has_transition_props_ = false;
    need_update = true;
  }

  // attributes
  if (dirty_ & kDirtyAttr) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleAttr");
    for (const auto &attr : updated_attr_map_) {
      SetAttributeInternal(attr.first, attr.second);
      need_update = true;
    }
    for (const auto &attr : reset_attr_vec_) {
      ResetAttribute(attr);
      need_update = true;
    }
    updated_attr_map_.clear();
    reset_attr_vec_.clear();
    dirty_ &= ~kDirtyAttr;
  }

  // If above props and styles need to be updated, this patch needs trigger
  // layout.
  if (need_update || dirty_ & kDirtyCreated || dirty_ & kDirtyForceUpdate) {
    option.need_layout_ = true;
  }

  // events
  if (dirty_ & kDirtyEvent) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleEvents");
    // OPTME(linxs): pass event diff result later?
    element_manager_->ResolveEvents(data_model_.get(), this);
    dirty_ &= ~kDirtyEvent;
  }

  // actions
  if (dirty_ & kDirtyCreated) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleCreate");
    // FIXME(linxs): FlushProps can be optimized, for example can we just
    // create viewElement,imageElement,textElement.. directly?
    FlushProps();
    dirty_ &= ~kDirtyCreated;
  } else if ((need_update || dirty_ & kDirtyForceUpdate) && prop_bundle_) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleUpdate");
    element_manager()->UpdateLayoutNodeProps(layout_node_, prop_bundle_);
    if (!is_virtual()) {
      UpdateFiberElement();
    }
  }

  dirty_ &= ~kDirtyForceUpdate;
  ResetPropBundle();
}

bool FiberElement::FlushActionsAsRoot() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::FlushActionsAsRoot");
  if (parent() == nullptr) {
    LOGE("FiberElement::FlushActionsAsRoot failed since parent is nullptr");
    return false;
  }
  ActionOption options;
  FiberElement *fiber_parent = static_cast<FiberElement *>(parent());
  if (fiber_parent->is_wrapper()) {
    fiber_parent = WrapperElement::FindTheRealParent(fiber_parent);
  }
  fiber_parent->UpdateCurrentFlushOption(options);
  if (render_parent_ == nullptr) {
    fiber_parent->GenerateChildrenActions(options);
  }
  FlushActions(options);
  return options.need_layout_;
}

// need parent's option
void FiberElement::FlushActions(ActionOption &option) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::FlushActions");
  if (!flush_required_) {
    return;
  }
  flush_required_ = false;
  ScopedOption scoped_update_option(option);
  if (dirty_ > 0) {
    // create or update Platform Op
    PrepareForCreateOrUpdate(option);

    // update current flush option after resolving styles
    UpdateCurrentFlushOption(scoped_update_option.GetOption());

    // handle fixed style changed if needed
    if (fixed_changed_) {
      HandleSelfFixedChange();
      fixed_changed_ = false;
    }

    // process insert or remove related actions
    GenerateChildrenActions(option);

    dirty_ = 0;
  } else {
    // update current flush option before traversal children
    UpdateCurrentFlushOption(scoped_update_option.GetOption());
  }

  for (auto *invalidation_set : invalidation_lists_.descendants) {
    if (invalidation_set->InvalidatesSelf()) {
      continue;
    }

    VisitChildren([invalidation_set](FiberElement *child) {
      if (!child->StyleDirty() && !child->is_raw_text() &&
          invalidation_set->InvalidatesElement(*child->data_model())) {
        child->MarkStyleDirty(false);
      }
    });
  }
  invalidation_lists_.descendants.clear();

  // recursively call FlushActions
  for (const auto &child : scoped_children_) {
    if (option.children_propagate_inherited_styles_flag_) {
      child->MarkNeedPropagateInheritedProperties();
    }

    child->FlushActions(option);
  }
  // below flags should be delayed until children flushed
  children_propagate_inherited_styles_flag_ = false;
  reset_inherited_ids_.clear();
}

void FiberElement::GenerateChildrenActions(ActionOption &options) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::GenerateChildrenActions");
  // process insert or remove related actions
  if (dirty_ & kDirtyTree) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleChildrenAction");
    for (const auto &param : action_param_list_) {
      switch (param.type_) {
        case Action::kInsertChildAct: {
          PrepareChildForInsertion(param.child_.Get(), options);
          if (!param.child_->is_fixed_) {
            HandleInsertChildAction(param.child_.Get(),
                                    static_cast<int>(param.index_),
                                    param.ref_node_);
          } else {
            InsertFixedElement(param.child_.Get(), param.ref_node_);
          }
        } break;

        case Action::kRemoveChildAct: {
          if (!param.child_->is_fixed_) {
            HandleRemoveChildAction(param.child_.Get());
          } else {
            RemoveFixedElement(param.child_.Get());
          }
        } break;

        case Action::kRemoveIntergenerationAct: {
          if (param.child_->parent_ == this) {
            break;
          }
          if (param.child_->is_fixed_) {
            RemoveFixedElement(param.child_.Get());
          } else if (param.child_->ZIndex() != 0) {
            param.child_->element_container()->RemoveSelf(false);
          }

        } break;

        default:
          break;
      }
    }
    dirty_ &= ~kDirtyTree;
    options.need_layout_ = true;
  }

  action_list_.clear();
  action_param_list_.clear();

  if (dirty_ & kDirtyReAttachContainer) {
    if (is_fixed_) {
      InsertFixedElement(this, nullptr);
    } else if (ZIndex() != 0) {
      HandleContainerInsertion(render_parent_, this, next_render_sibling_);
    }
    dirty_ &= ~kDirtyReAttachContainer;
  }
}

// static
void FiberElement::PrepareChildForInsertion(FiberElement *child,
                                            ActionOption &option) {
  if (child->dirty_ & kDirtyCreated) {
    // make sure the child has been created,before insert op
    if (option.children_propagate_inherited_styles_flag_) {
      child->MarkNeedPropagateInheritedProperties();
    }
    child->PrepareForCreateOrUpdate(option);
  }
  if (child->is_layout_only_) {
    ScopedOption scoped_option(option);
    child->UpdateCurrentFlushOption(scoped_option.GetOption());
    for (const auto &grand : child->scoped_children_) {
      PrepareChildForInsertion(grand.Get(), scoped_option.GetOption());
    }
  }
}

void FiberElement::HandleInsertChildAction(FiberElement *child, int to_index,
                                           FiberElement *ref_node) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleInsertChildAction");
  StoreLayoutNode(child, ref_node);

  auto *parent = this;

  if (child->is_wrapper()) {
    // try to mark for wrapper element related.
    FindEnclosingNoneWrapper(parent, child);
  }

  if (UNLIKELY(parent->is_wrapper() || (parent->wrapper_element_count_ > 0) ||
               child->is_wrapper())) {
    WrapperElement::AttachChildToTargetParentForWrapper(parent, child,
                                                        ref_node);
  } else {
    parent->InsertLayoutNode(child, ref_node);
  }

  HandleContainerInsertion(parent, child, ref_node);
}

void FiberElement::HandleRemoveChildAction(FiberElement *child) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleRemoveChildAction");
  auto *parent = this;

  RestoreLayoutNode(child);
  if (!child->is_wrapper() && !child->attached_to_layout_parent_) {
    // parent is detached, child is removed from parent, and then the parent is
    // inserted to view tree,but the action is still stored in its parent

    // 1.if the child is not wrapper and not attached to layout tree, just
    // return
    // 2. if the child is wrapper, remove the wrapper's children recursively in
    // RemoveFromParentForWrapperChild
    // 3. if the parent is wrapper, just handle in
    // RemoveFromParentForWrapperChild
    return;
  }

  if (UNLIKELY(parent->is_wrapper() || parent->wrapper_element_count_ > 0) ||
      child->is_wrapper()) {
    if (child->enclosing_none_wrapper_) {
      child->enclosing_none_wrapper_->wrapper_element_count_--;
    }
    WrapperElement::RemoveFromParentForWrapperChild(parent, child);
  } else {
    this->RemoveLayoutNode(child);
  }

  child->element_container()->RemoveSelf(false);
}

void FiberElement::HandleContainerInsertion(FiberElement *parent,
                                            FiberElement *child,
                                            FiberElement *ref_node) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::HandleContainerInsertion");
  // for element container tree
  // a quick check for determine if need to append the container to the
  // end(check ref is null) ref is null, find the first none-wrapper ancestor's
  // next sibling as ref! ref_node: null means to append to the real parent!!
  // FIXME(linxs): for wrapper, we can merge the below logic
  auto *temp_parent = parent;
  while (!ref_node && temp_parent && temp_parent->is_layout_only_) {
    ref_node = temp_parent->next_render_sibling_;
    temp_parent = temp_parent->render_parent_;
  }

  if (!child->element_container()->parent() && !child->is_virtual_) {
    // the child has been inserted to parent in
    // AttachChildToTargetContainerRecursive, just ignore it
    parent->element_container()->AttachChildToTargetContainer(child, ref_node);
  }
}

FiberElement *FiberElement::FindEnclosingNoneWrapper(FiberElement *parent,
                                                     FiberElement *node) {
  while (parent) {
    if (!parent->is_wrapper()) {
      node->enclosing_none_wrapper_ = parent;
      parent->wrapper_element_count_++;
      break;
    }
    parent = static_cast<FiberElement *>(parent->parent_);
  }
  return parent;
}

void FiberElement::MarkPlatformNodeDestroyedRecursively() {
  // All descent UI will be deleted recursively in platform side, should mark it
  // recursively
  for (size_t i = 0; i < GetChildCount(); ++i) {
    auto *child = static_cast<FiberElement *>(GetChildAt(i));
    child->MarkPlatformNodeDestroyedRecursively();
    // The z-index child's parent may be different from ui parent
    // and not destroyed
    if (child->HasElementContainer() && child->ZIndex() != 0 &&
        child->has_painting_node_) {
      child->element_container()->Destroy();
    }
    if (child->parent_ == this) {
      child->parent_ = nullptr;
      child->has_painting_node_ = false;
      child->has_platform_layout_node_ = false;
    }
  }
  // clear element's children only in radon or radon compatible mode.
  scoped_children_.clear();
}

bool FiberElement::InComponent() const {
  auto p = static_cast<FiberElement *>(GetParentComponentElement());
  if (p) {
    return !(p->is_page());
  }
  return false;
}

std::string FiberElement::ParentComponentIdString() const {
  auto *p = static_cast<FiberElement *>(GetParentComponentElement());
  if (p) {
    return static_cast<ComponentElement *>(p)->component_id().str();
  }
  return "";
}

void FiberElement::AddChildAt(base::scoped_refptr<FiberElement> child,
                              int index) {
  if (index == -1) {
    scoped_children_.push_back(child);
  } else {
    scoped_children_.insert(scoped_children_.begin() + index, child);
  }
  // new inserted child should be marked to do inheritance from parent
  child->MarkNeedPropagateInheritedProperties();
  OnNodeAdded(child.Get());
  NotifyNodeInserted(this, child.Get());
  child->set_parent(this);
}

int FiberElement::IndexOf(const FiberElement *child) const {
  for (auto it = scoped_children_.begin(); it != scoped_children_.end(); ++it) {
    if (it->Get() == child) {
      return static_cast<int>(std::distance(scoped_children_.begin(), it));
    }
  }
  return -1;
}

Element *FiberElement::GetChildAt(size_t index) {
  if (index >= scoped_children_.size()) {
    return nullptr;
  }
  return scoped_children_[index].Get();
}

std::vector<Element *> FiberElement::GetChild() {
  std::vector<Element *> ret;
  for (const auto &child : scoped_children_) {
    ret.push_back(child.Get());
  }
  return ret;
}

// If new animator is enabled and this element has been created before, we
// should consume transition styles in advance. Also transition manager needs to
// verify every property to determine whether to intercept this update.
// Therefore, the operations related to Transition in the SetStyle process are
// divided into three steps:
// 1. Check whether to consume all transition styles in advance if needed.
// 2. Skip all transition styles in the later process if they have been consume
// in advance.
// 3. Check every property to determine whether to intercept this update.
void FiberElement::SetStyle(const StyleMap &styles) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, ELEMENT_SET_STYLE);
  if (styles.empty()) {
    return;
  }
  // set font-size first.Other css may use this to calc rem or em.
  auto it = styles.find(CSSPropertyID::kPropertyIDFontSize);
  if (it != styles.end()) {
    SetFontSize(&(it->second));
  }

  bool should_consume_trans_styles_in_advance =
      ShouldConsumeTransitionStylesInAdvance();
  // #1. Consume all transition styles in advance.
  if (should_consume_trans_styles_in_advance) {
    ConsumeTransitionStylesInAdvance(styles);
  }

  for (const auto &style : styles) {
    if (!is_raw_text() && IsInheritable(style.first)) {
      // save the css value to inherited styles map
      inherited_styles_[style.first] = style.second;
      children_propagate_inherited_styles_flag_ = true;
    }

    if (style.first == CSSPropertyID::kPropertyIDDirection) {
      // direction has been resolved before
      continue;
    }

    //  we delay to handle direction related styles later, just save such kind
    //  of styles;
    // a special case is Logic Direction style, which can not be set, we need to
    // process it here
    if (LIKELY(!TryResolveLogicStyleAndSaveDirectionRelatedStyle(
            style.first, style.second))) {
      // #2. Skip all transition styles in the later process if they have been
      // consume in advance.
      if (should_consume_trans_styles_in_advance &&
          CSSProperty::IsTransitionProps(style.first)) {
        continue;
      }
      // #3. Check every property to determine whether to intercept this update.
      if (css_transition_manager_ &&
          css_transition_manager_->ConsumeCSSProperty(style.first,
                                                      style.second)) {
        continue;
      }
      SetStyleInternal(style.first, style.second);
    }
  }
}

void FiberElement::ResetStyleInternal(CSSPropertyID css_id) {
  // Since the previous element styles cannot be accessed in element, we
  // need to record some necessary styles which New Animator transition needs.
  // TODO(wujintian): We only need to record layout-only properties, while other
  // properties can be accessed through ComputedCSSStyle.
  ResetElementPreviousStyle(css_id);

  // do something for inherit, direction,etc.
  WillResetCSSValue(css_id);

  // reset style value to layout node and painting node
  ResetCSSValue(css_id);
}

void FiberElement::SetAttributeInternal(const lepus::String &key,
                                        const lepus::Value &value) {
#if OS_ANDROID
  // FIXME(linxs): only Android need to check flatten, it's better to move to
  // Android platform size?
  CheckFlattenProp(key, value);
#endif
  PreparePropBundleIfNeed();

  // Any attribute will cause has_layout_only_props_ = false
  has_layout_only_props_ = false;

  // record attributes, used for worklet
  attributes_.Table()->SetValue(key, value);

  prop_bundle_->SetProps(key.c_str(), value);

  // If the current node is a list child node, it is necessary to convert
  // kFullSpan's value to ListComponentInfo::Type and synchronize it to
  // LayoutNode.
  constexpr const static char kFullSpan[] = "full-span";
  if (parent() != nullptr && static_cast<FiberElement *>(parent())->is_list() &&
      key.IsEquals(kFullSpan)) {
    ListComponentInfo::Type type = ListComponentInfo::Type::DEFAULT;
    if (value.IsBool() && value.Bool()) {
      type = ListComponentInfo::Type::LIST_ROW;
    }
    element_manager()->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kListCompType,
        lepus::Value(static_cast<int32_t>(type)));
  }

#if 0  // TODO(linxs): to process it in CLI compile period
    StyleMap attr_styles;
    if (key.IsEquals("scroll-x") && value.String()->IsEqual("true")) {
      attr_styles.insert_or_assign(
          kPropertyIDLinearOrientation,
          CSSValue::MakeEnum((int) starlight::LinearOrientationType::kHorizontal));
      element_manager()->UpdateLayoutNodeAttribute(
          layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
    } else if (key.IsEquals("scroll-y") && value.String()->IsEqual("true")) {
      attr_styles.insert_or_assign(
          kPropertyIDLinearOrientation,
          CSSValue::MakeEnum((int) starlight::LinearOrientationType::kVertical));
      element_manager()->UpdateLayoutNodeAttribute(
          layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
    } else if (key.IsEquals("scroll-x-reverse") &&
               value.String()->IsEqual("true")) {
      attr_styles.insert_or_assign(
          kPropertyIDLinearOrientation,
          CSSValue::MakeEnum(
              (int) starlight::LinearOrientationType::kHorizontalReverse));
      element_manager()->UpdateLayoutNodeAttribute(
          layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
    } else if (key.IsEquals("scroll-y-reverse") &&
               value.String()->IsEqual("true")) {
      attr_styles.insert_or_assign(
          kPropertyIDLinearOrientation,
          CSSValue::MakeEnum(
              (int) starlight::LinearOrientationType::kVerticalReverse));
      element_manager()->UpdateLayoutNodeAttribute(
          layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
    } else if (key.IsEqual("column-count")) {
      element_manager()->UpdateLayoutNodeAttribute(
          layout_node_, starlight::LayoutAttribute::kColumnCount, value);
    } else if (key.IsEqual(ListComponentInfo::kListCompType)) {
      element_manager()->UpdateLayoutNodeAttribute(
          layout_node_, starlight::LayoutAttribute::kListCompType, value);
    }
    SetStyle(attr_styles);
#endif
}

void FiberElement::ResetAttribute(const lepus::String &key) {
  has_layout_only_props_ = false;

  // record attributes, used for worklet
  attributes_.Table()->Erase(key);
  ResetProp(key.c_str());
}

void FiberElement::AddDataset(const lepus::String &key,
                              const lepus::Value &value) {
  data_model_->SetDataSet(key, value);
}

void FiberElement::SetDataset(const lepus::Value &data_set) {
  data_model_->SetDataSet(data_set);
}

void FiberElement::SetJSEventHandler(const lepus::String &name,
                                     const lepus::String &type,
                                     const lepus::String &callback) {
  data_model_->SetStaticEvent(type, name, callback);
  MarkDirty(kDirtyEvent);
}

void FiberElement::SetLepusEventHandler(const lepus::String &name,
                                        const lepus::String &type,
                                        const lepus::Value &script,
                                        const lepus::Value &callback) {
  data_model_->SetLepusEvent(type, name, script, callback);
  MarkDirty(kDirtyEvent);
}

void FiberElement::SetNativeProps(const lepus::Value &native_props) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, ELEMENT_SET_NATIVE_PROPS);
  if (!native_props.IsTable()) {
    LOGE("SetNativeProps's param must be a Table!");
    return;
  }

  if (native_props.Table()->size() == 0) {
    LOGE("SetNativeProps's param must not be empty!");
    return;
  }

  ForEachLepusValue(native_props, [self = this](const lepus::Value &key,
                                                const lepus::Value &value) {
    auto id = CSSProperty::GetPropertyID(key.String());
    if (id != kPropertyEnd) {
      self->SetStyle(id, value);
    } else {
      self->SetAttribute(key.String(), value);
    }
  });

  PipelineOptions option;
  element_manager()->OnPatchFinishForFiber(option, this);
}

void FiberElement::RemoveEvent(const lepus::String &name,
                               const lepus::String &type) {
  data_model_->RemoveEvent(name, type);
  MarkDirty(kDirtyEvent);
}

void FiberElement::RemoveAllEvents() {
  data_model_->RemoveAllEvents();
  MarkDirty(kDirtyEvent);
}

void FiberElement::SetParsedStyle(const StyleMap &map,
                                  const lepus::Value &config) {
  constexpr const static char *kOnlySelector = "selectorParsedStyles";
  const auto &only_selector_prop = config.GetProperty(kOnlySelector);
  if (only_selector_prop.IsBool()) {
    only_selector_extreme_parsed_styles_ = only_selector_prop.Bool();
  }

  has_extreme_parsed_styles_ = true;
  extreme_parsed_styles_ = map;
  MarkDirty(kDirtyStyle);
}

void FiberElement::AddConfig(const lepus::String &key,
                             const lepus::Value &value) {
  config_.SetProperty(key, value);
}

void FiberElement::SetConfig(const lepus::Value &config) {
  if (!config.IsObject()) {
    LOGW("FiberElement SetConfig failed since the config is not object");
    return;
  }
  config_ = config;
}

void FiberElement::MarkStyleDirty(bool recursive) {
  MarkDirty(kDirtyStyle);
  css_related_changed_ = true;
  if (recursive) {
    for (const auto &child : scoped_children_) {
      child->MarkStyleDirty(recursive);
    }
  }
}

void FiberElement::FlushProps() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, ELEMENT_FLUSH_PROPS);

  if (is_scroll_view() || is_list()) {
    element_manager()->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
  }

  // Update The root if needed
  if (!has_painting_node_) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "Catalyzer::FlushProps::NoPaintingNode");
    PreparePropBundleIfNeed();

    // check is in inlineContainer before attachLayoutNode
    CheckHasInlineContainer(!is_fixed_ ? parent_ : element_manager_->root());

    // no need attach Layout node for wrapper
    element_manager()->AttachLayoutNode(layout_node_, prop_bundle_.get());

    // FIXME(linxs): any other case has platform layout nodes??
    has_platform_layout_node_ =
        layout_node_->is_custom() || layout_node_->IsParentInlineContainer();
    bool platform_is_flatten = true;
#if ENABLE_RENDERKIT
    is_virtual_ = false;
    platform_is_flatten = !(has_z_props_ || is_fixed_);
#else
    is_virtual_ = element_manager_->IsShadowNodeVirtual(tag_);
    platform_is_flatten = TendToFlatten();
#endif
    bool is_layout_only = CanBeLayoutOnly() || is_virtual_;
    is_layout_only_ = is_layout_only;
    // native layer don't flatten.
    CreateElementContainer(platform_is_flatten);

    has_painting_node_ = true;
  }
  has_keyframe_props_ = false;
  has_transition_props_ = false;
}

// if child's related css variable is updated, invalidate child's style.
void FiberElement::RecursivelyMarkChildrenCSSVariableDirty(
    const lepus::Value &css_variable_updated) {
  for (const auto &child : scoped_children_) {
    lepus::Value css_variable_updated_merged =
        lepus::Value::Clone(css_variable_updated);
    // first, merge changing_css_variables with element's css_variable,
    // element's css_variable is with high priority.
    child->data_model()->MergeWithCSSVariables(css_variable_updated_merged);
    if (IsRelatedCSSVariableUpdated(child->data_model(),
                                    css_variable_updated_merged)) {
      child->MarkStyleDirty(false);
    }
    child->RecursivelyMarkChildrenCSSVariableDirty(css_variable_updated_merged);
  }
}

void FiberElement::UpdateFiberElement() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::UpdateFiberElement");
  if (!is_layout_only_) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::UpdatePaintingNode");
    painting_context()->UpdatePaintingNode(id_, TendToFlatten(),
                                           prop_bundle_.get());
  } else if (!CanBeLayoutOnly()) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::TransitionToNativeView");
    // Is layout only and can not be layout only
    element_container()->TransitionToNativeView();
  }
  element_container()->StyleChanged();
}

bool FiberElement::IsRelatedCSSVariableUpdated(
    AttributeHolder *holder, const lepus::Value changing_css_variables) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::IsRelatedCSSVariableUpdated");

  bool changed = false;
  ForEachLepusValue(
      changing_css_variables,
      [holder, &changed](const lepus::Value &key, const lepus::Value &value) {
        if (!changed) {
          auto it = holder->css_variable_related().find(key.String());
          if (it != holder->css_variable_related().end() &&
              !it->second.IsEqual(value.String())) {
            changed = true;
          }
        }
      });
  return changed;
}

void FiberElement::UpdateCSSVariable(const lepus::Value &css_variable_updated) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::UpdateCSSVariable");
  ForEachLepusValue(
      css_variable_updated,
      [self = this](const lepus::Value &key, const lepus::Value &value) {
        self->data_model()->UpdateCSSVariableFromSetProperty(key.String(),
                                                             value.String());
      });

  if (IsRelatedCSSVariableUpdated(data_model(), css_variable_updated)) {
    // invalidate self.
    MarkStyleDirty(false);
  }
  RecursivelyMarkChildrenCSSVariableDirty(css_variable_updated);
  PipelineOptions option;
  element_manager()->OnPatchFinishForFiber(option, this);
}

void FiberElement::ResolveStyleValue(CSSPropertyID id,
                                     const tasm::CSSValue &value,
                                     bool force_update) {
  if (computed_css_style()->SetValue(id, value)) {
    // The properties of transition and keyframe no need to be pushed to bundle
    // separately here. Those properties will be pushed to bundle together
    // later.
    if (!(CheckTransitionProps(id) || CheckKeyframeProps(id))) {
      PushToBundle(id);
    }
  }
}

bool FiberElement::DisableFlattenWithOpacity() {
  return has_opacity_ && !is_text() && !is_image();
}

bool FiberElement::TendToFlatten() {
  return config_flatten_ && !has_event_listener_ && !has_animate_props_ &&
         !has_non_flatten_attrs_ && !has_user_interaction_enabled_ &&
         !DisableFlattenWithOpacity() && !has_z_props_;
}

void FiberElement::SetFontSize(const tasm::CSSValue *value) {
  // TODO(linxs): dynamic style
  //    styles_manager_.UpdateFontSizeStyle(value);
  auto result = starlight::CSSStyleUtils::ResolveFontSize(
      *value, element_manager()->GetLynxEnvConfig(),
      element_manager()->GetLynxEnvConfig().ViewportWidth(),
      element_manager()->GetLynxEnvConfig().ViewportHeight(), font_size_,
      root_font_size_, element_manager()->GetCSSParserConfigs());
  if (result.has_value() && *result != font_size_) {
    font_size_ = *result;
    computed_css_style()->SetFontSize(font_size_, root_font_size_);
    element_manager()->UpdateLayoutNodeFontSize(layout_node_, font_size_,
                                                root_font_size_);

    PreparePropBundleIfNeed();
    prop_bundle_->SetProps(
        CSSProperty::GetPropertyName(CSSPropertyID::kPropertyIDFontSize)
            .c_str(),
        font_size_);
  }
}

Element *FiberElement::Sibling(int offset) const {
  if (!parent_) return nullptr;
  auto index = static_cast<FiberElement *>(parent_)->IndexOf(this);
  // We know the index can't be -1
  return parent_->GetChildAt(index + offset);
}

void FiberElement::InsertLayoutNode(FiberElement *child, FiberElement *ref) {
  DCHECK(!ref || !ref->is_wrapper());
  element_manager()->InsertLayoutNodeBefore(layout_node_, child->layout_node_,
                                            ref ? ref->layout_node_ : nullptr);
  child->attached_to_layout_parent_ = true;
}

void FiberElement::RemoveLayoutNode(FiberElement *child) {
  element_manager()->RemoveLayoutNode(layout_node_, child->layout_node_);
  child->attached_to_layout_parent_ = false;
}

void FiberElement::StoreLayoutNode(FiberElement *child, FiberElement *ref) {
  child->render_parent_ = this;
  FiberElement *next_layout_sibling = ref;
  FiberElement *previous_layout_sibling =
      next_layout_sibling ? next_layout_sibling->previous_render_sibling_
                          : last_render_child_;
  if (previous_layout_sibling) {
    previous_layout_sibling->next_render_sibling_ = child;
  } else {
    first_render_child_ = child;
  }
  child->previous_render_sibling_ = previous_layout_sibling;

  if (next_layout_sibling) {
    next_layout_sibling->previous_render_sibling_ = child;
  } else {
    last_render_child_ = child;
  }
  child->next_render_sibling_ = next_layout_sibling;
}

void FiberElement::RestoreLayoutNode(FiberElement *node) {
  if (node->previous_render_sibling_) {
    node->previous_render_sibling_->next_render_sibling_ =
        node->next_render_sibling_;
  } else {
    first_render_child_ = node->next_render_sibling_;
  }
  if (node->next_render_sibling_) {
    node->next_render_sibling_->previous_render_sibling_ =
        node->previous_render_sibling_;
  } else {
    last_render_child_ = node->previous_render_sibling_;
  }
  node->render_parent_ = nullptr;
  node->previous_render_sibling_ = nullptr;
  node->next_render_sibling_ = nullptr;
}

bool FiberElement::RefreshStyle(StyleMap &parsed_styles,
                                std::vector<CSSPropertyID> &reset_ids) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::RefreshStyle");
  pre_parsed_styles_map_.clear();
  std::swap(pre_parsed_styles_map_, parsed_styles_map_);
  if (!has_extreme_parsed_styles_) {
    // Once css_related_changed_ is set to true, it will never be set to false
    // again. Otherwise, there will be a bug in the scene where the inline style
    // is used to cover the selector style. When the inline style is deleted,
    // the selector style cannot be set correctly. Take the following code as an
    // example, when useInline is set to false, background-color will not be
    // reset to red.
    // clang-format off
    // ttml: <view class="show" style="{{useInline ? background-color:'blue' : ''}}"/>
    // ttss: .show { background-color:'blue' }
    // clang-format on
    if (css_related_changed_) {
      auto *css_fragment = GetRelatedCSSFragment();
      // resolve styles from css fragment
      if (css_fragment) {
        element_manager()->ResolveStyleForFiber(this, css_fragment,
                                                parsed_styles_map_);
      }
    }

    if (!current_raw_inline_styles_.empty()) {
      auto &configs = element_manager_->GetCSSParserConfigs();
      for (const auto &style : current_raw_inline_styles_) {
        UnitHandler::Process(style.first, style.second,
                             updated_inline_parsed_styles_, configs);
      }
      current_raw_inline_styles_.clear();
    }

    // merge inline styles
    for (const auto &it : updated_inline_parsed_styles_) {
      parsed_styles_map_[it.first] = it.second;
    }
  } else {
    // if extreme_parsed_styles_ has set, we should ignore any class&inline
    // styles
    parsed_styles_map_ = extreme_parsed_styles_;
    if (only_selector_extreme_parsed_styles_ &&
        !current_raw_inline_styles_.empty()) {
      auto &configs = element_manager_->GetCSSParserConfigs();
      for (const auto &style : current_raw_inline_styles_) {
        UnitHandler::Process(style.first, style.second,
                             updated_inline_parsed_styles_, configs);
      }
      current_raw_inline_styles_.clear();
      for (const auto &pair : updated_inherited_styles_) {
        parsed_styles_map_[pair.first] = pair.second;
      }
    }
    has_extreme_parsed_styles_ = false;
    extreme_parsed_styles_.clear();
  }

  // diff styles if needed
  bool ret =
      DiffStyleImpl(pre_parsed_styles_map_, parsed_styles_map_, parsed_styles);
  // styles left in old_map need to be removed
  for (const auto &style : pre_parsed_styles_map_) {
    reset_ids.emplace_back(style.first);
  }
  return ret;
}

void FiberElement::OnClassChanged(const ClassList &old_classes,
                                  const ClassList &new_classes) {
  CheckHasInvalidationForClass(old_classes, new_classes);
}

// For snapshot test
void FiberElement::DumpStyle(StyleMap &computed_styles) {
  StyleMap styles;
  std::vector<CSSPropertyID> reset_style_ids;
  this->RefreshStyle(styles, reset_style_ids);
  computed_styles = parsed_styles_map_;
}

void FiberElement::OnPseudoStatusChanged(PseudoState prev_status,
                                         PseudoState current_status) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "FiberElement::OnPseudoStatusChanged");
  // FIXME: Every element will emit the OnPseudoStatusChanged event
  auto *css_fragment = GetRelatedCSSFragment();
  if (css_fragment && css_fragment->enable_css_selector()) {
    // If disable the invalidation do nothing
    if (!css_fragment->enable_css_invalidation()) {
      return;
    }
    css::InvalidationLists invalidation_lists;
    AttributeHolder::CollectPseudoChangedInvalidation(
        css_fragment, invalidation_lists, prev_status, current_status);
    data_model_->SetPseudoState(current_status);
    for (auto *invalidation_set : invalidation_lists.descendants) {
      if (invalidation_set->InvalidatesSelf()) {
        MarkStyleDirty(false);
      }
      if (invalidation_set->WholeSubtreeInvalid() ||
          !invalidation_set->IsEmpty()) {
        VisitChildren([&invalidation_set](FiberElement *child) {
          if (!child->StyleDirty() && !child->is_raw_text() &&
              invalidation_set->InvalidatesElement(*child->data_model())) {
            child->MarkStyleDirty(false);
          }
        });
      }
      PipelineOptions pipeline_options;
      element_manager_->OnPatchFinishForFiber(pipeline_options, this);
    }
    return;
  }

  if (!css_fragment || css_fragment->pseudo_map().empty()) {
    // no need do any pseudo changing logic if no any touch pseudo token
    return;
  }

  bool cascade_pseudo_enabled = element_manager_->GetEnableCascadePseudo();
  MarkStyleDirty(cascade_pseudo_enabled);

  data_model_->SetPseudoState(current_status);
  PipelineOptions pipeline_options;
  element_manager_->OnPatchFinishForFiber(pipeline_options, this);
}

bool FiberElement::IsInheritable(CSSPropertyID id) const {
  if (!IsCSSInheritanceEnabled()) {
    return false;
  }

  if (!element_manager_->GetDynamicCSSConfigs().custom_inherit_list_.empty()) {
    return element_manager_->GetDynamicCSSConfigs().custom_inherit_list_.count(
        id);
  }
  return DynamicCSSStylesManager::GetInheritableProps().count(id);
}

bool FiberElement::IsCSSInheritanceEnabled() const {
  return element_manager_->GetDynamicCSSConfigs().enable_css_inheritance_;
}

bool FiberElement::IsDirectionChangedEnabled() const {
  // FIXME(linxs): we just use enable_css_inheritance_ to indicate is enable
  // direction temporarily
  return element_manager_->GetDynamicCSSConfigs().enable_css_inheritance_;
}

// return ture means the style has already been processed
bool FiberElement::TryResolveLogicStyleAndSaveDirectionRelatedStyle(
    CSSPropertyID id, CSSValue value) {
  if (!IsDirectionChangedEnabled()) {
    return false;
  }
  // special case.
  if (id == kPropertyIDTextAlign) {
    CSSStyleValue style_type = ResolveTextAlign(id, value, direction_);
    SetStyleInternal(style_type.first, style_type.second);
    return true;
  }

  auto ret_pair = DynamicCSSStylesManager::ResolveLogicPropertyID(id);
  CSSPropertyID trans_id = ret_pair.first;
  bool is_logic_style = ret_pair.second;

  if (is_logic_style) {
    pending_updated_direction_related_styles_[trans_id] = {value, true};
    return true;
  } else if (DynamicCSSStylesManager::CheckIsDirectionAwareStyle(id)) {
    pending_updated_direction_related_styles_[trans_id] = {value, false};
    return true;
  }

  return false;
}

// try to Resolve Direction css
void FiberElement::TryDoDirectionRelatedCSSChange(CSSPropertyID id,
                                                  CSSValue value,
                                                  IsLogic is_logic_style) {
  CSSPropertyID trans_id =
      DynamicCSSStylesManager::ResolveDirectionRelatedPropertyID(
          id, direction_, is_logic_style);
  current_direction_related_styles_[id] = {trans_id, value, is_logic_style};
  SetStyleInternal(trans_id, value);
}

void FiberElement::WillResetCSSValue(CSSPropertyID &css_id) {
  // remove self inherit properties if needed
  auto it = inherited_styles_.find(css_id);
  if (it != inherited_styles_.end()) {
    inherited_styles_.erase(it);
    reset_inherited_ids_.emplace_back(css_id);
    children_propagate_inherited_styles_flag_ = true;
  }

  // direction related css
  if (IsDirectionChangedEnabled()) {
    // if direction_changed_ is true, all direction related styles will be
    // handled together
    auto ret_pair = DynamicCSSStylesManager::ResolveLogicPropertyID(css_id);
    // take care: logic CSS ID should be transited firstly
    css_id = ret_pair.first;
    auto direction_css_it = current_direction_related_styles_.find(css_id);
    if (direction_css_it != current_direction_related_styles_.end()) {
      current_direction_related_styles_.erase(direction_css_it);
    }
  }
}

void FiberElement::ResetCSSValue(CSSPropertyID css_id) {
  bool is_layout_only = LayoutNode::IsLayoutOnly(css_id);
  if (is_layout_only) {
    auto viewport_unit_style_it = viewport_unit_styles_.find(css_id);
    if (viewport_unit_style_it != viewport_unit_styles_.end()) {
      viewport_unit_styles_.erase(viewport_unit_style_it);
    }
  }
  bool need_layout = is_layout_only || LayoutNode::IsLayoutWanted(css_id);
  if (need_layout) {
    element_manager()->ResetLayoutNodeStyle(layout_node_, css_id);
  }
  if (css_id == kPropertyIDPosition) {
    if (is_fixed_) {
      fixed_changed_ = true;
    }
    is_sticky_ = is_fixed_ = false;
  }

  if (is_layout_only) {
    return;
  }
  has_layout_only_props_ = false;
  computed_css_style()->ResetValue(css_id);
  CheckZIndexProps(css_id, true);
  CheckTransitionProps(css_id);
  CheckKeyframeProps(css_id);
  // The properties of transition and keyframe no need to be pushed to bundle
  // separately here. Those properties will be pushed to bundle together
  // later.
  if (!(CSSProperty::IsTransitionProps(css_id) ||
        CSSProperty::IsKeyframeProps(css_id))) {
    ResetProp(CSSProperty::GetPropertyName(css_id).c_str());
  }
}

void FiberElement::HandleSelfFixedChange() {
  if (!fixed_changed_ || !render_parent_) {
    return;
  }
  if (is_fixed_) {
    // non-fixed to fixed
    auto *parent = render_parent_;
    parent->HandleRemoveChildAction(this);
    parent->InsertFixedElement(this, next_render_sibling_);
  } else {
    // fixed to non-fixed
    RemoveFixedElement(this);
    auto *parent = static_cast<FiberElement *>(this->parent_);
    auto index = parent->IndexOf(this);
    auto *ref_node = static_cast<FiberElement *>(parent->GetChildAt(index + 1));
    parent->HandleInsertChildAction(this, -1, ref_node);
  }
}

void FiberElement::InsertFixedElement(FiberElement *child,
                                      FiberElement *ref_node) {
  DCHECK(child->is_fixed_);
  // FIXME(linxs): insert fixed child, to be refined later, currently always
  // insert to the end
  auto *parent = static_cast<FiberElement *>(element_manager_->root());
  parent->HandleInsertChildAction(child, 0, nullptr);
  child->fixed_changed_ = false;
}

void FiberElement::RemoveFixedElement(FiberElement *child) {
  // FIXME(linxs): remove fixed child, to be refined later
  DCHECK(child->render_parent_ == element_manager_->root());
  auto *parent = static_cast<FiberElement *>(element_manager_->root());
  parent->HandleRemoveChildAction(child);
  child->fixed_changed_ = false;
}

void FiberElement::CheckViewportUnit(CSSPropertyID id, CSSValue value) {
  // If style has viewport unit(vw/vh), try to store it to
  // viewport_unit_styles_, and also mark the dynamic_style_flags_, which will
  // be used in UpdateDynamicElementStyle()
  const auto &pattern = value.GetPattern();
  if (pattern == CSSValuePattern::VW || pattern == CSSValuePattern::VH) {
    dynamic_style_flags_ |= DynamicCSSStylesManager::kUpdateViewport;
    viewport_unit_styles_[id] = value;
    RequireDynamicStyleUpdate();
  }
}

bool FiberElement::CheckHasInvalidationForId(const std::string &old_id,
                                             const std::string &new_id) {
  auto *css_fragment = GetRelatedCSSFragment();
  // resolve styles from css fragment
  if (!css_fragment || !css_fragment->enable_css_invalidation()) {
    return false;
  }
  auto old_size = invalidation_lists_.descendants.size();
  AttributeHolder::CollectIdChangedInvalidation(
      css_fragment, invalidation_lists_, old_id, new_id);
  return invalidation_lists_.descendants.size() != old_size;
}

bool FiberElement::CheckHasInvalidationForClass(const ClassList &old_classes,
                                                const ClassList &new_classes) {
  auto *css_fragment = GetRelatedCSSFragment();
  // resolve styles from css fragment
  if (!css_fragment || !css_fragment->enable_css_invalidation()) {
    return false;
  }
  auto old_size = invalidation_lists_.descendants.size();
  AttributeHolder::CollectClassChangedInvalidation(
      css_fragment, invalidation_lists_, old_classes, new_classes);
  return invalidation_lists_.descendants.size() != old_size;
}

void FiberElement::VisitChildren(
    const base::MoveOnlyClosure<void, FiberElement *> &visitor) {
  for (auto &child : scoped_children_) {
    // In fiber mode, we skip the children in component
    if (!child->is_component()) {
      visitor(child.Get());
      child->VisitChildren(visitor);
    }
  }
}

#if ENABLE_RENDERKIT
void FiberElement::SetMeasureFunc(std::unique_ptr<MeasureFunc> func) {
  layout_node_->SetMeasureFunc(std::move(func));
}
#endif

void FiberElement::ConsumeTransitionStylesInAdvanceInternal(
    CSSPropertyID css_id, const tasm::CSSValue &value) {
  SetStyleInternal(css_id, value);
}

void FiberElement::ResetTransitionStylesInAdvanceInternal(
    CSSPropertyID css_id) {
  ResetStyleInternal(css_id);
}

void FiberElement::OnPatchFinish(const PipelineOptions &option) {
  element_manager_->OnPatchFinishForFiber(option, this);
}

std::optional<CSSValue> FiberElement::GetElementStyle(
    tasm::CSSPropertyID css_id) {
  auto iter = parsed_styles_map_.find(css_id);
  if (iter == parsed_styles_map_.end()) {
    iter = updated_inherited_styles_.find(css_id);
    if (iter == updated_inherited_styles_.end()) {
      return std::optional<CSSValue>();
    }
  }
  return iter->second;
}

void FiberElement::UpdateDynamicElementStyle() {
  // If needed, try to iterate all elements that have
  // dynamic_style_update_required_ flag
  if (!dynamic_style_update_required_) {
    return;
  }
  if (dynamic_style_flags_ > 0) {
    // Handle viewport related: re-parse all styles in viewport_unit_styles_, to
    // make the layout node refresh. It's better to move this action to layout
    // node side
    const auto &env_config = element_manager_->GetLynxEnvConfig();
    bool viewport_changed =
        !(env_config.ViewportWidth() ==
              computed_css_style()->GetMeasureContext().viewport_width_ &&
          env_config.ViewportHeight() ==
              computed_css_style()->GetMeasureContext().viewport_height_);
    if (viewport_changed &&
        dynamic_style_flags_ & DynamicCSSStylesManager::kUpdateViewport) {
      computed_css_style()->SetViewportWidth(env_config.ViewportWidth());
      computed_css_style()->SetViewportHeight(env_config.ViewportHeight());
      for (const auto &style : viewport_unit_styles_) {
        element_manager()->UpdateLayoutNodeStyle(layout_node_, style.first,
                                                 style.second);
      }
    }
    // TODO(linxs): udpate screen metrics & font-size...
  }
  auto *child = first_render_child_;
  while (child) {
    child->UpdateDynamicElementStyle();
    child = child->next_render_sibling_;
  }
}

}  // namespace tasm
}  // namespace lynx
