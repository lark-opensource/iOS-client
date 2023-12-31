// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_NAPI_ENVIRONMENT_H_
#define LYNX_JSBRIDGE_NAPI_NAPI_ENVIRONMENT_H_

#if !defined(_MSC_VER)
#include <cxxabi.h>
#endif

#include <memory>
#include <string>
#include <utility>

#include "base/base_export.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/napi/napi_runtime_proxy.h"
#include "jsbridge/napi/shim/shim_napi.h"
#include "jsbridge/runtime/template_delegate.h"

namespace lynx {
namespace piper {

class NapiEnvironment {
 public:
  class Module {
   public:
    virtual ~Module() = default;
    virtual void OnLoad(Napi::Object& app) = 0;
    virtual bool IsLazy() { return false; }
  };

  // NapiEnvironment contains common logic shared between UI and JS threads.
  // When there are differences, we put them into the Delegate (NapiLoader).
  class Delegate {
   public:
    using Module = NapiEnvironment::Module;

    virtual ~Delegate() = default;

    // Called when the environment is attached to a JS runtime.
    // May be used to inject global objects/constructors.
    virtual void OnAttach(Napi::Env env) {}

    // Called when the environment is detached from the JS runtime.
    // May be used for clean-up.
    virtual void OnDetach(Napi::Env env) {}

    virtual void RegisterModule(const std::string& name,
                                std::unique_ptr<Module> module) {}

    virtual Module* GetModule(const std::string& name) { return nullptr; }

    virtual void LoadInstantModules(Napi::Object& lynx) {}
  };
  BASE_EXPORT static NapiEnvironment* From(Napi::Env env);

  NapiEnvironment(std::unique_ptr<Delegate> delegate);
  ~NapiEnvironment();

  void Attach();
  void Detach();

  Delegate* delegate() { return delegate_.get(); }

  NapiRuntimeProxy* proxy() { return proxy_.get(); }

  void SetRuntimeProxy(std::unique_ptr<NapiRuntimeProxy> proxy) {
    proxy_ = std::move(proxy);
  }

  std::weak_ptr<Runtime> GetJSRuntime() { return proxy_->GetJSRuntime(); }

  BASE_EXPORT void RegisterModule(const std::string& name,
                                  std::unique_ptr<Module> module);
  BASE_EXPORT Module* GetModule(const std::string& name);

 private:
  std::unique_ptr<Delegate> delegate_;
  std::unique_ptr<NapiRuntimeProxy> proxy_;
  bool attached_ = false;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_NAPI_ENVIRONMENT_H_
