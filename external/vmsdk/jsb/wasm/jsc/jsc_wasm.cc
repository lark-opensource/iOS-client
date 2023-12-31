// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "jsc_wasm.h"

#include "common/wasm_log.h"
#include "common/wasm_utils.h"
#include "js_env_jsc.h"
#include "jsc_class_creator.h"
#include "jsc_ext_api.h"
#include "jsc_wasm_global.h"
#include "jsc_wasm_instance.h"
#include "jsc_wasm_memory.h"
#include "jsc_wasm_module.h"
#include "jsc_wasm_table.h"
#include "runtime/wasm_runtime.h"

namespace vmsdk {
namespace jsc {

using wasm::WasmRuntime;

void JSCWasmExt::RegisterWebAssembly(JSContextRef ctx,
                                     std::atomic<bool>* ctx_invalid) {
  WasmRuntime* rt = nullptr;
  JSObjectRef wasm_obj = CreateWasmObject(ctx, &rt, ctx_invalid);
  if (wasm_unlikely(rt == nullptr)) {
    // log for debugging if ALog is enabled.
    LOGW("RegisterWebAssembly failed by WasmRuntime creating error!");
    WLOGW("RegisterWebAssembly failed by WasmRuntime creating error!");
    return;
  }

  JSValueRef exception_val{};
  JSValueRef* exception(&exception_val);
  JSCExtAPI::Attach(ctx, JSCWasmExt::kWasmName, wasm_obj,
                    kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum,
                    NULL /*global*/, exception);

  JSPropertyAttributes default_attr = kJSPropertyAttributeDontEnum;
  JSObjectRef module_ctor =
      JSCWasmModule::CreateConstructor(ctx, rt, exception);
  JSCExtAPI::Attach(ctx, JSCWasmExt::kModuleName, module_ctor, default_attr,
                    wasm_obj, exception);

  JSObjectRef inst_ctor =
      JSCWasmInstance::CreateConstructor(ctx, rt, exception);
  JSCExtAPI::Attach(ctx, JSCWasmExt::kInstanceName, inst_ctor, default_attr,
                    wasm_obj, exception);

  JSObjectRef memory_ctor =
      JSCWasmMemory::CreateConstructor(ctx, rt, exception);
  JSCExtAPI::Attach(ctx, JSCWasmExt::kMemoryName, memory_ctor, default_attr,
                    wasm_obj, exception);

  JSObjectRef table_ctor = JSCWasmTable::CreateConstructor(ctx, rt, exception);
  JSCExtAPI::Attach(ctx, JSCWasmExt::kTableName, table_ctor, default_attr,
                    wasm_obj, exception);

  JSObjectRef global_ctor =
      JSCWasmGlobal::CreateConstructor(ctx, rt, exception);
  JSCExtAPI::Attach(ctx, JSCWasmExt::kGlobalName, global_ctor, default_attr,
                    wasm_obj, exception);
}

JSObjectRef JSCWasmExt::CreateWasmObject(JSContextRef ctx, WasmRuntime** rt_ptr,
                                         std::atomic<bool>* ctx_invalid) {
  JSClassDefinition def =
      JSClassCreator::GetClassDefinition(JSCWasmExt::kWasmName, Finalize);
  // FIXME(): add WebAssemlby's static methods property in static_funcs
  JSStaticFunction static_funcs[] = {{0, 0, 0}};
  def.staticFunctions = static_funcs;
  JSClassRef wasm_jsclass = JSClassCreate(&def);

  WasmRuntime* rt = new WasmRuntime(new JSCEnv(ctx, ctx_invalid));
  *rt_ptr = rt;
  JSObjectRef wasm_jsobj = JSObjectMake(ctx, wasm_jsclass, rt);
  return wasm_jsobj;
}

void JSCWasmExt::Finalize(JSObjectRef obj) {
  WLOGD("%s: finalizing JSC WebAssembly...", __func__);
  WasmRuntime* rt = static_cast<WasmRuntime*>(JSObjectGetPrivate(obj));
  if (rt) WasmRuntime::Free(rt);
}

}  // namespace jsc
}  // namespace vmsdk
