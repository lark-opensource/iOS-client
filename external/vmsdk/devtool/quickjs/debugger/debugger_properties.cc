// Copyright 2019 The Lynx Authors. All rights reserved.

#include "devtool/quickjs/debugger/debugger_properties.h"

#include "devtool/quickjs/debugger_inner.h"
#include "devtool/quickjs/interface.h"
#include "devtool/quickjs/protocols.h"
#include "devtool/quickjs/runtime/runtime.h"

#define QJSTypedArrayTypeName(V)                   \
  V("Uint8ClampedArray", LEPUS_TYPED_UINT8C_ARRAY) \
  V("Int8Array", LEPUS_TYPED_INT8_ARRAY)           \
  V("Uint8Array", LEPUS_TYPED_UINT8_ARRAY)         \
  V("Int16Array", LEPUS_TYPED_INT16_ARRAY)         \
  V("Uint16Array", LEPUS_TYPED_UINT16_ARRAY)       \
  V("Int32Array", LEPUS_TYPED_INT32_ARRAY)         \
  V("Uint32Array", LEPUS_TYPED_UINT32_ARRAY)       \
  V("Float32Array", LEPUS_TYPED_FLOAT32_ARRAY)     \
  V("Float64Array", LEPUS_TYPED_FLOAT64_ARRAY)

#define QJSObjectSubTypeTypeName(V) \
  V(array, LEPUS_IsArray)           \
  V(proxy, IsProxy)                 \
  V(regexp, lepus_is_regexp)        \
  V(typedarray, LEPUS_IsTypedArray) \
  V(error, LEPUS_IsError)           \
  V(dataview, LEPUS_IsDataView)     \
  V(date, IsDate)                   \
  V(map, IsMap)                     \
  V(set, IsSet)                     \
  V(weak_map, IsWeakMap)            \
  V(weak_set, IsWeakSet)            \
  V(generator, IsGenerator)         \
  V(promise, IsPromise)

#define QJSObjectDescMethod(V)                                      \
  V(GetArrayDescription, LEPUS_IsArray)                             \
  V(GetProxyDescription, IsProxy)                                   \
  V(GetRegExpDescription, lepus_is_regexp)                          \
  V(GetTypedArrayDescription, LEPUS_IsTypedArray)                   \
  V(GetExceptionDescription, LEPUS_IsError)                         \
  V(GetDateViewDescription, LEPUS_IsDataView)                       \
  V(GetGeneratorFuncName, IsGenerator)                              \
  V(GetFunctionDescription, LEPUS_IsFunction)                       \
  V(GetPromiseDescription, IsPromise)                               \
  V(GetWeakRefDescription, IsWeakRef)                               \
  V(GetFRDescription, IsFinalizationRegistry)                       \
  V(GetArrayIteratorDescription, IsArrayIterator)                   \
  V(GetStringIteratorDescription, IsStringIterator)                 \
  V(GetSetIteratorDescription, IsSetIterator)                       \
  V(GetMapIteratorDescription, IsMapIterator)                       \
  V(GetRegExpStringIteratorDescription, IsRegExpStringIterator)     \
  V(GetAsyncFunctionDescription, IsAsyncFunction)                   \
  V(GetAsyncGeneratorDescription, IsAsyncGenerator)                 \
  V(GetAsyncFunctionResolveDescription, IsAsyncFunctionResolve)     \
  V(GetAsyncFunctionRejectDescription, IsAsyncFunctionReject)       \
  V(GetPromiseResolveFunctionDescription, IsPromiseResolveFunction) \
  V(GetPromiseRejectFunctionDescription, IsPromiseRejectFunction)   \
  V(GetAsyncFromSyncIteratorDescription, IsAsyncFromSyncIterator)

#define QJSObjectClassNameNameType(V)                           \
  V(capital_array, LEPUS_IsArray)                               \
  V(capital_proxy, IsProxy)                                     \
  V(capital_regexp, lepus_is_regexp)                            \
  V(capital_dataview, LEPUS_IsDataView)                         \
  V(capital_date, IsDate)                                       \
  V(capital_map, IsMap)                                         \
  V(capital_set, IsSet)                                         \
  V(capital_weak_map, IsWeakMap)                                \
  V(capital_weak_set, IsWeakSet)                                \
  V(capital_generator_function, IsGeneratorFunction)            \
  V(capital_generator, IsGenerator)                             \
  V(capital_function, LEPUS_IsFunction)                         \
  V(capital_promise, IsPromise)                                 \
  V(capital_weak_ref, IsWeakRef)                                \
  V(capital_fr, IsFinalizationRegistry)                         \
  V(capital_array_iterator, IsArrayIterator)                    \
  V(capital_string_iterator, IsStringIterator)                  \
  V(capital_set_iterator, IsSetIterator)                        \
  V(capital_map_iterator, IsMapIterator)                        \
  V(capital_regexp_string_iterator, IsRegExpStringIterator)     \
  V(capital_async_function, IsAsyncFunction)                    \
  V(capital_async_generator, IsAsyncGenerator)                  \
  V(capital_async_generator_function, IsAsyncGeneratorFunction) \
  V(capital_async_function_resolve, IsAsyncFunctionResolve)     \
  V(capital_async_function_reject, IsAsyncFunctionReject)       \
  V(capital_async_from_sync_iterator, IsAsyncFromSyncIterator)  \
  V(capital_promise_resolve_func, IsPromiseResolveFunction)     \
  V(capital_promise_reject_func, IsPromiseRejectFunction)

#define QJSDebuggerType(V)       \
  V(LEPUS_TAG_INT, number)       \
  V(LEPUS_TAG_FLOAT64, number)   \
  V(LEPUS_TAG_BIG_INT, bigint)   \
  V(LEPUS_TAG_BIG_FLOAT, bigint) \
  V(LEPUS_TAG_STRING, string)    \
  V(LEPUS_TAG_BOOL, boolean)     \
  V(LEPUS_TAG_SYMBOL, symbol)    \
  V(LEPUS_TAG_NULL, object)      \
  V(LEPUS_TAG_EXCEPTION, exception)

#define QJComplexObjDesc(V)                               \
  V(Promise, capital_promise)                             \
  V(WeakRef, capital_weak_ref)                            \
  V(FR, capital_fr)                                       \
  V(ArrayIterator, capital_array_iterator)                \
  V(StringIterator, capital_string_iterator)              \
  V(SetIterator, capital_set_iterator)                    \
  V(MapIterator, capital_map_iterator)                    \
  V(RegExpStringIterator, capital_regexp_string_iterator) \
  V(AsyncFunction, capital_async_function)                \
  V(AsyncGenerator, capital_async_generator)              \
  V(AsyncFunctionResolve, capital_async_function_resolve) \
  V(AsyncFunctionReject, capital_async_function_reject)   \
  V(PromiseResolveFunction, capital_promise_resolve_func) \
  V(PromiseRejectFunction, capital_promise_reject_func)   \
  V(AsyncFromSyncIterator, capital_async_from_sync_iterator)

#define ComplexDesc(type, desc_str)                                           \
  static LEPUSValue Get##type##Description(LEPUSContext* ctx,                 \
                                           LEPUSValue val) {                  \
    return LEPUS_DupValue(ctx, GetDebuggerInfo(ctx)->literal_pool->desc_str); \
  }
QJComplexObjDesc(ComplexDesc)
#undef ComplexDesc

    static LEPUSValue
    GetFunctionDescription(LEPUSContext* ctx, LEPUSValue val) {
  return lepus_function_toString(ctx, val, 0, NULL);
}

#ifdef ENABLE_LEPUSNG
static void GetLepusRefDeepCopyResult(LEPUSContext* ctx, LEPUSValue& obj) {
  if (LEPUS_VALUE_GET_TAG(obj) == LEPUS_TAG_LEPUS_REF) {
    LEPUSRuntime* rt = LEPUS_GetRuntime(ctx);
    if (LEPUS_LepusRefIsTable(rt, obj) || LEPUS_LepusRefIsArray(rt, obj)) {
      LEPUSValue js_obj = LEPUS_DeepCopy(ctx, obj);
      LEPUS_FreeValue(ctx, obj);
      obj = js_obj;
    }
  }
}
#endif

