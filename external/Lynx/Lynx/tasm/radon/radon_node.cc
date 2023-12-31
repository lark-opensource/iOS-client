// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/radon/radon_node.h"

#include <functional>
#include <list>
#include <sstream>
#include <utility>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "base/lynx_env.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "css/css_property.h"
#include "css/css_selector_constants.h"
#include "lepus/array.h"
#include "lepus/lepus_string.h"
#include "lepus/table.h"
#include "lepus/value.h"
#include "tasm/attribute_holder.h"
#include "tasm/base/base_def.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/page_proxy.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_page.h"

#if ENABLE_INSPECTOR
using lynxdev::devtool::DevtoolFunction;
#endif

namespace lynx {
namespace tasm {

RadonNode::RadonNode(PageProxy* const page_proxy_,
                     const lepus::String& tag_name, uint32_t node_index)
    : RadonBase(kRadonNode, tag_name, node_index), page_proxy_{page_proxy_} {
  if (!page_proxy_) {
    return;
  }
  // force_calc_new_style_ should be true when using Radon mode.
  force_calc_new_style_ =
      page_proxy_->element_manager()->GetForceCalcNewStyle() ||
      !page_proxy_->IsRadonDiff();
}

RadonNode::RadonNode(const RadonNode& node, PtrLookupMap& map)
    : RadonBase{node, map},
      AttributeHolder{node},
      page_proxy_{node.page_proxy_},
      force_calc_new_style_{node.force_calc_new_style_} {}

RadonNode::~RadonNode() {
  if (element_) {
    page_proxy_->element_manager()->node_manager()->Erase(element_->impl_id());
  }
}

bool RadonNode::CreateElementIfNeeded() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonNode::CreateElementIfNeeded",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  if (element_ == nullptr) {
    MoveChangedInlineStylesToInlineStyles();
    auto* element = page_proxy_->element_manager()->CreateNode(tag(), this);
    if (page_proxy_->GetPageElementEnabled() && tag().IsEquals("page")) {
      page_proxy_->element_manager()->SetRootOnLayout(element->layout_node());
      page_proxy_->element_manager()->catalyzer()->set_root(element);
      page_proxy_->element_manager()->SetRoot(element);
    }
    element_.reset(element);
    page_proxy_->element_manager()->node_manager()->Record(element_->impl_id(),
                                                           element_.get());

    EXEC_EXPR_FOR_INSPECTOR({
      if (GetDevtoolFlag()) {
        TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY,
                          "devtool logic: CreateElementIfNeeded");
        CheckAndProcessSlotForInspector(element);
        CheckAndProcessComponentRemoveViewForInspector(element);
        TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
      }
    });
    return true;
  }
  return false;
}

void RadonNode::ResetElementRecursively() {
  element_.reset();
  ClearCachedStyles();
  RadonBase::ResetElementRecursively();
}

void RadonNode::RemoveElementFromParent() {
  if (!NeedsElement()) {
    // When the component is 'removeComponentElement', should directly call its
    // children's RemoveElementFromParent.
    RadonBase::RemoveElementFromParent();
    return;
  }
  auto element = element_.get();
  if (element != nullptr) {
    EXEC_EXPR_FOR_INSPECTOR(NotifyElementNodeRemoved());
    auto parent_element = static_cast<tasm::RadonElement*>(element->parent());
    if (parent_element) {
      int32_t index = parent_element->IndexOf(element);
      parent_element->RemoveNode(element, index);
    }
    // delete fixed children of element node.
    std::list<RadonBase*> radon_base_list;

    for (auto& radon_base_child : radon_children_) {
      radon_base_list.push_back(radon_base_child.get());
    }
    auto root_element =
        static_cast<RadonElement*>(page_proxy_->element_manager()->root());
    while (!radon_base_list.empty()) {
      RadonBase* front = radon_base_list.front();
      radon_base_list.pop_front();
      if (front) {
        for (auto& radon_base_child : front->radon_children_) {
          radon_base_list.push_back(radon_base_child.get());
        }
        if (front->element() && front->element()->is_fixed_) {
          EXEC_EXPR_FOR_INSPECTOR(
              static_cast<RadonNode*>(front)->NotifyElementNodeRemoved());
          root_element->RemoveNode(front->element(),
                                   root_element->IndexOf(front->element()));
        }
      }
    }
  }
}

void RadonNode::UpdateClass(const lepus::String& clazz) {
  if (radon_classes_.IsEqual(clazz)) {
    return;
  }
  radon_classes_ = clazz;
  class_dirty_ = true;
  if (need_transmit_class_dirty_) {
    class_transmit_option_.RemoveClass(classes_.begin(), classes_.end());
  }
  classes_.clear();
  if (radon_classes_.empty()) {
    return;
  }
  // CSS class is separated by " ", so we check is radon_class_ has a " ".
  // If no " " found, radon_class_ is treated as a whole class.
  // radon_class_ is treaded as multi classes split by " " otherwise.
  if (radon_classes_.str().find(' ') == std::string::npos) {
    AddSingleClass(radon_classes_);
  } else {
    std::vector<std::string> split_classes;
    if (base::SplitString(radon_classes_.str(), ' ', split_classes)) {
      for (auto& split_class : split_classes) {
        AddSingleClass(base::TrimString(split_class));
      }
    }
  }
}

void RadonNode::AddSingleClass(const lepus::String& clazz) {
  if (clazz.empty()) {
    return;
  }

  classes_.push_back(clazz);

  // See if this class is listed in component's external classes and may change.
  // This has to be done at run time to ensure the correctness of class='{{}}'.
  if (component() && component()->external_classes().find(clazz) !=
                         component()->external_classes().end()) {
    has_external_class_ = true;
  }
  if (need_transmit_class_dirty_) {
    class_transmit_option_.AddClass(clazz);
  }
}

