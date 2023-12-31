// Copyright 2021 The Vmsdk Authors. All rights reserved.
#include "jsb/module/module_delegate_impl.h"

#include "jsb/runtime/js_runtime.h"

namespace vmsdk {
namespace piper {
std::string GenerateErrorMessage(const std::string &module,
                                 const std::string &method,
                                 const std::string &error) {
  auto message = std::string{"In module: "}.append(module);
  message.append(" method: ").append(method);
  message.append(" ").append(error);
  return message;
}

int64_t ModuleDelegateImpl::RegisterJSCallbackFunction(Napi::Function func) {
  if (runtime_delegate_ == nullptr) {
    return piper::ModuleCallback::kInvalidCallbackId;
  }
  auto runtime = runtime_delegate_->GetJSRuntime();
  if (runtime != nullptr) {
    int64_t index = ++callback_id_index_;
    callbacks_.emplace(index, std::move(func));
    return index;
  } else {
    return piper::ModuleCallback::kInvalidCallbackId;
  }
}

// maybe destruct on non-JSThread, by iOS block
ModuleDelegateImpl::~ModuleDelegateImpl() {
  is_running_ = false;
  VLOGD("ModuleDelegateImpl::~ModuleDelegateImpl()");
}

void ModuleDelegateImpl::Terminate() {
  VLOGD("ModuleDelegateImpl::Terminate()");
  is_running_ = false;
  ClearJSCallbackTasks();
  callbacks_.clear();
  runtime_delegate_->Terminate();
  runtime_delegate_ = nullptr;
}

// Must call on JSThread
// Clear non-executed tasks before JSRuntime delete.
// Avoid use-after-delete issue
void ModuleDelegateImpl::ClearJSCallbackTasks() {
  auto runtime = runtime_delegate_->GetJSRuntime();
  if (runtime != nullptr) {
    runtime->RemoveTaskByGroupId((uintptr_t)this);
  }
}

// Maybe called on non-JSThread
void ModuleDelegateImpl::CallJSCallback(
    const std::shared_ptr<piper::ModuleCallback> &callback,
    int64_t id_to_delete) {
  if (!is_running_ || runtime_delegate_ == nullptr) {
    VLOGE("ModuleDelegateImpl::CallJSCallback, runtime_delegate_=nullptr");
    return;
  }
  auto runtime = runtime_delegate_->GetJSRuntime();
  if (runtime != nullptr) {
    auto closure = general::Bind(
        [this, callback, id_to_delete]() {
          this->CallJSCallbackInner(callback, id_to_delete);
        },
        (uintptr_t)this);

    runtime->RunNowOrPostTask(closure);
  }
}

// Must call on JSThread
void ModuleDelegateImpl::CallJSCallbackInner(
    const std::shared_ptr<piper::ModuleCallback> &callback,
    int64_t id_to_delete) {
  if (!is_running_ || runtime_delegate_ == nullptr) {
    VLOGE("ModuleDelegateImpl::CallJSCallbackInner, runtime_delegate_=nullptr");
    return;
  }
  auto runtime = runtime_delegate_->GetJSRuntime();
  if (runtime == nullptr) {
    VLOGE("ModuleDelegateImpl::CallJSCallbackInner, GetJSRuntime == nullptr");
    return;
  }

  if (id_to_delete != piper::ModuleCallback::kInvalidCallbackId) {
    callbacks_.erase(id_to_delete);
  }

  if (callback == nullptr || callback->callback_id() <= 0 ||
      callbacks_.size() == 0) {
    return;
  }

  auto iterator = callbacks_.find(callback->callback_id());
  if (iterator == callbacks_.end()) {
    return;
  }

  auto jsExecutor = runtime->getJSExecutor();
  if (jsExecutor != nullptr) {
    jsExecutor->invokeCallback(callback, &iterator->second);
    callbacks_.erase(iterator);
  } else {
    VLOGE("ModuleDelegateImpl::CallJSCallbackInner, jsExecutor == nullptr");
  }
}

void ModuleDelegateImpl::OnErrorOccurred(int32_t error_code,
                                         const std::string &module,
                                         const std::string &method,
                                         const std::string &message) {
  std::string msg = GenerateErrorMessage(module, method, message);
  if (runtime_delegate_ == nullptr) {
    VLOGE("ModuleDelegateImpl::OnErrorOccurred, runtime_delegate_=nullptr");
    return;
  }
  runtime_delegate_->CallOnErrorCallback(msg);
}

void ModuleDelegateImpl::OnMethodInvoked(const std::string &module_name,
                                         const std::string &method_name,
                                         int32_t code) {
  if (runtime_delegate_ == nullptr) {
    VLOGE("ModuleDelegateImpl::OnMethodInvoked, runtime_delegate_=nullptr");
    return;
  }
  auto runtime = runtime_delegate_->GetJSRuntime();
  if (runtime != nullptr) {
    runtime->OnModuleMethodInvoked(module_name, method_name, code);
  }
}

void ModuleDelegateImpl::OnJSBridgeInvoked(const std::string &module_name,
                                           const std::string &method_name,
                                           const std::string &param_str) {
  // js_runtime_->OnJSBridgeInvoked(module_name, method_name, param_str);
}

#ifdef OS_ANDROID
void ModuleDelegateImpl::RunOnJSThread(std::function<void()> func) {
  if (runtime_delegate_ == nullptr) {
    VLOGE("ModuleDelegateImpl::RunOnJSThread, runtime_delegate_=nullptr");
    return;
  }
  auto runtime = runtime_delegate_->GetJSRuntime();
  if (runtime != nullptr) {
    runtime->RunNowOrPostTask(general::Bind([func]() { func(); }));
  }
}
#endif

}  // namespace piper
}  // namespace vmsdk