LEPUSValue GenerateUniqueObjId(LEPUSContext* ctx, LEPUSValue obj) {
  LEPUSObject* p = LEPUS_VALUE_GET_OBJ(obj);
  auto obj_id = (uint64_t)p;
  std::string obj_id_str = std::to_string(obj_id);
  auto* debugger_info = GetDebuggerInfo(ctx);
  auto& state = debugger_info->pause_state;
  // dup obj
  if (LEPUS_IsArray(ctx, state.get_properties_array)) {
    LEPUS_SetPropertyUint32(ctx, state.get_properties_array,
                            state.get_properties_array_len++,
                            LEPUS_DupValue(ctx, obj));
  } else {
    auto& running_state = debugger_info->running_state;
    LEPUS_SetPropertyUint32(ctx, running_state.get_properties_array,
                            running_state.get_properties_array_len++,
                            LEPUS_DupValue(ctx, obj));
  }
  return LEPUS_NewString(ctx, obj_id_str.c_str());
}

// get object subtype
static LEPUSValue GetObjectSubtype(LEPUSContext* ctx, LEPUSValue value) {
  LEPUSValue subtype = LEPUS_UNDEFINED;
  auto* info = GetDebuggerInfo(ctx);
#define ObjectSubType(str, check_func)                      \
  if (check_func(ctx, value)) {                             \
    subtype = LEPUS_DupValue(ctx, info->literal_pool->str); \
    return subtype;                                         \
  }
  QJSObjectSubTypeTypeName(ObjectSubType)
#undef ObjectSubType
      if (LEPUS_IsArrayBuffer(value)) {
    subtype =
        LEPUS_DupValue(ctx, GetDebuggerInfo(ctx)->literal_pool->arraybuffer);
  }
  return subtype;
}

// get type of lepusvalue
LEPUSValue GetType(LEPUSContext* ctx, LEPUSValue value) {
  LEPUSValue type = LEPUS_UNDEFINED;
  int64_t tag = LEPUS_VALUE_GET_TAG(value);
  auto* info = GetDebuggerInfo(ctx);
  switch (tag) {
#define DebuggerType(object_type, str)                   \
  case object_type: {                                    \
    type = LEPUS_DupValue(ctx, info->literal_pool->str); \
    break;                                               \
  }
    QJSDebuggerType(DebuggerType)
#undef DebuggerType
        case LEPUS_TAG_OBJECT : {
      if (LEPUS_IsFunction(ctx, value)) {
        type = LEPUS_DupValue(ctx, info->literal_pool->function);
      } else {
        type = LEPUS_DupValue(ctx, info->literal_pool->object);
      }
      break;
    }
    default: {
      type = LEPUS_DupValue(ctx, info->literal_pool->undefined);
      break;
    }
  }
  return type;
}

LEPUSValue GetValue(LEPUSContext* ctx, LEPUSValue value,
                    int32_t return_by_value) {
  LEPUSValue val = LEPUS_UNINITIALIZED;
  int64_t tag = LEPUS_VALUE_GET_TAG(value);
  switch (tag) {
    case LEPUS_TAG_INT:
    case LEPUS_TAG_FLOAT64:
    case LEPUS_TAG_BIG_INT:
    case LEPUS_TAG_BIG_FLOAT:
    case LEPUS_TAG_STRING:
    case LEPUS_TAG_BOOL:
    case LEPUS_TAG_NULL: {
      val = LEPUS_DupValue(ctx, value);
      break;
    }
    case LEPUS_TAG_OBJECT: {
      if (return_by_value) {
        val = LEPUS_DupValue(ctx, value);
      }
      break;
    }
    case LEPUS_TAG_EXCEPTION: {
      auto* info = GetDebuggerInfo(ctx);
      val = LEPUS_DupValue(ctx, info->literal_pool->exception);
      break;
    }
    case LEPUS_TAG_UNDEFINED:
    default: {
      val = LEPUS_UNDEFINED;
      break;
    }
  }
  return val;
}

static LEPUSValue GetSymbolDescription(LEPUSContext* ctx, LEPUSValue value) {
  LEPUSAtom symbol_atom = lepus_symbol_to_atom(ctx, value);
  LEPUSValue value_string = LEPUS_AtomToString(ctx, symbol_atom);  // dup
  const char* value_cstr = LEPUS_ToCString(ctx, value_string);
  int32_t buf_len = strlen(value_cstr) + 9;
  char* buf = static_cast<char*>(lepus_malloc(ctx, (sizeof(char) * buf_len)));
  LEPUSValue ret = LEPUS_UNDEFINED;
  if (buf) {
    *buf = '\0';
    strcat(buf, "Symbol(");
    strcat(buf, value_cstr);
    strcat(buf, ")");
    ret = LEPUS_NewString(ctx, buf);
  }
  lepus_free(ctx, buf);
  LEPUS_FreeCString(ctx, value_cstr);
  LEPUS_FreeValue(ctx, value_string);
  return ret;
}

// construct property preview
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-PropertyPreview
static LEPUSValue GeneratePropertyPreview(LEPUSContext* ctx,
                                          LEPUSValue property_value,
                                          int32_t return_by_value) {
  LEPUSValue property = LEPUS_NewObject(ctx);
  if (LEPUS_IsException(property)) {
    return LEPUS_UNDEFINED;
  }
  int64_t tag = LEPUS_VALUE_GET_TAG(property_value);
  switch (tag) {
    case LEPUS_TAG_INT:
    case LEPUS_TAG_FLOAT64: {
      LEPUSValue description = LEPUS_ToString(ctx, property_value);
      DebuggerSetPropertyStr(ctx, property, "description", description);
      break;
    }
    case LEPUS_TAG_NULL: {
      auto* info = GetDebuggerInfo(ctx);
      LEPUSValue subtype = LEPUS_DupValue(ctx, info->literal_pool->null);
      DebuggerSetPropertyStr(ctx, property, "subtype", subtype);
      break;
    }
    case LEPUS_TAG_SYMBOL: {
      LEPUSValue description = GetSymbolDescription(ctx, property_value);
      DebuggerSetPropertyStr(ctx, property, "description", description);
      break;
    }
    case LEPUS_TAG_OBJECT: {
      LEPUSValue subtype = GetObjectSubtype(ctx, property_value);
      if (!LEPUS_IsUndefined(subtype)) {
        DebuggerSetPropertyStr(ctx, property, "subtype", subtype);
      }
      break;
    }
  }
  // value
  LEPUSValue value = GetValue(ctx, property_value, return_by_value);
  if (!LEPUS_IsUninitialized(value)) {
    DebuggerSetPropertyStr(ctx, property, "value", value);
  }
  // type
  LEPUSValue type = GetType(ctx, property_value);
  DebuggerSetPropertyStr(ctx, property, "type", type);
  return property;
}

