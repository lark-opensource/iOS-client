// Copyright 2020 The Lynx Authors. All rights reserved.
// interface for lynx.so for android

//
// on release mode
// lynx.so --(getRuntime) ---->bdp_render.so ----makeV8Runtime------->lynx_v8.so
//                                 ⬆️-------(v8_provider getCtx)------⬇️
//
//
// on devtool mode
//  if we want support mini_app, we have to export symbol and there is a issue
//  when we want to use devtool

//  issue : lynx.so and devtool.so also build runtime sources
//  (jsi、log、runtime。。。runtime/v8_provider) lynx work fine cause they hide
//  symbol // why not modular and use module dependencies ??????????????? but we
//  must export interface symbol for miniapp to get v8_runtime/ctx ptr, and we
//  can't export them at same time

//  so we have to use twists and incomprehensible ways to be compatible
// lynx_devtool.so -(1)-- lynx.so --(getRuntime) ---->bdp_lynx.so
// ----makeV8Runtime------->lynx_v8.so
//                                 ⬆️-------(v8_provider getCtx)------⬇️
// - lynx_devtool.so hide symbol
// - lynx.so export symbol （so we can support miniapp）
// (1) use runtime(JSI) class build in lynx.so even lynx_devtool.so has same
// class。
//

#ifndef LYNX_JSBRIDGE_APPBRAND_RUNTIME_PROVIDER_H_
#define LYNX_JSBRIDGE_APPBRAND_RUNTIME_PROVIDER_H_

#ifndef PROVIDER_EXPORT
#ifdef NO_EXPORT
#define PROVIDER_EXPORT
#else
#define PROVIDER_EXPORT __attribute__((visibility("default")))
#endif
#endif

namespace provider {
namespace piper {

class PROVIDER_EXPORT RuntimeProvider {
 public:
  RuntimeProvider() = default;
  virtual ~RuntimeProvider(){};
  // must be subclass of jsi::runtime
  virtual void* MakeRuntime(const char* group_id) = 0;
};

class PROVIDER_EXPORT RuntimeProviderGenerator {
 public:
  RuntimeProviderGenerator() = delete;

  static RuntimeProvider& Provider();
  static void SetProvider(RuntimeProvider* provider);
  static bool Valid() { return provider_ != nullptr; }

 protected:
  // Fixme(chenpeihan): set provider when lynx env init (avoid multithreading
  // get/set)
  static RuntimeProvider* provider_;
};
}  // namespace piper
}  // namespace provider

#undef PROVIDER_EXPORT
#endif  // LYNX_JSBRIDGE_APPBRAND_RUNTIME_PROVIDER_H_
