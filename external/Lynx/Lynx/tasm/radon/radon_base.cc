// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/radon/radon_base.h"

#include <sstream>
#include <utility>

#include "base/log/logging.h"
#include "base/lynx_env.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "tasm/diff_algorithm.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/radon/node_selector.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_page.h"
#include "tasm/react/element.h"
#include "tasm/react/select_element_token.h"

namespace lynx {
namespace tasm {

constexpr const static char* kDefaultPageTag = "page";

RadonBase::RadonBase(RadonNodeType node_type, const lepus::String& tag_name,
                     RadonNodeIndexType node_index)
    : node_type_{node_type}, node_index_{node_index}, tag_name_{tag_name} {}

RadonBase::RadonBase(const RadonBase& node, PtrLookupMap& map)
    : radon_component_{node.radon_component_},
      node_type_{node.node_type_},
      node_index_{node.node_index_},
      tag_name_{node.tag_name_} {}

void RadonBase::AddChild(std::unique_ptr<RadonBase> child) {
  child->SetComponent(radon_component_);
  AddChildWithoutSetComponent(std::move(child));
}

void RadonBase::AddChildWithoutSetComponent(std::unique_ptr<RadonBase> child) {
  child->radon_parent_ = this;
  child->radon_previous_ = LastChild();
  if (!radon_children_.empty()) {
    LastChild()->radon_next_ = child.get();
  }
  radon_children_.push_back(std::move(child));
}

void RadonBase::AddSubTree(std::unique_ptr<RadonBase> child) {
  AddChildWithoutSetComponent(std::move(child));
}

std::unique_ptr<RadonBase> RadonBase::RemoveChild(RadonBase* child) {
  auto it = find_if(radon_children_.begin(), radon_children_.end(),
                    [child](std::unique_ptr<RadonBase>& pChild) {
                      return pChild.get() == child;
                    });
  if (it == radon_children_.end()) {
    return std::unique_ptr<RadonBase>(nullptr);
  }
  if (child->radon_previous_) {
    child->radon_previous_->radon_next_ = child->radon_next_;
  }
  if (child->radon_next_) {
    child->radon_next_->radon_previous_ = child->radon_previous_;
  }
  auto deleted_child = std::move(*it);
  radon_children_.erase(it);
  return deleted_child;
}

void RadonBase::ClearChildrenRecursivelyInPostOrder() RADON_DIFF_ONLY {
  for (auto& child : radon_children_) {
    if (child) {
      child->ClearChildrenRecursivelyInPostOrder();
    }
  }
  radon_children_.clear();
}

void RadonBase::OnComponentRemovedInPostOrder() {
  for (auto& child : radon_children_) {
    if (child) {
      child->OnComponentRemovedInPostOrder();
    }
  }
}

void RadonBase::SetComponent(RadonComponent* component) {
  radon_component_ = component;
}

void RadonBase::PushDynamicNode(RadonBase* node) RADON_ONLY {
  dynamic_nodes_.push_back(node);
}

RadonBase* RadonBase::GetDynamicNode(RadonNodeIndexType index,
                                     RadonNodeIndexType node_index) RADON_ONLY {
  if (index >= dynamic_nodes_.size()) {
    LOGF("GetDynamicNode overflow. node_index "
         << node_index << " index: " << index
         << " dynamic_nodes_.size(): " << dynamic_nodes_.size());
  }
  auto* node = dynamic_nodes_[index];
  if (node->node_index_ != node_index) {
    LOGF("GetDynamicNode indices not equal. target node index "
         << node_index << " but got: " << node->node_index_);
  }
  return node;
}

void RadonBase::Dispatch(const DispatchOption& option) {
  DispatchSelf(option);
  DispatchSubTree(option);
}

void RadonBase::DispatchSelf(const DispatchOption& option) {}

void RadonBase::DispatchSubTree(const DispatchOption& option) {
  EXEC_EXPR_FOR_INSPECTOR(
      DispatchOptionObserverForInspector observer(option, this));
  if (dispatched_ && option.class_transmit_.IsEmpty() &&
      !option.css_variable_changed_ && !option.global_properties_changed_ &&
      !option.ssr_hydrating_) {
    DispatchDynamicChildren(option);
  } else {
    DispatchChildren(option);
  }
  dispatched_ = true;
}

void RadonBase::DispatchDynamicChildren(const DispatchOption& option)
    RADON_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonBase::Dynamic",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  for (auto* dynamic_node : dynamic_nodes_) {
    dynamic_node->Dispatch(option);
  }
}

void RadonBase::DispatchChildren(const DispatchOption& option) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DispatchChildren",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  for (auto& child : radon_children_) {
    child->Dispatch(option);
  }
}

void RadonBase::DispatchForDiff(const DispatchOption& option) RADON_DIFF_ONLY {
  DispatchSelf(option);
  DispatchChildrenForDiff(option);
  dispatched_ = true;
}

void RadonBase::DispatchChildrenForDiff(const DispatchOption& option)
    RADON_DIFF_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DispatchChildrenForDiff",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  EXEC_EXPR_FOR_INSPECTOR(
      DispatchOptionObserverForInspector observer(option, this));
  for (auto& child : radon_children_) {
    child->DispatchForDiff(option);
  }
}

