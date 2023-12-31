// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/air/air_element/air_if_element.h"

namespace lynx {
namespace tasm {

AirIfElement::AirIfElement(ElementManager *manager, uint32_t lepus_id,
                           int32_t id)
    : AirBlockElement(manager, kAirIf, kAirIfTag, lepus_id, id) {}

AirIfElement::AirIfElement(const AirIfElement &node, AirPtrLookUpMap &map)
    : AirBlockElement{node, map} {
  AirElement *node_parent = const_cast<AirIfElement &>(node).parent();
  if (map.find(node_parent) != map.end()) {
    set_parent(map[node_parent]);
  }
  for (const auto &child : node.air_children_) {
    InsertNode(air_factory::Copy(*child, map).get());
  }
}

void AirIfElement::UpdateIfIndex(int32_t ifIndex) {
  if (static_cast<uint32_t>(ifIndex) == active_index_ &&
      !air_children_.empty()) {
    return;
  }

  RemoveAllNodes();
  active_index_ = ifIndex;
}

uint32_t AirIfElement::NonVirtualNodeCountInParent() {
  uint32_t sum = 0;
  for (auto node : air_children_) {
    sum += node->NonVirtualNodeCountInParent();
  }
  return sum;
}

}  // namespace tasm
}  // namespace lynx
