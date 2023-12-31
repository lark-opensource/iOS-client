// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "jsc/jsc_wasm_instance.h"

#include <memory>

#include "common/messages.h"
#include "common/wasm_log.h"
#include "common/wasm_utils.h"
#include "jsc/js_env_jsc.h"
#include "jsc/jsc_builtin_objects.h"
#include "jsc/jsc_class_creator.h"
#include "jsc/jsc_ext_api.h"
#include "jsc/jsc_wasm_module.h"
#include "runtime/wasm_module.h"
#include "runtime/wasm_runtime.h"

namespace vmsdk {
using vmsdk::ExceptionMessages;
namespace jsc {

JSCWasmInstance::JSCWasmInstance(std::shared_ptr<WasmInstance>& instance)
    : instance_(instance) {}

JSCWasmInstance::~JSCWasmInstance() {
  WLOGD("%s: instance use_count: %d\n", __func__, (int)instance_.use_count());
}

JSObjectRef JSCWasmInstance::CreateJSObject(
    JSContextRef ctx, JSObjectRef constructor,
    std::shared_ptr<WasmInstance>& instance, JSValueRef* exception) {
  JSClassDefinition def =
      JSClassCreator::GetClassDefinition("Instance", Finalize);
  JSClassRef obj_jsclass = JSClassCreate(&def);
  JSCWasmInstance* inst_data = new JSCWasmInstance(instance);
  JSObjectRef obj = JSObjectMake(ctx, obj_jsclass, inst_data);

  JSValueRef prototype = JSObjectGetProperty(
      ctx, constructor, JSCBuiltinObjects::PrototypeStr(), exception);
  prototype = JSValueToObject(ctx, prototype, exception);
  JSObjectSetPrototype(ctx, obj, prototype);
  return obj;
}

void JSCWasmInstance::Finalize(JSObjectRef object) {
  JSCWasmInstance* inst =
      reinterpret_cast<JSCWasmInstance*>(JSObjectGetPrivate(object));
  delete inst;
}

JSObjectRef JSCWasmInstance::CreatePrototype(JSContextRef ctx,
                                             JSValueRef* exception) {
  JSClassDefinition def =
      JSClassCreator::GetClassDefinition("Instance.Prototype", NULL);

  JSClassRef prototype_jsclass = JSClassCreate(&def);
  // FIXME(): add the private data to be attached to constructor;
  JSObjectRef prototype = JSObjectMake(ctx, prototype_jsclass, NULL);

  return prototype;
}

JSObjectRef JSCWasmInstance::CreateConstructor(JSContextRef ctx,
                                               WasmRuntime* rt,
                                               JSValueRef* exception) {
  JSClassDefinition def = JSClassCreator::GetClassDefinition(
      "WebAssembly.Instance", NULL, CallAsConstructor);

  JSClassRef ctor_jsclass = JSClassCreate(&def);
  // set the private data with wctx object(WasmRuntime*)
  JSObjectRef ctor = JSObjectMake(ctx, ctor_jsclass, rt);

  JSObjectRef prototype = CreatePrototype(ctx, exception);
  JSCExtAPI::InitConstructor(ctx, ctor, "Instance", prototype, exception);

  return ctor;
}

JSObjectRef JSCWasmInstance::CallAsConstructor(JSContextRef ctx,
                                               JSObjectRef constructor,
                                               size_t argumentCount,
                                               const JSValueRef arguments[],
                                               JSValueRef* exception) {
  WLOGI("JSCWasmInstance::CallAsConstructor @ %s\n", __func__);
  if (argumentCount == 0 || !JSValueIsObject(ctx, arguments[0])) {
    if (exception) {
      *exception =
          JSCExtAPI::CreateException(ctx, ExceptionMessages::kModuleNeeded);
    }
    return nullptr;
  }
  JSObjectRef module = JSValueToObject(ctx, arguments[0], nullptr);
  WasmRuntime* wasm_rt =
      reinterpret_cast<WasmRuntime*>(JSObjectGetPrivate(constructor));
  if (!wasm_rt) {
    if (exception) {
      *exception = JSCExtAPI::CreateException(
          ctx, ExceptionMessages::kInstantiationFailed);
    }
    return nullptr;
  }

  {
    JSObjectRef module_ctor = JS_NULL;
    JS_ENV* js_env = wasm_rt->GetJSEnv();
    if (wasm_likely(js_env)) {
      module_ctor = js_env->js_module_constructor();
    }
    if (!JSCWasmModule::IsWasmModuleObject(ctx, module_ctor, module,
                                           exception)) {
      if (exception) {
        *exception =
            JSCExtAPI::CreateException(ctx, ExceptionMessages::kModuleNeeded);
      }
      return nullptr;
    }
  }

  JSObjectRef import_obj = nullptr;
  if (argumentCount > 1 && JSValueIsObject(ctx, arguments[1]))
    import_obj = JSValueToObject(ctx, arguments[1], nullptr);

  JSCWasmModule* js_module =
      reinterpret_cast<JSCWasmModule*>(JSObjectGetPrivate(module));
  WasmModule* wasm_module = js_module->GetModulePtr();
  if (!wasm_module) {
    if (exception) {
      *exception = JSCExtAPI::CreateException(
          ctx, ExceptionMessages::kInstantiationFailed);
    }
    return nullptr;
  }

  std::shared_ptr<WasmInstance> wasm_instance =
      wasm_rt->CreateWasmInstance(wasm_module, JSCEnv::FromJSC(import_obj));
  if (!wasm_instance) {
    if (exception) {
      *exception = JSCExtAPI::CreateException(
          ctx, ExceptionMessages::kInstantiationFailed);
    }
    return nullptr;
  }

  JSObjectRef result =
      CreateJSObject(ctx, constructor, wasm_instance, exception);
  JSObjectRef exported_obj = JSObjectMake(ctx, nullptr, nullptr);

  if (wasm_rt->FillExportsObject(JSCEnv::FromJSC(exported_obj), wasm_module,
                                 wasm_instance)) {
    WLOGE("wasm instance exporting failed.");
    if (exception) {
      *exception = JSCExtAPI::CreateException(
          ctx, ExceptionMessages::kInstantiationFailed);
    }
    return nullptr;
  } else {
    JSObjectSetProperty(ctx, result, JSStringCreateWithUTF8CString("exports"),
                        exported_obj, JSClassCreator::DefaultAttr(), nullptr);
  }

  return result;
}

}  // namespace jsc
}  // namespace vmsdk