// iterate map/set/weakmap/weakset object to get properties
static LEPUSValue GetMapSetProperties(LEPUSContext* ctx, LEPUSValue obj,
                                      GetEntryCallback callback,
                                      int32_t magic) {
  LEPUSValue result = LEPUS_NewArray(ctx);
  uint32_t size;
  LEPUSValue map_size = lepus_map_get_size(ctx, obj, magic);
  LEPUS_ToUint32(ctx, &size, map_size);
  LEPUS_FreeValue(ctx, map_size);

  for (int32_t i = 0; i < size; i++) {
    struct LEPUSMapRecord* record = DebuggerMapFindIndex(ctx, obj, i, magic);
    if (!record) {
      continue;
    }
    LEPUSValue key_value = LEPUS_NewObject(ctx);
    LEPUSValue key = LEPUS_DupValue(ctx, GetMapRecordKey(record));      // dup
    LEPUSValue value = LEPUS_DupValue(ctx, GetMapRecordValue(record));  // dup
    LEPUSValue key_ret =
        callback(ctx, key, LEPUS_PROP_WRITABLE, LEPUS_PROP_CONFIGURABLE,
                 LEPUS_PROP_ENUMERABLE);  // free key
    if (LEPUS_IsUndefined(value)) {
      // set/weakset: value
      DebuggerSetPropertyStr(ctx, key_value, "value", key_ret);
    } else {
      // map/weakmap: key-value
      LEPUSValue value_ret =
          callback(ctx, value, LEPUS_PROP_WRITABLE, LEPUS_PROP_CONFIGURABLE,
                   LEPUS_PROP_ENUMERABLE);  // free value
      DebuggerSetPropertyStr(ctx, key_value, "key", key_ret);
      DebuggerSetPropertyStr(ctx, key_value, "value", value_ret);
    }
    LEPUS_SetPropertyUint32(ctx, result, i, key_value);
  }
  return result;
}

static LEPUSValue GetTypedArrayDescription(LEPUSContext* ctx,
                                           LEPUSValue value) {
  LEPUSTypedArrayType typed_array_type = LEPUS_GetTypedArrayType(ctx, value);
  LEPUSValue ret = LEPUS_UNDEFINED;
  int32_t arr_len = LEPUS_GetLength(ctx, value);
  size_t buf_len = 64;
  char* buf = static_cast<char*>(lepus_malloc(ctx, sizeof(char) * buf_len));
  if (buf) {
    *buf = '\0';
    switch (typed_array_type) {
#define TypedArrayDescription(name, type) \
  case type: {                            \
    strcat(buf, name);                    \
    break;                                \
  }
      QJSTypedArrayTypeName(TypedArrayDescription)
#undef TypedArrayDescription
          default : {
        break;
      }
    }
    strcat(buf, "(");
    snprintf(buf + strlen(buf), buf_len - strlen(buf), "%d", arr_len);
    strcat(buf, ")");
    ret = LEPUS_NewString(ctx, buf);
  }
  lepus_free(ctx, buf);
  return ret;
}

static LEPUSValue GetArrayBufferDescription(LEPUSContext* ctx,
                                            LEPUSValue value) {
  LEPUSValue byte_length = lepus_array_buffer_get_byteLength(
      ctx, value, LEPUS_GetClassID(ctx, value));
  int32_t len = -1;
  LEPUS_ToInt32(ctx, &len, byte_length);

  char buf[32] = "ArrayBuffer(";
  snprintf(buf + strlen(buf), 32 - strlen(buf), "%d", len);
  strcat(buf, ")");
  return LEPUS_NewString(ctx, buf);
}

static LEPUSValue GetDateViewDescription(LEPUSContext* ctx, LEPUSValue value) {
  LEPUSValue byte_length = lepus_typed_array_get_byteLength(ctx, value, 1);
  int32_t len = -1;
  LEPUS_ToInt32(ctx, &len, byte_length);
  char buf[32] = "DataView(";
  snprintf(buf + strlen(buf), 32 - strlen(buf), "%d", len);
  strcat(buf, ")");
  return LEPUS_NewString(ctx, buf);
}

// get exception object description
LEPUSValue GetExceptionDescription(LEPUSContext* ctx, LEPUSValue exception) {
  LEPUSValue description = LEPUS_UNDEFINED;
  const char* exception_msg_str = LEPUS_ToCString(ctx, exception);
  int32_t len = strlen(exception_msg_str) + 1;
  char* exception_description_str =
      static_cast<char*>(lepus_malloc(ctx, (sizeof(char) * len)));
  int32_t allocate_size = (int32_t)strlen(exception_msg_str) + 1;
  int32_t use_size = allocate_size;
  if (exception_description_str) {
    *exception_description_str = '\0';
    strcat(exception_description_str, exception_msg_str);
    const char* exception_stack_str;
    uint8_t is_error = LEPUS_IsError(ctx, exception);
    if (is_error) {
      LEPUSValue stack = LEPUS_GetPropertyStr(ctx, exception, "stack");
      if (!LEPUS_IsUndefined(stack)) {
        exception_stack_str = LEPUS_ToCString(ctx, stack);
        use_size += strlen(exception_stack_str);
        while (use_size >= allocate_size) {
          char* new_exp_desc_str = static_cast<char*>(
              lepus_realloc(ctx, exception_description_str, allocate_size * 2));
          if (new_exp_desc_str) {
            allocate_size *= 2;
            exception_description_str = new_exp_desc_str;
          } else {
            LEPUS_FreeCString(ctx, exception_msg_str);
            description = LEPUS_NewString(ctx, exception_description_str);
            lepus_free(ctx, exception_description_str);
            LEPUS_FreeCString(ctx, exception_stack_str);
            return description;
          }
        }
        strcat(exception_description_str, exception_stack_str);
        LEPUS_FreeCString(ctx, exception_stack_str);
      }
      LEPUS_FreeValue(ctx, stack);
    }
  }
  LEPUS_FreeCString(ctx, exception_msg_str);
  description = LEPUS_NewString(ctx, exception_description_str);
  lepus_free(ctx, exception_description_str);
  return description;
}

// get exception object classname
static LEPUSValue GetExceptionClassName(LEPUSContext* ctx, LEPUSValue value) {
  const char* exception_head = LEPUS_ToCString(ctx, value);
  LEPUSValue result = LEPUS_NewString(ctx, exception_head);
  LEPUS_FreeCString(ctx, exception_head);
  return result;
}

LEPUSValue GetPromiseProperties(LEPUSContext* ctx, LEPUSValue obj,
                                LEPUSValue& res) {
  LEPUSValue promise_obj = DebuggerGetPromiseProperties(ctx, obj);
  LEPUSValue state = LEPUS_GetPropertyStr(ctx, promise_obj, "PromiseState");
  LEPUSValue promise_state_val =
      GetRemoteObject(ctx, state, 0, 0);  // free state
  LEPUSValue promise_state = LEPUS_NewObject(ctx);
  DebuggerSetPropertyStr(ctx, promise_state, "name",
                         LEPUS_NewString(ctx, "[[PromiseState]]"));
  DebuggerSetPropertyStr(ctx, promise_state, "value", promise_state_val);

  LEPUSValue result = LEPUS_GetPropertyStr(ctx, promise_obj, "PromiseResult");
  LEPUSValue promise_result_val =
      GetRemoteObject(ctx, result, 0, 0);  // free result
  LEPUSValue promise_result = LEPUS_NewObject(ctx);
  DebuggerSetPropertyStr(ctx, promise_result, "name",
                         LEPUS_NewString(ctx, "[[PromiseResult]]"));
  DebuggerSetPropertyStr(ctx, promise_result, "value", promise_result_val);
  LEPUS_FreeValue(ctx, promise_obj);

  LEPUS_SetPropertyUint32(ctx, res, 0, promise_state);
  LEPUS_SetPropertyUint32(ctx, res, 1, promise_result);
  return res;
}