void RadonNode::UpdateInlineStyle(CSSPropertyID id, const CSSValue& value) {
  // for flush props performance
  auto it = changed_inline_styles_.find(id);
  if (it == changed_inline_styles_.end() || !(it->second == value)) {
    inline_style_dirty_ = true;
    changed_inline_styles_[id] = value;
  }
}

void RadonNode::UpdateDynamicAttribute(const lepus::String& key,
                                       const lepus::Value& value) {
  auto it = attributes_.find(key);
  if (it == attributes_.end() || !it->second.first.IsEqual(value)) {
    changed_attributes_[key] = {value, true};
    attributes_[key] = {value, true};
    attr_dirty_ = true;
    has_dynamic_attr_ = true;
  }
  if (key.IsEqual(kTransmitClassDirty)) {
    need_transmit_class_dirty_ = value.Bool();
  }
}

void RadonNode::UpdateIdSelector(const lepus::String& id_selector) {
  if (id_selector == id_selector_) {
    return;
  }
  UpdateDynamicAttribute(kIdSelectorAttrName, lepus::Value(id_selector.impl()));
  // TODO: update css id selector.
  id_selector_ = id_selector;
  id_dirty_ = true;
}

void RadonNode::UpdateDataSet(const lepus::String& key,
                              const lepus::Value& value) {
  auto iter = data_set_.find(key);
  if (iter != data_set_.end() && iter->second == value) {
    return;
  }
  data_set_[key] = value;
  data_set_dirty_ = true;
}

bool RadonNode::NeedsToUpdateClassDueToClassTransmit(
    const DispatchOption& option) {
  if (option.class_transmit_.IsEmpty()) {
    return false;
  }
  CSSFragment* style_sheet = ParentStyleSheet();
  for (auto& origin : classes_) {
    for (auto& deleted : option.class_transmit_.removed_classes_) {
      auto rule = CSSPatching::MergeCSSSelector(
          CSSPatching::GetClassSelectorRule(origin),
          CSSPatching::GetClassSelectorRule(deleted));
      if (style_sheet->GetCSSStyle(rule) != nullptr) {
        return true;
      }
    }
    for (auto& added : option.class_transmit_.added_classes_) {
      auto rule = CSSPatching::MergeCSSSelector(
          CSSPatching::GetClassSelectorRule(origin),
          CSSPatching::GetClassSelectorRule(added));
      if (style_sheet->GetCSSStyle(rule) != nullptr) {
        return true;
      }
    }
  }
  return false;
}

bool RadonNode::DiffIncrementally(const DispatchOption& option) RADON_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonNode:Dispatch::UpdateFlush",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  bool need_flush = false;
  if (invalidated_) {
    page_proxy_->element_manager()->OnValidateNode(element_.get());
    invalidated_ = false;
  }
  need_flush |= DiffStyleIncrementally(option);
  need_flush |= DiffAttributeIncrementally();
  return need_flush;
}

bool RadonNode::DiffStyleIncrementally(const DispatchOption& option)
    RADON_ONLY {
  bool class_transmit_dirty = NeedsToUpdateClassDueToClassTransmit(option);
  bool need_flush = false;

  // inline style > css styles
  if (id_dirty_ || class_dirty_ || has_external_class_ ||
      css_variables_changed_ || class_transmit_dirty) {
    // mix inline_style_ and css style
    StyleMap new_styles;
    page_proxy_->element_manager()->GetStyleList(this, new_styles);
    // mix new_styles with changed_inline_styles
    for (const auto& pair : changed_inline_styles_) {
      new_styles[pair.first] = pair.second;
      inline_styles_[pair.first] = pair.second;
    }
    need_flush = DiffStyleImpl(last_styles_, new_styles, true);

    if (id_dirty_ || class_dirty_) {
      this->OnSelectorChanged();
    }
    id_dirty_ = false;
    class_dirty_ = false;
    inline_style_dirty_ = false;
    css_variables_changed_ = false;
  } else if (dynamic_inline_style_ && inline_style_dirty_) {
    // !id_dirty_ && !class_dirty_
    need_flush = DiffStyleImpl(inline_styles_, changed_inline_styles_, true);
    inline_style_dirty_ = false;
  } else if (inline_style_dirty_) {
    // !id_dirty_ && !class_dirty_ && (!dynamic_inline_style ||
    // !inline_style_dirty_)
    need_flush = DiffStyleImpl(inline_styles_, changed_inline_styles_, false);
    inline_style_dirty_ = false;
  }

  if (data_set_dirty_) {
    this->OnDataSetChanged();
    data_set_dirty_ = false;
  }

  changed_inline_styles_.clear();
  return need_flush;
}

bool RadonNode::DiffAttributeIncrementally() RADON_ONLY {
  auto need_flush = false;
  if (attr_dirty_) {
    for (auto& attr : changed_attributes_) {
      page_proxy_->element_manager()->OnUpdateAttr(element_.get(), attr.first,
                                                   attr.second.first);
    }
    changed_attributes_.clear();
    attr_dirty_ = false;
    need_flush = true;
  }
  return need_flush;
}

