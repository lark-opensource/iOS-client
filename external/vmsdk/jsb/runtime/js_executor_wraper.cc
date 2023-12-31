#include "jsb/runtime/js_executor_wraper.h"

#include "basic/log/logging.h"

namespace vmsdk {
namespace runtime {

JSExecutorWraper::JSExecutorWraper(
    const JS_ENGINE_TYPE engine_type,
    const std::shared_ptr<piper::VmsdkModuleManager> &module_manager,
    const bool is_multi_thread)
    : JSExecutor(), module_manager_(module_manager) {
  js_runtime_ = runtime::NAPIRuntimeFactory::getInstance()->createRuntime(
      engine_type, is_multi_thread);
}

JSExecutorWraper::~JSExecutorWraper() { VLOGI("~JSExecutorWraper"); }

void JSExecutorWraper::Destroy() {
  // must detroy all the runtime object before Runtime is destroyed
  if (module_manager_ != nullptr) {
    module_manager_->Destroy();
    module_manager_.reset();
  }

  // Destroy the runtime in the JS thread
  VLOGI("JSExecutorWraper::Destroy");
  js_runtime_.reset();
}

std::shared_ptr<vmsdk::runtime::NAPIRuntime> JSExecutorWraper::GetJSRuntime() {
  return js_runtime_;
}

void JSExecutorWraper::invokeCallback(
    std::shared_ptr<piper::ModuleCallback> callback,
    piper::ModuleCallbackFunctionHolder *holder) {
  if (!js_runtime_) {
    return;
  }
  Napi::Env env = js_runtime_->Env();

  Napi::HandleScope scope(env);
  Napi::ContextScope contextScope(env);

  callback->Invoke(env, holder);
  js_runtime_->ExecutePendingJob();
}

// register "NativeModules" to current global
void JSExecutorWraper::createNativeAppInstance() {
  Napi::Env env = js_runtime_->Env();
  Napi::HandleScope scope(env);
  Napi::ContextScope contextScope(env);

  Napi::Value nativeManageProxy =
      piper::VmsdkModuleBindingWrap::CreateFromVmsdkModuleBinding(
          env, module_manager_->bindingPtr.get());
  env.Global()["NativeModules"] = nativeManageProxy;
  return;
}

}  // namespace runtime
}  // namespace vmsdk