// get exception object properties
LEPUSValue GetExceptionProperties(LEPUSContext* ctx, LEPUSValue val) {
  LEPUSValue exception_desc = GetExceptionDescription(ctx, val);
  LEPUSValue exception_msg = GetExceptionClassName(ctx, val);
  LEPUSValue preview_properties = LEPUS_NewArray(ctx);
  auto* info = GetDebuggerInfo(ctx);
  uint32_t idx = 0;
  LEPUSObject* p1 =
      DebuggerCreateObjFromShape(info, info->debugger_obj->preview_prop);
  SetFixedShapeObjValue(ctx, p1, idx++,
                        LEPUS_DupValue(ctx, info->literal_pool->stack));
  SetFixedShapeObjValue(ctx, p1, idx++,
                        LEPUS_DupValue(ctx, info->literal_pool->string));
  SetFixedShapeObjValue(ctx, p1, idx++, LEPUS_DupValue(ctx, exception_desc));
  LEPUS_SetPropertyUint32(ctx, preview_properties, 0,
                          LEPUS_MKPTR(LEPUS_TAG_OBJECT, p1));
  LEPUS_FreeValue(ctx, exception_desc);
  if (!LEPUS_IsUndefined(exception_msg)) {
    idx = 0;
    LEPUSObject* p2 =
        DebuggerCreateObjFromShape(info, info->debugger_obj->preview_prop);
    SetFixedShapeObjValue(ctx, p2, idx++,
                          LEPUS_DupValue(ctx, info->literal_pool->message));
    SetFixedShapeObjValue(ctx, p2, idx++,
                          LEPUS_DupValue(ctx, info->literal_pool->string));
    SetFixedShapeObjValue(ctx, p2, idx++, LEPUS_DupValue(ctx, exception_msg));
    LEPUS_SetPropertyUint32(ctx, preview_properties, 1,
                            LEPUS_MKPTR(LEPUS_TAG_OBJECT, p2));
  }
  LEPUS_FreeValue(ctx, exception_msg);
  return preview_properties;
}

static void GetProxyInternalProperties(LEPUSContext* ctx, LEPUSValue val,
                                       LEPUSValue& ret) {
  LEPUSValue proxy = DebuggerGetProxyProperties(ctx, val);
  LEPUSValue proxy_handler = LEPUS_GetPropertyStr(ctx, proxy, "Handler");
  LEPUSValue handler = LEPUS_NewObject(ctx);
  LEPUSValue handler_val = GetRemoteObject(ctx, proxy_handler, 0, 0);
  DebuggerSetPropertyStr(ctx, handler, "name",
                         LEPUS_NewString(ctx, "[[Handler]]"));
  DebuggerSetPropertyStr(ctx, handler, "value", handler_val);
  LEPUS_SetPropertyUint32(ctx, ret, 0, handler);

  LEPUSValue proxy_target = LEPUS_GetPropertyStr(ctx, proxy, "Target");
  LEPUSValue target_val = GetRemoteObject(ctx, proxy_target, 0, 0);
  LEPUSValue target = LEPUS_NewObject(ctx);
  DebuggerSetPropertyStr(ctx, target, "name",
                         LEPUS_NewString(ctx, "[[Target]]"));
  DebuggerSetPropertyStr(ctx, target, "value", target_val);
  LEPUS_SetPropertyUint32(ctx, ret, 1, target);

  LEPUSValue proxy_is_revoked = LEPUS_GetPropertyStr(ctx, proxy, "IsRevoked");
  LEPUSValue is_revoked_val = GetRemoteObject(ctx, proxy_is_revoked, 0, 0);
  LEPUSValue is_revoked = LEPUS_NewObject(ctx);
  DebuggerSetPropertyStr(ctx, is_revoked, "name",
                         LEPUS_NewString(ctx, "[[IsRevoked]]"));
  DebuggerSetPropertyStr(ctx, is_revoked, "value", is_revoked_val);
  LEPUS_SetPropertyUint32(ctx, ret, 2, is_revoked);
  LEPUS_FreeValue(ctx, proxy);
}

static LEPUSValue SetFunctionLocation(LEPUSContext* ctx,
                                      LEPUSDebuggerInfo* info, LEPUSValue name,
                                      LEPUSValue& val) {
  LEPUSValue function_location = LEPUS_NewObject(ctx);
  DebuggerSetPropertyStr(ctx, function_location, "name", name);
  LEPUSValue location = LEPUS_NewObject(ctx);
  DebuggerSetPropertyStr(ctx, location, "type",
                         LEPUS_DupValue(ctx, info->literal_pool->object));
  DebuggerSetPropertyStr(
      ctx, location, "subtype",
      LEPUS_DupValue(ctx, info->literal_pool->internal_location));
  struct LEPUSFunctionBytecode* b = LEPUS_GetFunctionBytecode(val);
  int32_t script_id = -1;
  int32_t start_line = 0;
  int32_t start_column = 0;
  if (b) {
    script_id = GetScriptIdByFunctionBytecode(ctx, b);
    start_line = GetFunctionDebugLineNum(ctx, b);  // start from 0
    start_column = GetFunctionDebugColumnNum(ctx, b);
  }
  LEPUSValue line_column =
      GetLocation(ctx, start_line, start_column, script_id);
  DebuggerSetPropertyStr(ctx, location, "value", line_column);
  DebuggerSetPropertyStr(
      ctx, location, "description",
      LEPUS_DupValue(ctx, info->literal_pool->capital_object));
  DebuggerSetPropertyStr(ctx, function_location, "value", location);
  return function_location;
}

static void GetGeneratorFunctionProperties(LEPUSContext* ctx, LEPUSValue& obj,
                                           LEPUSValue& result, uint32_t& index,
                                           GetPropertyCallback callback) {
  //[[FunctionLocation]]
  auto* info = GetDebuggerInfo(ctx);
  LEPUSValue location = SetFunctionLocation(
      ctx, info, LEPUS_DupValue(ctx, info->literal_pool->function_location),
      obj);
  LEPUS_SetPropertyUint32(ctx, result, index++, location);
  // [[IsGenerator]]
  LEPUSValue is_generator = LEPUS_NewObject(ctx);
  DebuggerSetPropertyStr(ctx, is_generator, "name",
                         LEPUS_DupValue(ctx, info->literal_pool->is_generator));
  LEPUSValue true_bool = LEPUS_NewBool(ctx, true);
  LEPUSValue true_val = GetRemoteObject(ctx, true_bool, 0, 0);
  DebuggerSetPropertyStr(ctx, is_generator, "value", true_val);
  LEPUS_SetPropertyUint32(ctx, result, index++, is_generator);
}

static void GetGeneratorProperties(LEPUSContext* ctx, LEPUSValue& obj,
                                   LEPUSValue& result, uint32_t& index,
                                   GetPropertyCallback callback) {
  //[[GeneratorState]]
  auto* info = GetDebuggerInfo(ctx);
  LEPUSValue generator_state = GetGeneratorState(ctx, obj);
  if (!LEPUS_IsUndefined(generator_state)) {
    LEPUSValue state_ret =
        callback(ctx, LEPUS_DupValue(ctx, info->literal_pool->generator_state),
                 generator_state, LEPUS_PROP_WRITABLE, LEPUS_PROP_CONFIGURABLE,
                 LEPUS_PROP_ENUMERABLE);
    LEPUS_SetPropertyUint32(ctx, result, index++, state_ret);
  }

  //[[GeneratorFunction]]
  LEPUSValue gen_func = GetGeneratorFunction(ctx, obj);
  if (!LEPUS_IsUndefined(gen_func)) {
    LEPUS_DupValue(ctx, gen_func);
    LEPUSValue func_ret = callback(
        ctx, LEPUS_DupValue(ctx, info->literal_pool->generator_function),
        gen_func, LEPUS_PROP_WRITABLE, LEPUS_PROP_CONFIGURABLE,
        LEPUS_PROP_ENUMERABLE);  // free generator_func
    LEPUS_SetPropertyUint32(ctx, result, index++, func_ret);
  }

  // [[GeneratorLocation]]
  LEPUSValue location = SetFunctionLocation(
      ctx, info,
      LEPUS_DupValue(ctx, info->literal_pool->generator_function_location),
      gen_func);
  LEPUS_FreeValue(ctx, gen_func);
  LEPUS_SetPropertyUint32(ctx, result, index++, location);
}