void RadonNode::DispatchFirstTime() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonNode:DispatchFirstTime",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  StyleMap new_styles;
  if (page_proxy_->IsRadonDiff()) {
    page_proxy_->element_manager()->GetCachedStyleList(this, new_styles);
  } else {
    page_proxy_->element_manager()->GetStyleList(this, new_styles);
  }

  for (const auto& iter : changed_inline_styles_) {
    new_styles[iter.first] = iter.second;
    inline_styles_[iter.first] = iter.second;
  }
  page_proxy_->element_manager()->ResolveAttributesAndStyle(
      this, element_.get(), new_styles);

  for (const auto& iter : changed_attributes_) {
    element_->SetAttribute(iter.first, iter.second.first);
  }
  changed_attributes_.clear();
  // get parent in advance, we need know whether the node is native inline view
  RadonElement* parent_element = GetParentWithFixed(ParentElement());

  element_->FlushPropsFirstTimeWithParentElement(parent_element);
  last_styles_ = std::move(new_styles);

  CSSFragment* fragment = ParentStyleSheet();
  if (fragment) {
    if (fragment->enable_css_selector()) {
      page_proxy_->element_manager()->UpdatePseudoShadowsNew(this,
                                                             element_.get());
    } else if (fragment->HasPseudoStyle()) {
      page_proxy_->element_manager()->UpdatePseudoShadows(this, element_.get());
    }
  }
  class_dirty_ = false;
  inline_style_dirty_ = false;
  attr_dirty_ = false;

  auto key = lepus::String(kTransmitClassDirty);
  auto it = attributes_.find(key);
  if (it != attributes_.end()) {
    need_transmit_class_dirty_ = it->second.first.Bool();
  }
}

RadonElement* RadonNode::GetParentWithFixed(RadonElement* parent_element) {
  if (!parent_element || !element() || element()->parent()) {
    return nullptr;
  }

  if (element()->is_fixed_) {
    return static_cast<RadonElement*>(page_proxy_->element_manager()->root());
  }
  return parent_element;
}

void RadonNode::InsertElementIntoParent(RadonElement* parent_element) {
  auto parent = GetParentWithFixed(parent_element);
  if (!parent) {
    return;
  }

  if (element()->is_fixed_) {
    parent->InsertNode(element_.get());
  } else {
    RadonElement* previous_element = PreviousSiblingElement();
    const auto base_index = parent->IndexOf(previous_element) + 1;
    parent->InsertNode(element_.get(), base_index);
  }
}

void RadonNode::DispatchSelf(const DispatchOption& option) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonDispatchSelf",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  if (!NeedsElement() || !option.need_update_element_) {
    return;
  }
  if (CreateElementIfNeeded()) {
    // if element is nullptr, the element will be created.
    DispatchFirstTime();
    InsertElementIntoParent(ParentElement());
    option.has_patched_ = true;
    EXEC_EXPR_FOR_INSPECTOR({
      if (GetDevtoolFlag() && GetRadonPlug()) {
        create_plug_element_ = true;
      }
    });
  } else if (DiffIncrementally(option)) {
    EXEC_EXPR_FOR_INSPECTOR(NotifyElementNodeSetted());
    // if element is created, diff it and flush on need.
    element_->FlushProps();
    option.has_patched_ = true;
  }
  if (!class_transmit_option_.IsEmpty()) {
    auto& removed = class_transmit_option_.removed_classes_;
    option.class_transmit_.RemoveClass(removed.begin(), removed.end());
    for (auto iter : class_transmit_option_.added_classes_) {
      option.class_transmit_.AddClass(iter);
    }
    class_transmit_option_.removed_classes_.clear();
    class_transmit_option_.added_classes_.clear();
  }
}

void RadonNode::CreateContentNode() {
  page_proxy_->element_manager()->GenerateContentData(pseudo_content_, this,
                                                      element_.get());
  ContentData* data = element_->content_data();
  while (data) {
    RadonNode* node = nullptr;

    if (data->isText()) {
      node = new RadonNode(page_proxy_, "raw-text", kRadonInvalidNodeIndex);
      auto* text_data = static_cast<TextContentData*>(data);
      lepus::Value value(lepus::StringImpl::Create(text_data->text().c_str()));
      node->SetStaticAttribute("text", value);
    } else if (data->isImage()) {
      node = new RadonNode(page_proxy_, "inline-image", kRadonInvalidNodeIndex);
      auto* image_data = static_cast<ImageContentData*>(data);
      lepus::Value value(lepus::StringImpl::Create(image_data->url().c_str()));
      node->SetStaticAttribute("src", value);
    } else if (data->isAttr()) {
      auto* image_data = static_cast<AttrContentData*>(data);
      auto content = image_data->attr_content();
      if (content.IsString()) {
        node = new RadonNode(page_proxy_, "raw-text", kRadonInvalidNodeIndex);
        node->SetStaticAttribute("text", content);
      }
    }

    if (node) {
      for (auto& style : inline_styles_) {
        node->SetStaticInlineStyle(style.first, style.second);
      }
      AddChild(std::unique_ptr<RadonBase>{node});
    }

    data = data->next();
  }
}

CSSFragment* RadonNode::ParentStyleSheet() const {
  CSSFragment* style_sheet = nullptr;
  if (radon_component_) {
    style_sheet = radon_component_->GetStyleSheet();
  }
  return style_sheet;
}

CSSFragment* RadonNode::GetPageStyleSheet() {
  RadonPage* page = root_node();
  if (page == nullptr) {
    return nullptr;
  }
  CSSFragment* rootSheet = page->GetStyleSheet();
  return rootSheet;
}

bool RadonNode::GetCSSScopeEnabled() {
  if (page_proxy_ == nullptr) {
    return false;
  }
  return page_proxy_->GetCSSScopeEnabled();
}

bool RadonNode::GetCascadePseudoEnabled() {
  return page_proxy_->element_manager()->GetEnableCascadePseudo();
}

