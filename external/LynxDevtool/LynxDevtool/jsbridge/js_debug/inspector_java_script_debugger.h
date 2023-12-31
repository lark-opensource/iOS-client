// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_JS_DEBUG_INSPECTOR_JAVA_SCRIPT_DEBUGGER_H
#define LYNX_INSPECTOR_JS_DEBUG_INSPECTOR_JAVA_SCRIPT_DEBUGGER_H

#include <string>
#include <vector>

#include "base/closure.h"
#include "jsbridge/java_script_debugger.h"
#include "third_party/rapidjson/document.h"

namespace lynx {

namespace piper {
class JSExecutor;
}  // namespace piper

namespace devtool {
class InspectorClient;

class InspectorJavaScriptDebugger : public piper::JavaScriptDebugger {
 public:
  InspectorJavaScriptDebugger(DebugType debug_type);
  ~InspectorJavaScriptDebugger();

  void SetSharedVM(const std::string& group_name);
  void SetEnableNeeded(bool enable);
  void SetRuntimeEnableNeeded(bool enable);

  void InitWithRuntime(const std::shared_ptr<piper::Runtime>& runtime,
                       const std::string& group_id,
                       bool is_worker = false) override;
  void InitWithContext(
      const std::shared_ptr<lepus::Context>& context) override {}
  void OnDestroy(bool is_worker = false) override;
  void StopDebug() override;
  void SetInspectorManager(
      std::shared_ptr<devtool::InspectorManager> manager) override;
  DebugType GetDebugType() override { return debug_type_; }

  virtual bool ResponseFromJSEngine(const std::string& message) = 0;
  void RunOnJSThread(base::closure closure, bool is_worker = false);
  void DispatchMessageToJSEngine(const std::string& message);
  void DispatchDebuggerDisableMessage();
  void SetViewDestroyed(bool destroyed);

 private:
  std::shared_ptr<devtool::InspectorClient> inspector_client_sp_;
  std::shared_ptr<devtool::InspectorClient> worker_client_sp_;
  bool enable_needed_ = false;
  bool runtime_enable_needed_ = false;
  bool shared_vm_;
  int view_id_;
  std::weak_ptr<InspectorManager> manager_;
  DebugType debug_type_;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_JS_DEBUG_INSPECTOR_JAVA_SCRIPT_DEBUGGER_H