// Iterate the object and call pfunc to get object abbreviated properties
static LEPUSValue GetObjectAbbreviatedProperties(LEPUSContext* ctx,
                                                 LEPUSValue& obj,
                                                 GetPropertyCallback callback) {
  LEPUSValue result = LEPUS_NewArray(ctx);
  if (LEPUS_IsException(result)) {
    return LEPUS_UNDEFINED;
  }
  if (!LEPUS_IsObject(obj)) {
    return result;
  }
  uint32_t index = 0;
  LEPUSObject* p = LEPUS_VALUE_GET_OBJ(obj);
  if (LEPUS_IsError(ctx, obj)) {
    LEPUSValue ret = GetExceptionProperties(ctx, obj);
    LEPUS_SetPropertyUint32(ctx, result, index++, ret);
  } else if (IsPromise(ctx, obj)) {
    GetPromiseProperties(ctx, obj, result);
  } else {
#ifdef ENABLE_LEPUSNG
    GetLepusRefDeepCopyResult(ctx, obj);
#endif
    // TODO: HANDLE COMPLEX TYPE
    LEPUSPropertyEnum* tab = NULL;
    uint32_t len = 0;
    LEPUS_GetOwnPropertyNames(
        ctx, &tab, &len, obj,
        LEPUS_GPN_STRING_MASK | LEPUS_GPN_SYMBOL_MASK | LEPUS_GPN_PRIVATE_MASK);

    for (uint32_t i = 0; i < len; i++) {
      LEPUSAtom atom = tab[i].atom;
      LEPUSPropertyDescriptor desc;
      int32_t has_property = LEPUS_GetOwnProperty(ctx, &desc, obj, atom);

      if (has_property > 0) {
        int32_t writable = 0;
        int32_t configurable = desc.flags & LEPUS_PROP_CONFIGURABLE;
        int32_t enumerable = desc.flags & LEPUS_PROP_ENUMERABLE;
        LEPUSValue name = LEPUS_UNDEFINED;
        LEPUSValue val = LEPUS_UNDEFINED;

        if (desc.flags & LEPUS_PROP_GETSET || desc.flags & LEPUS_PROP_LENGTH) {
          if (!LEPUS_IsUndefined(desc.getter)) {
            name = GetAtomGetValue(ctx);
            val = LEPUS_DupValue(ctx, desc.getter);
            LEPUSValue ret = callback(ctx, name, val, writable, configurable,
                                      enumerable);  // free val, name
            if (!LEPUS_IsUndefined(ret)) {
              LEPUS_SetPropertyUint32(ctx, result, index++, ret);
            }
          }
          if (!LEPUS_IsUndefined(desc.setter)) {
            name = GetAtomSetValue(ctx);
            val = LEPUS_DupValue(ctx, desc.setter);
            LEPUSValue ret = callback(ctx, name, val, writable, configurable,
                                      enumerable);  // free val, name
            if (!LEPUS_IsUndefined(ret)) {
              LEPUS_SetPropertyUint32(ctx, result, index++, ret);
            }
          }

          if (desc.flags & LEPUS_PROP_LENGTH) {
            goto free;
          }
        } else {
          val = LEPUS_DupValue(ctx, desc.value);
          name = LEPUS_AtomToValue(ctx, atom);
          writable = desc.flags & LEPUS_PROP_WRITABLE;
          LEPUSValue ret = callback(ctx, name, val, writable, configurable,
                                    enumerable);  // free val
          if (!LEPUS_IsUndefined(ret)) {
            LEPUS_SetPropertyUint32(ctx, result, index++, ret);
          }
        }
      }
    free:
      LEPUS_FreeValue(ctx, desc.value);
      LEPUS_FreeValue(ctx, desc.getter);
      LEPUS_FreeValue(ctx, desc.setter);
      LEPUS_FreeAtom(ctx, atom);
    }
    lepus_free(ctx, tab);
  }
  return result;
}

// if the object is map/set/weakmap/weakset, get the magic number
static int32_t GetMapSetMagicNumber(LEPUSContext* ctx, LEPUSValue subtype) {
  const char* magic_number_table[] = {"map", "set", "weakmap", "weakset"};
  const char* subtype_str = LEPUS_ToCString(ctx, subtype);
  int32_t number = -1;
  for (uint32_t i = 0; i < 4; i++) {
    if (subtype_str && strcmp(subtype_str, magic_number_table[i]) == 0) {
      number = i;
      break;
    }
  }
  LEPUS_FreeCString(ctx, subtype_str);
  return number;
}

static LEPUSValue GetObjectDescription(LEPUSContext* ctx, LEPUSValue value);

// get description of lepusvalue
LEPUSValue GetDescription(LEPUSContext* ctx, LEPUSValue value) {
  LEPUSValue description = LEPUS_UNDEFINED;
  int64_t tag = LEPUS_VALUE_GET_TAG(value);
  switch (tag) {
    case LEPUS_TAG_INT:
    case LEPUS_TAG_FLOAT64:
    case LEPUS_TAG_BIG_INT:
    case LEPUS_TAG_BIG_FLOAT:
    case LEPUS_TAG_BOOL: {
      description = LEPUS_ToString(ctx, value);
      break;
    }
    case LEPUS_TAG_STRING: {
      description = LEPUS_DupValue(ctx, value);
      break;
    }
    case LEPUS_TAG_SYMBOL: {
      description = GetSymbolDescription(ctx, value);
      break;
    }
    case LEPUS_TAG_OBJECT: {
      description = GetObjectDescription(ctx, value);
      break;
    }
    default: {
      auto* info = GetDebuggerInfo(ctx);
      description = LEPUS_DupValue(ctx, info->literal_pool->unknown);
      break;
    }
  }
  return description;
}

// get entries preview
// entry: description, overflow, properties, type
static LEPUSValue EntryPreviewCallback(LEPUSContext* ctx,
                                       LEPUSValue& entry_value,
                                       int32_t writeable, int32_t configurable,
                                       int32_t enumerable) {
  LEPUSValue entry = LEPUS_NewObject(ctx);
  if (LEPUS_IsException(entry)) {
    return LEPUS_UNDEFINED;
  }

  LEPUSValue overflow = LEPUS_NewBool(ctx, 0);  // false
  LEPUSValue properties = LEPUS_NewArray(ctx);  // []

#ifdef ENABLE_LEPUSNG
  GetLepusRefDeepCopyResult(ctx, entry_value);
#endif

  if (LEPUS_VALUE_GET_TAG(entry_value) == LEPUS_TAG_OBJECT &&
      !LEPUS_IsFunction(ctx, entry_value)) {
    LEPUSValue subtype = GetObjectSubtype(ctx, entry_value);
    DebuggerSetPropertyStr(ctx, entry, "subtype", subtype);
  }

  LEPUSValue type = GetType(ctx, entry_value);
  LEPUSValue description = GetDescription(ctx, entry_value);
  DebuggerSetPropertyStr(ctx, entry, "type", type);
  DebuggerSetPropertyStr(ctx, entry, "description", description);
  DebuggerSetPropertyStr(ctx, entry, "overflow", overflow);
  DebuggerSetPropertyStr(ctx, entry, "properties", properties);
  LEPUS_FreeValue(ctx, entry_value);
  return entry;
}

