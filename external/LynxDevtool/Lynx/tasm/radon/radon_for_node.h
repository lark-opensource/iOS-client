// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_RADON_RADON_FOR_NODE_H_
#define LYNX_TASM_RADON_RADON_FOR_NODE_H_

#include <memory>
#include <set>

#include "tasm/radon/radon_node.h"

namespace lynx {
namespace tasm {

class RadonForNode : public RadonBase {
 public:
  RadonForNode(uint32_t node_index);
  RadonForNode(const RadonForNode& node, PtrLookupMap& map);
  ~RadonForNode() override = default;

  void AddChild(std::unique_ptr<RadonBase> child) final;
  void Dispatch(const DispatchOption&) final;

  void UpdateChildrenCount(uint32_t count);
  RadonBase* GetForNodeChild(uint32_t index);

 private:
  uint32_t children_count_ = 0;
  std::unique_ptr<RadonBase> node_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_RADON_FOR_NODE_H_
