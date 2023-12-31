// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_OBSERVER_INSPECTOR_RUNTIME_OBSERVER_H_
#define LYNX_INSPECTOR_OBSERVER_INSPECTOR_RUNTIME_OBSERVER_H_

#include <memory>

#include "jsbridge/java_script_debugger.h"
#include "jsbridge/runtime/lynx_runtime_observer.h"

namespace lynx {

namespace devtool {

class InspectorManager;

class InspectorRuntimeObserver : public runtime::LynxRuntimeObserver {
 public:
  explicit InspectorRuntimeObserver(
      const std::shared_ptr<InspectorManager>& manager);
  ~InspectorRuntimeObserver() override = default;

  intptr_t CreateJavascriptDebugger() override;
  void OnMessagePosted(intptr_t message) override;
  intptr_t CreateConsolePostMan() override;
  intptr_t CreateInspectorRuntimeManager() override;
  void OnJsTaskRunnerReady(
      const fml::RefPtr<fml::TaskRunner>& js_runner) override;
  void OnWorkerTaskRunnerReady(
      const fml::RefPtr<fml::TaskRunner>& js_runner) override;

  const std::weak_ptr<piper::JavaScriptDebugger>& GetJSDebugger() override {
    return debugger_;
  };
  void InitWorker(const std::shared_ptr<piper::Runtime>& runtime) override;
  void OnWorkerDestroy() override;

 private:
  std::weak_ptr<piper::JavaScriptDebugger> debugger_;
  std::weak_ptr<InspectorManager> manager_;
};
}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_OBSERVER_INSPECTOR_RUNTIME_OBSERVER_H_
