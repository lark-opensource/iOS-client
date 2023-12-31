// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/jsc/jsc_context_wrapper_impl.h"

#import "webassembly_bridge.h"

@implementation WebAssemblyBridge

+ (void)initWasm {
  Class clazz = NSClassFromString(@"RegisterWebAssembly");
  SEL selector = NSSelectorFromString(@"registerWebAssembly");
  if ([clazz respondsToSelector:selector]) {
    int64_t (*func)(id, SEL) = (int64_t(*)(id, SEL))[clazz methodForSelector:selector];
    lynx::piper::JSCContextWrapperImpl::register_wasm_func_ =
        reinterpret_cast<void (*)(void*, void*)>(func(clazz, selector));
    NSLog(@"RegisterWebAssembly found");
  } else {
    NSLog(@"RegisterWebAssembly not found");
  }
}

@end
