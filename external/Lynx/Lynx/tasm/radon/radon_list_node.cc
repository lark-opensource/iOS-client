#include "tasm/radon/radon_list_node.h"

#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/page_proxy.h"
#include "tasm/radon/radon_component.h"
#include "tasm/radon/radon_page.h"
#include "tasm/template_assembler.h"

namespace lynx {
namespace tasm {

RadonListNode::RadonListNode(const RadonListNode& node, PtrLookupMap& map)
    : RadonListBase{node, map} {}

// TODO: 1. check component name valid.  2. read diffable attribute.
RadonListNode::RadonListNode(lepus::Context* context, PageProxy* page_proxy,
                             TemplateAssembler* tasm, uint32_t node_index)
    : RadonListBase(context, page_proxy, tasm, node_index) {}

void RadonListNode::SyncComponentExtraInfo(RadonComponent* comp, uint32_t index,
                                           int64_t operation_id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "RadonListNode::SyncComponentExtraInfo",
              [this](lynx::perfetto::EventContext ctx) {
                UpdateTraceDebugInfo(ctx.event());
              });

  RadonListBase::SyncComponentExtraInfo(comp, index, operation_id);
  auto* comp_info = &components_.at(index);
  const lepus::Value& props = comp_info->properties_;
  DispatchOption option(page_proxy_);
  if (!comp->dispatched()) {
    comp->UpdateRadonComponentWithoutDispatch(
        BaseComponent::RenderType::UpdateByNative, props, comp_info->data_);
    comp->CreateComponentInLepus();
    comp->UpdateComponentInLepus();
    comp->Dispatch(option);
  } else {
    comp->UpdateRadonComponent(BaseComponent::RenderType::UpdateByNative, props,
                               comp_info->data_, option);
    root_node()->proxy_->OnComponentPropertyChanged(comp);
  }

  PipelineOptions pipeline_options;
  pipeline_options.operation_id = operation_id;

  if (page_proxy_->IsRadonDiff()) {
    page_proxy_->element_manager()->OnPatchFinishFromRadon(option.has_patched_,
                                                           pipeline_options);
  } else {
    /*
     * in radon mode, hsa_patched_ flag may be changed in update function (tt:if
     * and tt:for). But we can't modify has_patched_ flag in update function
     * now. Here we call OnPatchFinishInner manually to avoid some bad case.
     */
    page_proxy_->element_manager()->OnPatchFinishInner(pipeline_options);
  }
}

bool RadonListNode::DiffIncrementally(const DispatchOption& option) {
  platform_info_.diffable_list_result_ = true;
  return RadonNode::DiffIncrementally(option) ||
         !platform_info_.update_actions_.Empty();
}

void RadonListNode::DidUpdateInLepus() { DiffListComponents(); }

}  // namespace tasm
}  // namespace lynx
