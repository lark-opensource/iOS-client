// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_func_pack.h"

#include "common/wasm_log.h"
#include "wasm_runtime.h"

namespace vmsdk {
namespace wasm {
WasmFuncPack::WasmFuncPack(js_value js_func, WasmRuntime* rt) : runtime_(rt) {
  func_.js_func = js_func;
  WasmRuntime::Dup(runtime_);
}

WasmFuncPack::WasmFuncPack(wasm_func_t* w_func, WasmRuntime* rt,
                           std::shared_ptr<WasmInstance>& inst)
    : runtime_(rt), inst_(inst) {
  func_.wasm_func = w_func;
  WasmRuntime::Dup(runtime_);
}

WasmFuncPack::~WasmFuncPack() {
  WLOGD("%s: deleting wasm func pack...", __func__);
  WasmRuntime::Free(runtime_);
}

js_value WasmFuncPack::CallWasmFunc(void* pack, size_t argc,
                                    const js_value arguments[],
                                    js_value* exception) {
  wasm_func_t* wfunc = static_cast<WasmFuncPack*>(pack)->func_.wasm_func;
  WasmRuntime* wasm_rt =
      static_cast<WasmRuntime*>(static_cast<WasmFuncPack*>(pack)->runtime_);

  wasm_functype_t* func_ty = wasm_func_type(wfunc);
  const wasm_valtype_vec_t* param_tys = wasm_functype_params(func_ty);

  size_t w_argc = param_tys->size;
  wasm_val_t wasm_args[w_argc];
  JS_ENV* env = wasm_rt->GetJSEnv();

  for (size_t i = 0; i < param_tys->size; ++i) {
    wasm_args[i].kind = wasm_valtype_kind(param_tys->data[i]);
    js_value arg = i < argc ? arguments[i] : env->MakeNumber(NAN);
    if (wasm_rt->JsToWasm(arg, wasm_args + i)) {
      *exception =
          env->MakeException("Illegal parameter(s) for wasm function.");
      return JS_NULL;
    }
  }

  const wasm_valtype_vec_t* res_tys = wasm_functype_results(func_ty);
  wasm_val_t wasm_res[res_tys->size];
  for (size_t i = 0; i < res_tys->size; ++i) {
    wasm_res[i].kind = WASM_ANYREF;
    wasm_res[i].of.ref = NULL;
  }

  wasm_val_vec_t args_vec = WASM_ARRAY_VEC(wasm_args);
  wasm_val_vec_t results = WASM_ARRAY_VEC(wasm_res);
  wasm_trap_t* trap = wasm_func_call(wfunc, &args_vec, &results);
  if (trap) {
    wasm_name_t message;
    wasm_trap_message(trap, &message);

    static const char* prefix = "WebAssembly Trap: ";
    static size_t prefix_len = strlen(prefix);
    size_t len = message.size + prefix_len + 1;
    char msg[len];
    memcpy(msg, prefix, prefix_len);
    memcpy(msg + prefix_len, message.data, message.size);
    msg[len] = '\0';

    js_value ret_exp = env->MakePlainObject();
    js_value js_msg = env->MakeString(msg);
    env->SetProperty(ret_exp, "message", js_msg);

    if (exception) *exception = ret_exp;
    return JS_NULL;
  }
  js_value res = JS_NULL;
  if (res_tys->size == 1) {
    wasm_rt->WasmToJs(&res, &wasm_res[0]);
  }
  return res;
}

wasm_trap_t* WasmFuncPack::WasmCallback(void* env, const wasm_val_vec_t* args,
                                        wasm_val_vec_t* results) {
  WasmFuncPack* pack = static_cast<WasmFuncPack*>(env);
  WasmRuntime* runtime = pack->runtime_;

  size_t argc = args->size;
  js_value js_args[argc];
  for (size_t i = 0; i < argc; ++i)
    runtime->WasmToJs(&js_args[i], &(args->data[i]));

  js_value exception = JS_NULL;
  JS_ENV* js_env = runtime->GetJSEnv();
  js_value val = js_env->CallAsFunction(
      pack->func_.js_func, js_env->GetUndefined(), argc, js_args, &exception);
  if (!js_env->IsNull(exception) ||
      (results->size && runtime->JsToWasm(val, &(results->data[0])))) {
    wasm_name_t message;
    wasm_name_new_from_string_nt(&message, "wasm callback abort");
    return wasm_trap_new(runtime->GetStore(), &message);
  }
  return nullptr;
}

}  // namespace wasm
}  // namespace vmsdk