AttributeHolder* RadonNode::HolderParent() const {
  RadonBase* parent = radon_parent_;
  while (parent != nullptr && !parent->NeedsElement()) {
    parent = parent->Parent();
  }
  // Find a parent needElement or nullptr.
  if (parent) {
    return static_cast<RadonNode*>(parent);
  }
  return nullptr;
}

bool RadonNode::InComponent() const {
  return radon_component_->IsRadonComponent();
}

int RadonNode::ParentComponentId() const {
  if (radon_component_) {
    return radon_component_->ComponentId();
  }
  return 0;
}

void RadonNode::OnRenderFailed() { SetInvalidated(true); }

int RadonNode::ImplId() const {
  return element_ ? element_->impl_id() : kInvalidImplId;
}

#ifdef ENABLE_TEST_DUMP
rapidjson::Value RadonNode::DumpToJSON(rapidjson::Document& doc) {
  rapidjson::Document::AllocatorType& allocator = doc.GetAllocator();
  rapidjson::Value value;
  value.SetObject();

  if (element()) {
    value.AddMember("Impl Id", element()->impl_id(), allocator);
  }
  value.AddMember("Type", RadonNodeTypeStrings[NodeType() + 1], allocator);
  value.AddMember("Tag", tag_name_.str(), allocator);
  value.AddMember("Attribute", DumpAttributeToJSON(doc), allocator);
  if (!radon_component_->name().empty()) {
    value.AddMember("Radon Component", radon_component_->name().str(),
                    allocator);
  }

  if (IsRadonComponent()) {
    auto* component = static_cast<RadonComponent*>(this);
    if (component) {
      std::string dsl = lynx::tasm::GetDSLName(component->GetDSL());
      value.AddMember("Component DSL", dsl, allocator);
      value.AddMember("Component Info Map",
                      component->DumpComponentInfoMap(doc), allocator);
    }
  }

  auto radon_children_size = static_cast<uint32_t>(radon_children_.size());
  value.AddMember("child count", radon_children_size, allocator);

  if (radon_children_size > 0) {
    rapidjson::Value children;
    children.SetArray();
    for (auto&& child : radon_children_) {
      children.GetArray().PushBack(child->DumpToJSON(doc), allocator);
    }
    value.AddMember("children", children, allocator);
  }

  return value;
}

// Extends DumpAttributeToLepusValue from base class AttributeHolder.
// This function added component name and path info
void RadonNode::DumpAttributeToLepusValue(
    base::scoped_refptr<lepus::Dictionary>& props) {
  AttributeHolder::DumpAttributeToLepusValue(props);
  if (this->IsRadonComponent()) {
    auto* component = static_cast<RadonComponent*>(this);
    if (component) {
      props->SetValue("name", lepus::Value(component->name().impl()));
      props->SetValue("path", lepus::Value(component->path().impl()));
    }
  }
}

// Extends DumpAttributeToMarkup from base class AttributeHolder.
// This function added component name and path info
void RadonNode::DumpAttributeToMarkup(std::ostringstream& ss) {
  if (IsRadonComponent()) {
    auto* component = static_cast<RadonComponent*>(this);
    if (component) {
      ss << " name=\"" << component->name().str() << "\"";
      ss << " path=\"" << component->path().str() << "\"";
    }
  }

  AttributeHolder::DumpAttributeToMarkup(ss);
}

#endif

void RadonNode::SwapElement(const std::unique_ptr<RadonBase>& old_radon_base,
                            const DispatchOption& option) RADON_DIFF_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonNode::SwapElement",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  auto* old_radon_node = static_cast<RadonNode*>(old_radon_base.get());
  // re-use old_radon_node's need_transmit_class_dirty_
  need_transmit_class_dirty_ = old_radon_node->need_transmit_class_dirty_;
  pseudo_state_ = old_radon_node->pseudo_state_;
  element_.reset(old_radon_node->element_.release());
  if (element_) {
    // use new node's AttributeHolder
    element_->SetAttributeHolder(this);
    EXEC_EXPR_FOR_INSPECTOR({
      // when set RemoveComponentElement and open DevtoolDebug and DomTree
      // switch, component node will still has an element for inspect which has
      // no parent and children.For this element, it just need reset
      // AttributeHolder and NotifyElementNodeSetted.
      if (GetDevtoolFlag() && element_->inspector_attribute_->needs_erase_id_) {
        NotifyElementNodeSetted();
        return;
      }
    });
    auto previous_fixed = element_->is_fixed_;
    has_dynamic_class_ |= old_radon_node->has_dynamic_class_;
    has_dynamic_inline_style_ |= old_radon_node->has_dynamic_inline_style_;
    has_dynamic_attr_ |= old_radon_node->has_dynamic_attr_;
    // handle node's diff logic in ShouldFlush
    if (ShouldFlush(old_radon_base, option)) {
      EXEC_EXPR_FOR_INSPECTOR(NotifyElementNodeSetted());
      // should modify element tree structure if the node's fixed style has been
      // changed
      TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "handle fixed element");
      if (element_->is_fixed_ != previous_fixed) {
        if (element_->is_fixed_) {
          auto* parent = static_cast<RadonElement*>(element()->parent());
          auto index = parent->IndexOf(element());
          EXEC_EXPR_FOR_INSPECTOR(NotifyElementNodeRemoved());
          parent->RemoveNode(element(), index, false);
          GetRootElement()->InsertNode(element());
          EXEC_EXPR_FOR_INSPECTOR(NotifyElementNodeAdded());
        } else {
          auto* parent = GetRootElement();
          auto index = parent->IndexOf(element());
          EXEC_EXPR_FOR_INSPECTOR(NotifyElementNodeRemoved());
          parent->RemoveNode(element(), index, false);
          InsertElementIntoParent(ParentElement());
          EXEC_EXPR_FOR_INSPECTOR(NotifyElementNodeAdded());
        }
      }
      TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
      element_->FlushProps();
      option.has_patched_ = true;
    }
  }
}

