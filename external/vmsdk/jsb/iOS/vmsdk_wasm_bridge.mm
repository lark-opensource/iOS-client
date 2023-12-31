// Copyright 2022 The Vmsdk Authors. All rights reserved.

#import "vmsdk_wasm_bridge.h"

#include <atomic>
#include "jsb/wasm/jsc/jsc_wasm.h"

WASM_EXPORT extern "C" void RegisterWebAssemblyFunc(void* js_context, void* ctx_invalid) {
  if (!js_context) {
    NSLog(@"Register WebAssembly with invalid js context!");
    return;
  }
  NSLog(@"Register WebAssembly Stub ... \n");
  vmsdk::jsc::JSCWasmExt::RegisterWebAssembly(reinterpret_cast<JSContextRef>(js_context),
                                              reinterpret_cast<std::atomic<bool>*>(ctx_invalid));
}

@implementation RegisterWebAssembly

+ (int64_t)registerWebAssembly {
  return reinterpret_cast<int64_t>(RegisterWebAssemblyFunc);
}

@end