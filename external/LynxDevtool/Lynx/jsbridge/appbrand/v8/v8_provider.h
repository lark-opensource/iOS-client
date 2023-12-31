// Copyright 2020 The Lynx Authors. All rights reserved.
// interface for lynx_v8.so for android

#ifndef LYNX_JSBRIDGE_APPBRAND_V8_V8_PROVIDER_H_
#define LYNX_JSBRIDGE_APPBRAND_V8_V8_PROVIDER_H_

#include "v8.h"

#ifndef PROVIDER_EXPORT
#define PROVIDER_EXPORT __attribute__((visibility("default")))
#endif

namespace provider {
namespace v8 {

class PROVIDER_EXPORT V8Provider {
 public:
  V8Provider() = default;
  virtual ~V8Provider() = default;
  virtual ::v8::Isolate* GenerateIsolate(const char* name) = 0;
  virtual ::v8::Local<::v8::Context> GenerateContext(const char* name) = 0;
  virtual bool ReleaseContext(const char* name) = 0;
  void* CreateV8Runtime(const char* name);

 private:
  V8Provider(const V8Provider&) = delete;
  V8Provider& operator=(const V8Provider&) = delete;
};

class PROVIDER_EXPORT V8ProviderGenerator {
 public:
  static V8Provider& Provider();
  static void SetProvider(V8Provider* provider);

 private:
  // Fixme(chenpeihan): set provider when lynx env init (avoid multithreading
  // get/set)
  static V8Provider* provider_;
  V8ProviderGenerator() = delete;
  V8ProviderGenerator(const V8ProviderGenerator&) = delete;
  V8ProviderGenerator& operator=(const V8ProviderGenerator&) = delete;
};
}  // namespace v8
}  // namespace provider

#undef PROVIDER_EXPORT
#endif  // LYNX_JSBRIDGE_APPBRAND_V8_V8_PROVIDER_H_
