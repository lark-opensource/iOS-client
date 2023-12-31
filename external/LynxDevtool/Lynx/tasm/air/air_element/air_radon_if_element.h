// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_AIR_AIR_ELEMENT_AIR_RADON_IF_ELEMENT_H_
#define LYNX_TASM_AIR_AIR_ELEMENT_AIR_RADON_IF_ELEMENT_H_

#include <memory>
#include <vector>

#include "tasm/air/air_element/air_block_element.h"

namespace lynx {
namespace tasm {

class AirRadonIfElement : public AirBlockElement {
 public:
  AirRadonIfElement(ElementManager* manager, uint32_t lepus_id,
                    int32_t id = -1);
  AirRadonIfElement(const AirRadonIfElement& node, AirPtrLookUpMap& map);

  bool is_if() const override { return true; }
  void InsertNode(AirElement* child, bool from_virtual_child = false) override;

  AirElement* UpdateIfIndex(int32_t ifIndex);

  uint32_t NonVirtualNodeCountInParent() override;

  AirElement* ActiveNode() {
    return active_index_ < air_children_.size()
               ? air_children_[active_index_].get()
               : nullptr;
  }

 private:
  uint32_t active_index_ = -1;
  bool inserted_{false};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_AIR_AIR_ELEMENT_AIR_RADON_IF_ELEMENT_H_
