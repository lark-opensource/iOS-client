// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/air/air_element/air_radon_if_element.h"

namespace lynx {
namespace tasm {

AirRadonIfElement::AirRadonIfElement(ElementManager* manager, uint32_t lepus_id,
                                     int32_t id)
    : AirBlockElement(manager, kAirRadonIf, kAirRadonIfTag, lepus_id, id) {}

AirRadonIfElement::AirRadonIfElement(const AirRadonIfElement& node,
                                     AirPtrLookUpMap& map)
    : AirBlockElement{node, map} {
  AirElement* node_parent = const_cast<AirRadonIfElement&>(node).parent();
  if (map.find(node_parent) != map.end()) {
    set_parent(map[node_parent]);
  }
  for (const auto& child : node.air_children_) {
    InsertNode(air_factory::Copy(*child, map).get());
  }
}

void AirRadonIfElement::InsertNode(AirElement* child, bool from_virtual_child) {
  if (!from_virtual_child) {
    InsertAirNode(child);
  }
  if (parent_ && !inserted_) {
    // Just need to insert one element, the real element needs to be inserted
    // will be inserted in update phase.
    inserted_ = true;
    active_index_ = 0;
    parent_->InsertNode(child, true);
  }
}

AirElement* AirRadonIfElement::UpdateIfIndex(int32_t ifIndex) {
  AirElement* active_node = ActiveNode();
  if (static_cast<uint32_t>(ifIndex) == active_index_ && active_node) {
    // No change in condition branch, do nothing.
    return active_node;
  }
  AirElement* last_non_virtual_node = nullptr;
  if (active_index_ != static_cast<uint32_t>(ifIndex) &&
      !air_children_.empty()) {
    if (active_node && parent_) {
      last_non_virtual_node = active_node->LastNonVirtualNode();
    }
  }
  active_index_ = static_cast<uint32_t>(ifIndex);
  if (active_index_ >= 0 && active_index_ < air_children_.size()) {
    if (parent_) {
      if (last_non_virtual_node) {
        // The condition branch has changed and the element corresponding to
        // previous condition branch is valid. Find the index of previous
        // element and insert the new element after it.
        int index = parent_->IndexOf(last_non_virtual_node);
        parent_->InsertNodeAfterIndex(air_children_[active_index_].get(),
                                      index);
      } else {
        // No child was inserted into parent element, need to find the correct
        // index to insert.
        int index_sum = 0;
        AirElement* tmp = this;
        AirElement* tmp_parent = tmp->air_parent_;
        while (tmp != parent_) {
          // tmp!= parent_ means tmp is a virtual node
          int index = tmp_parent->IndexOfAirChild(tmp);
          for (auto i = 0; i < index; ++i) {
            index_sum +=
                tmp_parent->air_children_[i]->NonVirtualNodeCountInParent();
          }
          tmp = tmp_parent;
          tmp_parent = tmp->air_parent_;
        }
        if (index_sum >= 0 &&
            index_sum <= static_cast<int>(parent_->GetChildCount())) {
          index_sum -= 1;
          parent_->InsertNodeAfterIndex(air_children_[active_index_].get(),
                                        index_sum);
        }
      }
      if (active_node) {
        // New element has been inserted, remove the previous one.
        parent_->RemoveNode(active_node, false);
      }
    }
  } else if (active_node) {
    // The new condition branch has no corresponding element, just remove the
    // previous one.
    parent_->RemoveNode(active_node, false);
  }
  return ActiveNode();
}

uint32_t AirRadonIfElement::NonVirtualNodeCountInParent() {
  if (!air_children_.empty()) {
    if (active_index_ < air_children_.size()) {
      return air_children_[active_index_]->NonVirtualNodeCountInParent();
    }
  }
  return 0;
}

}  // namespace tasm
}  // namespace lynx
