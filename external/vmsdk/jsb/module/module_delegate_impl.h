// Copyright 2021 The Vmsdk Authors. All rights reserved.

#ifndef MODULE_DELEGATE_IMPL_H
#define MODULE_DELEGATE_IMPL_H

#include <unordered_map>

#include "basic/log/logging.h"
#include "basic/task/callback.h"
#include "basic/timer/timer_node.h"
#include "jsb/module/module_delegate.h"
#include "jsb/runtime/runtime_delegate.h"

namespace vmsdk {
namespace piper {

class ModuleDelegateImpl : public piper::ModuleDelegate {
 public:
  explicit ModuleDelegateImpl(
      const std::shared_ptr<runtime::JSRuntimeDelegate> &runtime_delegate)
      : runtime_delegate_(runtime_delegate) {}
  ~ModuleDelegateImpl();

  ModuleDelegateImpl(const ModuleDelegateImpl &) = delete;
  ModuleDelegateImpl &operator=(const ModuleDelegateImpl &) = delete;
  ModuleDelegateImpl(ModuleDelegateImpl &&) = delete;
  ModuleDelegateImpl &operator=(ModuleDelegateImpl &&) = delete;

  int64_t RegisterJSCallbackFunction(Napi::Function func) override;
  void CallJSCallback(const std::shared_ptr<piper::ModuleCallback> &callback,
                      int64_t id_to_delete =
                          piper::ModuleCallback::kInvalidCallbackId) override;
  void OnErrorOccurred(int32_t error_code, const std::string &module,
                       const std::string &method,
                       const std::string &message) override;
  void OnMethodInvoked(const std::string &module_name,
                       const std::string &method_name, int32_t code) override;
  void OnJSBridgeInvoked(const std::string &module_name,
                         const std::string &method_name,
                         const std::string &param_str) override;
  void Terminate() override;

  bool IsRunning() override { return is_running_; }

#ifdef OS_ANDROID
  void RunOnJSThread(std::function<void()> func) override;
#endif

 private:
  void CallJSCallbackInner(
      const std::shared_ptr<piper::ModuleCallback> &callback,
      int64_t id_to_delete);

  void ClearJSCallbackTasks();

  std::shared_ptr<runtime::JSRuntimeDelegate> runtime_delegate_;
  std::unordered_map<int64_t, piper::ModuleCallbackFunctionHolder> callbacks_;
  int64_t callback_id_index_ = 0;
  std::atomic_bool is_running_{true};
};

}  // namespace piper
}  // namespace vmsdk

#endif  // MODULE_DELEGATE_IMPL_H
