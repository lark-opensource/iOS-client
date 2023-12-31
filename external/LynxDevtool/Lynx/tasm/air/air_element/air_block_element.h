// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_AIR_AIR_ELEMENT_AIR_BLOCK_ELEMENT_H_
#define LYNX_TASM_AIR_AIR_ELEMENT_AIR_BLOCK_ELEMENT_H_

#include "tasm/air/air_element/air_element.h"

namespace lynx {
namespace tasm {

class AirBlockElement : public AirElement {
 public:
  AirBlockElement(ElementManager* manager, uint32_t lepus_id, int32_t id = -1);
  AirBlockElement(ElementManager* manager, AirElementType type,
                  const lepus::String& tag, uint32_t lepus_id, int32_t id = -1);
  AirBlockElement(const AirBlockElement& node, AirPtrLookUpMap& map);

  bool is_block() const override { return true; }
  void InsertNode(AirElement* child, bool from_virtual_child = false) override;
  void RemoveNode(AirElement* child, bool destroy = true) override;
  void RemoveAllNodes(bool destroy = true) override;

  uint32_t NonVirtualNodeCountInParent() override;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_AIR_AIR_ELEMENT_AIR_BLOCK_ELEMENT_H_
