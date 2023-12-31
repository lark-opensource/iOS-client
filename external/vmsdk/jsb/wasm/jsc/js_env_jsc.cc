// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "js_env_jsc.h"

#include "jsc_builtin_objects.h"
#include "jsc_ext_api.h"
#include "jsc_wasm_global.h"
#include "jsc_wasm_memory.h"
#include "jsc_wasm_table.h"
#include "runtime/wasm_func_pack.h"
#include "runtime/wasm_runtime.h"

namespace vmsdk {
using wasm::WasmFuncPack;
using wasm::WasmGlobal;
using wasm::WasmMemory;
using wasm::WasmRuntime;
using wasm::WasmTable;

namespace jsc {

JSCEnv::JSCEnv(JSContextRef ctx, std::atomic<bool>* ctx_invalid)
    : js_ctx_(ctx),
      ctx_invalid_(ctx_invalid),
      undef_(FromJSC(JSValueMakeUndefined(ctx))),
      null_(FromJSC(JSValueMakeNull(ctx))),
      wasm_rt_(nullptr) {
  JSClassDefinition cdef =
      JSClassCreator::GetClassDefinition("wasm.func", WasmFuncFinalizer);
  cdef.callAsFunction = CallWasmFunc;
  wasm_func_class_ = JSClassCreate(&cdef);
}

bool JSCEnv::IsJSObject(js_value val) {
  return JSValueIsObject(js_ctx_, ToJSC<JSValueRef>(val));
}

bool JSCEnv::IsJSWasmFunction(js_value val) {
  JSValueRef jsc_val = ToJSC<JSValueRef>(val);
  return JSValueIsObjectOfClass(js_ctx_, jsc_val, wasm_func_class_);
}

bool JSCEnv::IsJSFunction(js_value val) {
  JSValueRef jsc_val = ToJSC<JSValueRef>(val);
  if (JSValueIsObject(js_ctx_, jsc_val)) {
    JSObjectRef obj = JSValueToObject(js_ctx_, jsc_val, nullptr);
    return JSObjectIsFunction(js_ctx_, obj);
  }
  return false;
}

bool JSCEnv::IsNumber(js_value val) {
  return JSValueIsNumber(js_ctx_, ToJSC<JSValueRef>(val));
}

bool JSCEnv::IsUndefined(js_value val) {
  return JSValueIsUndefined(js_ctx_, ToJSC<JSValueRef>(val));
}

bool JSCEnv::IsNull(js_value val) { return ToJSC<JSValueRef>(val) == nullptr; }

bool JSCEnv::SetProperty(js_value obj, const char* name, js_value val) {
  JSValueRef exception = nullptr;
  JSObjectSetProperty(
      js_ctx_, ToJSC<JSObjectRef>(obj), JSStringCreateWithUTF8CString(name),
      ToJSC<JSValueRef>(val), kJSPropertyAttributeNone, &exception);
  return exception == nullptr;
}

bool JSCEnv::SetPropertyAtIndex(js_value obj, uint32_t index, js_value val) {
  JSValueRef exception = nullptr;
  JSObjectSetPropertyAtIndex(js_ctx_, ToJSC<JSObjectRef>(obj), index,
                             ToJSC<JSValueRef>(val), &exception);
  return exception == nullptr;
}

js_value JSCEnv::GetProperty(js_value target, const char* name) {
  // Caller must ensure that target is a JSObjectRef.
  return FromJSC(JSObjectGetProperty(js_ctx_, ToJSC<JSObjectRef>(target),
                                     JSStringCreateWithUTF8CString(name),
                                     nullptr));
}

js_value JSCEnv::MakeFunction(const char* name, void* pack) {
  JSObjectRef function = JSObjectMake(js_ctx_, wasm_func_class_, pack);
  if (name) {
    JSValueRef name_ref =
        JSValueMakeString(js_ctx_, JSStringCreateWithUTF8CString(name));
    JSObjectSetProperty(js_ctx_, function,
                        JSStringCreateWithUTF8CString("name"), name_ref,
                        JSClassCreator::DefaultAttr(), nullptr);
  }
  JSValueRef exception = nullptr;
  JSObjectRef js_function =
      JSCBuiltinObjects::GetJSFunction(js_ctx_, &exception);
  if (js_function == nullptr || exception) {
    return nullptr;
  }
  JSValueRef may_func_prototype = JSObjectGetPrototype(js_ctx_, js_function);
  JSObjectSetPrototype(js_ctx_, function, may_func_prototype);
  return FromJSC(function);
}

js_value JSCEnv::MakePlainObject() {
  return FromJSC(JSObjectMake(js_ctx_, nullptr, nullptr));
}

js_value JSCEnv::ReserveObject(js_value obj) {
  JSValueProtect(js_ctx_, ToJSC<JSValueRef>(obj));
  return obj;
}

void JSCEnv::ReleaseObject(js_value obj) {
  JSValueUnprotect(js_ctx_, ToJSC<JSValueRef>(obj));
}

js_value JSCEnv::MakeString(const char* str) {
  return FromJSC(
      JSValueMakeString(js_ctx_, JSStringCreateWithUTF8CString(str)));
}

js_value JSCEnv::MakeNumber(double num) {
  return FromJSC(JSValueMakeNumber(js_ctx_, num));
}

js_value JSCEnv::MakeException(const char* msg) {
  return FromJSC(JSCExtAPI::CreateException(js_ctx_, msg));
}

js_value JSCEnv::MakeMemory(WasmMemory* mem, size_t pages) {
  JSValueRef exception{NULL};
  JSObjectRef js_obj = JSCWasmMemory::CreateJSObject(
      js_ctx_, js_memory_constructor_, mem, pages, nullptr);
  if (exception) js_obj = nullptr;
  return FromJSC(js_obj);
}

JSValueRef JSCEnv::CallWasmFunc(JSContextRef ctx, JSObjectRef function,
                                JSObjectRef thisObject, size_t argc,
                                const JSValueRef arguments[],
                                JSValueRef* exception) {
  void* pack = JSObjectGetPrivate(function);
  if (pack == nullptr) {
    if (exception)
      *exception = JSCExtAPI::CreateException(
          ctx, "Invalid wasm function to be called.");
    return nullptr;
  }
  return ToJSC<JSValueRef>(WasmFuncPack::CallWasmFunc(
      pack, argc, FromJSC(&arguments[0]), FromJSC(exception)));
}

double JSCEnv::ValueToNumber(js_value val) {
  return JSValueToNumber(js_ctx_, ToJSC<JSValueRef>(val), nullptr);
}

js_value JSCEnv::ValueToObject(js_value val) {
  JSValueRef jsc_val = ToJSC<JSValueRef>(val);
  if (JSValueIsObject(js_ctx_, jsc_val))
    return FromJSC(JSValueToObject(js_ctx_, jsc_val, nullptr));
  return nullptr;
}

js_value JSCEnv::ValueToFunction(js_value val) {
  JSValueRef jsc_val = ToJSC<JSValueRef>(val);
  if (JSValueIsObject(js_ctx_, jsc_val)) {
    JSObjectRef maybe_func = JSValueToObject(js_ctx_, jsc_val, nullptr);
    if (JSObjectIsFunction(js_ctx_, maybe_func)) return FromJSC(maybe_func);
  }
  return nullptr;
}

js_value JSCEnv::CallAsFunction(js_value function, js_value thisObject,
                                size_t argc, js_value args[],
                                js_value* exception) {
  JSValueRef jsc_exception = nullptr;
  JSValueRef val = JSObjectCallAsFunction(
      js_ctx_, ToJSC<JSObjectRef>(function), nullptr, argc,
      ToJSC<const JSValueRef*>(args), &jsc_exception);
  if (jsc_exception && exception) *exception = FromJSC(jsc_exception);
  return FromJSC(val);
}

void JSCEnv::WasmFuncFinalizer(JSObjectRef func) {
  WasmRuntime::WasmFuncPackFinalizer(JSObjectGetPrivate(func));
}

WasmGlobal* JSCEnv::GetGlobal(js_value val) {
  JSObjectRef val_obj = ToJSC<JSObjectRef>(val);
  JSCWasmGlobal* jsc_global =
      reinterpret_cast<JSCWasmGlobal*>(JSObjectGetPrivate(val_obj));
  return jsc_global->global();
}

WasmMemory* JSCEnv::GetMemory(js_value val) {
  // FIXME(yangwenming): check whether this is a wasm memory.
  JSObjectRef val_obj = ToJSC<JSObjectRef>(val);
  JSCWasmMemory* jsc_memory =
      reinterpret_cast<JSCWasmMemory*>(JSObjectGetPrivate(val_obj));
  return jsc_memory->memory();
}

WasmTable* JSCEnv::GetTable(js_value val) {
  JSObjectRef val_obj = ToJSC<JSObjectRef>(val);
  if (JSCWasmTable::IsJSCWasmTable(js_ctx_, val_obj)) {
    JSCWasmTable* jsc_table =
        reinterpret_cast<JSCWasmTable*>(JSObjectGetPrivate(val_obj));
    return jsc_table->table();
  }
  return nullptr;
}

js_value JSCEnv::MakeTable(WasmTable* table) {
  JSValueRef exception{NULL};
  JSValueRef ret = JSCWasmTable::CreateJSObject(js_ctx_, js_table_constructor_,
                                                table, &exception);
  if (exception) ret = nullptr;
  return FromJSC(ret);
}

js_value JSCEnv::MakeGlobal(WasmGlobal* gbl) {
  JSValueRef exception{NULL};
  JSObjectRef js_obj = JSCWasmGlobal::CreateJSObject(
      js_ctx_, js_global_constructor_, gbl, nullptr);
  if (exception) js_obj = nullptr;
  return FromJSC(js_obj);
}

}  // namespace jsc
}  // namespace vmsdk