static LEPUSValue GetObjectProperties(LEPUSContext* ctx, LEPUSValue& obj,
                                      GetPropertyCallback callback) {
  int64_t tag = LEPUS_VALUE_GET_TAG(obj);
#ifdef ENABLE_LEPUSNG
  GetLepusRefDeepCopyResult(ctx, obj);
#endif
  // properties
  LEPUSValue result = GetObjectAbbreviatedProperties(ctx, obj, callback);
  int32_t index = LEPUS_GetLength(ctx, result);
  // add length and proto
  LEPUSPropertyEnum* tab = NULL;
  uint32_t len = 0;
  LEPUS_GetOwnPropertyNames(
      ctx, &tab, &len, obj,
      LEPUS_GPN_STRING_MASK | LEPUS_GPN_SYMBOL_MASK | LEPUS_GPN_PRIVATE_MASK);

  for (uint32_t i = 0; i < len; i++) {
    LEPUSAtom atom = tab[i].atom;
    LEPUSPropertyDescriptor desc;
    int32_t has_property = LEPUS_GetOwnProperty(ctx, &desc, obj, atom);
    LEPUS_FreeAtom(ctx, atom);
    if (has_property > 0 && desc.flags & LEPUS_PROP_LENGTH) {
      // length
      LEPUSValue val = LEPUS_DupValue(ctx, desc.value);
      LEPUSValue ret = callback(ctx, GetAtomSetValue(ctx), val, 0,
                                desc.flags & LEPUS_PROP_CONFIGURABLE,
                                desc.flags & LEPUS_PROP_ENUMERABLE);
      LEPUS_SetPropertyUint32(ctx, result, index++, ret);
    }
    LEPUS_FreeValue(ctx, desc.getter);
    LEPUS_FreeValue(ctx, desc.setter);
    LEPUS_FreeValue(ctx, desc.value);
  }
  lepus_free(ctx, tab);

  auto* info = GetDebuggerInfo(ctx);
  // [[entries]]
  if (tag == LEPUS_TAG_OBJECT) {
    LEPUSValue subtype = GetObjectSubtype(ctx, obj);
    int32_t magic = GetMapSetMagicNumber(ctx, subtype);
    if (magic != -1) {
      // MAP, SET, WEAKMAP, WEAKSET
      LEPUSValue entries =
          GetMapSetProperties(ctx, obj, EntryPreviewCallback, magic);
      int32_t entries_size = LEPUS_GetLength(ctx, entries);
      LEPUSValue entries_size_val = LEPUS_NewInt32(ctx, entries_size);
      LEPUSValue size =
          callback(ctx, LEPUS_DupValue(ctx, info->literal_pool->size),
                   entries_size_val, 0, 0, 0);
      LEPUS_SetPropertyUint32(ctx, result, index++, size);
      LEPUSValue ret =
          callback(ctx, LEPUS_DupValue(ctx, info->literal_pool->entries),
                   entries, 1, 1, 0);  // free entries
      LEPUS_SetPropertyUint32(ctx, result, index++, ret);
    }
    LEPUS_FreeValue(ctx, subtype);
  }

  // __proto__
  LEPUSValue proto = LEPUS_DupValue(ctx, LEPUS_GetPrototype(ctx, obj));
  LEPUSValue ret =
      callback(ctx, LEPUS_DupValue(ctx, info->literal_pool->proto), proto, 1, 1,
               0);  // free proto
  LEPUS_SetPropertyUint32(ctx, result, index++, ret);
  return result;
}

// get proxy description
static LEPUSValue GetProxyDescription(LEPUSContext* ctx, LEPUSValue val) {
  return LEPUS_NewString(ctx, "Proxy");
}

// get array object description
static LEPUSValue GetArrayDescription(LEPUSContext* ctx, LEPUSValue value) {
  int32_t arr_len = LEPUS_GetLength(ctx, value);
  char buf[32] = "Array(";
  snprintf(buf + strlen(buf), 32 - strlen(buf), "%d", arr_len);
  strcat(buf, ")");
  return LEPUS_NewString(ctx, buf);
}

// get RegExp object description
static LEPUSValue GetRegExpDescription(LEPUSContext* ctx, LEPUSValue value) {
  struct LEPUSRegExp* re = lepus_get_regexp(ctx, value, 0);
  LEPUSValue result = LEPUS_NULL;
  if (re) {
    LEPUSValue pattern = LEPUS_DupValue(
        ctx, LEPUS_MKPTR(LEPUS_TAG_STRING, GetRegExpPattern(re)));
    const char* pattern_str = LEPUS_ToCString(ctx, pattern);
    LEPUS_FreeValue(ctx, pattern);
    result = LEPUS_NewString(ctx, pattern_str);
    LEPUS_FreeCString(ctx, pattern_str);
  }
  return result;
}

// get map/set/weakmap/weakset description
static LEPUSValue GetMapSetDescription(LEPUSContext* ctx, LEPUSValue value,
                                       int32_t magic, const char* head) {
  LEPUSValue map_set_size = lepus_map_get_size(ctx, value, magic);
  uint32_t size = 0;
  LEPUS_ToUint32(ctx, &size, map_set_size);
  size_t buf_len = 32;
  char* buf = static_cast<char*>(lepus_malloc(ctx, sizeof(char) * buf_len));
  LEPUSValue result = LEPUS_UNDEFINED;
  if (buf) {
    *buf = '\0';
    strcat(buf, head);
    strcat(buf, "(");
    snprintf(buf + strlen(buf), buf_len - strlen(buf), "%d", size);
    strcat(buf, ")");
    result = LEPUS_NewString(ctx, buf);
    lepus_free(ctx, buf);
  }
  LEPUS_FreeValue(ctx, map_set_size);
  return result;
}

// get object description
static LEPUSValue GetObjectDescription(LEPUSContext* ctx, LEPUSValue value) {
  LEPUSValue description = LEPUS_UNDEFINED;
  auto* info = GetDebuggerInfo(ctx);
#define ObjectDescription(method, type)                                      \
  if (type(ctx, value)) {                                                    \
    description = method(ctx, value);                                        \
    if (LEPUS_IsUndefined(description)) {                                    \
      description = LEPUS_DupValue(ctx, info->literal_pool->capital_object); \
    }                                                                        \
    return description;                                                      \
  }
  QJSObjectDescMethod(ObjectDescription)
#undef ObjectDescription
      if (IsDate(ctx, value)) {
    description = get_date_string(ctx, value, 0, NULL, 0x13);
  }
  else if (IsMap(ctx, value)) {
    description = GetMapSetDescription(ctx, value, 0, "Map");
  }
  else if (IsSet(ctx, value)) {
    description = GetMapSetDescription(ctx, value, 1, "Set");
  }
  else if (IsWeakMap(ctx, value)) {
    description = GetMapSetDescription(ctx, value, 2, "WeakMap");
  }
  else if (IsWeakSet(ctx, value)) {
    description = GetMapSetDescription(ctx, value, 3, "WeakSet");
  }
  else if (LEPUS_IsArrayBuffer(value)) {
    description = GetArrayBufferDescription(ctx, value);
  }
  if (LEPUS_IsUndefined(description)) {
    description = LEPUS_DupValue(ctx, info->literal_pool->capital_object);
  }
  return description;
}

static void SetPreviewName(LEPUSContext* ctx, LEPUSValue name, LEPUSValue obj) {
  auto* info = GetDebuggerInfo(ctx);
  switch (LEPUS_VALUE_GET_TAG(name)) {
    case LEPUS_TAG_SYMBOL: {
      DebuggerSetPropertyStr(
          ctx, obj, "name",
          LEPUS_DupValue(ctx, info->literal_pool->capital_symbol));
      LEPUS_FreeValue(ctx, name);
      break;
    }
    case LEPUS_TAG_NULL: {
      DebuggerSetPropertyStr(ctx, obj, "name",
                             LEPUS_DupValue(ctx, info->literal_pool->null));
      LEPUS_FreeValue(ctx, name);
      break;
    }
    default: {
      DebuggerSetPropertyStr(ctx, obj, "name", name);
      break;
    }
  }
}

// This function is called to get the properties preview when the object is
// iterated ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-PropertyPreview
// properties: name, type, value
static LEPUSValue PropertyPreviewCallback(
    LEPUSContext* ctx, LEPUSValue property_name, LEPUSValue& property_value,
    int32_t writeable, int32_t configurable, int32_t enumerable) {
#ifdef ENABLE_LEPUSNG
  GetLepusRefDeepCopyResult(ctx, property_value);
#endif
  LEPUSValue property_preview = GeneratePropertyPreview(ctx, property_value, 0);
  if (!LEPUS_IsUndefined(property_preview)) {
    SetPreviewName(ctx, property_name, property_preview);
    if (LEPUS_IsObject(property_value)) {
      auto* info = GetDebuggerInfo(ctx);
      if (LEPUS_IsArray(ctx, property_value)) {
        DebuggerSetPropertyStr(ctx, property_preview, "value",
                               GetArrayDescription(ctx, property_value));
      } else if (LEPUS_IsFunction(ctx, property_value)) {
        LEPUS_DupValue(ctx, property_value);
        LEPUSValue func_value = GetRemoteObject(ctx, property_value, 0, 0);
        DebuggerSetPropertyStr(ctx, property_preview, "value", func_value);
      } else {
        DebuggerSetPropertyStr(
            ctx, property_preview, "value",
            LEPUS_DupValue(ctx, info->literal_pool->capital_object));
      }
    }
    LEPUS_FreeValue(ctx, property_value);
    return property_preview;
  }
  return LEPUS_UNDEFINED;
}