void RadonNode::ReApplyStyle(const DispatchOption& option) RADON_DIFF_ONLY {
#if ENABLE_HMR
  if (element_) {
    EXEC_EXPR_FOR_INSPECTOR({
      if (GetDevtoolFlag() && element_->inspector_attribute_->needs_erase_id_) {
        NotifyElementNodeSetted();
        return;
      }
    });
    // handle node's diff logic in ShouldFlushStyle
    if (ShouldFlushStyle(this, option)) {
      EXEC_EXPR_FOR_INSPECTOR(NotifyElementNodeSetted());
      element_->FlushProps();
      option.has_patched_ = true;
    }
  }
#endif
}

bool RadonNode::ShouldFlush(const std::unique_ptr<RadonBase>& old_radon_base,
                            const DispatchOption& option) RADON_DIFF_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonNode::ShouldFlush",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });

  if (!option.need_diff_) {
    return HydrateNode(option);
  }

  auto* old_radon_node = static_cast<RadonNode*>(old_radon_base.get());
  bool updated = false;
  id_dirty_ = !(id_selector_ == old_radon_node->id_selector_);
  class_dirty_ = false;
  if (has_dynamic_class_) {
    class_dirty_ = classes_ != old_radon_node->classes_;
  }

  updated |= ShouldFlushAttr(old_radon_node);
  updated |= ShouldFlushDataSet(old_radon_node);
  updated |= ShouldFlushStyle(old_radon_node, option);
  updated |= HydrateNode(option);
  EXEC_EXPR_FOR_INSPECTOR({
    // When the RadonNode's style doesn't change, but its class or id has been
    // changed, we still need to notify devtool to update it.
    if (!updated && (class_dirty_ || id_dirty_)) {
      NotifyElementNodeSetted();
    }
  });
  id_dirty_ = false;
  class_dirty_ = false;
  style_invalidated_ = true;
  return updated;
}

bool RadonNode::ShouldFlushAttr(const RadonNode* old_radon_node)
    RADON_DIFF_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonNode::ShouldFlushAttr",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  bool attr_updated = false;
  if (id_dirty_ || has_dynamic_attr() || old_radon_node->has_dynamic_attr()) {
    // attribute now can be updated, inserted or removed in compileNG.
    const AttrMap& old_attrs = old_radon_node->attributes();
    const AttrMap& new_attrs = attributes();
    for (const auto& new_attr : new_attrs) {
      auto old_iter = old_attrs.find(new_attr.first);
      if (old_iter != old_attrs.end()) {
        if (old_iter->second.first != new_attr.second.first) {
          // Attribute is changed, so we update it.
          attr_updated = true;
          page_proxy_->element_manager()->OnUpdateAttr(
              element_.get(), new_attr.first, new_attr.second.first);
        }
      } else {
        // Attribute is inserted, so we update it.
        attr_updated = true;
        page_proxy_->element_manager()->OnUpdateAttr(
            element_.get(), new_attr.first, new_attr.second.first);
      }
      // update need_transmit_class_dirty_
      if (new_attr.first.IsEqual(kTransmitClassDirty)) {
        need_transmit_class_dirty_ = new_attr.second.first.Bool();
      }
    }
    for (const auto& old_attr : old_attrs) {
      auto new_iter = new_attrs.find(old_attr.first);
      if (new_iter == new_attrs.end()) {
        // Attribute is removed, so we remove it in element node.
        attr_updated = true;
        page_proxy_->element_manager()->OnDeletedAttr(element_.get(),
                                                      old_attr.first);
        // remove need_transmit_class_dirty attr
        if (old_attr.first.IsEqual(kTransmitClassDirty)) {
          need_transmit_class_dirty_ = false;
        }
      }
    }
  }
  return attr_updated;
}

bool RadonNode::ShouldFlushDataSet(const RadonNode* old_radon_node)
    RADON_DIFF_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonNode::ShouldFlushDataSet",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  // If element_ is null, do not flush dataset.
  if (!element_) {
    return false;
  }
  const static auto& check_flush = [](const DataMap& new_data,
                                      const DataMap& old_data) {
    // When both are empty, do not need flush data set.
    if (old_data.empty() && new_data.empty()) {
      return false;
    }
    if (old_data.size() != new_data.size()) {
      return true;
    }
    // When exec this loop, new_data size == old_data size.
    // If new_data == old_data, each key in new_data can be found in
    // old_data, and the values in new_data & old_data are equal too. In
    // other words, if there is a key not found in old_data or value in
    // new_data not equals with that in old_data, new_data != old_data.
    // Since the above two statements are contrapositive, exec the following
    // loop can check new_data == old_data when new_data size == old_data
    // size.
    for (const auto& new_iter : new_data) {
      auto old_iter = old_data.find(new_iter.first);
      if (old_iter == old_data.end()) {
        return true;
      }
      if (!old_iter->second.IsEqual(new_iter.second)) {
        return true;
      }
    }
    return false;
  };
  const auto& old_data = old_radon_node->dataset();
  const auto& new_data = dataset();
  bool should_flush = check_flush(new_data, old_data);
  if (should_flush) {
    page_proxy_->element_manager()->OnUpdateDataSet(element_.get(), new_data);
  }
  return should_flush;
}

