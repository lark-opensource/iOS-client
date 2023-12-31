// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/radon/radon_for_node.h"

#include <utility>
#include <vector>

#include "lepus/array.h"
#include "lepus/table.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_factory.h"

namespace lynx {
namespace tasm {

RadonForNode::RadonForNode(uint32_t node_index)
    : RadonBase{kRadonForNode, "for", node_index} {}

RadonForNode::RadonForNode(const RadonForNode& node, PtrLookupMap& map)
    : RadonBase{node, map} {
  if (node.node_) {
    AddChild(radon_factory::Copy(*(node.node_), map));
  }
}

void RadonForNode::AddChild(std::unique_ptr<RadonBase> child) {
  node_ = std::move(child);
  node_->SetComponent(component());
}

void RadonForNode::Dispatch(const DispatchOption& option) {
  DispatchChildren(option);
}

RadonBase* RadonForNode::GetForNodeChild(uint32_t index) {
  DCHECK(index < children_count_);
  return radon_children_[index].get();
}

void RadonForNode::UpdateChildrenCount(uint32_t count) {
  for (uint32_t i = 0; i < count; i++) {
    if (node_ && radon_children_.size() <= i) {
      node_->radon_component_ = radon_component_;
      this->RadonNode::AddChild(radon_factory::Copy(*node_));
    }
  }

  auto remove_range = std::vector<RadonBase*>{};
  remove_range.reserve(radon_children_.size() - count);
  std::transform(
      radon_children_.begin() + count, radon_children_.end(),
      std::back_inserter(remove_range),
      [](std::unique_ptr<RadonBase>& pChild) { return pChild.get(); });

  for (auto* child : remove_range) {
    auto pChild = this->RadonBase::RemoveChild(child);
    pChild->RemoveElementFromParent();
  }
  children_count_ = count;
}

}  // namespace tasm
}  // namespace lynx
