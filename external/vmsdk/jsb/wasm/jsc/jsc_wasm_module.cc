// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "jsc/jsc_wasm_module.h"

#include "common/messages.h"
#include "common/wasm_log.h"
#include "common/wasm_utils.h"
#include "jsc/jsc_builtin_objects.h"
#include "jsc/jsc_class_creator.h"
#include "jsc/jsc_ext_api.h"
#include "runtime/wasm_module.h"
#include "runtime/wasm_runtime.h"

namespace vmsdk {
using vmsdk::ExceptionMessages;
namespace jsc {

JSCWasmModule::~JSCWasmModule() { delete module_; }

bool JSCWasmModule::IsWasmModuleObject(JSContextRef ctx,
                                       JSObjectRef constructor,
                                       JSObjectRef target,
                                       JSValueRef* exception) {
  return JSCExtAPI::HasInstance(ctx, constructor, target, exception);
}

JSObjectRef JSCWasmModule::CreateJSObject(JSContextRef ctx,
                                          JSObjectRef constructor,
                                          WasmModule* module,
                                          JSValueRef* exception) {
  JSClassDefinition def =
      JSClassCreator::GetClassDefinition("Module", Finalize);
  JSClassRef obj_jsclass = JSClassCreate(&def);
  JSCWasmModule* module_data = new JSCWasmModule(module);
  JSObjectRef obj = JSObjectMake(ctx, obj_jsclass, module_data);

  JSValueRef prototype = JSObjectGetProperty(
      ctx, constructor, JSCBuiltinObjects::PrototypeStr(), exception);
  prototype = JSValueToObject(ctx, prototype, exception);
  JSObjectSetPrototype(ctx, obj, prototype);
  return obj;
}

void JSCWasmModule::Finalize(JSObjectRef object) {
  JSCWasmModule* mod =
      reinterpret_cast<JSCWasmModule*>(JSObjectGetPrivate(object));
  if (mod) {
    delete mod;
  }
}

JSObjectRef JSCWasmModule::CreatePrototype(JSContextRef ctx,
                                           JSValueRef* exception) {
  JSClassDefinition def =
      JSClassCreator::GetClassDefinition("Module.Prototype", NULL);

  JSClassRef prototype_jsclass = JSClassCreate(&def);
  // FIXME(): add the private data to be attached to constructor;
  JSObjectRef prototype = JSObjectMake(ctx, prototype_jsclass, NULL);

  return prototype;
}

JSObjectRef JSCWasmModule::CreateConstructor(JSContextRef ctx, WasmRuntime* rt,
                                             JSValueRef* exception) {
  JSClassDefinition def = JSClassCreator::GetClassDefinition(
      "WebAssembly.Module", NULL, CallAsConstructor);

  JSPropertyAttributes default_attr = JSClassCreator::DefaultAttr();
  JSStaticFunction static_funcs[] = {
      {"exports", ExportsCallback, default_attr},
      {"imports", ImportsCallback, default_attr},
      // FIXME(wasm): implement this function.
      //  {"customSection", nullptr, default_attr},
      {0, 0, 0}};
  def.staticFunctions = static_funcs;

  JSClassRef ctor_jsclass = JSClassCreate(&def);
  JSObjectRef ctor = JSObjectMake(ctx, ctor_jsclass, rt);

  JSObjectRef prototype = CreatePrototype(ctx, exception);
  JSCExtAPI::InitConstructor(ctx, ctor, "Module", prototype, exception);

  JS_ENV* env = rt->GetJSEnv();
  if (wasm_likely(env)) {
    env->SetModuleConstructor(ctor);
  }

  return ctor;
}

JSObjectRef JSCWasmModule::CallAsConstructor(JSContextRef ctx,
                                             JSObjectRef constructor,
                                             size_t argumentCount,
                                             const JSValueRef arguments[],
                                             JSValueRef* exception) {
  WLOGI("JSCWasmModule::CallAsConstructor @ %s\n", __func__);
  if (argumentCount == 0) {
    if (exception)
      *exception =
          JSCExtAPI::CreateException(ctx, ExceptionMessages::kTypedArrayNeeded);
    return nullptr;
  }
  size_t byteLength = 0;
  uint8_t* data = GetWireBytes(ctx, arguments[0], &byteLength, exception);
  if (*exception) return nullptr;
  if (data == nullptr) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kTypedArrayNeeded);
    return nullptr;
  }

