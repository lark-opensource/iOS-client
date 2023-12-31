// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_COMMON_JS_ENV_H_
#define JSB_WASM_COMMON_JS_ENV_H_

#if JS_ENGINE_JSC  // JS_ENGINE_JSC
#include "jsc/js_env_jsc.h"
typedef vmsdk::jsc::JSCEnv JS_ENV;
#else  // JS_ENGINE_QJS
#include "qjs/js_env_qjs.h"
typedef vmsdk::qjs::QJSEnv JS_ENV;
#endif

#endif  // JSB_WASM_COMMON_JS_ENV_H_