// construct object_preview info
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-ObjectPreview
static void SetObjectPreview(LEPUSContext* ctx, LEPUSValue type,
                             LEPUSValue subtype, LEPUSValue description,
                             LEPUSValue property_obj, LEPUSValue remote_obj) {
  LEPUSValue object_preview = LEPUS_NewObject(ctx);
  if (LEPUS_IsException(object_preview)) {
    return;
  }
  DebuggerSetPropertyStr(ctx, object_preview, "overflow",
                         LEPUS_NewBool(ctx, 0));
  DebuggerSetPropertyStr(ctx, object_preview, "type",
                         LEPUS_DupValue(ctx, type));
  if (!LEPUS_IsUndefined(subtype)) {
    DebuggerSetPropertyStr(ctx, object_preview, "subtype",
                           LEPUS_DupValue(ctx, subtype));
  }
  DebuggerSetPropertyStr(ctx, object_preview, "description",
                         LEPUS_DupValue(ctx, description));

  int32_t magic_number = GetMapSetMagicNumber(ctx, subtype);
  if (magic_number != -1) {
    // MAP, SET, WEAKMAP, WEAKSET
    LEPUSValue entries = GetMapSetProperties(
        ctx, property_obj, EntryPreviewCallback, magic_number);
    DebuggerSetPropertyStr(ctx, object_preview, "entries", entries);
  } else if (LEPUS_IsError(ctx, property_obj)) {
    LEPUSValue properties = GetExceptionProperties(ctx, property_obj);
    DebuggerSetPropertyStr(ctx, object_preview, "properties", properties);
  } else {
    // ARRAY, OBJECT
    LEPUSValue properties = GetObjectAbbreviatedProperties(
        ctx, property_obj, PropertyPreviewCallback);
    DebuggerSetPropertyStr(ctx, object_preview, "properties", properties);
  }
  DebuggerSetPropertyStr(ctx, remote_obj, "preview", object_preview);
}

static LEPUSValue GetTypedArrayType(LEPUSContext* ctx,
                                    LEPUSTypedArrayType typed_array_type) {
  LEPUSValue ret = LEPUS_UNDEFINED;
  switch (typed_array_type) {
#define TypedArrayType(name, type)    \
  case type: {                        \
    ret = LEPUS_NewString(ctx, name); \
    break;                            \
  }
    QJSTypedArrayTypeName(TypedArrayType)
#undef TypedArrayType
        default : {
      break;
    }
  }
  return ret;
}

// get object class name
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-RemoteObject
static LEPUSValue GetObjectClassName(LEPUSContext* ctx, LEPUSValue value) {
  LEPUSValue class_name = LEPUS_UNDEFINED;
  auto* info = GetDebuggerInfo(ctx);
#define ObjectClassName(str, type)                             \
  if (type(ctx, value)) {                                      \
    class_name = LEPUS_DupValue(ctx, info->literal_pool->str); \
    return class_name;                                         \
  }
  QJSObjectClassNameNameType(ObjectClassName)
#undef ObjectClassName
      if (LEPUS_IsTypedArray(ctx, value)) {
    LEPUSTypedArrayType typed_array_type = LEPUS_GetTypedArrayType(ctx, value);
    LEPUSValue type = GetTypedArrayType(ctx, typed_array_type);
    class_name = type;
  }
  else if (LEPUS_IsArrayBuffer(value)) {
    class_name = LEPUS_DupValue(ctx, info->literal_pool->capital_arraybuffer);
  }
  else if (LEPUS_IsError(ctx, value)) {
    class_name = GetExceptionClassName(ctx, value);
  }
  else if (IsGenerator(ctx, value)) {
    class_name = GetGeneratorFuncName(ctx, value);
  }
  else {
    class_name = LEPUS_DupValue(ctx, info->literal_pool->capital_object);
  }
  return class_name;
}

// construct remoteObject info
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-RemoteObject
LEPUSValue GetRemoteObject(LEPUSContext* ctx, LEPUSValue& property_value,
                           int32_t need_preview,
                           int32_t return_by_value) {  // free property_value
#ifdef ENABLE_LEPUSNG
  GetLepusRefDeepCopyResult(ctx, property_value);
#endif
  LEPUSValue remote_obj =
      GeneratePropertyPreview(ctx, property_value, return_by_value);
  if (LEPUS_IsUndefined(remote_obj) && LEPUS_IsObject(property_value)) {
    LEPUS_FreeValue(ctx, property_value);
    return remote_obj;
  }
  if (LEPUS_IsObject(property_value)) {
    LEPUSValue remote_obj_id = GenerateUniqueObjId(ctx, property_value);
    DebuggerSetPropertyStr(ctx, remote_obj, "objectId", remote_obj_id);
    LEPUSValue description = GetObjectDescription(ctx, property_value);
    LEPUSValue class_name = GetObjectClassName(ctx, property_value);
    DebuggerSetPropertyStr(ctx, remote_obj, "className", class_name);
    DebuggerSetPropertyStr(ctx, remote_obj, "description", description);
    if (LEPUS_IsFunction(ctx, property_value) || LEPUS_IsNull(property_value)) {
      need_preview = 0;
    }
    if (need_preview) {
      // type and subtype is a property of remote obj, do not need to free
      LEPUSValue type = LEPUS_GetPropertyStr(ctx, remote_obj, "type");
      LEPUSValue subtype = LEPUS_GetPropertyStr(ctx, remote_obj, "subtype");
      SetObjectPreview(ctx, type, subtype, description, property_value,
                       remote_obj);
      LEPUS_FreeValue(ctx, type);
      LEPUS_FreeValue(ctx, subtype);
    }
    LEPUS_FreeValue(ctx, property_value);
  } else {
    LEPUS_FreeValue(ctx, property_value);
  }
  return remote_obj;
}

// This function is called to get the properties description when the object is
// iterated
// ref:https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-PropertyDescriptor
static LEPUSValue PropertyDescriptorCallback(
    LEPUSContext* ctx, LEPUSValue property_name, LEPUSValue& property_value,
    int32_t writeable, int32_t configurable, int32_t enumerable) {
  LEPUSValue property_descriptor = LEPUS_NewObject(ctx);
  if (LEPUS_IsException(property_descriptor)) {
    LEPUS_FreeValue(ctx, property_name);
    LEPUS_FreeValue(ctx, property_value);
    return LEPUS_UNDEFINED;
  }

  int64_t tag = LEPUS_VALUE_GET_TAG(property_name);
  switch (tag) {
    case LEPUS_TAG_SYMBOL: {
      LEPUSAtom symbol_atom = lepus_symbol_to_atom(ctx, property_name);
      DebuggerSetPropertyStr(ctx, property_descriptor, "name",
                             LEPUS_AtomToString(ctx, symbol_atom));
      break;
    }
    default: {
      // TODO: handle other type
      DebuggerSetPropertyStr(ctx, property_descriptor, "name",
                             LEPUS_DupValue(ctx, property_name));
      break;
    }
  }
  DebuggerSetPropertyStr(ctx, property_descriptor, "configurable",
                         LEPUS_NewBool(ctx, configurable));
  DebuggerSetPropertyStr(ctx, property_descriptor, "enumerable",
                         LEPUS_NewBool(ctx, enumerable));
  DebuggerSetPropertyStr(ctx, property_descriptor, "writable",
                         LEPUS_NewBool(ctx, writeable));
  LEPUSValue value =
      GetRemoteObject(ctx, property_value, 1, 0);  // free property_value
  DebuggerSetPropertyStr(ctx, property_descriptor, "value", value);
  LEPUS_FreeValue(ctx, property_name);
  return property_descriptor;
}

