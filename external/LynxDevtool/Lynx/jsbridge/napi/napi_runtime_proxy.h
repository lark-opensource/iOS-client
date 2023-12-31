// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_H_
#define LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_H_

#include <memory>
#include <string>
#include <utility>

#include "base/base_export.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/napi/shim/shim_napi.h"
#include "jsbridge/runtime/template_delegate.h"

namespace lynx {
namespace piper {

class NapiRuntimeProxyV8Factory;
class NapiRuntimeProxyQuickjsFactory;

class DelegateObserver {
 public:
  DelegateObserver(runtime::TemplateDelegate* delegate) : delegate_(delegate) {}
  void PostJSTask(base::closure closure) {
    delegate_->RunOnJSThread(std::move(closure));
  }

 private:
  runtime::TemplateDelegate* delegate_;
};

class BASE_EXPORT NapiRuntimeProxy {
 public:
  static std::unique_ptr<NapiRuntimeProxy> Create(
      std::shared_ptr<Runtime> runtime,
      runtime::TemplateDelegate* delegate = nullptr);
  NapiRuntimeProxy(runtime::TemplateDelegate* delegate);
  virtual ~NapiRuntimeProxy();

  virtual void Attach();
  virtual void Detach();

  Napi::Env Env() { return env_; }
  void SetJSRuntime(std::shared_ptr<Runtime> runtime) { js_runtime_ = runtime; }

  std::weak_ptr<Runtime> GetJSRuntime() { return js_runtime_; }

  static void SetFactory(NapiRuntimeProxyV8Factory* factory);
  static void SetQuickjsFactory(NapiRuntimeProxyQuickjsFactory* factory);

  void SetupLoader();
  void RemoveLoader();

 protected:
  Napi::Env env_;
  std::shared_ptr<DelegateObserver> delegate_observer_;
  std::weak_ptr<Runtime> js_runtime_;
  std::string loader_;

 private:
  static NapiRuntimeProxyV8Factory* s_factory;
  static NapiRuntimeProxyQuickjsFactory* qjs_factory_;  // Only used on iOS.
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_H_
