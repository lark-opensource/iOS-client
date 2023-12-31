// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/runtime/none_inspector_runtime_manager.h"

#include "base/threading/thread_local.h"
#include "config/config.h"

#if defined(OS_WIN)
#ifndef JS_ENGINE_TYPE
#define JS_ENGINE_TYPE 2
#endif
#else
#ifndef JS_ENGINE_TYPE
#define JS_ENGINE_TYPE 1
#endif
#endif

#if JS_ENGINE_TYPE == 1
#include "jsbridge/jsc/jsc_api.h"
#elif JS_ENGINE_TYPE == 2
#include "jsbridge/quickjs/quickjs_api.h"
#endif  // JS_ENGINE_TYPE

#ifdef OS_IOS
#include "jsbridge/jsc/jsc_api.h"
#endif

#ifdef OS_ANDROID
#include "jsbridge/android/lynx_proxy_runtime_helper.h"
#endif

#if defined(OS_WIN)
#if JS_ENGINE_TYPE == 0
#include "jsbridge/v8/v8_api.h"
#elif JS_ENGINE_TYPE == 2
#include "jsbridge/quickjs/quickjs_api.h"
#endif

#if ENABLE_NAPI_BINDING
#include "jsbridge/napi/napi_runtime_proxy_v8.h"
#endif

#if ENABLE_NAPI_BINDING
extern void RegisterV8RuntimeProxyFactory(
    lynx::piper::NapiRuntimeProxyV8Factory*);
#endif
#endif

namespace lynx {
namespace runtime {

NoneInspectorRuntimeManager* NoneInspectorRuntimeManager::Instance() {
  static lynx_thread_local(NoneInspectorRuntimeManager) instance_;
  return &instance_;
}

std::shared_ptr<piper::Runtime> NoneInspectorRuntimeManager::MakeRuntime(
    bool force_use_lightweight_js_engine) {
#if defined(MODE_HEADLESS)
  // TODO(hongzhiyuan.hzy): Maybe we can implement a headless-exclusive
  // NoneInspectorRuntimeManager in the future.
#if JS_ENGINE_TYPE == 1
  return piper::makeJSCRuntime();
#elif JS_ENGINE_TYPE == 2
  return piper::makeQuickJsRuntime();
#endif
#endif

#if defined(OS_IOS) || defined(OS_OSX)
  LOGI("make JSC runtime");
  return piper::makeJSCRuntime();
#endif

#ifdef OS_ANDROID
  if (!force_use_lightweight_js_engine) {
    auto ret = LynxProxyRuntimeHelper::Instance().MakeRuntime();
    if (ret) {
      LOGI("make runtime with proxy runtime helper. "
           << ", force_use_lightweight_js_engine "
           << force_use_lightweight_js_engine);
      return ret;
    }
  }

#if JS_ENGINE_TYPE == 1
  LOGI("make JSC runtime");
  return piper::makeJSCRuntime();
#elif JS_ENGINE_TYPE == 2
  LOGI("make QuickJS runtime");
  return piper::makeQuickJsRuntime();
#endif  // JS_ENGINE_TYPE

#endif  // OS_ANDROID

#if defined(OS_WIN)
#if JS_ENGINE_TYPE == 0

#if ENABLE_NAPI_BINDING
  static piper::NapiRuntimeProxyV8FactoryImpl factory;
  LOGI("Setting napi proxy factory from none inspector: " << &factory);
  RegisterV8RuntimeProxyFactory(&factory);
#endif

  return piper::makeV8Runtime();
#elif JS_ENGINE_TYPE == 2
  return piper::makeQuickJsRuntime();
#endif

#endif  // OS_WIN

// fit compile on linux
#if !defined(OS_IOS) && !defined(OS_ANDROID)
  return nullptr;
#endif
}

std::shared_ptr<piper::Runtime>
NoneInspectorRuntimeManager::InitAppBrandRuntime(
    std::shared_ptr<piper::Runtime> js_runtime,
    std::shared_ptr<piper::JSIExceptionHandler> exception_handler,
    std::vector<std::pair<std::string, std::string> >& js_pre_sources,
    std::shared_ptr<piper::JSExecutor> executor, int64_t rt_id,
    bool ensure_console) {
  js_runtime->setRuntimeId(rt_id);
  auto js_context = js_runtime->createContext(js_runtime->createVM(nullptr));
  EnsureConsolePostMan(js_context, executor);
  js_runtime->InitRuntime(js_context, exception_handler);

  auto context_wrapper =
      std::make_shared<NoneSharedJSContextWrapper>(js_context);
  js_context->SetReleaseObserver(context_wrapper);
  context_wrapper->initGlobal(js_runtime, js_context->GetPostMan());
  if (ensure_console) {
    context_wrapper->EnsureConsole(js_context->GetPostMan());
  }
  js_runtime->setCreatedType(piper::JSRuntimeCreatedType::vm_context);
  return js_runtime;
}

}  // namespace runtime
}  // namespace lynx
