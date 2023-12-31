// Copyright 2020 The Lynx Authors. All rights reserved.
// interface for lynx_v8.so for android

#ifndef LYNX_JSBRIDGE_APPBRAND_V8_V8_APP_BRAND_RUNTIME_H_
#define LYNX_JSBRIDGE_APPBRAND_V8_V8_APP_BRAND_RUNTIME_H_

#include <memory>
#include <string>

#include "jsbridge/v8/v8_runtime.h"

#ifndef RUNTIME_EXPORT
#define RUNTIME_EXPORT __attribute__((visibility("default")))
#endif
namespace provider {
namespace v8 {

class RUNTIME_EXPORT AppBrandRuntime : public lynx::piper::V8Runtime {
 public:
  AppBrandRuntime(std::string group_name);

  std::shared_ptr<lynx::piper::VMInstance> createVM(
      const lynx::piper::StartupData*) const override;

  std::shared_ptr<lynx::piper::JSIContext> createContext(
      std::shared_ptr<lynx::piper::VMInstance>) const override;

 private:
  std::string group_name_;
  AppBrandRuntime(const AppBrandRuntime&) = delete;
  AppBrandRuntime& operator=(const AppBrandRuntime&) = delete;
};

class RUNTIME_EXPORT AppBrandIsolateWrapper
    : public lynx::piper::V8IsolateInstance {
 public:
  explicit AppBrandIsolateWrapper(std::string group_name);
  ~AppBrandIsolateWrapper() = default;
  void InitIsolate(const char* arg, bool useSnapshot) override;
  virtual ::v8::Isolate* Isolate() const override;

 private:
  std::string group_name_;
  ::v8::Isolate* isolate_;
  AppBrandIsolateWrapper(const AppBrandIsolateWrapper&) = delete;
  AppBrandIsolateWrapper& operator=(const AppBrandIsolateWrapper&) = delete;
};

class RUNTIME_EXPORT AppBrandContextWrapper
    : public lynx::piper::V8ContextWrapper {
 public:
  explicit AppBrandContextWrapper(std::shared_ptr<lynx::piper::VMInstance> vm,
                                  std::string name);
  void Init() override;
  virtual ::v8::Local<::v8::Context> getContext() const override;
  virtual ::v8::Isolate* getIsolate() const override;

 private:
  std::string group_name_;
  ::v8::Persistent<::v8::Context> ctx_;
  AppBrandContextWrapper(const AppBrandIsolateWrapper&) = delete;
  AppBrandIsolateWrapper& operator=(const AppBrandIsolateWrapper&) = delete;
};

}  // namespace v8
}  // namespace provider

#undef RUNTIME_EXPORT
#endif  // LYNX_JSBRIDGE_APPBRAND_V8_V8_APP_BRAND_RUNTIME_H_
