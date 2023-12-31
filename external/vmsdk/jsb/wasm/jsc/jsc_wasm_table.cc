// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "jsc_wasm_table.h"

#include "common/messages.h"
#include "common/wasm_log.h"
#include "common/wasm_utils.h"
#include "js_env_jsc.h"
#include "jsc_builtin_objects.h"
#include "jsc_class_creator.h"
#include "jsc_ext_api.h"
#include "runtime/wasm_runtime.h"
#include "runtime/wasm_table.h"

namespace vmsdk {
namespace wasm {
class WasmFuncPack;
}
namespace jsc {
using wasm::TableElementType;
using wasm::WasmFuncPack;

JSClassDefinition JSCWasmTable::class_def_ =
    JSClassCreator::GetClassDefinition("Table", Finalize);

JSClassRef JSCWasmTable::class_ref_ = JSClassRetain(JSClassCreate(&class_def_));

JSCWasmTable::~JSCWasmTable() { delete table_; }

void JSCWasmTable::Finalize(JSObjectRef object) {
  JSCWasmTable* tbl =
      reinterpret_cast<JSCWasmTable*>(JSObjectGetPrivate(object));
  if (tbl) {
    delete tbl;
  }
}

JSObjectRef JSCWasmTable::CreateJSObject(JSContextRef ctx,
                                         JSObjectRef constructor,
                                         WasmTable* table,
                                         JSValueRef* exception) {
  JSCWasmTable* table_data = new JSCWasmTable(table);
  JSObjectRef obj = JSObjectMake(ctx, class_ref_, table_data);

  JSValueRef prototype = JSObjectGetProperty(
      ctx, constructor, JSCBuiltinObjects::PrototypeStr(), exception);
  prototype = JSValueToObject(ctx, prototype, exception);
  JSObjectSetPrototype(ctx, obj, prototype);
  return obj;
}

bool JSCWasmTable::IsJSCWasmTable(JSContextRef ctx, JSValueRef target) {
  return JSValueIsObjectOfClass(ctx, target, class_ref_);
}

JSObjectRef JSCWasmTable::CallAsConstructor(JSContextRef ctx,
                                            JSObjectRef constructor,
                                            size_t argumentCount,
                                            const JSValueRef arguments[],
                                            JSValueRef* exception) {
  WLOGI("JSCWasmTable::CallAsConstructor @ %s\n", __func__);
  if (argumentCount < 1 || !JSValueIsObject(ctx, arguments[0])) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kDescriptorNeeded);
    return nullptr;
  }

  JSObjectRef table_desc = JSValueToObject(ctx, arguments[0], exception);
  JSValueRef init_value = JSObjectGetProperty(
      ctx, table_desc, JSStringCreateWithUTF8CString("initial"), NULL);
  if (JSValueIsUndefined(ctx, init_value)) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kDescriptorNeeded);
    return nullptr;
  }
  int32_t init_num;
  if (!JSCExtAPI::GetInt32(ctx, init_value, &init_num) || init_num < 0) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kInvalidInitialSize);
    return nullptr;
  }

  // get max page size
  JSValueRef max_value = JSObjectGetProperty(
      ctx, table_desc, JSStringCreateWithUTF8CString("maximum"), NULL);
  int32_t max_num;
  if (JSValueIsUndefined(ctx, max_value)) {
    max_num = MaxSaneTableSize;
  } else if (!JSCExtAPI::GetInt32(ctx, max_value, &max_num) || max_num < 0) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kInvalidTableLimits);
    return nullptr;
  }
  if (max_num > MaxSaneTableSize) {
    max_num = MaxSaneTableSize;
  }
  if (init_num > max_num) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kInvalidTableLimits);
    return nullptr;
  }

  JSValueRef element_type = JSObjectGetProperty(
      ctx, table_desc, JSStringCreateWithUTF8CString("element"), NULL);
  JSStringRef ty_str = NULL;
  if (JSValueIsString(ctx, element_type)) {
    ty_str = JSValueToStringCopy(ctx, element_type, NULL);
  }

  if (ty_str == NULL || !JSStringIsEqualToUTF8CString(ty_str, "anyfunc")) {
    *exception = JSCExtAPI::CreateException(
        ctx, ExceptionMessages::kUnsupportedElemType);
    return nullptr;
  }

  WasmRuntime* wasm_rt =
      reinterpret_cast<WasmRuntime*>(JSObjectGetPrivate(constructor));
  // NOTE: only support "anyfunc".
  WasmTable* table =
      wasm_rt->CreateWasmTable(init_num, max_num, TableElementType::FuncRef);
  if (table == nullptr) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kInternalError);
    return nullptr;
  }
  return CreateJSObject(ctx, constructor, table, exception);
}

