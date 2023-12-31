// Copyright 2019 The Lynx Authors. All rights reserved.
#include "css/css_style_sheet_manager.h"

#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "css/css_fragment.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace tasm {
// app.ttss
static uint32_t sBasicCSSId = 0;

SharedCSSFragment* CSSStyleSheetManager::GetCSSStyleSheetForComponent(
    int32_t id) {
  // Actually this function can be fully replaced by
  // GetCSSStyleSheet(id). And component_fragments_ can be deleted.
  // No need to import self.
  return GetCSSStyleSheet(id);
}

SharedCSSFragment* CSSStyleSheetManager::GetCSSStyleSheetForPage(int32_t id) {
  if (enable_new_import_rule_) {
    return GetCSSStyleSheet(id);
  }
  auto it = page_fragments_.find(id);
  if (it != page_fragments_.end() && it->second->is_baked()) {
    return it->second.get();
  }
  auto fragment = std::make_unique<SharedCSSFragment>(id);
  fragment->ImportOtherFragment(GetCSSStyleSheet(sBasicCSSId));
  if (id > 0) {
    fragment->ImportOtherFragment(GetCSSStyleSheet(id));
  }
  fragment->MarkBaked();
  auto ptr = fragment.get();
  page_fragments_[id] = std::move(fragment);
  return ptr;
}

SharedCSSFragment* CSSStyleSheetManager::GetCSSStyleSheet(int32_t id) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "CSSStyleSheetManager::GetCSSStyleSheet");
  SharedCSSFragment* fragment = GetSharedCSSFragmentById(id);
  if (fragment == nullptr) {
    if (delegate_ && delegate_->DecodeCSSFragmentById(id)) {
      fragment = GetSharedCSSFragmentById(id);
    } else {
      return nullptr;
    }
  }
  if (fragment == nullptr || fragment->is_baked()) {
    return fragment;
  }
  FlatDependentCSS(fragment);
  return fragment;
}

void CSSStyleSheetManager::FlatDependentCSS(SharedCSSFragment* fragment) {
  auto dependents = fragment->dependent_ids();
  for (auto id = dependents.rbegin(); id != dependents.rend(); id++) {
    auto dependent_fragment = GetCSSStyleSheet(*id);
    fragment->ImportOtherFragment(dependent_fragment);
  }
  fragment->MarkBaked();
}

void CSSStyleSheetManager::ResetPageAndComponentFragments() {
#if ENABLE_HMR
  page_fragments_.clear();
#endif
}

}  // namespace tasm
}  // namespace lynx
