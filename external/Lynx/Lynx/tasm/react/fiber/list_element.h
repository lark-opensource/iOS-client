// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_FIBER_LIST_ELEMENT_H_
#define LYNX_TASM_REACT_FIBER_LIST_ELEMENT_H_

#include <string>
#include <vector>

#include "tasm/react/fiber/fiber_element.h"
#include "tasm/react/list_node.h"

namespace lynx {
namespace tasm {

class TemplateAssembler;

using ListActions = std::vector<int32_t>;

class ListElement : public FiberElement, public tasm::ListNode {
 public:
  ListElement(ElementManager* manager, const lepus::String& tag,
              const lepus::Value& component_at_index,
              const lepus::Value& enqueue_component);
  ~ListElement() override = default;
  void set_tasm(TemplateAssembler* tasm) { tasm_ = tasm; }

  bool is_list() const override { return true; }

  void AppendComponentInfo(tasm::ListComponentInfo& info) override {}
  void RemoveComponent(uint32_t sign) override {}
  void RenderComponentAtIndex(uint32_t row, int64_t operationId = 0) override {}
  void UpdateComponent(uint32_t sign, uint32_t row,
                       int64_t operationId = 0) override {}

  int32_t ComponentAtIndex(uint32_t index, int64_t operationId,
                           bool enable_reuse_notification) override;
  void EnqueueComponent(int32_t sign) override;

  void UpdateCallbacks(const lepus::Value& component_at_index,
                       const lepus::Value& enqueue_component);

 protected:
  void OnNodeAdded(FiberElement* child) override;
  void FilterComponents(std::vector<tasm::ListComponentInfo>& components,
                        tasm::TemplateAssembler* tasm) override {}
  bool HasComponent(const std::string& component_name,
                    const std::string& current_entry) override {
    return false;
  }
  void SetAttributeInternal(const lepus::String& key,
                            const lepus::Value& value) override;

 private:
  tasm::TemplateAssembler* tasm_{nullptr};
  lepus::Value component_at_index_{};
  lepus::Value enqueue_component_{};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_FIBER_LIST_ELEMENT_H_