// Radon Element Structure

void RadonBase::ResetElementRecursively() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonBase::ResetElementRecursively",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  dispatched_ = false;
  for (auto& node : radon_children_) {
    node->ResetElementRecursively();
  }
}

void RadonBase::WillRemoveNode() {
  if (will_remove_node_has_been_called_) {
    return;
  }
  will_remove_node_has_been_called_ = true;
  for (auto& node : radon_children_) {
    if (node) {
      node->WillRemoveNode();
    }
  }
}

void RadonBase::RemoveElementFromParent() {
  for (auto& node : radon_children_) {
    node->RemoveElementFromParent();
  }
}

bool RadonBase::GetDevtoolFlag() {
  RadonNode* root = root_node();
  return root && root->page_proxy_->element_manager()->GetDevtoolFlag() &&
         root->page_proxy_->element_manager()->IsDomTreeEnabled();
}

RadonElement* RadonBase::PreviousSiblingElement() {
  if (radon_previous_) {
    auto* element = radon_previous_->LastNoFixedElement();
    if (element) {
      return element;
    }
    return radon_previous_->PreviousSiblingElement();
  }
  // radon_previous == nullptr
  if (radon_parent_) {
    if (radon_parent_->NeedsElement()) {
      return nullptr;
    }
    return radon_parent_->PreviousSiblingElement();
  }
  return nullptr;
}

RadonElement* RadonBase::LastNoFixedElement() const {
  if (NeedsElement()) {
    // issue: #4954
    // When the element is the first layer child of the root page, should just
    // return this element no matter it is fixed or not. Otherwise if the
    // element is fixed, we may insert next element in a wrong index.
    if (element() && radon_parent_->IsRadonPage()) {
      return element();
    }
    if (element() && !element()->is_fixed_) {
      return element();
    }
    return nullptr;
  }
  for (auto it = radon_children_.rbegin(); it != radon_children_.rend(); it++) {
    RadonElement* element = nullptr;
    if ((*it)->NeedsElement()) {
      element = (*it)->element();
    } else {
      element = (*it)->LastNoFixedElement();
    }
    if (element != nullptr && !element->is_fixed_) {
      return element;
    }
  }
  return nullptr;
}

RadonPage* RadonBase::root_node() {
  if (root_node_ == nullptr) {
    RadonBase* node = this;
    while (node->Parent() != nullptr) {
      node = node->Parent();
    }
    if (node->IsRadonPage()) {
      root_node_ = static_cast<RadonPage*>(node);
    }
  }
  return root_node_;
}

RadonElement* RadonBase::GetRootElement() {
  if (root_element_ == nullptr) {
    RadonPage* radon_page = root_node();
    if (!radon_page->page_proxy_->GetPageElementEnabled()) {
      root_element_ = radon_page->element();
    } else if (!radon_page->radon_children_.empty() &&
               radon_page->radon_children_.front()->tag_name_.IsEqual(
                   kDefaultPageTag)) {
      // if page_element enabled, the root_element should be the first child of
      // RadonPage.
      root_element_ = radon_page->radon_children_.front()->element();
    }
  }
  return root_element_;
}

RadonElement* RadonBase::ParentElement() {
  auto* parent = radon_parent_;
  while (parent) {
    if (parent->NeedsElement()) {
      return parent->element();
    }
    parent = parent->radon_parent_;
  }
  return nullptr;
}

RadonBase* RadonBase::LastChild() {
  if (radon_children_.empty()) {
    return nullptr;
  } else {
    return radon_children_.back().get();
  }
}

void RadonBase::Visit(bool including_self,
                      const base::MoveOnlyClosure<bool, RadonBase*>& visitor) {
  bool visit_children = true;
  if (including_self) {
    visit_children = visitor(this);
  }
  if (!visit_children) return;
  for (auto& child : radon_children_) {
    child->Visit(true, visitor);
  }
}

