// Copyright 2021 The Vmsdk Authors. All rights reserved.

#ifndef MODULE_MODULE_DELEGATE_H
#define MODULE_MODULE_DELEGATE_H

#include "jsb/module/vmsdk_module_callback.h"

namespace vmsdk {
namespace piper {

class ModuleDelegate {
 public:
  ModuleDelegate() = default;
  virtual ~ModuleDelegate() = default;

  ModuleDelegate(const ModuleDelegate &) = delete;
  ModuleDelegate &operator=(const ModuleDelegate &) = delete;
  ModuleDelegate(ModuleDelegate &&) = delete;
  ModuleDelegate &operator=(ModuleDelegate &&) = delete;

  virtual int64_t RegisterJSCallbackFunction(Napi::Function func) = 0;
  virtual void CallJSCallback(
      const std::shared_ptr<ModuleCallback> &callback,
      int64_t id_to_delete = ModuleCallback::kInvalidCallbackId) = 0;
  virtual void OnErrorOccurred(int32_t error_code, const std::string &module,
                               const std::string &method,
                               const std::string &message) = 0;
  virtual void OnMethodInvoked(const std::string &module_name,
                               const std::string &method_name,
                               int32_t code) = 0;
  virtual void OnJSBridgeInvoked(const std::string &module_name,
                                 const std::string &method_name,
                                 const std::string &param_str) = 0;
  virtual void Terminate() = 0;
  virtual bool IsRunning() = 0;
// for android, MethodInvoker will handle a set of promise
// on js thread, have no choice but provide this method
#ifdef OS_ANDROID
  virtual void RunOnJSThread(std::function<void()> func) = 0;
#endif
};

}  // namespace piper
}  // namespace vmsdk

#endif  // MODULE_MODULE_DELEGATE_H
