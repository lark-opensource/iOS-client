// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/air/air_element/air_for_element.h"

#include <algorithm>

#include "tasm/air/air_element/air_page_element.h"
#include "tasm/react/element_manager.h"

namespace lynx {
namespace tasm {

AirForElement::AirForElement(ElementManager* manager, uint32_t lepus_id,
                             int32_t id)
    : AirBlockElement(manager, kAirFor, kAirForTag, lepus_id, id) {}

AirForElement::AirForElement(const AirForElement& node, AirPtrLookUpMap& map)
    : AirBlockElement{node, map} {
  AirElement* node_parent = const_cast<AirForElement&>(node).parent();
  if (map.find(node_parent) != map.end()) {
    set_parent(map[node_parent]);
  }
  if (node.node_) {
    InsertNode(air_factory::Copy(*node.node_, map).get());
  }
}

std::vector<base::scoped_refptr<AirLepusRef>> AirForElement::GetForNodeChild(
    uint32_t lepus_id) {
  return air_element_manager_->air_node_manager()->GetAllNodesForLepusId(
      lepus_id);
}

void AirForElement::InsertNode(AirElement* child, bool from_virtual_child) {
  if (!from_virtual_child) {
    InsertAirNode(child);
  }
  // save the first child, copy the first child when update in radon mode
  if (!node_) {
    node_ = air_element_manager_->air_node_manager()->Get(child->impl_id());
  }
  if (parent_) {
    parent_->InsertNode(child, true);
  }
}

void AirForElement::RemoveAllNodes(bool destroy) {
  if (parent_) {
    for (auto child : air_children_) {
      parent_->RemoveNode(child.get(), destroy);
    }
  }
  if (destroy) {
    air_children_.erase(air_children_.begin(), air_children_.end());
    node_.reset();
  }
}

void AirForElement::UpdateChildrenCount(uint32_t count) {
  if (!parent_) {
    return;
  }
  bool is_radon = air_element_manager_->AirRoot()->IsRadon();
  // Copy node is only needed in radon mode.
  for (uint32_t i = 0; i < count; ++i) {
    if (node_ && air_children_.size() <= i && is_radon) {
      auto copy_node = air_factory::Copy(*node_);
      InsertAirNode(copy_node.get());
      // If node_ is valid, the size of air_children_ must be greater than or
      // equal to 1. Find the correct index to insert in parent.
      AirElement* last_non_virtual_node =
          air_children_[i - 1]->LastNonVirtualNode();
      int index = parent_->IndexOf(last_non_virtual_node);
      if (index >= 0 && index < static_cast<int>(parent_->GetChildCount())) {
        parent_->InsertNodeAfterIndex(copy_node.get(), index);
      }
    }
  }
  if (air_children_.size() < count) {
    return;
  }
  auto remove_range = std::vector<AirElement*>{};
  remove_range.reserve(air_children_.size() - count);
  std::transform(
      air_children_.begin() + count, air_children_.end(),
      std::back_inserter(remove_range),
      [](const std::shared_ptr<AirElement>& pChild) { return pChild.get(); });

  // The updated count may be zero, which means no items exists in tt:for.
  // But we should always keep node_ valid to ensure that if the count changed
  // again, AirForElement has valid child element to copy.
  for (auto* child : remove_range) {
    parent_->RemoveNode(child, child != node_.get());
  }
  air_children_.erase(
      std::remove_if(air_children_.begin() + count, air_children_.end(),
                     [&](const std::shared_ptr<AirElement>& child) {
                       return child != node_;
                     }),
      air_children_.end());
}

AirElement* AirForElement::GetForNodeChildWithIndex(uint32_t index) {
  DCHECK(index < air_children_.size());
  return air_children_[index].get();
}

uint32_t AirForElement::NonVirtualNodeCountInParent() {
  uint32_t sum = 0;
  for (auto child : air_children_) {
    sum += child->NonVirtualNodeCountInParent();
  }
  return sum;
}

}  // namespace tasm
}  // namespace lynx