JSObjectRef JSCWasmTable::CreatePrototype(JSContextRef ctx,
                                          JSValueRef* exception) {
  JSClassDefinition def =
      JSClassCreator::GetClassDefinition("Table.Prototype", NULL);
  JSPropertyAttributes default_attr = JSClassCreator::DefaultAttr();
  JSStaticFunction static_funcs[] = {{"set", SetIndexCallback, default_attr},
                                     {"get", GetIndexCallback, default_attr},
                                     {"grow", GrowCallback, default_attr},
                                     {0, 0, 0}};
  def.staticFunctions = static_funcs;
  JSClassRef prototype_jsclass = JSClassCreate(&def);
  // FIXME(): add the private data to be attached to constructor;
  JSObjectRef prototype = JSObjectMake(ctx, prototype_jsclass, NULL);

  // NOTE(TL;DR)
  // JSStaticValue will define static property for prototype object, where
  // The "thisObject" in Getter and "Setter" is the prototype rather than
  // the instance object itself; likely, The "jsObject" in
  // JSStaticValue.JSObjectGetProperty(ctx, jsObject, ...) is the object
  // which jsclass directly binded(created with jsclass).
  // In order to set property with callback binding to instance object,
  // we need to adopt the JSCJSCExtAPIEXT::DefineProperty to set properties.
  //
  // JSStaticValue static_values[] = {
  //     {"length", GetLengthCallback, 0, default_attr}, {0, 0, 0, 0}};
  // def.staticValues = static_values;
  property_descriptor instance_values[] = {
      {"length", GetLengthCallback, 0, prop_none}, {0, 0, 0, prop_none}};
  JSCExtAPI::DefineProperties(ctx, prototype, instance_values, exception);

  return prototype;
}

JSObjectRef JSCWasmTable::CreateConstructor(JSContextRef ctx, WasmRuntime* rt,
                                            JSValueRef* exception) {
  JSClassDefinition def = JSClassCreator::GetClassDefinition(
      "WebAssembly.Table", NULL, CallAsConstructor);
  JSClassRef ctor_jsclass = JSClassCreate(&def);
  // set the private data with wctx object(WasmRuntime*)
  JSObjectRef ctor = JSObjectMake(ctx, ctor_jsclass, rt);

  JSObjectRef prototype = CreatePrototype(ctx, exception);
  JSCExtAPI::InitConstructor(ctx, ctor, "Table", prototype, exception);

  JS_ENV* env = rt->GetJSEnv();
  if (wasm_likely(env)) {
    env->SetTableContructor(ctor);
  }
  return ctor;
}

JSValueRef JSCWasmTable::GetLengthCallback(
    JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject,
    size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
  if (!JSValueIsObjectOfClass(ctx, thisObject, class_ref_)) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kInvalidArgs);
    return nullptr;
  }
  JSCWasmTable* tbl =
      static_cast<JSCWasmTable*>(JSObjectGetPrivate(thisObject));
  DCHECK(tbl && "should not be null pointer");
  int length = (tbl && tbl->table_) ? tbl->table_->size() : 0;
  return JSValueMakeNumber(ctx, length);
}

