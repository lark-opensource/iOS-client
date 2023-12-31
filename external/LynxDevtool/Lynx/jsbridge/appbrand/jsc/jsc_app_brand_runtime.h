// Copyright 2020 The Lynx Authors. All rights reserved.
// interface for lynx_v8.so for android

#ifndef LYNX_JSBRIDGE_APPBRAND_JSC_JSC_APP_BRAND_RUNTIME_H_
#define LYNX_JSBRIDGE_APPBRAND_JSC_JSC_APP_BRAND_RUNTIME_H_

#include <memory>
#include <string>

#include "jsbridge/appbrand/jsc/jsc_provider.h"
#include "jsbridge/appbrand/runtime_provider.h"
#include "jsbridge/jsc/jsc_runtime.h"

namespace provider {
namespace jsc {
class AppBrandContextWrapper : public lynx::piper::JSCContextWrapper,
                               public JSCCreatorObserver {
 public:
  explicit AppBrandContextWrapper(std::shared_ptr<lynx::piper::VMInstance> vm,
                                  std::string group_name);
  ~AppBrandContextWrapper() override;
  void init() override;

  const std::atomic<bool>& contextInvalid() const override;
  std::atomic<intptr_t>& objectCounter() const override;
  JSGlobalContextRef getContext() const override;

  // |JSCCreatorDelegate|
  const char* context_name() const override { return group_name_.c_str(); }
  void onSharedContextDestroyed() override;

 private:
  std::string group_name_;
  JSGlobalContextRef ctx_;
  static JSContextGroupRef group_;
  std::atomic<bool> ctx_invalid_;
  mutable std::atomic<intptr_t> object_counter_;
  AppBrandContextWrapper(const AppBrandContextWrapper&) = delete;
  AppBrandContextWrapper& operator=(const AppBrandContextWrapper&) = delete;
};

class AppBrandContextGroupWrapper : public lynx::piper::JSCContextGroupWrapper {
 public:
  AppBrandContextGroupWrapper(std::string group_name);
  ~AppBrandContextGroupWrapper() override {}
  void InitContextGroup() override {}

 private:
  std::string group_name_;
  AppBrandContextGroupWrapper(const AppBrandContextGroupWrapper&) = delete;
  AppBrandContextGroupWrapper& operator=(const AppBrandContextGroupWrapper&) =
      delete;
};

class AppBrandRuntime : public lynx::piper::JSCRuntime {
 public:
  AppBrandRuntime(std::string group_name);
  std::shared_ptr<lynx::piper::VMInstance> createVM(
      const lynx::piper::StartupData*) const override;
  std::shared_ptr<lynx::piper::JSIContext> createContext(
      std::shared_ptr<lynx::piper::VMInstance> vm) const override;

 private:
  std::string group_name_;
  AppBrandRuntime(const AppBrandRuntime&) = delete;
  AppBrandRuntime& operator=(const AppBrandRuntime&) = delete;
};

}  // namespace jsc
}  // namespace provider

#endif  // LYNX_JSBRIDGE_APPBRAND_JSC_JSC_APP_BRAND_RUNTIME_H_
