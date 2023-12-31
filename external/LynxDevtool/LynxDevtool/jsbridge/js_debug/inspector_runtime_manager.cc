// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/js_debug/inspector_runtime_manager.h"

#include "base/lynx_env.h"
#include "config/config.h"
#include "jsbridge/js_debug/debug_helper.h"
#include "jsbridge/js_debug/inspector_js_env_provider.h"
#include "jsbridge/js_executor.h"
#include "jsbridge/runtime/lynx_runtime_observer.h"

#if ENABLE_NAPI_BINDING
#include "jsbridge/napi/napi_runtime_proxy_v8.h"
#if OS_IOS
#include "jsbridge/napi/napi_runtime_proxy_quickjs_factory_impl.h"
#endif
#endif

#if ENABLE_NAPI_BINDING
extern void RegisterV8RuntimeProxyFactory(
    lynx::piper::NapiRuntimeProxyV8Factory*);
#if OS_IOS
extern void RegisterQuickjsRuntimeProxyFactory(
    lynx::piper::NapiRuntimeProxyQuickjsFactory* factory);
#endif
#endif

namespace lynx {
namespace runtime {

std::shared_ptr<piper::Runtime> InspectorRuntimeManager::CreateJSRuntime(
    const std::string& group_id,
    std::shared_ptr<piper::JSIExceptionHandler> exception_handler,
    std::vector<std::pair<std::string, std::string>>& js_pre_sources,
    bool force_use_lightweight_js_engine,
    std::shared_ptr<piper::JSExecutor> executor, int64_t rt_id,
    bool ensure_console) {
#if ENABLE_NAPI_BINDING
  static piper::NapiRuntimeProxyV8FactoryImpl factory;
  LOGI("Setting napi proxy V8 factory from inspector: " << &factory);
  RegisterV8RuntimeProxyFactory(&factory);
#if OS_IOS
  static piper::NapiRuntimeProxyQuickjsFactoryImpl qjs_factory;
  LOGI("Setting napi proxy Quickjs factory from inspector: " << &qjs_factory);
  RegisterQuickjsRuntimeProxyFactory(&qjs_factory);
#endif
#endif

  devtool::DebugType debug_type = devtool::error_type;
  auto observer = executor->getRuntimeObserver();
  if (observer != nullptr) {
    auto debugger = observer->GetJSDebugger().lock();
    if (debugger != nullptr) {
      debug_type = debugger->GetDebugType();
    }
  }
  if (debug_type == devtool::error_type) {
    debug_type = base::LynxEnv::GetInstance().IsV8Enabled()
                     ? devtool::v8_debug
                     : devtool::quickjs_debug;
  }
  std::shared_ptr<piper::Runtime> js_runtime = MakeJSRuntime(debug_type);

  bool shared_vm =
      !IsSingleJSContext(group_id) || debug_type == devtool::quickjs_debug;

  js_runtime->setRuntimeId(rt_id);
  js_runtime->setGroupId(group_id);

  bool need_create_vm = false;
  if (IsSingleJSContext(group_id)) {
    CreateJSContextResult result = CreateJSContext(js_runtime, shared_vm);
    need_create_vm = result.first;
    std::shared_ptr<piper::JSIContext> js_context = result.second;
    InitJSRuntimeCreatedType(need_create_vm, js_runtime);

    LOGI("js debug: create none shared js context! debug type: "
         << debug_type << ", context: " << js_context.get()
         << ", group: " << group_id);

    js_runtime->InitRuntime(js_context, exception_handler);

    auto context_wrapper =
        std::make_shared<NoneSharedJSContextWrapper>(js_context);
    js_context->SetReleaseObserver(context_wrapper);
    context_wrapper->initGlobal(js_runtime, nullptr);
    if (ensure_console) {
      context_wrapper->EnsureConsole(nullptr);
    }

    executor->initJavaScriptDebugger(js_runtime, group_id);

    context_wrapper->loadPreJS(js_runtime, js_pre_sources);
  } else {
    std::shared_ptr<piper::JSIContext> js_context =
        GetSharedJSContext(group_id);

    if (js_context) {
      LOGI("js debug: get shared js context!: " << js_context.get()
                                                << ", group: " << group_id);

      js_runtime->InitRuntime(js_context, exception_handler);

      executor->initJavaScriptDebugger(js_runtime, group_id);

      js_runtime->setCreatedType(
          piper::JSRuntimeCreatedType::none_vm_none_context);
    } else {
      CreateJSContextResult result = CreateJSContext(js_runtime, shared_vm);
      need_create_vm = result.first;
      js_context = result.second;
      InitJSRuntimeCreatedType(need_create_vm, js_runtime);

      LOGI("js debug: create shared js context!: " << js_context.get()
                                                   << ", group: " << group_id);

      js_runtime->InitRuntime(js_context, exception_handler);

      auto context_wrapper =
          std::make_shared<SharedJSContextWrapper>(js_context, group_id, this);
      js_context->SetReleaseObserver(context_wrapper);
      auto global_runtime = MakeJSRuntime(debug_type);
      global_runtime->setGroupId(group_id);
      global_runtime->setRuntimeId(devtool::kDefaultGlobalRuntimeID);
      global_runtime->InitRuntime(js_context, exception_handler);
      context_wrapper->initGlobal(global_runtime, nullptr);
      if (ensure_console) {
        context_wrapper->EnsureConsole(nullptr);
      }

      executor->initJavaScriptDebugger(js_runtime, group_id);

      context_wrapper->loadPreJS(js_runtime, js_pre_sources);

      shared_context_map_.insert(std::make_pair(group_id, context_wrapper));
      group_to_engine_type_.emplace(group_id, debug_type);
    }
  }
  return js_runtime;
}

void InspectorRuntimeManager::SetReleaseCallback(
    devtool::DebugType type, const ReleaseCallback& callback) {
  release_callback_[type] = callback;
}

CreateJSContextResult InspectorRuntimeManager::CreateJSContext(
    std::shared_ptr<piper::Runtime>& rt, bool shared_vm) {
  piper::StartupData* data = nullptr;
  std::shared_ptr<lynx::piper::VMInstance> vm = nullptr;
  bool need_create_vm = false;
  if (shared_vm) {
    need_create_vm = EnsureVM(rt);
    vm = mVMContainer_[rt->type()];
  } else {
    need_create_vm = true;
    vm = rt->createVM(data);
  }
  auto ctx = rt->createContext(vm);
  return std::make_pair(need_create_vm, ctx);
}

std::shared_ptr<piper::JSIContext> InspectorRuntimeManager::GetSharedJSContext(
    const std::string& group_id) {
  if (shared_context_map_.find(group_id) == shared_context_map_.end()) {
    return nullptr;
  }
  auto context_wrapper = shared_context_map_[group_id];
  return context_wrapper->getJSContext();
}

void InspectorRuntimeManager::OnRelease(const std::string& group_id) {
  auto it = shared_context_map_.find(group_id);
  if (it != shared_context_map_.end()) {
    LOGI("InspectorRuntimeManager remove context, group_id: " << group_id);
    auto engine_it = group_to_engine_type_.find(group_id);
    if (engine_it != group_to_engine_type_.end()) {
      auto callback_it = release_callback_.find(engine_it->second);
      if (callback_it != release_callback_.end()) {
        (callback_it->second)(group_id);
      }
    }
    shared_context_map_.erase(it);
  } else {
    LOGR("InspectorRuntimeManager::OnRelease error: not find shared jscontext!:"
         << group_id);
  }
}

std::shared_ptr<piper::Runtime> InspectorRuntimeManager::MakeJSRuntime(
    devtool::DebugType type) {
  auto provider = lynx::devtool::InspectorClient::GetJsEnvProvider(type);
  if (!provider) {
    LOGF(
        "you must set inspector_env or set "
        "disableLynxDebugRuntime=yes when use inspector");
  }
  return provider->MakeRuntime();
}

std::shared_ptr<piper::Runtime> InspectorRuntimeManager::InitAppBrandRuntime(
    std::shared_ptr<piper::Runtime> js_runtime,
    std::shared_ptr<piper::JSIExceptionHandler> exception_handler,
    std::vector<std::pair<std::string, std::string>>& js_pre_sources,
    std::shared_ptr<piper::JSExecutor> executor, int64_t rt_id,
    bool ensure_console) {
  auto js_context = js_runtime->createContext(js_runtime->createVM(nullptr));
  js_runtime->InitRuntime(js_context, exception_handler);
  js_runtime->setRuntimeId(rt_id);
  auto context_wrapper =
      std::make_shared<NoneSharedJSContextWrapper>(js_context);
  js_context->SetReleaseObserver(context_wrapper);
  context_wrapper->initGlobal(js_runtime, nullptr);

  piper::JSRuntimeCreatedType type = piper::JSRuntimeCreatedType::vm_context;
  js_runtime->setCreatedType(type);
  return js_runtime;
}

}  // namespace runtime
}  // namespace lynx
