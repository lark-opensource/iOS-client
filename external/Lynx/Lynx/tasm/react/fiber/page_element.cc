// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/react/fiber/page_element.h"

#include "tasm/react/element_manager.h"
#include "tasm/template_assembler.h"

namespace lynx {
namespace tasm {

constexpr const static char* kDefaultPageTag = "page";
constexpr const static char* kDefaultPageName = "page";
constexpr const static char* kDefaultPagePath = "__PAGE_PATH";

PageElement::PageElement(ElementManager* manager,
                         const lepus::String& component_id, int32_t css_id)
    : ComponentElement(manager, component_id, css_id, tasm::DEFAULT_ENTRY_NAME,
                       kDefaultPageName, kDefaultPagePath, kDefaultPageTag) {
  manager->SetRootOnLayout(layout_node());
  manager->catalyzer()->set_root(this);
  manager->SetRoot(this);
  // make sure page's default overflow is hidden
  SetDefaultOverflow(false);
}

bool PageElement::FlushActionsAsRoot() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "PageElement::FlushActionsAsRoot");
  FiberElement::ActionOption flush_option;
  UpdateCurrentFlushOption(flush_option);
  FiberElement::FlushActions(flush_option);
  return flush_option.need_layout_;
}

}  // namespace tasm
}  // namespace lynx