// get internal property descriptor of value
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#type-InternalPropertyDescriptor
static LEPUSValue GetInternalProperties(LEPUSContext* ctx, LEPUSValue& val) {
  LEPUSValue internal_properties = LEPUS_NewArray(ctx);
  uint32_t index = 0;

  if (LEPUS_IsFunction(ctx, val)) {
    auto* info = GetDebuggerInfo(ctx);
    // [[FunctionLocation]]
    LEPUSValue function_location = SetFunctionLocation(
        ctx, info, LEPUS_DupValue(ctx, info->literal_pool->function_location),
        val);
    LEPUS_SetPropertyUint32(ctx, internal_properties, index++,
                            function_location);
  } else if (IsProxy(ctx, val)) {
    // val will be freed after GetInternalProperties call
    GetProxyInternalProperties(ctx, val, internal_properties);
  } else if (IsGenerator(ctx, val)) {
    GetGeneratorProperties(ctx, val, internal_properties, index,
                           PropertyDescriptorCallback);
  } else if (IsGeneratorFunction(ctx, val)) {
    GetGeneratorFunctionProperties(ctx, val, internal_properties, index,
                                   PropertyDescriptorCallback);
  }
  return internal_properties;
}

static void GetPropertiesparams(LEPUSContext* ctx, LEPUSValue params,
                                uint64_t* obj_id, LEPUSValue* obj,
                                uint8_t* own_properties) {
  LEPUSValue params_object_id = LEPUS_GetPropertyStr(ctx, params, "objectId");
  const char* object_id = LEPUS_ToCString(ctx, params_object_id);
  LEPUS_FreeValue(ctx, params_object_id);
  *obj = GetObjFromObjectId(ctx, object_id, obj_id);  // obj has been dupped
  LEPUS_FreeCString(ctx, object_id);
  LEPUSValue params_own_properties =
      LEPUS_GetPropertyStr(ctx, params, "ownProperties");
  if (!LEPUS_IsUndefined(params_own_properties)) {
    *own_properties = LEPUS_VALUE_GET_BOOL(params_own_properties);
  }
  LEPUS_FreeValue(ctx, params);
}

static LEPUSValue GetProperties(LEPUSContext* ctx, LEPUSValue& obj,
                                uint32_t obj_id) {
  LEPUSValue result = LEPUS_UNDEFINED;
  int32_t max_size = DEBUGGER_MAX_SCOPE_LEVEL;
  int32_t frame_id = obj_id / max_size;
  int32_t scope = obj_id % max_size;

  if (scope == 0) {                    // global variables
    obj = LEPUS_GetGlobalObject(ctx);  // dup
  } else if (scope == 1) {             // local variables
    obj = GetLocalVariables(ctx, frame_id);
  } else if (scope >= 2) {  // closure variables
    obj = GetFrameClosureVariables(ctx, frame_id, scope - 2);
  }
  if (LEPUS_IsException(obj)) {
    return result;
  }
  LEPUSValue unique_obj_id =
      GenerateUniqueObjId(ctx, obj);  // generate object id
  LEPUS_FreeValue(ctx, unique_obj_id);
  // Iterate the object and call pfunc for processing
  if (scope == 0) {
    result =
        GetObjectAbbreviatedProperties(ctx, obj, PropertyDescriptorCallback);

    LEPUSValue global_var_obj = GetGlobalVarObj(ctx);  // dup
    LEPUSValue result_global_var_obj = GetObjectAbbreviatedProperties(
        ctx, global_var_obj, PropertyDescriptorCallback);
    LEPUS_FreeValue(ctx, global_var_obj);

    int32_t global_var_array_len = LEPUS_GetLength(ctx, result_global_var_obj);
    int32_t global_array_len = LEPUS_GetLength(ctx, result);

    for (int32_t i = 0; i < global_var_array_len; i++) {
      LEPUSValue val = LEPUS_GetPropertyUint32(ctx, result_global_var_obj, i);
      LEPUS_SetPropertyUint32(ctx, result, global_array_len++, val);
    }
    LEPUS_FreeValue(ctx, result_global_var_obj);
  } else {
    result =
        GetObjectAbbreviatedProperties(ctx, obj, PropertyDescriptorCallback);
  }
  return result;
}

// handle "Runtime.getProperties" protocol
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-getProperties
void HandleGetProperties(DebuggerParams* runtime_options) {
  LEPUSContext* ctx = runtime_options->ctx;
  LEPUSValue message = runtime_options->message;
  LEPUSValue params = LEPUS_GetPropertyStr(ctx, message, "params");

  uint8_t own_properties = 0;
  uint64_t obj_id = 0;
  LEPUSValue obj;  // get property of this obj
  GetPropertiesparams(ctx, params, &obj_id, &obj, &own_properties);

  LEPUSValue internal_properties = LEPUS_UNDEFINED;
  LEPUSValue result = LEPUS_UNDEFINED;
  if (LEPUS_IsUndefined(obj)) {  // this means that obj must be a frame local ,
                                 // frame closure or global scope
    result = GetProperties(ctx, obj, obj_id);
  } else {
    // Iterate the object and call pfunc for processing
    result = GetObjectProperties(ctx, obj, PropertyDescriptorCallback);
    // if own properties is true, get internal property descriptor
    if (own_properties) {
      internal_properties = GetInternalProperties(ctx, obj);
    }
  }

  LEPUS_FreeValue(ctx, obj);
  LEPUSValue ret = LEPUS_NewObject(ctx);
  DebuggerSetPropertyStr(ctx, ret, "result", result);
  if (!LEPUS_IsUndefined(internal_properties)) {
    DebuggerSetPropertyStr(ctx, ret, "internalProperties", internal_properties);
  }

  SendResponse(ctx, message, ret);
}

// TODO: side-effect exception
LEPUSValue GetSideEffectResult(LEPUSContext* ctx) {
  LEPUSValue ret = LEPUS_NewObject(ctx);
  auto* info = GetDebuggerInfo(ctx);
  LEPUSValue result = LEPUS_NewObject(ctx);
  LEPUSValue exception_details = LEPUS_NewObject(ctx);
  DebuggerSetPropertyStr(ctx, ret, "result", result);
  DebuggerSetPropertyStr(ctx, ret, "exceptionDetails", exception_details);

  DebuggerSetPropertyStr(ctx, result, "type",
                         LEPUS_DupValue(ctx, info->literal_pool->object));
  DebuggerSetPropertyStr(ctx, exception_details, "exceptionId",
                         LEPUS_NewInt32(ctx, 8));
  DebuggerSetPropertyStr(
      ctx, exception_details, "text",
      LEPUS_DupValue(ctx, info->literal_pool->capital_uncaught));
  DebuggerSetPropertyStr(ctx, exception_details, "lineNumber",
                         LEPUS_NewInt32(ctx, -1));
  DebuggerSetPropertyStr(ctx, exception_details, "columnNumber",
                         LEPUS_NewInt32(ctx, -1));
  LEPUSValue exception = LEPUS_NewObject(ctx);
  DebuggerSetPropertyStr(ctx, exception_details, "exception", exception);
  DebuggerSetPropertyStr(ctx, exception, "type",
                         LEPUS_DupValue(ctx, info->literal_pool->object));
  DebuggerSetPropertyStr(
      ctx, exception, "description",
      LEPUS_NewString(ctx,
                      "EvalError: Possible side-effect in debug-evaluate"));
  return ret;
}
