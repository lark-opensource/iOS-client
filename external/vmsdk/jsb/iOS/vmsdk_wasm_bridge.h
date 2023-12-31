// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_IOS_VMSDK_WASM_BRIDGE_H_
#define JSB_IOS_VMSDK_WASM_BRIDGE_H_

#import <Foundation/Foundation.h>

#define WASM_EXPORT __attribute__((visibility("default")))

// register webassembly to js_context
extern "C" WASM_EXPORT void RegisterWebAssemblyFunc(void* js_context, void* exception);

@interface RegisterWebAssembly : NSObject

+ (int64_t)registerWebAssembly;

@end

#endif  // JSB_IOS_VMSDK_WASM_BRIDGE_H_