// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RADON_RADON_DIFF_LIST_NODE2_H_
#define LYNX_TASM_RADON_RADON_DIFF_LIST_NODE2_H_

#include <memory>
#include <vector>

#include "tasm/radon/radon_list_base.h"

namespace lynx {
namespace tasm {

class RadonComponent;
class TemplateAssembler;
class ListReusePool;

class RadonDiffListNode2 : public RadonListBase {
 public:
  // called by lepus function _CreateVirtualListNode
  RadonDiffListNode2(lepus::Context* context, PageProxy* page_proxy,
                     TemplateAssembler* tasm, uint32_t node_index);

  int32_t ComponentAtIndex(uint32_t index, int64_t operationId,
                           bool enable_reuse_notification) final;
  void EnqueueComponent(int32_t sign) final;

 protected:
  void DispatchFirstTime() override;
  void RadonDiffChildren(const std::unique_ptr<RadonBase>& old_radon_child,
                         const DispatchOption& option) override;
  bool ShouldFlush(const std::unique_ptr<RadonBase>& old_radon_child,
                   const DispatchOption& option) override;

 private:
  void SyncComponentExtraInfo(RadonComponent* comp, uint32_t index,
                              int64_t operation_id) override;
  // Handle a new created component, update the component and then render
  // recursively.
  void UpdateAndRenderNewComponent(RadonComponent* component,
                                   const lepus::Value& incoming_property,
                                   const lepus::Value& incoming_data);
  // Handle a component which created before, handle lifecycle but not element.
  void UpdateOldComponent(RadonComponent* component,
                          ListComponentInfo& component_info);
  // Do extra steps to ensure that any item-key isn't empty or duplicate
  void FilterComponents(std::vector<ListComponentInfo>& components,
                        TemplateAssembler* tasm) override;
  void CheckItemKeys(std::vector<ListComponentInfo>& components);

  void SetupListInfo(bool list_updated);

  // New Arch
  std::unique_ptr<ListReusePool> reuse_pool_;

  // Option Handler
  // The databinding process of list sub-component is triggered by platform
  // list, hence we need to store some dispatch_option in the
  // list_component_info when we update the list. After the platform notify
  // radon to update the sub-component, we can reuse these dispatchOptions.
  void TransmitDispatchOptionFromOldComponentToNewComponent(
      ListComponentInfo& old_component, ListComponentInfo& new_component);
  void TransmitDispatchOptionFromListNodeToListComponent(
      const DispatchOption& option);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_RADON_DIFF_LIST_NODE2_H_
