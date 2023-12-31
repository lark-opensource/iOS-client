#include "jsbridge/jsi_executor.h"

#include <jsbridge/bindings/console.h>

#include "base/log/logging.h"
#include "base/lynx_env.h"
#include "config/config.h"
#include "jsbridge/appbrand/app_brand_runtime_maker.h"
#include "jsbridge/runtime/none_inspector_runtime_manager.h"
#include "jsbridge/runtime/runtime_manager.h"
#include "jsbridge/utils/utils.h"

// BINARY_KEEP_SOURCE_FILE
namespace lynx {
namespace piper {

lynx_thread_local(runtime::RuntimeManager*)
    JSIExecutor::inspector_runtime_manager_instance_;

JSIExecutor::JSIExecutor(
    const std::shared_ptr<JSIExceptionHandler>& handler,
    const std::string& group_id,
    const std::shared_ptr<LynxModuleManager>& module_manager,
    const std::shared_ptr<runtime::LynxRuntimeObserver>& observer,
    bool forceUseLightweightJSEngine)
    : JSExecutor(handler, group_id, observer, forceUseLightweightJSEngine),
      module_manager_(module_manager) {
#if ENABLE_ARK_REPLAY
  module_manager_testBench_ = nullptr;
#endif
  if (runtime_observer_ != nullptr &&
      lynx::base::LynxEnv::GetInstance().IsJsDebugEnabled()) {
    js_debugger_.reset(reinterpret_cast<JavaScriptDebuggerWrapper*>(
        runtime_observer_->CreateJavascriptDebugger()));
  }
  if (module_manager_) {
    module_manager_->InitModuleInterceptor();
  }
}

JSIExecutor::~JSIExecutor() { LOGI("lynx ~JSIExecutor"); }

void JSIExecutor::Destroy() {
  // must detroy all the runtime object before Runtime is destroyed
  module_manager_->Destroy();
  module_manager_.reset();

  // Destroy the runtime in the JS thread
  LOGI("JSIExecutor::Destroy");

  js_runtime_.reset();
}

runtime::RuntimeManager* JSIExecutor::runtimeManagerInstance() {
#if defined(OS_IOS) && (defined(__i386__) || defined(__arm__))
  // do nothong
#else
  if (inspector_runtime_manager_instance_ == nullptr) {
    inspector_runtime_manager_instance_ = createInspectorRuntimeManager();
  }
#endif
  return (runtime_observer_ != nullptr &&
          lynx::base::LynxEnv::GetInstance().IsJsDebugEnabled() &&
          inspector_runtime_manager_instance_ != nullptr)
             ? inspector_runtime_manager_instance_
             : runtime::NoneInspectorRuntimeManager::Instance();
}

runtime::RuntimeManager* JSIExecutor::GetCurrentRuntimeManagerInstance(
    bool allow_inspector) {
  return (inspector_runtime_manager_instance_ != nullptr && allow_inspector)
             ? inspector_runtime_manager_instance_
             : runtime::NoneInspectorRuntimeManager::Instance();
}

void JSIExecutor::loadPreJSBundle(
    bool use_provider_js_env,
    std::vector<std::pair<std::string, std::string>>& js_pre_sources,
    bool ensure_console, int64_t rt_id, bool enable_user_code_cache,
    const std::string& code_cache_source_url) {
  if (use_provider_js_env) {
    js_runtime_ = runtimeManagerInstance()->InitAppBrandRuntime(
        provider::piper::AppBrandRuntimeMaker::MakeJSRuntime(group_id_),
        exception_handler, js_pre_sources,
        std::static_pointer_cast<piper::JSExecutor>(shared_from_this()), rt_id,
        ensure_console);
    return;
  }
  js_runtime_ = runtimeManagerInstance()->CreateJSRuntime(
      group_id_, exception_handler, js_pre_sources,
      forceUseLightweightJSEngine_,
      std::static_pointer_cast<piper::JSExecutor>(shared_from_this()), rt_id,
      ensure_console);
  js_runtime_->SetEnableUserCodeCache(enable_user_code_cache);
  js_runtime_->SetCodeCacheSourceUrl(code_cache_source_url);
}

runtime::RuntimeManager* JSIExecutor::createInspectorRuntimeManager() {
  if (runtime_observer_ == nullptr) {
    return nullptr;
  }

  return reinterpret_cast<runtime::RuntimeManager*>(
      runtime_observer_->CreateInspectorRuntimeManager());
}

void JSIExecutor::invokeCallback(
    std::shared_ptr<piper::ModuleCallback> callback,
    piper::ModuleCallbackFunctionHolder* holder) {
  Scope scope(*js_runtime_);
  callback->Invoke(js_runtime_.get(), holder);
}

std::shared_ptr<piper::App> JSIExecutor::createNativeAppInstance(
    int64_t rt_id, runtime::TemplateDelegate* delegate,
    std::unique_ptr<lynx::runtime::LynxApiHandler> api_handler,
    piper::TimedTaskAdapter timed_task_adapter) {
  Scope scope(*js_runtime_);
  piper::Object nativeModuleProxy = piper::Object::createFromHostObject(
      *js_runtime_, module_manager_.get()->bindingPtr);
#if ENABLE_ARK_REPLAY
  piper::Value module = module_manager_->bindingPtr->get(
      js_runtime_.get(),
      piper::PropNameID::forAscii(*js_runtime_, "LynxReplayDataModule"));
  if (!module.isNull()) {
    module_manager_testBench_ = std::make_shared<ModuleManagerTestBench>();
    module_manager_testBench_.get()->initBindingPtr(
        module_manager_testBench_, module_manager_.get()->delegate,
        module_manager_.get()->bindingPtr);
    module_manager_testBench_.get()->initRecordModuleData(module, *js_runtime_);
    nativeModuleProxy = piper::Object::createFromHostObject(
        *js_runtime_, module_manager_testBench_.get()->bindingPtr);
  }
#endif
  return piper::App::Create(rt_id, js_runtime_, delegate, exception_handler,
                            std::move(nativeModuleProxy),
                            std::move(api_handler),
                            std::move(timed_task_adapter));
}

void JSIExecutor::initJavaScriptDebugger(
    const std::shared_ptr<piper::Runtime>& runtime,
    const std::string& group_id) {
  if (js_debugger_ != nullptr) {
    js_debugger_->debugger_->InitWithRuntime(runtime, group_id);
  }
}

piper::JSRuntimeCreatedType JSIExecutor::getJSRuntimeType() {
  if (js_runtime_) {
    return js_runtime_->getCreatedType();
  }
  return piper::JSRuntimeCreatedType::unknown;
}

std::shared_ptr<piper::Runtime> JSIExecutor::GetJSRuntime() {
  return js_runtime_;
}

void JSIExecutor::SetUrl(const std::string& url) {
  if (module_manager_->bindingPtr &&
      module_manager_->bindingPtr->interceptor_) {
    module_manager_->bindingPtr->interceptor_->SetTemplateUrl(url);
  }
}

std::shared_ptr<piper::ConsoleMessagePostMan>
JSIExecutor::CreateConsoleMessagePostMan() {
  if (runtime_observer_ == nullptr) {
    return nullptr;
  }
  return std::shared_ptr<ConsoleMessagePostMan>(
      reinterpret_cast<ConsoleMessagePostMan*>(
          runtime_observer_->CreateConsolePostMan()));
}

}  // namespace piper
}  // namespace lynx