void RadonNode::CollectInvalidationSetsAndInvalidate(RadonNode* old_radon_node)
    RADON_DIFF_ONLY {
  CSSFragment* style_sheet =
      GetCSSScopeEnabled() ? GetPageStyleSheet() : ParentStyleSheet();
  if (!style_sheet || !style_sheet->enable_css_invalidation()) {
    return;
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "RadonNode::CollectInvalidationSetsAndInvalidate",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  css::InvalidationLists invalidation_lists;
  // Works when CSS Selector is enabled
  if (id_dirty_) {
    CollectIdChangedInvalidation(style_sheet, invalidation_lists,
                                 old_radon_node->id_selector_.str(),
                                 id_selector_.str());
  }
  if (class_dirty_) {
    CollectClassChangedInvalidation(style_sheet, invalidation_lists,
                                    old_radon_node->classes(), classes());
  }

  for (auto* invalidation_set : invalidation_lists.descendants) {
    if (invalidation_set->InvalidatesSelf()) {
      // In radon mode, we don't need self invalidation
      continue;
    }

    Visit(false, [invalidation_set, this](RadonBase* child) {
      if (child->IsRadonNode()) {
        auto* node = static_cast<RadonNode*>(child);
        if (!node->style_invalidated_ && !node->tag().IsEqual("raw-text") &&
            invalidation_set->InvalidatesElement(*node)) {
          node->style_invalidated_ = true;
        }
      }
      return !child->IsRadonComponent() ||
             (child->IsRadonComponent() && GetCSSScopeEnabled());
    });
  }
}

bool RadonNode::OptimizedShouldFlushStyle(
    RadonNode* old_radon_node, const DispatchOption& option) RADON_DIFF_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonNode::OptimizedShouldFlushStyle",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  bool style_updated = false;
  if (option.ShouldForceUpdate() || id_dirty_ || class_dirty_ ||
      has_external_class_ || css_variables_changed_ || style_invalidated_) {
    CollectInvalidationSetsAndInvalidate(old_radon_node);
    auto old_style_list = old_radon_node->cached_styles();
    StyleMap new_style_list;
    page_proxy_->element_manager()->GetCachedStyleList(this, new_style_list);
    style_updated |= DiffStyleImpl(old_style_list, new_style_list, true);
  } else if (has_dynamic_inline_style_) {
    // !class_transmit
    // !option.css_variable_changed_
    // !css_variables_changed_
    // !has_external_class_
    // !id_dirty_
    // !class_dirty_
    // no need to use GetCachedStyleList to get new style, diff inline_styles
    // is enough
    set_cached_styles(old_radon_node->cached_styles());
    // css_variable_map should be reused either.
    set_css_variables_map(old_radon_node->css_variables_map());
    style_updated |=
        DiffStyleImpl(old_radon_node->inline_styles_, inline_styles_, true);
  } else {
    // !class_transmit
    // !option.css_variable_changed_
    // !css_variables_changed_
    // !has_external_class_
    // !id_dirty_
    // !class_dirty_
    // !has_dynamic_inline_style_
    // static inline style couldn't be changed,
    // just set cached styles.
    set_cached_styles(old_radon_node->cached_styles());
    // css_variable_map should be reused either.
    set_css_variables_map(old_radon_node->css_variables_map());
  }
  return style_updated;
}

bool RadonNode::ShouldFlushStyle(RadonNode* old_radon_node,
                                 const DispatchOption& option) RADON_DIFF_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonNode::ShouldFlushStyle",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  bool style_updated = false;
  // TODO: check external class.
  if (need_transmit_class_dirty_) {
    for (auto& clazz : classes_) {
      class_transmit_option_.AddClass(clazz);
    }
  }

  auto old_style_list = old_radon_node->cached_styles();
  StyleMap new_style_list;

  if (option.ignore_cached_style_) {
    // HMR
    page_proxy_->element_manager()->GetUpdatedStyleList(this, new_style_list);
    style_updated |= DiffStyleImpl(old_style_list, new_style_list, true);
  } else if (force_calc_new_style_) {
    // Default logic: use GetCachedStyleList to get new style every time.
    page_proxy_->element_manager()->GetCachedStyleList(this, new_style_list);
    style_updated |= DiffStyleImpl(old_style_list, new_style_list, true);
  } else {
    // Optimized logic: use GetCachedStyleList to get new style only when
    // needed.
    style_updated |= OptimizedShouldFlushStyle(old_radon_node, option);
  }

  if (!class_transmit_option_.IsEmpty()) {
    for (auto iter : class_transmit_option_.added_classes_) {
      option.class_transmit_.AddClass(iter);
    }
    class_transmit_option_.added_classes_.clear();
  }
  return style_updated;
}

void RadonNode::CollectInvalidationSetsForPseudoAndInvalidate(
    CSSFragment* style_sheet, PseudoState prev, PseudoState curr) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "RadonNode::CollectInvalidationSetsForPseudoAndInvalidate",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  if (!style_sheet->enable_css_invalidation()) {
    return;
  }
  css::InvalidationLists invalidation_lists;
  CollectPseudoChangedInvalidation(style_sheet, invalidation_lists, prev, curr);

  bool should_patch = false;
  for (auto* invalidation_set : invalidation_lists.descendants) {
    if (invalidation_set->InvalidatesSelf() && element()) {
      should_patch |= RefreshStyle();
    }
    if (invalidation_set->WholeSubtreeInvalid() ||
        !invalidation_set->IsEmpty()) {
      Visit(false, [&should_patch, invalidation_set, this](RadonBase* child) {
        if (child->IsRadonNode() && child->element() &&
            !child->TagName().IsEqual("raw-text") &&
            invalidation_set->InvalidatesElement(
                *static_cast<RadonNode*>(child))) {
          should_patch |= static_cast<RadonNode*>(child)->RefreshStyle();
        }
        return !child->IsRadonComponent() ||
               (child->IsRadonComponent() && GetCSSScopeEnabled());
      });
    }
  }
  if (should_patch) {
    PipelineOptions pipeline_options;
    page_proxy_->element_manager()->OnPatchFinishInner(pipeline_options);
  }
}

