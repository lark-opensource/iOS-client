// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_OBSERVER_INSPECTOR_LEPUS_CONTEXT_OBSERVER_H_
#define LYNX_INSPECTOR_OBSERVER_INSPECTOR_LEPUS_CONTEXT_OBSERVER_H_

#include <memory>
#include <string>

#include "jsbridge/java_script_debugger.h"
#include "jsbridge/lepus_context_observer.h"

namespace lynx {
namespace devtool {
class InspectorManager;

class InspectorLepusContextObserver : public tasm::LepusContextObserver {
 public:
  explicit InspectorLepusContextObserver(
      const std::shared_ptr<InspectorManager>& manager);
  ~InspectorLepusContextObserver() override = default;

  intptr_t CreateJavascriptDebugger(const std::string& url) override;
  void OnConsoleMessage(const std::string& level,
                        const std::string& msg) override;

 private:
  std::weak_ptr<piper::JavaScriptDebugger> debugger_;
  std::weak_ptr<InspectorManager> manager_;
  bool need_post_console_ = false;
};
}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_OBSERVER_INSPECTOR_LEPUS_CONTEXT_OBSERVER_H_
