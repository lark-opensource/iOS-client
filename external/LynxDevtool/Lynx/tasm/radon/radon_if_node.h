// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_RADON_RADON_IF_NODE_H_
#define LYNX_TASM_RADON_RADON_IF_NODE_H_

#include <memory>

#include "tasm/radon/radon_node.h"

namespace lynx {
namespace tasm {

constexpr int32_t kRadonIfNodeInvalidActiveIndex = -1;

class RadonIfNode : public RadonBase {
 public:
  RadonIfNode(RadonNodeIndexType node_index);
  RadonIfNode(const RadonIfNode& node, PtrLookupMap& map);
  ~RadonIfNode() override = default;

  RadonBase* UpdateIfIndex(int32_t ifIndex);
  void AddChild(std::unique_ptr<RadonBase> child) final;

  void Dispatch(const DispatchOption&) final;

 private:
  void InsertChildNode();
  uint32_t active_index_ = kRadonIfNodeInvalidActiveIndex;
  RadonBaseVector nodes_ = {};
  RadonBase* ActiveNode() {
    return radon_children_.size() > 0 ? radon_children_[0].get() : nullptr;
  }
#if ENABLE_INSPECTOR
  void NotifyPlugElementRemoved(std::unique_ptr<RadonBase>& node);
#endif  // ENABLE_INSPECTOR
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_RADON_IF_NODE_H_
