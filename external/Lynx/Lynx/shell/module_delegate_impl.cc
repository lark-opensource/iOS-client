// Copyright 2021 The Lynx Authors. All rights reserved.

#include "shell/module_delegate_impl.h"

#include <utility>

namespace lynx {
namespace shell {

namespace {

std::string GenerateErrorMessage(const std::string& module,
                                 const std::string& method,
                                 const std::string& error) {
  auto message = std::string{"In module: "}.append(module);
  message.append(" method: ").append(method);
  message.append(" ").append(error);
  return message;
}

}  // namespace

int64_t ModuleDelegateImpl::RegisterJSCallbackFunction(piper::Function func) {
  // TODO(heshan):now not support copyable lambda for std::function, cannot use
  // ActSync, tricky... can ensure call on js thread
  auto* runtime = actor_->Impl();
  if (runtime == nullptr) {
    return piper::ModuleCallback::kInvalidCallbackId;
  }
  return runtime->RegisterJSCallbackFunction(std::move(func));
}

void ModuleDelegateImpl::CallJSCallback(
    const std::shared_ptr<piper::ModuleCallback>& callback,
    int64_t id_to_delete) {
  actor_->Act([callback, id_to_delete](auto& runtime) {
    runtime->CallJSCallback(callback, id_to_delete);
  });
}

void ModuleDelegateImpl::OnErrorOccurred(int32_t error_code,
                                         const std::string& module,
                                         const std::string& method,
                                         const std::string& message) {
  actor_->Act([error_code, module, method, message](auto& runtime) {
    runtime->OnErrorOccurred(error_code,
                             GenerateErrorMessage(module, method, message));
  });
}

void ModuleDelegateImpl::OnMethodInvoked(const std::string& module_name,
                                         const std::string& method_name,
                                         int32_t code) {
  actor_->Act([module_name, method_name, code](auto& runtime) {
    runtime->OnModuleMethodInvoked(module_name, method_name, code);
  });
}

void ModuleDelegateImpl::FlushJSBTiming(piper::NativeModuleInfo timing) {
  actor_->Act([timing = std::move(timing)](auto& runtime) mutable {
    runtime->FlushJSBTiming(std::move(timing));
  });
}

#if defined(OS_ANDROID) || defined(OS_WIN) || defined(OS_OSX)
void ModuleDelegateImpl::RunOnJSThread(base::closure func) {
  actor_->Act([func = std::move(func)](auto& runtime) { func(); });
}
#endif

}  // namespace shell
}  // namespace lynx
