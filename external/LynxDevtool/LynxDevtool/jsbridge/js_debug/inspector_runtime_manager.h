// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_JS_DEBUG_INSPECTOR_RUNTIME_MANAGER_H_
#define LYNX_INSPECTOR_JS_DEBUG_INSPECTOR_RUNTIME_MANAGER_H_

#include "jsbridge/js_debug/inspector_java_script_debugger.h"
#include "jsbridge/runtime/runtime_manager.h"

namespace lynx {
namespace runtime {

class InspectorRuntimeManager : public RuntimeManager {
 public:
  friend class RuntimeManager;
  using ReleaseCallback = std::function<void(const std::string& group_str)>;

  InspectorRuntimeManager() {}
  virtual std::shared_ptr<piper::Runtime> CreateJSRuntime(
      const std::string& group_id,
      std::shared_ptr<piper::JSIExceptionHandler> exception_handler,
      std::vector<std::pair<std::string, std::string>>& js_pre_sources,
      bool forceUseLightweightJSEngine,
      std::shared_ptr<piper::JSExecutor> executor, int64_t rt_id,
      bool ensure_console = false) override;

  // Deprecated, replaced by MakeJSRuntime.
  virtual std::shared_ptr<piper::Runtime> MakeRuntime(
      bool force_use_lightweight_js_engine) override {
    return nullptr;
  }

  std::shared_ptr<piper::Runtime> InitAppBrandRuntime(
      std::shared_ptr<piper::Runtime> app_brand_js_runtime,
      std::shared_ptr<piper::JSIExceptionHandler> exception_handler,
      std::vector<std::pair<std::string, std::string>>& js_pre_sources,
      std::shared_ptr<piper::JSExecutor> executor, int64_t rt_id,
      bool ensure_console) override;

  void SetReleaseCallback(devtool::DebugType type,
                          const ReleaseCallback& callback);

 private:
  virtual CreateJSContextResult CreateJSContext(
      std::shared_ptr<piper::Runtime>& rt, bool shared_vm) override;
  std::shared_ptr<piper::JSIContext> GetSharedJSContext(
      const std::string& group_id);
  void OnRelease(const std::string& group_id) override;
  std::shared_ptr<piper::Runtime> MakeJSRuntime(devtool::DebugType type);

  std::unordered_map<devtool::DebugType, ReleaseCallback> release_callback_;
  std::unordered_map<std::string, devtool::DebugType> group_to_engine_type_;
};

}  // namespace runtime
}  // namespace lynx

#endif  // #define LYNX_INSPECTOR_JS_DEBUG_INSPECTOR_RUNTIME_MANAGER_H_