void RadonNode::OnPseudoStateChanged(PseudoState prev, PseudoState curr) {
  CSSFragment* style_sheet =
      GetCSSScopeEnabled() ? GetPageStyleSheet() : ParentStyleSheet();
  if (style_sheet && style_sheet->enable_css_selector()) {
    return CollectInvalidationSetsForPseudoAndInvalidate(style_sheet, prev,
                                                         curr);
  }

  bool should_patch = false;
  if (page_proxy_->element_manager()->GetEnableCascadePseudo()) {
    // Refresh styles of all descendants to support nested focus pseudo class
    Visit(true, [&should_patch](RadonBase* child) {
      if (child->IsRadonNode() && child->element()) {
        should_patch |= static_cast<RadonNode*>(child)->RefreshStyle();
      }
      return !child->IsRadonComponent() ||
             (child->IsRadonComponent() &&
              static_cast<RadonNode*>(child)->GetCSSScopeEnabled());
    });
  } else {
    should_patch = RefreshStyle();
  }
  if (should_patch) {
    PipelineOptions pipeline_options;
    page_proxy_->element_manager()->OnPatchFinishInner(pipeline_options);
  }
}

bool RadonNode::RefreshStyle() {
  StyleMap old_styles = cached_styles();
  ClearCachedStyles();
  StyleMap new_styles;
  page_proxy_->element_manager()->GetCachedStyleList(this, new_styles);
  return DiffStyleImpl(old_styles, new_styles, true);
}

bool RadonNode::DiffStyleImpl(StyleMap& old_map, StyleMap& new_map,
                              bool check_remove) {
  StyleMap update_styles;
  std::vector<CSSPropertyID> reset_style_names;
  update_styles.reserve(old_map.size() + new_map.size());
  reset_style_names.reserve(old_map.size() / 2);
  bool need_update = false;
  // Should update old map if and only if in Radon mode.
  bool should_update_old_map = !page_proxy_->IsRadonDiff();
  if (check_remove) {
    for (auto it = old_map.begin(); it != old_map.end();) {
      auto it_new_map = new_map.find(it->first);
      // style does not exist in rhs, delete it
      if (it_new_map == new_map.end()) {
        auto key = it->first;
        need_update = true;
        reset_style_names.push_back(key);
        if (should_update_old_map) {
          it = old_map.erase(it);
        } else {
          ++it;
        }
        if (&old_map != &last_styles_) {
          last_styles_.erase(key);
          if (!force_calc_new_style_) {
            // Optimized CSSStyle Diff logic: should update cached_styles_
            cached_styles_.erase(key);
          }
        }
      } else {
        ++it;
      }
    }
    page_proxy_->element_manager()->OnDeleteStyle(element_.get(),
                                                  reset_style_names);
  }

  // iterate all styles in new_map
  for (auto& it : new_map) {
    // try to find the corresponding style in old_map
    auto it_old_map = old_map.find(it.first);
    // if r does not exist in lhs, r is a new style to add
    // if r exist in lhs but with different value, update it
    if (it_old_map == old_map.end() || !(it.second == it_old_map->second)) {
      need_update = true;
      update_styles.insert_or_assign(it.first, it.second);
      last_styles_[it.first] = it.second;
      if (!force_calc_new_style_) {
        // Optimized CSSStyle Diff logic: should update cached_styles_
        cached_styles_[it.first] = it.second;
      }
      if (should_update_old_map) {
        old_map[it.first] = it.second;
      }
    }
    // no need to update: it_old_map != old_map.end() && it.second ==
    // it_old_map->second
  }
  page_proxy_->element_manager()->OnUpdateStyle(element_.get(), update_styles);
  return need_update;
}

// Devtool related functions.
bool RadonNode::GetDevtoolFlag() {
  return page_proxy_->element_manager()->GetDevtoolFlag() &&
         page_proxy_->element_manager()->IsDomTreeEnabled();
}

#if ENABLE_INSPECTOR
void RadonNode::NotifyElementNodeAdded() {
  if (GetDevtoolFlag()) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "devtool logic: NotifyElementNodeAdded");
    page_proxy_->element_manager()->OnElementNodeAddedForInspector(element());
  }
}

void RadonNode::NotifyElementNodeRemoved() {
  if (GetDevtoolFlag()) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "devtool logic: NotifyElementNodeRemoved");
    page_proxy_->element_manager()->OnElementNodeRemovedForInspector(element());
  }
}

void RadonNode::NotifyElementNodeSetted() {
  if (GetDevtoolFlag()) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "devtool logic: NotifyElementNodeSetted");
    page_proxy_->element_manager()->OnElementNodeSettedForInspector(element(),
                                                                    this);
  }
}

RadonPlug* RadonNode::GetRadonPlug() {
  RadonBase* current = this;
  RadonBase* parent = current->Parent();
  while (parent) {
    if (parent->NodeType() == kRadonPlug) {
      return static_cast<RadonPlug*>(parent);
    } else if (parent->NodeType() == kRadonIfNode ||
               parent->NodeType() == kRadonForNode) {
      parent = parent->Parent();
    } else {
      return nullptr;
    }
  }
  return nullptr;
}
#endif  // ENABLE_INSPECTOR

RadonNode* RadonNode::NodeParent() {
  RadonBase* parent = radon_parent_;
  while (parent != nullptr && !parent->NeedsElement() &&
         !parent->IsRadonComponent()) {
    parent = parent->Parent();
  }
  if (parent) {
    return static_cast<RadonNode*>(parent);
  }
  return nullptr;
}

