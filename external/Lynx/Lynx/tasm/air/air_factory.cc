// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/air/air_factory.h"

#include "tasm/air/air_element/air_block_element.h"
#include "tasm/air/air_element/air_component_element.h"
#include "tasm/air/air_element/air_element.h"
#include "tasm/air/air_element/air_for_element.h"
#include "tasm/air/air_element/air_if_element.h"
#include "tasm/air/air_element/air_radon_if_element.h"
#include "tasm/react/element_manager.h"

namespace lynx {
namespace tasm {
namespace air_factory {
namespace {
std::shared_ptr<AirElement> MakeAirElement(const AirElement& node,
                                           AirPtrLookUpMap& map) {
  std::shared_ptr<AirElement> element = nullptr;
  AirElementType element_type = node.GetElementType();
  switch (element_type) {
    case kAirBlock:
      element = std::make_shared<AirBlockElement>(
          static_cast<const AirBlockElement&>(node), map);
      break;
    case kAirIf:
      element = std::make_shared<AirIfElement>(
          static_cast<const AirIfElement&>(node), map);
      break;
    case kAirRadonIf:
      element = std::make_shared<AirRadonIfElement>(
          static_cast<const AirRadonIfElement&>(node), map);
      break;
    case kAirFor:
      element = std::make_shared<AirForElement>(
          static_cast<const AirForElement&>(node), map);
      break;
    case kAirComponent:
      element = std::make_shared<AirComponentElement>(
          static_cast<const AirComponentElement&>(node), map);
      break;
    case kAirNormal:
      element = std::make_shared<AirElement>(node, map);
      break;
    default:
      LOGE("air_factory called with uncopyable AirElement type:"
           << element_type);
      break;
  }
  const_cast<AirElement&>(node).element_manager()->air_node_manager()->Record(
      element->impl_id(), element);
  const_cast<AirElement&>(node)
      .element_manager()
      ->air_node_manager()
      ->RecordForLepusId(element->GetLepusId(),
                         static_cast<uint64_t>(element->GetLepusId()),
                         AirLepusRef::Create(element));
  return element;
}

void CopyAndAddToParent(const AirElement& node, AirElement& parent,
                        AirPtrLookUpMap& map) {
  auto copy = MakeAirElement(node, map);
  auto& copyNode = *copy;
  map[&const_cast<AirElement&>(node)] = copy.get();

  parent.InsertNode(copy.get());

  AirElementType type = node.GetElementType();
  if (!(type == kAirIf || type == kAirRadonIf || type == kAirFor)) {
    for (const auto& child : node.air_children()) {
      CopyAndAddToParent(*child, copyNode, map);
    }
  }

  for (auto* dynamic_node : node.dynamic_nodes()) {
    if (map.find(dynamic_node) != map.end()) {
      copyNode.PushDynamicNode(map[dynamic_node]);
    }
  }
}
}  // namespace

std::shared_ptr<AirElement> Copy(const AirElement& node, AirPtrLookUpMap& map) {
  auto copy = MakeAirElement(node, map);
  map[&const_cast<AirElement&>(node)] = copy.get();

  for (const auto& child : node.air_children()) {
    CopyAndAddToParent(*child, *copy, map);
  }

  for (auto* dynamic_node : node.dynamic_nodes()) {
    if (map.find(dynamic_node) != map.end()) {
      copy->PushDynamicNode(map[dynamic_node]);
    }
  }

  return copy;
}

std::shared_ptr<AirElement> Copy(const AirElement& node) {
  auto map = AirPtrLookUpMap{};
  return Copy(node, map);
}
}  // namespace air_factory
}  // namespace tasm
}  // namespace lynx
