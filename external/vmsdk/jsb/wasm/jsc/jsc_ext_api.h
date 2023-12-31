// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_JSC_EXT_API_H_
#define JSB_WASM_JSC_EXT_API_H_

#include <JavaScriptCore/JavaScriptCore.h>

namespace vmsdk {
namespace jsc {

typedef enum {
  prop_none = 0,
  prop_writable = 1 << 0,
  prop_enumerable = 1 << 1,
  prop_configurable = 1 << 2,
  prop_default_method = prop_enumerable | prop_configurable,
  prop_default_property = prop_enumerable | prop_configurable | prop_writable,
} property_attributes;

typedef JSObjectCallAsFunctionCallback JSObjectPropertyGetter;
typedef JSObjectCallAsFunctionCallback JSObjectPropertySetter;

typedef struct {
  const char* name;
  JSObjectPropertyGetter getter;
  JSObjectPropertySetter setter;
  property_attributes attributes;
} property_descriptor;

typedef JSValueRef (*DebugCallback)(JSContextRef ctx, JSObjectRef function,
                                    JSObjectRef thisObject,
                                    size_t argumentCount,
                                    const JSValueRef arguments[],
                                    JSValueRef* exception);

class JSCExtAPI {
 public:
  // evaluate script with exception handling
  static JSObjectRef JSFunctionMake(JSContextRef ctx, const char* name,
                                    JSObjectCallAsFunctionCallback cb);

  static void InitConstructor(JSContextRef ctx, JSObjectRef ctor,
                              const char* name, JSObjectRef prototype,
                              JSValueRef* exception);
  // attatch obj to parent (parent[name] = obj), if parent == NULL adopt Global
  // as parent
  static void Attach(JSContextRef ctx, const char* name, JSObjectRef obj,
                     JSPropertyAttributes attrs, JSObjectRef parent = NULL,
                     JSValueRef* exception = NULL);

  static void DefineProperties(JSContextRef ctx, JSObjectRef object,
                               const property_descriptor* descriptor,
                               JSValueRef* exception);

  static bool ObjectHasProperty(JSContextRef ctx, JSObjectRef object,
                                const char* name);
  static JSObjectRef ObjectGetProperty(JSContextRef ctx, JSObjectRef object,
                                       const char* name);

  // add the debug method
  static void AttachDebugger(JSContextRef ctx, JSObjectRef obj,
                             const char* name, JSValueRef* exception = NULL,
                             DebugCallback callback = NULL);

  static JSValueRef ThrowCallException(JSContextRef ctx, JSObjectRef function,
                                       JSObjectRef thisObject,
                                       size_t argumentCount,
                                       const JSValueRef arguments[],
                                       JSValueRef* exception);

  static bool HasInstance(JSContextRef ctx, JSObjectRef constructor,
                          JSValueRef possibleInstance, JSValueRef* exception);

  static JSValueRef CreateException(JSContextRef ctx, const char* msg);

  static bool GetInt32(JSContextRef ctx, JSValueRef js_val, int32_t* res);

 private:
  static void DefineProperty(JSContextRef ctx, JSObjectRef object,
                             JSObjectRef fnDefineProperty,
                             const property_descriptor& descriptor,
                             JSValueRef* exception = NULL);
};

}  // namespace jsc
}  // namespace vmsdk
#endif  // JSB_WASM_JSC_EXT_API_H_
