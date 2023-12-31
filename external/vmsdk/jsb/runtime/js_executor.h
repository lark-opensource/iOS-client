#pragma once

#include <memory>
#include <string>

#include "jsb/module/vmsdk_module_callback.h"
#include "jsb/runtime/napi_runtime_wraper.h"
#include "napi_runtime.h"

namespace vmsdk {
namespace runtime {

class ModuleCallback;
class VmsdkModuleManager;
class ModuleCallbackFunctionHolder;

class JSExecutor : public std::enable_shared_from_this<JSExecutor> {
 public:
  JSExecutor(){};
  virtual ~JSExecutor() = default;
  virtual void Init() = 0;
  virtual void Destroy() = 0;
  virtual std::shared_ptr<vmsdk::runtime::NAPIRuntime> GetJSRuntime() = 0;

  virtual void invokeCallback(std::shared_ptr<piper::ModuleCallback> callback,
                              piper::ModuleCallbackFunctionHolder *holder) = 0;
  virtual void createNativeAppInstance() = 0;

 protected:
};

}  // namespace runtime
}  // namespace vmsdk
