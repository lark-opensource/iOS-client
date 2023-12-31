// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RADON_RADON_LIST_BASE_H_
#define LYNX_TASM_RADON_RADON_LIST_BASE_H_

#include <string>
#include <vector>

#include "lepus/table.h"
#include "tasm/radon/radon_node.h"
#include "tasm/react/list_node.h"

namespace lynx {
namespace tasm {

class RadonComponent;
class TemplateAssembler;
class RadonListBase : public ListNode, public RadonNode {
 public:
  RadonListBase(lepus::Context* context, PageProxy* page_proxy,
                TemplateAssembler* tasm, uint32_t node_index);
  RadonListBase(const RadonListBase& node, PtrLookupMap& map);
  // called by lepus function _AppendRadonListComponentInfo
  void AppendComponentInfo(ListComponentInfo& info) override;
  void RemoveComponent(uint32_t sign) override;
  void RenderComponentAtIndex(uint32_t row, int64_t operationId = 0) override;
  void UpdateComponent(uint32_t sign, uint32_t row,
                       int64_t operationId = 0) override;

 protected:
  lepus::Context* context_;
  TemplateAssembler* tasm_;
  std::vector<ListComponentInfo> new_components_;
  void DispatchFirstTime() override;
  bool DiffListComponents();
  virtual void SyncComponentExtraInfo(RadonComponent* comp, uint32_t index,
                                      int64_t operation_id);
  RadonComponent* CreateComponentWithType(uint32_t index);

 private:
  bool HasComponent(const std::string& component_name,
                    const std::string& current_entry) override;
  RadonComponent* GetComponent(uint32_t sign);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_RADON_LIST_BASE_H_
