// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "jsc/jsc_ext_api.h"

#include <cmath>

#include "common/wasm_log.h"
#include "jsc/jsc_builtin_objects.h"
#include "jsc/jsc_class_creator.h"

namespace vmsdk {
namespace jsc {

JSObjectRef JSCExtAPI::JSFunctionMake(JSContextRef ctx, const char* name,
                                      JSObjectCallAsFunctionCallback cb) {
  JSStringRef func_name = JSStringCreateWithUTF8CString(name);
  return JSObjectMakeFunctionWithCallback(ctx, func_name, cb);
}

void JSCExtAPI::InitConstructor(JSContextRef ctx, JSObjectRef ctor,
                                const char* name, JSObjectRef prototype,
                                JSValueRef* exception) {
  // set [[prototype]] = __proto__ for constructor
  // JSObjectSetPrototype(
  //     ctx, ctor,
  //     JSCBuiltinObjects::GetInstance(ctx)->GetFunctionPrototype());
  JSValueRef name_str =
      JSValueMakeString(ctx, JSStringCreateWithUTF8CString(name));
  JSObjectSetProperty(
      ctx, ctor, JSStringCreateWithUTF8CString("name"), name_str,
      kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum |
          kJSPropertyAttributeDontDelete,
      exception);
  JSObjectSetProperty(ctx, ctor, JSCBuiltinObjects::PrototypeStr(), prototype,
                      kJSPropertyAttributeReadOnly |
                          kJSPropertyAttributeDontEnum |
                          kJSPropertyAttributeDontDelete,
                      exception);
  JSObjectSetProperty(ctx, prototype,
                      JSStringCreateWithUTF8CString("constructor"), ctor,
                      kJSPropertyAttributeDontEnum, exception);
}

void JSCExtAPI::Attach(JSContextRef ctx, const char* name, JSObjectRef obj,
                       JSPropertyAttributes attrs, JSObjectRef parent,
                       JSValueRef* exception) {
  if (!parent) {
    parent = JSContextGetGlobalObject(ctx);
  }

  JSStringRef prop_name = JSStringCreateWithUTF8CString(name);
  JSObjectSetProperty(ctx, parent, prop_name, obj, attrs, exception);
}

static JSValueRef DefaultDebugCallback(JSContextRef ctx, JSObjectRef function,
                                       JSObjectRef thisObject,
                                       size_t argumentCount,
                                       const JSValueRef arguments[],
                                       JSValueRef* exception) {
  WLOGI("DebugCallback @ %s\n", __func__);
  return NULL;
}

void JSCExtAPI::AttachDebugger(JSContextRef ctx, JSObjectRef obj,
                               const char* name, JSValueRef* exception,
                               DebugCallback callback) {
  JSStringRef func_name = JSStringCreateWithUTF8CString(name);
  if (!callback) {
    callback = DefaultDebugCallback;
  }
  JSObjectRef debugger = JSCExtAPI::JSFunctionMake(ctx, name, callback);
  JSObjectSetProperty(ctx, obj, func_name, debugger, kJSPropertyAttributeNone,
                      exception);
}

bool JSCExtAPI::ObjectHasProperty(JSContextRef ctx, JSObjectRef object,
                                  const char* name) {
  JSStringRef property_name = JSStringCreateWithUTF8CString(name);
  return JSObjectHasProperty(ctx, object, property_name);
}

JSObjectRef JSCExtAPI::ObjectGetProperty(JSContextRef ctx, JSObjectRef object,
                                         const char* name) {
  JSStringRef property_name = JSStringCreateWithUTF8CString(name);
  JSValueRef obj = JSObjectGetProperty(ctx, object, property_name, NULL);
  return JSValueToObject(ctx, obj, NULL);
}

void JSCExtAPI::DefineProperties(JSContextRef ctx, JSObjectRef object,
                                 const property_descriptor* descriptor,
                                 JSValueRef* exception) {
  JSObjectRef fn = JSCBuiltinObjects::GetFnDefineProperty(ctx, exception);
  if (!fn) return;
  while (descriptor && descriptor->name) {
    DefineProperty(ctx, object, fn, *descriptor, exception);
    ++descriptor;
  }
}

void JSCExtAPI::DefineProperty(JSContextRef ctx, JSObjectRef object,
                               JSObjectRef fnDefineProperty,
                               const property_descriptor& descriptor,
                               JSValueRef* exception) {
  JSObjectRef desc_ref = JSObjectMake(ctx, nullptr, nullptr);
  JSObjectSetProperty(
      ctx, desc_ref, JSStringCreateWithUTF8CString("enumerable"),
      JSValueMakeBoolean(ctx, descriptor.attributes & prop_enumerable),
      kJSPropertyAttributeNone, exception);
  JSObjectSetProperty(
      ctx, desc_ref, JSStringCreateWithUTF8CString("configurable"),
      JSValueMakeBoolean(ctx, descriptor.attributes & prop_configurable),
      kJSPropertyAttributeNone, exception);
  if (descriptor.getter) {
    JSObjectRef getter =
        JSObjectMakeFunctionWithCallback(ctx, NULL, descriptor.getter);
    JSObjectSetProperty(ctx, desc_ref, JSStringCreateWithUTF8CString("get"),
                        getter, kJSPropertyAttributeNone, exception);
  }
  if (descriptor.setter) {
    JSObjectRef setter =
        JSObjectMakeFunctionWithCallback(ctx, NULL, descriptor.setter);
    JSObjectSetProperty(ctx, desc_ref, JSStringCreateWithUTF8CString("set"),
                        setter, kJSPropertyAttributeNone, exception);
  }

  JSValueRef args[] = {
      object,
      JSValueMakeString(ctx, JSStringCreateWithUTF8CString(descriptor.name)),
      desc_ref};
  JSObjectCallAsFunction(ctx, fnDefineProperty, nullptr, 3, args, exception);
}

// static
bool JSCExtAPI::HasInstance(JSContextRef ctx, JSObjectRef constructor,
                            JSValueRef value, JSValueRef* exception) {
  // constructor here is WebAssembly.XXX.prototype.constructor
  JSValueRef proto = JSObjectGetProperty(
      ctx, constructor, JSCBuiltinObjects::PrototypeStr(), exception);

  if (!JSValueIsObject(ctx, value)) {
    return false;
  }

  if (!JSValueIsObject(ctx, proto)) {
    if (exception) {
      *exception = JSCExtAPI::CreateException(
          ctx,
          "instanceof called on an object with an invalid prototype property.");
    }
    return false;
  }

  JSObjectRef object = JSValueToObject(ctx, value, exception);
  if ((exception && *exception) || !object) {
    return false;
  }

  while (true) {
    JSValueRef object_value = JSObjectGetPrototype(ctx, object);
    if (!JSValueIsObject(ctx, object_value)) {
      return false;
    }

    object = JSValueToObject(ctx, object_value, exception);
    if ((exception && *exception) || !object) {
      return false;
    }

    if (JSValueIsStrictEqual(ctx, proto, object)) {
      return true;
    }
  }

  return false;
}

JSValueRef JSCExtAPI::ThrowCallException(JSContextRef ctx, JSObjectRef function,
                                         JSObjectRef thisObject,
                                         size_t argumentCount,
                                         const JSValueRef arguments[],
                                         JSValueRef* exception) {
  if (exception) {
    JSStringRef js_str = JSValueToStringCopy(ctx, function, NULL);
    size_t len = JSStringGetLength(js_str);
    char str[len];
    JSStringGetUTF8CString(js_str, str, len);
    char msg[256] = {0};
    snprintf(msg, 255, "Exception by invoke Object without [[Call]] on %s",
             str);
    *exception = CreateException(ctx, msg);
  }
  return JSValueMakeUndefined(ctx);
}

JSValueRef JSCExtAPI::CreateException(JSContextRef ctx, const char* msg) {
  DCHECK(msg != nullptr);
  JSValueRef error_msg =
      JSValueMakeString(ctx, JSStringCreateWithUTF8CString(msg));
  JSObjectRef exception = JSObjectMakeError(ctx, 1, &error_msg, NULL);
  return exception;
}

bool JSCExtAPI::GetInt32(JSContextRef ctx, JSValueRef js_val, int32_t* res) {
  double ret = JSValueToNumber(ctx, js_val, NULL);
  if (!std::isfinite(ret) || ret > std::numeric_limits<int32_t>::max()) {
    return false;
  }
  *res = static_cast<int32_t>(ret);
  return true;
}

}  // namespace jsc
}  // namespace vmsdk