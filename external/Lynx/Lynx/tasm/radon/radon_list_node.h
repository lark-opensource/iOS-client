// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RADON_RADON_LIST_NODE_H_
#define LYNX_TASM_RADON_RADON_LIST_NODE_H_

#include "tasm/radon/radon_list_base.h"

namespace lynx {
namespace tasm {

class RadonComponent;
class TemplateAssembler;
class RadonListNode : public RadonListBase {
 public:
  // called by lepus function _CreateListRadonNode
  RadonListNode(lepus::Context* context, PageProxy* page_proxy,
                TemplateAssembler* tasm, uint32_t node_index);
  RadonListNode(const RadonListNode& node, PtrLookupMap& map);
  void DidUpdateInLepus();

 protected:
  bool DiffIncrementally(const DispatchOption&) override;

 private:
  void SyncComponentExtraInfo(RadonComponent* comp, uint32_t index,
                              int64_t operation_id) override;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_RADON_LIST_NODE_H_
