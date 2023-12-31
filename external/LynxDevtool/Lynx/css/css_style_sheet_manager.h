// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_CSS_STYLE_SHEET_MANAGER_H_
#define LYNX_CSS_CSS_STYLE_SHEET_MANAGER_H_

#include <memory>
#include <mutex>
#include <unordered_map>
#include <unordered_set>
#include <utility>

#include "css/shared_css_fragment.h"
#include "tasm/moulds.h"
#include "tasm/template_binary.h"

namespace lynx {
namespace tasm {

class CSSStyleSheetDelegate {
 public:
  CSSStyleSheetDelegate() = default;
  virtual ~CSSStyleSheetDelegate() = default;
  virtual bool DecodeCSSFragmentById(int32_t fragmentId) = 0;
};

class CSSStyleSheetManager {
 public:
  CSSStyleSheetManager(CSSStyleSheetDelegate* delegate) : delegate_(delegate){};
  typedef std::unordered_map<int32_t, std::unique_ptr<SharedCSSFragment>>
      CSSFragmentMap;
  SharedCSSFragment* GetCSSStyleSheetForComponent(int32_t id);
  SharedCSSFragment* GetCSSStyleSheetForPage(int32_t id);
  const CSSFragmentMap& raw_fragments() const { return raw_fragments_; }
  std::atomic_bool GetStopThread() const { return stop_thread_; }
  void ResetPageAndComponentFragments();

  void SetThreadStopFlag(bool stop_thread) { stop_thread_ = stop_thread; }

  SharedCSSFragment* GetSharedCSSFragmentById(int32_t id) {
    std::lock_guard<std::mutex> g_lock(fragment_mutex_);
    decoded_fragment_.emplace(id);
    if (raw_fragments_.find(id) != raw_fragments_.end()) {
      return raw_fragments_[id].get();
    } else {
      return nullptr;
    }
  }

  bool IsSharedCSSFragmentDecoded(int32_t id) {
    std::lock_guard<std::mutex> g_lock(fragment_mutex_);
    if (decoded_fragment_.find(id) != decoded_fragment_.end()) {
      return true;
    }
    return false;
  }

  void AddSharedCSSFragment(std::unique_ptr<SharedCSSFragment> fragment) {
    std::lock_guard<std::mutex> g_lock(fragment_mutex_);
    if (raw_fragments_.find(fragment->id()) != raw_fragments_.end()) {
      return;
    }
    raw_fragments_[fragment->id()] = std::move(fragment);
  }

  void SetEnableNewImportRule(bool enable) { enable_new_import_rule_ = enable; }

 private:
  friend class TemplateBinaryReader;
  friend class TemplateBinaryReaderSSR;
  friend class LynxBinaryBaseCSSReader;
  friend class LynxBinaryReader;

  SharedCSSFragment* GetCSSStyleSheet(int32_t id);
  void FlatDependentCSS(SharedCSSFragment* fragment);

  CSSRoute route_;
  CSSFragmentMap page_fragments_;
  CSSFragmentMap raw_fragments_;
  CSSStyleSheetDelegate* delegate_ = nullptr;
  std::unordered_set<int> decoded_fragment_;
  volatile std::atomic_bool stop_thread_ = false;
  std::mutex fragment_mutex_;
  bool enable_new_import_rule_ = false;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_STYLE_SHEET_MANAGER_H_
