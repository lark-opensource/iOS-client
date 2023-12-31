// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/radon/radon_if_node.h"

#include <utility>

#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_page.h"

namespace lynx {
namespace tasm {

RadonIfNode::RadonIfNode(RadonNodeIndexType node_index)
    : RadonBase{kRadonIfNode, "if", node_index} {}

RadonIfNode::RadonIfNode(const RadonIfNode& node, PtrLookupMap& map)
    : RadonBase{node, map} {
  for (const auto& node : node.nodes_) {
    AddChild(radon_factory::Copy(*node, map));
  }
}

void RadonIfNode::Dispatch(const DispatchOption& option) {
  DispatchChildren(option);
}

void RadonIfNode::AddChild(std::unique_ptr<RadonBase> child) {
  child->radon_parent_ = this;
  child->radon_previous_ = LastChild();
  child->SetComponent(radon_component_);
  if (!radon_children_.empty()) {
    LastChild()->radon_next_ = child.get();
  }
  nodes_.push_back(std::move(child));
}

RadonBase* RadonIfNode::UpdateIfIndex(int32_t ifIndex) {
  RadonBase* active_node = ActiveNode();
  if (static_cast<uint32_t>(ifIndex) == active_index_ && active_node) {
    return active_node;
  }
  if (!radon_children_.empty() &&
      active_index_ != static_cast<uint32_t>(ifIndex)) {
    auto pChild = RemoveChild(radon_children_.front().get());
    pChild->RemoveElementFromParent();
    EXEC_EXPR_FOR_INSPECTOR({
      if (GetDevtoolFlag()) {
        NotifyPlugElementRemoved(pChild);
      }
    });
  }
  active_index_ = ifIndex;
  if (active_index_ >= 0 && active_index_ < nodes_.size()) {
    nodes_[active_index_]->radon_component_ = radon_component_;
    this->RadonBase::AddChild(radon_factory::Copy(*nodes_[active_index_]));
  }
  return ActiveNode();
}

#if ENABLE_INSPECTOR
void RadonIfNode::NotifyPlugElementRemoved(std::unique_ptr<RadonBase>& node) {
  if (node->NodeType() == kRadonPlug) {
    if (node->radon_children_.size() == 0) {
      return;
    }
    for (auto& child : node->radon_children_) {
      if (child->NeedsElement()) {
        auto* raw_node = static_cast<RadonNode*>(child.get());
        raw_node->NotifyElementNodeRemoved();
      }
    }
  }
  for (auto& child : node->radon_children_) {
    NotifyPlugElementRemoved(child);
  }
}
#endif  // ENABLE_INSPECTOR

}  // namespace tasm
}  // namespace lynx
