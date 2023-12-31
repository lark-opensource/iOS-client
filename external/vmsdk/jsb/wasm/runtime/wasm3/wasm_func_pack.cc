// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_func_pack.h"

#include "wasm_runtime.h"

namespace vmsdk {
namespace wasm {

WasmFuncPack::WasmFuncPack(js_value js_func, WasmRuntime* rt) : runtime_(rt) {
  func_.js_func = js_func;
  WasmRuntime::Dup(runtime_);
}

WasmFuncPack::WasmFuncPack(IM3Function w_func, WasmRuntime* rt,
                           std::shared_ptr<WasmInstance>& inst)
    : runtime_(rt), inst_(inst) {
  WasmRuntime::Dup(runtime_);
  func_.wasm_func = w_func;
}

WasmFuncPack::~WasmFuncPack() {
  WLOGD("%s: deleting wasm func pack...", __func__);
  WasmRuntime::Free(runtime_);
}

js_value WasmFuncPack::CallWasmFunc(void* pack, size_t argc,
                                    const js_value arguments[],
                                    js_value* exception) {
  WasmRuntime* wasm_rt =
      static_cast<WasmRuntime*>(static_cast<WasmFuncPack*>(pack)->runtime_);
  IM3Function wfunc = static_cast<IM3Function>(
      static_cast<WasmFuncPack*>(pack)->func_.wasm_func);

  u32 args_num = m3_GetArgCount(wfunc);

  static u64 valbuff[128];
  static const void* valptrs[128];
  memset(valbuff, 0, sizeof(valbuff));
  memset(valptrs, 0, sizeof(valptrs));
  JS_ENV* env = wasm_rt->GetJSEnv();

  for (u32 i = 0; i < args_num; ++i) {
    u64* s = &valbuff[i];
    valptrs[i] = s;
    M3ValueType vt = m3_GetArgType(wfunc, i);
    js_value arg = i < argc ? arguments[i] : env->MakeNumber(NAN);
    if (wasm_rt->JsToWasm(arg, vt, s)) {
      *exception =
          env->MakeException("Illegal parameter(s) for wasm function.");
      return JS_NULL;
    }
  }

  M3Result result = m3Err_none;
  result = m3_Call(wfunc, args_num, valptrs);

  // Write exception.
  if (result) {
    WLOGD("wasm function got error for Call, \"%s\".\n", result);
    *exception = env->MakeException(result);
    return JS_NULL;
  }

  int ret_count = m3_GetRetCount(wfunc);
  // reuse valbuff for return values
  memset(valbuff, 0, sizeof(valbuff));
  for (int i = 0; i < ret_count; i++) {
    valptrs[i] = &valbuff[i];
  }

  result = m3_GetResults(wfunc, ret_count, valptrs);
  if (result) {
    WLOGI("wasm function got error for Results, \"%s\".\n", result);
    return JS_NULL;
  }

  u32 ret_num = m3_GetRetCount(wfunc);
  js_value res = env->GetUndefined();
  if (ret_num > 0) {
    u64* s = reinterpret_cast<u64*>(const_cast<void*>(valptrs[0]));
    M3ValueType vt = m3_GetRetType(wfunc, 0);
    // FIXME(wasm): throw js exception if the next result = 1.
    wasm_rt->WasmToJs(&res, vt, s);
  }
  return res;
}

// Stack structure from wasm.
// [Stack Bottom]
//                 |<--------------      4 Bytes     --------------->|
// +---------------+-------------------------------------------------+
// |               |   Part 1 [f32/i32, f64/i64-low bits]            |
// + _ Return Val_ +-------------------------------------------------+
// |               |   Part 2 [f64/i64-high bits]                    |
// +---------------+-------------------------------------------------+
// |               |   Part 1 [f32/i32, f64/i64-low bits]            |
// + _ Arg 2     _ +-------------------------------------------------+
// |               |   Part 2 [f64/i64-high bits]                    |
// +---------------+-------------------------------------------------+
// |               |   Part 1 [f32/i32, f64/i64-low bits]            |
// + _ Arg 1     _ +-------------------------------------------------+
// |               |   Part 2 [f64/i64-high bits]                    |
// +---------------+-------------------------------------------------+
// |               |   Part 1 [f32/i32, f64/i64-low bits]            |
// + _  ... ...  _ +-------------------------------------------------+
// |               |   Part 2 [f64/i64-high bits]                    |
// +---------------+-------------------------------------------------+
// [Stack Top]
const void* WasmFuncPack::WasmCallback(IM3Runtime runtime,
                                       IM3ImportContext _ctx, u64* _sp,
                                       void* _mem) {
  IM3Function w_func = _ctx->function;
  WasmFuncPack* pack = reinterpret_cast<WasmFuncPack*>(_ctx->userdata);
  WasmRuntime* rt = pack->runtime_;

  WLOGI("WasmCallback ret count: %d\n", m3_GetRetCount(w_func));
  u32 retc = m3_GetRetCount(w_func);
  u64* raw_return = nullptr;
  if (retc > 0) {
    // Only support one return value.
    raw_return = ((u64*)(_sp++));
  }

  // No pointer here in arguments.
  u32 argc = m3_GetArgCount(w_func);
  js_value js_args[argc];
  for (u32 i = 0; i < argc; ++i) {
    m3ApiGetArg(u64, arg);
    rt->WasmToJs(&js_args[i], m3_GetArgType(w_func, i), &arg);
  }

  js_value exception = JS_NULL;
  JS_ENV* js_env = rt->GetJSEnv();
  js_value ret_val = js_env->CallAsFunction(
      pack->func_.js_func, js_env->GetUndefined(), argc, js_args, &exception);
  if (!js_env->IsNull(exception)) {
    m3ApiTrap("JS Function calls failed.");
  }

  // Only support one return value.
  if (retc > 0) {
    // u64 rval;
    rt->JsToWasm(ret_val, m3_GetRetType(w_func, 0), raw_return);
    // *raw_return = rval;
    return m3Err_none;
  }
  m3ApiSuccess();
}
}  // namespace wasm
}  // namespace vmsdk
