#pragma once

#include <string>

#include "jsb/module/vmsdk_module_binding.h"
#include "jsb/module/vmsdk_module_callback.h"
#include "jsb/module/vmsdk_module_manager.h"
#include "jsb/runtime/js_executor.h"

namespace vmsdk {

namespace runtime {

class JSExecutorWraper : public JSExecutor {
 public:
  JSExecutorWraper(
      const JS_ENGINE_TYPE engine_type,
      const std::shared_ptr<piper::VmsdkModuleManager> &module_manager,
      const bool is_multi_thread);
  virtual ~JSExecutorWraper();

  virtual void Init() override{};
  virtual void Destroy() override;

  std::shared_ptr<vmsdk::runtime::NAPIRuntime> GetJSRuntime() override;
  void invokeCallback(std::shared_ptr<piper::ModuleCallback> callback,
                      piper::ModuleCallbackFunctionHolder *holder) override;
  void createNativeAppInstance() override;

 protected:
  std::shared_ptr<piper::VmsdkModuleManager> module_manager_;
  std::shared_ptr<vmsdk::runtime::NAPIRuntime> js_runtime_;

  JSExecutorWraper(const JSExecutorWraper &) = delete;
  JSExecutorWraper &operator=(const JSExecutorWraper &) = delete;
};

}  // namespace runtime
}  // namespace vmsdk
