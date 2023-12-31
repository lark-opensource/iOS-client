// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_MODULE_DELEGATE_IMPL_H_
#define LYNX_SHELL_MODULE_DELEGATE_IMPL_H_

#include <memory>
#include <string>

#include "base/closure.h"
#include "jsbridge/module/module_delegate.h"
#include "jsbridge/runtime/lynx_runtime.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace shell {

class ModuleDelegateImpl : public piper::ModuleDelegate {
 public:
  explicit ModuleDelegateImpl(
      const std::shared_ptr<LynxActor<runtime::LynxRuntime>>& actor)
      : actor_(actor) {}
  ~ModuleDelegateImpl() override = default;

  ModuleDelegateImpl(const ModuleDelegateImpl&) = delete;
  ModuleDelegateImpl& operator=(const ModuleDelegateImpl&) = delete;
  ModuleDelegateImpl(ModuleDelegateImpl&&) = delete;
  ModuleDelegateImpl& operator=(ModuleDelegateImpl&&) = delete;

  int64_t RegisterJSCallbackFunction(piper::Function func) override;
  void CallJSCallback(const std::shared_ptr<piper::ModuleCallback>& callback,
                      int64_t id_to_delete =
                          piper::ModuleCallback::kInvalidCallbackId) override;
  void OnErrorOccurred(int32_t error_code, const std::string& module,
                       const std::string& method,
                       const std::string& message) override;
  void OnMethodInvoked(const std::string& module_name,
                       const std::string& method_name, int32_t code) override;

  void FlushJSBTiming(piper::NativeModuleInfo timing) override;

#if defined(OS_ANDROID) || defined(OS_WIN) || defined(OS_OSX)
  void RunOnJSThread(base::closure func) override;
#endif

 private:
  std::shared_ptr<LynxActor<runtime::LynxRuntime>> actor_;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_MODULE_DELEGATE_IMPL_H_