RadonNode* RadonNode::Sibling(int offset) const {
  if (!radon_parent_) return nullptr;

  if (NodeType() == kRadonPlug) {
    return static_cast<RadonNode*>(radon_parent_)->Sibling(offset);
  }
  if (radon_parent_->NodeType() == kRadonPlug) {
    auto* slot = radon_parent_->radon_parent_;
    if (slot) {
      return static_cast<RadonNode*>(slot)->Sibling(offset);
    } else {
      return nullptr;
    }
  }
  const auto& siblings = radon_parent_->radon_children_;
  auto iter =
      std::find_if(siblings.begin(), siblings.end(),
                   [id = ImplId()](auto& ptr) { return ptr->ImplId() == id; });
  auto dist = std::distance(siblings.begin(), iter) + offset;
  if (dist < 0 || dist >= static_cast<long>(siblings.size())) {
    return nullptr;
  }
  return static_cast<RadonNode*>(siblings[dist].get());
}

// the sibling function is used to get the sibling node of current node, since
// there may be many sibling nodes, so we need to speicify the sibling node by
// passing the index. if the param value is positive, means get the sibling node
// behind the current node, otherwise, negative means get the sibling node in
// front of current node.
AttributeHolder* RadonNode::NextSibling() const { return Sibling(1); }

AttributeHolder* RadonNode::PreviousSibling() const { return Sibling(-1); }

size_t RadonNode::ChildCount() const { return radon_children_.size(); }

RadonNode* RadonNode::FirstNodeChild() {
  RadonBase* child =
      radon_children_.empty() ? nullptr : radon_children_[0].get();
  if (child != nullptr && !child->NeedsElement() &&
      !child->IsRadonComponent()) {
    child = child->radon_children_.empty() ? nullptr
                                           : child->radon_children_[0].get();
  }
  if (child) {
    return static_cast<RadonNode*>(child);
  }
  return nullptr;
}

RadonNode* RadonNode::LastNodeChild() {
  RadonBase* child =
      radon_children_.empty() ? nullptr : radon_children_.back().get();
  if (child != nullptr && !child->NeedsElement() &&
      !child->IsRadonComponent()) {
    child = child->radon_children_.empty()
                ? nullptr
                : child->radon_children_.back().get();
  }
  if (child) {
    return static_cast<RadonNode*>(child);
  }
  return nullptr;
}

#if ENABLE_INSPECTOR
void RadonNode::CheckAndProcessSlotForInspector(RadonElement* element) {
  // FIXME(zhengyuwei): adjust the location of the code below
  // eg: move to radon plug？ to be discussed
  if (GetDevtoolFlag()) {
    RadonPlug* radon_plug;
    if ((radon_plug = GetRadonPlug())) {
      auto* plug_parent = radon_plug->Parent();
      if (!plug_parent || !plug_parent->component() ||
          !plug_parent->component()->element()) {
        return;
      }
      auto component_element = plug_parent->component()->element();
      page_proxy_->element_manager()->RunDevtoolFunction(
          DevtoolFunction::InsertPlug,
          std::make_tuple(component_element, element));
      auto* slot = page_proxy_->element_manager()->CreateNode("slot", nullptr);
      page_proxy_->element_manager()->RunDevtoolFunction(
          DevtoolFunction::SetSlotElement, std::make_tuple(element, slot));
      page_proxy_->element_manager()->node_manager()->Record(slot->impl_id(),
                                                             slot);
      page_proxy_->element_manager()->RunDevtoolFunction(
          DevtoolFunction::InitSlotElement, std::make_tuple(slot, element));
      page_proxy_->element_manager()->RunDevtoolFunction(
          DevtoolFunction::SetPlugElement, std::make_tuple(slot, element));
      page_proxy_->element_manager()->RunDevtoolFunction(
          DevtoolFunction::SetSlotComponentElement,
          std::make_tuple(slot, component_element));
    }
  }
}

void RadonNode::CheckAndProcessComponentRemoveViewForInspector(
    RadonElement* element) {
  if (GetDevtoolFlag()) {
    if (Parent() && Parent()->NodeType() == kRadonComponent &&
        !Parent()->NeedsElement() && !Parent()->element()) {
      auto* component_element = page_proxy_->element_manager()->CreateNode(
          "component",
          static_cast<AttributeHolder*>(static_cast<RadonNode*>(Parent())));
      page_proxy_->element_manager()->node_manager()->Record(
          component_element->impl_id(), component_element);

      component_element->inspector_attribute_->needs_erase_id_ = true;

      static_cast<RadonNode*>(Parent())->element_.reset(component_element);
      page_proxy_->element_manager()->RunDevtoolFunction(
          DevtoolFunction::InitStyleRoot, std::make_tuple(element));
    }
  }
}
#endif  // ENABLE_INSPECTOR

// Move styles from changed_inline_styles to inline_styles_.
// used to correct attribute holder before creating element.
void RadonNode::MoveChangedInlineStylesToInlineStyles() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "RadonNode::MoveChangedInlineStylesToInlineStyles",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  for (const auto& iter : changed_inline_styles_) {
    inline_styles_[iter.first] = iter.second;
  }
  changed_inline_styles_.clear();
}

bool RadonNode::HydrateNode(const DispatchOption& option) {
  if (option.ssr_hydrating_) {
    return page_proxy_->element_manager()->Hydrate(this, element_.get());
  }
  return false;
}

void RadonNode::AttachSSRPageElement(RadonPage* ssr_page) {
  element_ = std::move(ssr_page->element_);
  element_->SetAttributeHolder(this);
}

}  // namespace tasm
}  // namespace lynx
