// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_COMMON_JS_TYPE_H_
#define JSB_WASM_COMMON_JS_TYPE_H_

#if JS_ENGINE_JSC
typedef struct js_value__* js_value;
typedef struct js_context__* js_context;
typedef const struct js_value__* js_value_ref;
#define JS_NULL nullptr
#else  // JS_ENGINE_QJS
extern "C" {
#include "quickjs.h"
}
typedef LEPUSValue js_value;
typedef LEPUSContext* js_context;
typedef const LEPUSValue js_value_ref;
#define JS_NULL LEPUS_NULL
#endif

#endif  // JSB_WASM_COMMON_JS_TYPE_H_