// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/react/fiber/list_element.h"

#include <string>
#include <vector>

#include "tasm/list_component_info.h"
#include "tasm/template_assembler.h"
namespace lynx {
namespace tasm {

ListElement::ListElement(ElementManager* manager, const lepus::String& tag,
                         const lepus::Value& component_at_index,
                         const lepus::Value& enqueue_component)
    : FiberElement(manager, tag),
      component_at_index_(component_at_index),
      enqueue_component_(enqueue_component) {}

void ListElement::OnNodeAdded(FiberElement* child) {
  // List's child should not be flatten.
  child->set_config_flatten(false);
  // List's child should not be layout only.
  child->MarkCanBeLayoutOnly(false);
}

int32_t ListElement::ComponentAtIndex(uint32_t index, int64_t operationId,
                                      bool enable_reuse_notification) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ListElement::ComponentAtIndex");

  std::vector<lepus::Value> args;
  args.emplace_back(base::scoped_refptr<ListElement>(this));
  args.emplace_back(impl_id());
  args.emplace_back(index);
  args.emplace_back(operationId);

  lepus::Value value = tasm_->context(tasm::DEFAULT_ENTRY_NAME)
                           ->CallWithClosure(component_at_index_, args);

  return static_cast<int32_t>(value.Number());
}

void ListElement::EnqueueComponent(int32_t sign) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ListElement::EnqueueComponent");

  std::vector<lepus::Value> args;
  args.emplace_back(base::scoped_refptr<ListElement>(this));
  args.emplace_back(impl_id());
  args.emplace_back(sign);
  tasm_->context(tasm::DEFAULT_ENTRY_NAME)
      ->CallWithClosure(enqueue_component_, args);
}

void ListElement::UpdateCallbacks(const lepus::Value& component_at_index,
                                  const lepus::Value& enqueue_component) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ListElement::UpdateCallbacks");

  component_at_index_ = component_at_index;
  enqueue_component_ = enqueue_component;
}
void ListElement::SetAttributeInternal(const lepus::String& key,
                                       const lepus::Value& value) {
  FiberElement::SetAttributeInternal(key, value);

  if (key.IsEqual("column-count")) {
    // layout node should use column-count to compute width.
    element_manager_->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kColumnCount, value);
  }
}

}  // namespace tasm
}  // namespace lynx