  WasmRuntime* wasm_rt =
      reinterpret_cast<WasmRuntime*>(JSObjectGetPrivate(constructor));
  WasmModule* mod = wasm_rt->CreateWasmModule(data, byteLength);

  if (mod == nullptr) {
    *exception = JSCExtAPI::CreateException(
        ctx, ExceptionMessages::kCreatingModuleFailed);
    return nullptr;
  }
  return CreateJSObject(ctx, constructor, mod, exception);
}

uint8_t* JSCWasmModule::GetWireBytes(JSContextRef ctx, JSValueRef val,
                                     size_t* byteLength,
                                     JSValueRef* exception) {
  JSTypedArrayType type{JSValueGetTypedArrayType(ctx, val, exception)};
  if (type == kJSTypedArrayTypeNone) {
    if (exception)
      *exception =
          JSCExtAPI::CreateException(ctx, ExceptionMessages::kTypedArrayNeeded);
    return nullptr;
  }

  JSObjectRef buffer = JSValueToObject(ctx, val, nullptr);
  if (type != kJSTypedArrayTypeArrayBuffer) {
    *byteLength = JSObjectGetTypedArrayByteLength(ctx, buffer, exception);
    size_t byte_offset{JSObjectGetTypedArrayByteOffset(ctx, buffer, exception)};
    uint8_t* data = static_cast<uint8_t*>(
                        JSObjectGetTypedArrayBytesPtr(ctx, buffer, exception)) +
                    byte_offset;
    return data;
  }
  *byteLength = JSObjectGetArrayBufferByteLength(ctx, buffer, exception);
  return static_cast<uint8_t*>(
      JSObjectGetArrayBufferBytesPtr(ctx, buffer, exception));
}

JSValueRef JSCWasmModule::ExportsCallback(
    JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject,
    size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
  if (argumentCount == 0 && !JSValueIsObject(ctx, arguments[0])) {
    if (exception)
      *exception =
          JSCExtAPI::CreateException(ctx, ExceptionMessages::kModuleNeeded);
    return nullptr;
  }
  JSObjectRef module_obj = JSValueToObject(ctx, arguments[0], nullptr);
  JSObjectRef res = JSObjectMakeArray(ctx, 0, NULL, nullptr);

  JSCWasmModule* js_mod =
      reinterpret_cast<JSCWasmModule*>(JSObjectGetPrivate(module_obj));
  if (js_mod && js_mod->module_) {
    WasmModule* mod = js_mod->module_;
    mod->exports(JSCEnv::FromJSC(ctx), JSCEnv::FromJSC(res), nullptr);
  }

  return res;
}

JSValueRef JSCWasmModule::ImportsCallback(
    JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject,
    size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
  if (argumentCount == 0 && !JSValueIsObject(ctx, arguments[0])) {
    if (exception)
      *exception =
          JSCExtAPI::CreateException(ctx, ExceptionMessages::kModuleNeeded);
    return nullptr;
  }
  JSObjectRef module_obj = JSValueToObject(ctx, arguments[0], nullptr);
  JSObjectRef res = JSObjectMakeArray(ctx, 0, NULL, nullptr);

  JSCWasmModule* js_mod =
      reinterpret_cast<JSCWasmModule*>(JSObjectGetPrivate(module_obj));
  if (js_mod && js_mod->module_) {
    WasmModule* mod = js_mod->module_;
    mod->imports(JSCEnv::FromJSC(ctx), JSCEnv::FromJSC(res), nullptr);
  }

  return res;
}

}  // namespace jsc
}  // namespace vmsdk