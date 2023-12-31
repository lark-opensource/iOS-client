// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_MODULE_MODULE_DELEGATE_H_
#define LYNX_JSBRIDGE_MODULE_MODULE_DELEGATE_H_

#include <memory>
#include <string>

#include "base/closure.h"
#include "jsbridge/module/lynx_module_callback.h"

namespace lynx {
namespace piper {
struct NativeModuleInfo;

class ModuleDelegate {
 public:
  ModuleDelegate() = default;
  virtual ~ModuleDelegate() = default;

  ModuleDelegate(const ModuleDelegate&) = delete;
  ModuleDelegate& operator=(const ModuleDelegate&) = delete;
  ModuleDelegate(ModuleDelegate&&) = delete;
  ModuleDelegate& operator=(ModuleDelegate&&) = delete;

  virtual int64_t RegisterJSCallbackFunction(Function func) = 0;
  // ret just is post to js thread or not
  virtual void CallJSCallback(
      const std::shared_ptr<ModuleCallback>& callback,
      int64_t id_to_delete = ModuleCallback::kInvalidCallbackId) = 0;
  virtual void OnErrorOccurred(int32_t error_code, const std::string& module,
                               const std::string& method,
                               const std::string& message) = 0;
  virtual void OnMethodInvoked(const std::string& module_name,
                               const std::string& method_name,
                               int32_t code) = 0;
  virtual void FlushJSBTiming(piper::NativeModuleInfo timing) = 0;
// for android, MethodInvoker will handle a set of promise
// on js thread, have no choice but provide this method
#if defined(OS_ANDROID) || defined(OS_WIN) || defined(OS_OSX)
  virtual void RunOnJSThread(base::closure func) = 0;
#endif
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_MODULE_MODULE_DELEGATE_H_
