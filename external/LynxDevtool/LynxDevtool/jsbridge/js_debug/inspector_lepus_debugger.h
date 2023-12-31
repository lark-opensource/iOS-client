// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_JS_DEBUG_INSPECTOR_LEPUS_DEBUGGER_H
#define LYNX_INSPECTOR_JS_DEBUG_INSPECTOR_LEPUS_DEBUGGER_H

#include <string>

#include "base/closure.h"
#include "jsbridge/java_script_debugger.h"

namespace lynx {

namespace devtool {
class InspectorClient;

class InspectorLepusDebugger : public piper::JavaScriptDebugger {
 public:
  InspectorLepusDebugger();

  void SetEnableNeeded(bool enable);
  bool IsEnableNeeded() { return enable_needed_; }

  void InitWithRuntime(const std::shared_ptr<piper::Runtime>& runtime,
                       const std::string& group_id,
                       bool is_worker = false) override {}
  void InitWithContext(const std::shared_ptr<lepus::Context>& context) override;
  void OnDestroy(bool is_worker = false) override;
  void StopDebug() override;
  DebugType GetDebugType() override { return lepus_debug; }

  void SetTargetNum(int num);

  int GetTargetNum() { return target_num_; }

  void SetDebugInfo(const std::string& info);
  const std::string& GetDebugInfo() { return debug_info_; }

  virtual void ResponseFromJSEngine(const std::string& message) = 0;
  void DispatchMessageToJSEngine(const std::string& message);
  void DispatchDebuggerDisableMessage();

  static void RunOnMainThread(lynx::base::closure closure);

 private:
  std::shared_ptr<devtool::InspectorClient> inspector_client_sp_;
  int target_num_;
  std::string debug_info_;
  bool enable_needed_ = false;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_JS_DEBUG_INSPECTOR_LEPUS_DEBUGGER_H