JSValueRef JSCWasmTable::GetIndexCallback(
    JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject,
    size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
  WLOGD("table.get() @ %s\n", __func__);
  JSCWasmTable* tbl =
      static_cast<JSCWasmTable*>(JSObjectGetPrivate(thisObject));
  if (!tbl || !tbl->table_ || argumentCount < 1) {
    WLOGI("table.get() with invalid arguments!\n");
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kInvalidArgs);
    return nullptr;
  }

  int32_t index;
  if (!JSCExtAPI::GetInt32(ctx, arguments[0], &index) || index < 0) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kInvalidArgs);
    return nullptr;
  }
  if (index >= tbl->table_->size()) {
    // FIXME(): enable assert after implement table in WasmRuntime
    // assert(length > index && "invalid index value");
    WLOGI("table[%d] out of bound [%zu]\n", index, tbl->table_->size());
    *exception = JSCExtAPI::CreateException(
        ctx, ExceptionMessages::kOutOfBoundOperation);
    return nullptr;
  }

  return JSCEnv::ToJSC<JSValueRef>(tbl->table_->get(index));
}

JSValueRef JSCWasmTable::SetIndexCallback(
    JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject,
    size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
  WLOGD("table.set() @ %s\n", __func__);
  JSCWasmTable* tbl =
      static_cast<JSCWasmTable*>(JSObjectGetPrivate(thisObject));
  if (!tbl || !tbl->table_ || argumentCount < 2) {
    WLOGI("table.set() with invalid arguments!\n");
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kInvalidArgs);
    return nullptr;
  }
  int32_t index = 0;
  if (!JSCExtAPI::GetInt32(ctx, arguments[0], &index) || index < 0) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kInvalidArgs);
    return nullptr;
  }

  size_t length = tbl->table_->size();
  if (length <= index) {
    // FIXME(): enable assert after implement table in WasmRuntime
    // assert(length > index && "invalid index value");
    *exception = JSCExtAPI::CreateException(
        ctx, ExceptionMessages::kOutOfBoundOperation);
    return nullptr;
  }

  JSValueRef value_obj = arguments[1];
  WasmFuncPack* func_data = NULL;
  if (tbl->table_->is_valid_elem(JSCEnv::FromJSC(value_obj))) {
    func_data = static_cast<WasmFuncPack*>(
        JSObjectGetPrivate(JSValueToObject(ctx, value_obj, exception)));
  } else if (!JSValueIsNull(ctx, value_obj)) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kInvalidTableElem);
    return nullptr;
  }
  tbl->table_->set(index, func_data);
  return JSValueMakeUndefined(ctx);
}

JSValueRef JSCWasmTable::GrowCallback(JSContextRef ctx, JSObjectRef function,
                                      JSObjectRef thisObject,
                                      size_t argumentCount,
                                      const JSValueRef arguments[],
                                      JSValueRef* exception) {
  WLOGD("table.grow @ %s\n", __func__);
  JSCWasmTable* tbl =
      static_cast<JSCWasmTable*>(JSObjectGetPrivate(thisObject));
  if (!tbl || !tbl->table_ || argumentCount < 1) {
    WLOGD("table.grow with invalid arguments!\n");
    *exception = JSCExtAPI::CreateException(
        ctx, ExceptionMessages::kGrowWithInvalidArgs);
    return nullptr;
  }

  int32_t num = 0;
  if (!JSCExtAPI::GetInt32(ctx, arguments[0], &num) || num < 0) {
    *exception = JSCExtAPI::CreateException(
        ctx, ExceptionMessages::kGrowWithInvalidArgs);
    return nullptr;
  }

  // grow the table size
  size_t length = tbl->table_->size();
  if (tbl->table_->grow(num)) {
    return JSValueMakeNumber(ctx, length);
  }
  WLOGD("Runtime.GrowTable failed!\n");
  *exception = JSCExtAPI::CreateException(ctx, ExceptionMessages::kGrowFailed);
  return nullptr;
}

}  // namespace jsc
}  // namespace vmsdk