#ifdef ENABLE_TEST_DUMP
rapidjson::Value RadonBase::DumpToJSON(rapidjson::Document& doc) {
  rapidjson::Document::AllocatorType& allocator = doc.GetAllocator();
  rapidjson::Value value;
  value.SetObject();

  value.AddMember("Type", RadonNodeTypeStrings[NodeType() + 1], allocator);
  value.AddMember("Tag", tag_name_.str(), allocator);
  if (!radon_component_->name().empty()) {
    value.AddMember("Radon Component", radon_component_->name().str(),
                    allocator);
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
#endif

bool RadonBase::SetLynxKey(const lepus::String& key,
                           const lepus::Value& value) RADON_DIFF_ONLY {
  if (key.IsEqual(kLynxKey)) {
    lynx_key_ = value;
    return true;
  }
  return false;
}

void RadonBase::LightDiffForStyle(RadonBaseVector& origin_radon_children,
                                  const DispatchOption& option)
    RADON_DIFF_ONLY {
#if ENABLE_HMR
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonBase::RadonStyleDiff",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  uint32_t index = 0;

  // update style of evert component
  while (index < origin_radon_children.size()) {
    auto& radon_child = origin_radon_children[index];
    radon_child->ReApplyStyle(option);
    radon_child->LightDiffForStyle(radon_children_, option);
    ++index;
  }
#endif
}

void RadonBase::RadonMyersDiff(RadonBaseVector& old_radon_children,
                               const DispatchOption& option) RADON_DIFF_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonBase::RadonMyersDiff",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  auto& new_radon_children = radon_children_;
  auto can_reuse_node = [](const std::unique_ptr<RadonBase>& lhs,
                           const std::unique_ptr<RadonBase>& rhs) {
    return lhs->CanBeReusedBy(rhs.get());
  };
  myers_diff::DiffResultBase actions;

  actions = myers_diff::MyersDiffWithoutUpdate(
      old_radon_children.begin(), old_radon_children.end(),
      new_radon_children.begin(), new_radon_children.end(), can_reuse_node);

  LynxWarning(option.need_diff_ ||
                  (actions.removals_.empty() && actions.insertions_.empty()),
              LYNX_ERROR_CODE_HYDRATE_RESULT_DEVIATE_FROM_SSR_RESULT,
              "Dom structure deviates from SSR result after hydration.");

  uint32_t old_index = 0, new_index = 0;
  uint32_t actions_removals_index = 0, actions_insertions_index = 0;

  if (actions.removals_.size() > 0 || actions.insertions_.size() > 0) {
    option.has_patched_ = true;
  }

  while (new_index < new_radon_children.size() ||
         old_index < old_radon_children.size()) {
    // remove radon node
    if (actions_removals_index < actions.removals_.size() &&
        static_cast<uint32_t>(actions.removals_[actions_removals_index]) ==
            old_index) {
      // here we just modify ElementTree, no need to modify RadonTree because
      // RadonTree would be modified correctly later.
      old_radon_children[old_index]->WillRemoveNode();
      old_radon_children[old_index]->RemoveElementFromParent();
      ++old_index;
      ++actions_removals_index;
      // insert radon node
    } else if (actions_insertions_index < actions.insertions_.size() &&
               static_cast<uint32_t>(
                   actions.insertions_[actions_insertions_index]) ==
                   new_index) {
      new_radon_children[new_index]->DispatchForDiff(option);
      ++new_index;
      ++actions_insertions_index;
      // diff radon node with same node_index
    } else if (new_index < new_radon_children.size() &&
               old_index < old_radon_children.size()) {
      DCHECK(new_radon_children[new_index]->node_index_ ==
             old_radon_children[old_index]->node_index_);
      auto& new_radon_child = new_radon_children[new_index];
      auto& old_radon_child = old_radon_children[old_index];
      new_radon_child->SwapElement(old_radon_child, option);
      new_radon_child->RadonDiffChildren(old_radon_child, option);
      ++new_index;
      ++old_index;
    } else {
      LOGF("RadonMyersDiff fatal.");
    }
  }
  if (!option.only_swap_element_) {
    // diff finished, handle old radon tree
    // just destruct the radon tree if this radon tree is not reusable.
    for (auto& old_child : old_radon_children) {
      old_child->WillRemoveNode();
    }
    for (auto& old_child : old_radon_children) {
      old_child->ClearChildrenRecursivelyInPostOrder();
    }
    old_radon_children.clear();
  }
}

void RadonBase::RadonDiffChildren(
    const std::unique_ptr<RadonBase>& old_radon_child,
    const DispatchOption& option) RADON_DIFF_ONLY {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonBase::RadonDiffChildren",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  RadonMyersDiff(old_radon_child->radon_children_, option);
}

void RadonBase::NeedModifySubTreeComponent(RadonComponent* const target) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonBase::ModifySubTreeComponent",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });
  ModifySubTreeComponent(target);
}

void RadonBase::ModifySubTreeComponent(RadonComponent* const target) {
  // iteratively set this and this's children's radon_component_ to target
  if (!target) {
    return;
  }
  radon_component_ = target;
  for (auto& child : radon_children_) {
    child->ModifySubTreeComponent(target);
  }
}

bool RadonBase::CanBeReusedBy(const RadonBase* const radon_base) const {
  return node_index_ == radon_base->node_index_ &&
         node_type_ == radon_base->node_type_ &&
         tag_name_ == radon_base->tag_name_ &&
         lynx_key_ == radon_base->lynx_key_;
}

int32_t RadonBase::IndexInSiblings() const {
  if (Parent() == nullptr) {
    return 0;
  }

  if (NodeType() == kRadonPlug) {
    return Parent()->IndexInSiblings();
  }
  if (Parent()->NodeType() == kRadonPlug) {
    auto slot = Parent()->Parent();
    return slot->IndexInSiblings();
  }

  auto& siblings = Parent()->radon_children_;
  auto iter =
      std::find_if(siblings.begin(), siblings.end(),
                   [id = ImplId()](auto& ptr) { return ptr->ImplId() == id; });
  return static_cast<int32_t>(std::distance(siblings.begin(), iter));
}

}  // namespace tasm
}  // namespace lynx
