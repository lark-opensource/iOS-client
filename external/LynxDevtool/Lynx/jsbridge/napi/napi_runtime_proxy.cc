// Copyright 2021 The Lynx Authors. All rights reserved.

#include "jsbridge/napi/napi_runtime_proxy.h"

#include "jsbridge/napi/napi_runtime_proxy_quickjs_factory.h"
#include "jsbridge/napi/napi_runtime_proxy_v8_factory.h"
#include "jsbridge/napi/shim/shim_napi_env.h"
#include "jsbridge/napi/shim/shim_napi_runtime.h"

#ifndef OS_IOS
#include "jsbridge/napi/napi_runtime_proxy_quickjs.h"
#include "jsbridge/quickjs/quickjs_runtime.h"
#endif

#if defined(OS_IOS) || defined(OS_OSX)
#include "jsbridge/jsc/jsc_runtime.h"
#include "jsbridge/napi/napi_runtime_proxy_jsc.h"
#endif

BASE_EXPORT void RegisterV8RuntimeProxyFactory(
    lynx::piper::NapiRuntimeProxyV8Factory *factory) {
  lynx::piper::NapiRuntimeProxy::SetFactory(factory);
}

BASE_EXPORT void RegisterQuickjsRuntimeProxyFactory(
    lynx::piper::NapiRuntimeProxyQuickjsFactory *factory) {
#if OS_IOS
  lynx::piper::NapiRuntimeProxy::SetQuickjsFactory(factory);
#endif
}

namespace lynx {
namespace piper {

// static
std::unique_ptr<NapiRuntimeProxy> NapiRuntimeProxy::Create(
    std::shared_ptr<Runtime> runtime, runtime::TemplateDelegate *delegate) {
  switch (runtime->type()) {
    case v8: {
      LOGI("Creating napi proxy using v8 factory: " << s_factory);
      if (s_factory) {
        auto proxy_v8 = s_factory->Create(runtime, delegate);
        proxy_v8->SetJSRuntime(runtime);
        return proxy_v8;
      }
      return nullptr;
    }
    case jsc: {
#if defined(OS_IOS) || defined(OS_OSX)
      LOGI("Creating napi proxy jsc");
      auto jsc_runtime = std::static_pointer_cast<JSCRuntime>(runtime);
      auto context = jsc_runtime->getSharedContext();
      auto jsc_context = std::static_pointer_cast<JSCContextWrapper>(context);
      auto proxy_jsc = NapiRuntimeProxyJSC::Create(jsc_context, delegate);
      proxy_jsc->SetJSRuntime(runtime);
      return proxy_jsc;
#else
      return nullptr;
#endif
    }
    case quickjs: {
#if !defined(OS_IOS) && !defined(OS_OSX)
      LOGI("Creating napi proxy quickjs");
      auto qjs_runtime = std::static_pointer_cast<QuickjsRuntime>(runtime);
      auto context = qjs_runtime->getSharedContext();
      auto qjs_context =
          std::static_pointer_cast<QuickjsContextWrapper>(context);
      auto proxy_qjs =
          NapiRuntimeProxyQuickjs::Create(qjs_context->getContext(), delegate);
      proxy_qjs->SetJSRuntime(runtime);
      return proxy_qjs;
#elif defined(OS_IOS)
      if (qjs_factory_) {
        auto proxy_qjs = qjs_factory_->Create(runtime, delegate);
        proxy_qjs->SetJSRuntime(runtime);
        return proxy_qjs;
      }
      return nullptr;
#else
      return nullptr;
#endif
    }
    default: {
      LOGE("Unknown runtime type: " << (int)runtime->type());
      break;
    }
  }
}
// the life cycle of shared_ptr to DelegateObserver is the same as
// NapiRuntimeProxy weak_ptr delegate_observer used to watch whether runtime is
// detached
void PostNAPIJSTask(napi_foreground_cb js_cb, void *data, void *task_ctx) {
  auto delegate_observer = std::weak_ptr<DelegateObserver>(
      *static_cast<std::shared_ptr<DelegateObserver> *>(task_ctx));
  delegate_observer.lock().get()->PostJSTask(
      [delegate_observer, js_cb, data]() {
        if (delegate_observer.lock()) {
          js_cb(data);
        }
      });
}

NapiRuntimeProxy::NapiRuntimeProxy(runtime::TemplateDelegate *delegate)
    : env_(napi_new_env()) {
  delegate_observer_ = std::make_shared<DelegateObserver>(delegate);
  napi_runtime_configuration runtime_conf = napi_create_runtime_configuration();
  napi_runtime_config_foreground_handler(runtime_conf, PostNAPIJSTask,
                                         &delegate_observer_);
  napi_attach_runtime_with_configuration(env_, runtime_conf);
  napi_delete_runtime_configuration(runtime_conf);
}

NapiRuntimeProxy::~NapiRuntimeProxy() { napi_free_env(env_); }

void NapiRuntimeProxy::Attach() {}

void NapiRuntimeProxy::Detach() { napi_detach_runtime(env_); }

void NapiRuntimeProxy::SetupLoader() {
  auto runtime = GetJSRuntime().lock();
  napi_env raw_env = env_;
  if (runtime && raw_env && raw_env->ctx) {
    Napi::ContextScope context_scope(env_);
    loader_ = "napiLoaderOnRT" + std::to_string(runtime->getRuntimeId());
    LOGI("NAPI Setup Loader: " << loader_);
    napi_setup_loader(env_, loader_.c_str());
  }
}

void NapiRuntimeProxy::RemoveLoader() {
  napi_env raw_env = env_;
  if (raw_env && raw_env->ctx && !loader_.empty()) {
    Napi::HandleScope handle_scope(env_);
    if (env_.Global().Has(loader_.c_str())) {
      LOGI("NAPI Remove Loader: " << loader_);
      env_.Global().Delete(loader_.c_str());
    }
  }
}

NapiRuntimeProxyV8Factory *NapiRuntimeProxy::s_factory = nullptr;
NapiRuntimeProxyQuickjsFactory *NapiRuntimeProxy::qjs_factory_ = nullptr;

// static
void NapiRuntimeProxy::SetFactory(NapiRuntimeProxyV8Factory *factory) {
  s_factory = factory;
}

// static
void NapiRuntimeProxy::SetQuickjsFactory(
    NapiRuntimeProxyQuickjsFactory *factory) {
  qjs_factory_ = factory;
}

}  // namespace piper
}  // namespace lynx
