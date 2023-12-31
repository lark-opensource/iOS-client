// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/radon/radon_dispatch_option.h"

#include "base/lynx_env.h"
#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/page_proxy.h"
#include "tasm/radon/radon_base.h"
#include "tasm/react/element_manager.h"

namespace lynx {
namespace tasm {

DispatchOption::DispatchOption(PageProxy* page_proxy)
    : need_notify_devtool_(page_proxy->element_manager()->GetDevtoolFlag() &&
                           page_proxy->element_manager()->IsDomTreeEnabled()) {
  if (page_proxy->IsServerSideRendering() ||
      (page_proxy->HasSSRRadonPage() && !page_proxy->ReadyToHydrate())) {
    need_update_element_ = false;
  }
}

bool operator==(const ListComponentDispatchOption& lhs,
                const ListComponentDispatchOption& rhs) {
  return (lhs.global_properties_changed_ == rhs.global_properties_changed_) &&
         (lhs.css_variable_changed_ == rhs.css_variable_changed_) &&
         (lhs.force_diff_entire_tree_ == rhs.force_diff_entire_tree_) &&
         (lhs.use_new_component_data_ == rhs.use_new_component_data_) &&
         (lhs.refresh_lifecycle_ == rhs.refresh_lifecycle_);
}

bool operator!=(const ListComponentDispatchOption& lhs,
                const ListComponentDispatchOption& rhs) {
  return !(lhs == rhs);
}

void ListComponentDispatchOption::reset() {
  global_properties_changed_ = false;
  css_variable_changed_ = false;
  force_diff_entire_tree_ = false;
  use_new_component_data_ = false;
  refresh_lifecycle_ = false;
}

#if ENABLE_INSPECTOR
DispatchOptionObserverForInspector::DispatchOptionObserverForInspector(
    const DispatchOption& option, RadonBase* radon_base)
    : option_(option), radon_base_(radon_base) {
  if (option_.need_notify_devtool_ && !radon_base_->dispatched_ &&
      radon_base_->element()) {
    need_notify_devtool_ = true;
    const_cast<DispatchOption&>(option_).need_notify_devtool_ = false;
  }
}

DispatchOptionObserverForInspector::~DispatchOptionObserverForInspector() {
  if (radon_base_->create_plug_element_) {
    radon_base_->NotifyElementNodeAdded();
    radon_base_->create_plug_element_ = false;
  }
  if (need_notify_devtool_) {
    if (!radon_base_->GetRadonPlug()) {
      radon_base_->NotifyElementNodeAdded();
    }
    const_cast<DispatchOption&>(option_).need_notify_devtool_ = true;
  } else if (radon_base_->GetDevtoolFlag() && radon_base_->element() &&
             radon_base_->element()->is_fixed_ && !radon_base_->dispatched_) {
    radon_base_->NotifyElementNodeAdded();
  }
}
#endif  // ENABLE_INSPECTOR

}  // namespace tasm
}  // namespace lynx
