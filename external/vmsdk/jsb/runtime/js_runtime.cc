#include "jsb/runtime/js_runtime.h"

#include "basic/log/logging.h"
#include "basic/task/callback.h"
#include "basic/vmsdk_exception_common.h"
#include "jsb/module/module_delegate_impl.h"

namespace vmsdk {
namespace runtime {

bool JSRuntimeUtils::CheckAndGetExceptionMsg(Napi::Env env, std::string &msg) {
  if (env == nullptr) {
    return false;
  }
  // auto &exception = general::ExceptionStorage::GetInstance().GetException();
  std::unique_ptr<general::VmsdkException> exception = nullptr;
  if (!env.IsExceptionPending() && !exception) return false;

  // get js exception
  if (env.IsExceptionPending()) {
    Napi::Error error = env.GetAndClearPendingException().As<Napi::Error>();
    Napi::Value message = error.Get("message");
    if (message.IsString()) {
      msg = "Message: " + message.ToString().Utf8Value();
    }

    Napi::Value stack = error.Get("stack");
    if (stack.IsString()) {
      msg = msg + ", Stack: " + stack.ToString().Utf8Value();
    }
  }

  // get java exception
  if (exception) {
    msg = "   Java Exception: " + exception->error_message_;
    general::ExceptionStorage::GetInstance().Reset();
  }
  return true;
}

// include js unhandled rejection exception
bool JSRuntimeUtils::CheckAndGetException2(Napi::Env env, std::string &msg) {
  if (env == nullptr) return false;

  // get js exception
  if (env.IsExceptionPending()) {
    Napi::Error error = env.GetAndClearPendingException().As<Napi::Error>();
    Napi::Value message = error.Get("message");
    if (message.IsString()) {
      msg = "Message: " + message.ToString().Utf8Value();
    }

    Napi::Value stack = error.Get("stack");
    if (stack.IsString()) {
      msg = msg + ", Stack: " + stack.ToString().Utf8Value();
    }
  }

  // get js unhandled rejection exception
  Napi::Value rejection_exception = env.GetUnhandledRecjectionException();
  if (rejection_exception.IsString()) {
    msg += rejection_exception.ToString().Utf8Value();
  }

  return (msg.size() != 0);
}

JSRuntime::JSRuntime(std::shared_ptr<TaskRunner> js_runner) {
  js_runner_ = js_runner;
}

JSRuntime::~JSRuntime() {
  TurnOff();
  if (js_executor_ != nullptr) {
    js_executor_->Destroy();
    js_executor_ = nullptr;
  }
}

// must run on JS_Thread
void JSRuntime::Init(
    const std::shared_ptr<vmsdk::piper::VmsdkModuleManager> &module_manager,
    JS_ENGINE_TYPE jsengine_type, bool is_multi_thread) {
  js_executor_ = std::make_shared<vmsdk::runtime::JSExecutorWraper>(
      jsengine_type, module_manager, is_multi_thread);
  napi_runtime_ = js_executor_->GetJSRuntime();
  napi_runtime_->Init();
}

void JSRuntime::RegisterNativeModuleProxy() {
  if (js_executor_ != nullptr) js_executor_->createNativeAppInstance();
}

void JSRuntime::RunNowOrPostTask(general::Closure *task) {
  js_runner_->RunNowOrPostTask(task);
}

void JSRuntime::PostTask(general::Closure *task) { js_runner_->PostTask(task); }

void JSRuntime::PostTaskAtFront(general::Closure *task) {
  js_runner_->PostTaskAtFront(task);
}

void JSRuntime::RemoveTaskByGroupId(uintptr_t group_Id) {
  js_runner_->RemoveTaskByGroupId(group_Id);
}

std::shared_ptr<general::TimerNode> JSRuntime::PostDelayedTask(
    general::Closure *task, int32_t delayed_time) {
  return js_runner_->PostDelayedTask(task, delayed_time);
}

void JSRuntime::RemoveTask(const std::shared_ptr<general::TimerNode> &task) {
  js_runner_->RemoveTask(task);
}

void JSRuntime::OnModuleMethodInvoked(const std::string &module,
                                      const std::string &method, int32_t code) {
  //   delegate_->OnModuleMethodInvoked(module, method, code);
}

void JSRuntime::EvaluateScript(const std::string &script) {
  Napi::Env napiEnv = napi_runtime_->Env();
  Napi::HandleScope scp(napiEnv);
  Napi::ContextScope contextScope(napiEnv);

  napiEnv.RunScript(script.c_str());
  // process exception
  std::string msg;
  if (JSRuntimeUtils::CheckAndGetExceptionMsg(napiEnv, msg)) {
    VLOGE("Run script exception: %s\n", msg.c_str());
  }
}

}  // namespace runtime
}  // namespace vmsdk
