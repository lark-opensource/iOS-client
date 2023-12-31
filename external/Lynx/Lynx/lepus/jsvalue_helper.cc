// Copyright 2022 The Lynx Authors. All rights reserved.

#include "lepus/jsvalue_helper.h"

#include <functional>

#include "lepus/array.h"
#include "lepus/table.h"
#include "lepus/value.h"
namespace lynx {
namespace lepus {

LEPUSValue LEPUSValueHelper::TableToJsValue(LEPUSContext* ctx,
                                            const lepus::Value& val,
                                            bool deep_convert) {
  DCHECK(val.IsTable());
  auto& table = *(val.val_table_);
  LEPUSValue obj = LEPUS_NewObject(ctx);

  for (auto& pair : table) {
    LEPUS_SetPropertyStr(ctx, obj, pair.first.c_str(),
                         ToJsValue(ctx, pair.second, deep_convert));
  }
  return obj;
}

LEPUSValue LEPUSValueHelper::ArrayToJsValue(LEPUSContext* ctx,
                                            const lepus::Value& val,
                                            bool deep_convert) {
  DCHECK(val.IsArray());
  auto& array = *(val.val_carray_);
  LEPUSValue ret = LEPUS_NewArray(ctx);

  for (auto i = decltype(array.size()){0}; i < array.size(); i++) {
    LEPUS_SetPropertyUint32(ctx, ret, static_cast<uint32_t>(i),
                            ToJsValue(ctx, array.get(i), deep_convert));
  }
  return ret;
}

LEPUSValue LEPUSValueHelper::ToJsValue(LEPUSContext* ctx,
                                       const lepus::Value& val,
                                       bool deep_convert) {
  switch (val.Type()) {
    case Value_Nil:
      return LEPUS_NULL;
    case Value_Undefined:
      return LEPUS_UNDEFINED;
    case Value_Double:
      return LEPUS_NewFloat64(ctx, val.val_double_);
    case Value_Bool:
      return LEPUS_NewBool(ctx, val.val_bool_);
    case Value_String:
      return LEPUS_NewString(ctx, val.val_str_->c_str());
    case Value_Table:
      if (deep_convert) {
        return TableToJsValue(ctx, val, true);
      } else {
        return CreateLepusRef(ctx, val.val_table_, Value_Table);
      }
    case Value_Array:
      if (deep_convert) {
        return ArrayToJsValue(ctx, val, true);
      } else {
        return CreateLepusRef(ctx, val.val_carray_, Value_Array);
      }
    case Value_RefCounted:
      return CreateLepusRef(ctx, val.val_ref_counted_, Value_RefCounted);
    case Value_Int32:
      return LEPUS_NewInt32(ctx, val.val_int32_t_);
    case Value_Int64:
      return NewInt64(ctx, val.val_int64_t_);
    case Value_UInt32:
      return NewUint32(ctx, val.val_uint32_t_);
    case Value_UInt64:
      return NewUint64(ctx, val.val_uint64_t_);
    case Value_NaN:
    case Value_CDate:
    case Value_RegExp:
    case Value_Closure:
    case Value_CFunction:
      assert(false);
      break;
    case Value_CPointer:
      return NewPointer(val.val_ptr_);
    case Value_JSObject:
      return CreateLepusRef(ctx, val.val_jsobject_, Value_JSObject);
    case Value_ByteArray:
      return CreateLepusRef(ctx, val.val_bytearray_, Value_Array);
    default: {
      if (val.IsJSValue()) {
        return LEPUS_DupValue(ctx, val.WrapJSValue());
      }
    };
  }
  return LEPUS_UNDEFINED;
}

LEPUSValue LEPUSValueHelper::ShallowToJSValue(LEPUSContext* ctx,
                                              const lepus::Value& val) {
  switch (val.Type()) {
    case Value_Table: {
      return TableToJsValue(ctx, val, false);
    } break;
    case Value_Array: {
      return ArrayToJsValue(ctx, val, false);
    } break;
    default:
      return ToJsValue(ctx, val);
  }
}

std::string LEPUSValueHelper::LepusRefToStdString(LEPUSContext* ctx,
                                                  const LEPUSValue& val) {
  if (!IsLepusRef(val)) return "undefined";
  LEPUSLepusRef* pref = static_cast<LEPUSLepusRef*>(LEPUS_VALUE_GET_PTR(val));

  switch (pref->tag) {
    case Value_Array: {
      Value lepus_value;
      lepus_value.SetArray(GetLepusArray(val));
      std::ostringstream s;
      s << lepus_value;
      return s.str();
    } break;
    case Value_Table: {
      return "[object Object]";
    } break;
    case Value_JSObject: {
      return "[object JSObject]";
    } break;
    case Value_ByteArray: {
      return "[object ByteArray]";
    } break;
    default:
      return "";
  }
}

std::string LEPUSValueHelper::ToStdString(LEPUSContext* ctx,
                                          const LEPUSValue& val) {
  if (LEPUS_IsUndefined(val)) {
    return "";
  }
  DCHECK(ctx);
  if (IsLepusRef(val)) {
    return LepusRefToStdString(ctx, val);
  }
  const char* chr = LEPUS_ToCString(ctx, val);
  if (chr) {
    std::string ret(chr);
    LEPUS_FreeCString(ctx, chr);
    return ret;
  }
  return "";
}

lepus::Value LEPUSValueHelper::ToLepusArray(LEPUSContext* ctx,
                                            const LEPUSValue& val,
                                            int32_t flag) {
  Value ret(lepus::CArray::Create());
  JSValueIteratorCallback to_lepus_array_callback =
      [&ret, flag](LEPUSContext* ctx, const LEPUSValue& key,
                   const LEPUSValue& value) {
        ret.Array()->push_back(ToLepusValue(ctx, value, flag));
      };

  IteratorJsValue(ctx, val, &to_lepus_array_callback);
  return ret;
}

lepus::Value LEPUSValueHelper::ToLepusTable(LEPUSContext* ctx,
                                            const LEPUSValue& val,
                                            int32_t flag) {
  Value ret(lepus::Dictionary::Create());
  JSValueIteratorCallback to_lepus_table_callback =
      [&ret, flag](LEPUSContext* ctx, const LEPUSValue& key,
                   const LEPUSValue& value) {
        ret.Table()->SetValue(ToStdString(ctx, key),
                              ToLepusValue(ctx, value, flag));
      };

  IteratorJsValue(ctx, val, &to_lepus_table_callback);
  return ret;
}  // namespace lepus

lepus::Value LEPUSValueHelper::ToLepusValue(LEPUSContext* ctx,
                                            const LEPUSValue& val,
                                            int32_t flag) {
  static lepus::Value empty_value;
  switch (LEPUS_VALUE_GET_TAG(val)) {
    case LEPUS_TAG_INT:
      return Value(LEPUS_VALUE_GET_INT(val));
    case LEPUS_TAG_BIG_INT: {
      int64_t int64;
      LEPUS_ToInt64(ctx, &int64, val);
      return Value(int64);
    } break;
    case LEPUS_TAG_FLOAT64: {
      double d;
      LEPUS_ToFloat64(ctx, &d, val);
      if (StringConvertHelper::IsInt64Double(d)) {
        return Value(static_cast<int64_t>(d));
      } else {
        return Value(d);
      }
    } break;
    case LEPUS_TAG_UNDEFINED: {
      lepus::Value ret;
      ret.SetUndefined();
      return ret;
    } break;
    case LEPUS_TAG_NULL:
      return Value();
    case LEPUS_TAG_BOOL:
      return Value(static_cast<bool>(LEPUS_VALUE_GET_BOOL(val)));
    case LEPUS_TAG_LEPUS_CPOINTER:
      return Value(JSCpointer(val));
    case LEPUS_TAG_STRING:
    case LEPUS_TAG_SEPARABLE_STRING: {
      void* cache = LEPUS_GetStringCache(val);
      Value ret;
      if (cache) {
        StringImpl* ptr = reinterpret_cast<StringImpl*>(cache);
        ret.SetString(ptr);
        return ret;
      } else {
        StringImpl* ptr = StringImpl::RawCreate(ToStdString(ctx, val));
        LEPUS_SetStringCache(ctx, val, ptr);
        ptr->Release();
        ret.SetString(ptr);
        return ret;
      }
    } break;
    case LEPUS_TAG_LEPUS_REF: {
      if (likely(flag == 0)) {
        return LepusRefToLepusValue(ctx, val);
      } else if (flag == 1) {
        return Value::Clone(LepusRefToLepusValue(ctx, val));
      } else {
        return Value::ShallowCopy(LepusRefToLepusValue(ctx, val), true);
      }
    } break;
    case LEPUS_TAG_OBJECT: {
      if (IsJsArray(ctx, val)) {
        return ToLepusArray(ctx, val, flag);
      } else if (IsJsFunction(ctx, val)) {
        if (flag == 0) {
          return lepus::Value(ctx, val);
        }
        return empty_value;
      } else {
        return ToLepusTable(ctx, val, flag);
      }
    } break;
    default:
      if (LEPUS_IsNumber(val)) {
        double d;
        LEPUS_ToFloat64(ctx, &d, val);
        if (StringConvertHelper::IsInt64Double(d)) {
          return Value(static_cast<int64_t>(d));
        } else {
          return Value(d);
        }
      }
      LOGE("ToLepusValue: unkown jsvalue type  " << GetType(ctx, val));
  }
  return empty_value;
}

bool LEPUSValueHelper::IsLepusEqualJsArray(LEPUSContext* ctx,
                                           lepus::CArray* src,
                                           const LEPUSValue& dst) {
  if (src->size() != static_cast<size_t>(GetLength(ctx, dst))) {
    return false;
  }
  for (uint32_t i = 0; i < src->size(); i++) {
    lepus::Value dst_element(ctx, GetPropertyJsValue(ctx, dst, i));
    if (src->get(i) != dst_element) return false;
  }
  return true;
}

bool LEPUSValueHelper::IsLepusEqualJsObject(LEPUSContext* ctx,
                                            lepus::Dictionary* src,
                                            const LEPUSValue& dst) {
  if (src->size() != static_cast<size_t>(GetLength(ctx, dst))) {
    return false;
  }
  for (auto& it : *src) {
    lepus::Value dst_property(ctx,
                              GetPropertyJsValue(ctx, dst, it.first.c_str()));
    if (it.second != dst_property) return false;
  }
  return true;
}

bool LEPUSValueHelper::IsJsValueEqualJsValue(LEPUSContext* ctx,
                                             const LEPUSValue& left,
                                             const LEPUSValue& right) {
  return LEPUS_VALUE_GET_BOOL(LEPUS_DeepEqual(ctx, left, right));
}

const char* LEPUSValueHelper::GetType(LEPUSContext* ctx,
                                      const LEPUSValue& val) {
  switch (LEPUS_VALUE_GET_TAG(val)) {
    case LEPUS_TAG_BIG_INT:
      return "LEPUS_BIG_INT";
    case LEPUS_TAG_BIG_FLOAT:
      return "LEPUS_BIG_FLOAT";
    case LEPUS_TAG_SYMBOL:
      return "LEPUS_TAG_SYMBOL";
    case LEPUS_TAG_STRING:
      return "LEPUS_TAG_STRING";
    case LEPUS_TAG_SEPARABLE_STRING:
      return "LEPUS_TAG_SEPARABLE_STRING";
    case LEPUS_TAG_SHAPE:
      return "LEPUS_TAG_SHAPE";
    case LEPUS_TAG_ASYNC_FUNCTION:
      return "LEPUS_TAG_ASYNC_FUNCTION";
    case LEPUS_TAG_VAR_REF:
      return "LEPUS_TAG_VAR_REF";
    case LEPUS_TAG_MODULE:
      return "LEPUS_TAG_MODULE";
    case LEPUS_TAG_FUNCTION_BYTECODE:
      return "LEPUS_TAG_FUNCTION_BYTECODE";
    case LEPUS_TAG_OBJECT: {
      if (IsJsArray(ctx, val)) {
        return "LEPUS_TAG_ARRAY";
      }
      return "LEPUS_TAG_OBJECT";
    } break;
    case LEPUS_TAG_INT:
      return "LEPUS_TAG_INT";
    case LEPUS_TAG_BOOL:
      return "LEPUS_TAG_BOOL";
    case LEPUS_TAG_NULL:
      return "LEPUS_TAG_NULL";
    case LEPUS_TAG_UNDEFINED:
      return "LEPUS_TAG_UNDEFINED";
    case LEPUS_TAG_UNINITIALIZED:
      return "LEPUS_TAG_UNINITIALIZED";
    case LEPUS_TAG_CATCH_OFFSET:
      return "LEPUS_TAG_CATCH_OFFSET";
    case LEPUS_TAG_EXCEPTION:
      return "LEPUS_TAG_EXCEPTION";
    case LEPUS_TAG_LEPUS_CPOINTER:
      return "LEPUS_TAG_LEPUS_CFUNCTION";
    case LEPUS_TAG_FLOAT64:
      return "LEPUS_TAG_FLOAT64";
  }
  return "";
}

void LEPUSValueHelper::PrintValue(std::ostream& s, LEPUSContext* ctx,
                                  const LEPUSValue& val, uint32_t prefix) {
#if ENABLE_PRINT_VALUE
  if (!IsJsObject(val)) {
    ToLepusValue(ctx, val).PrintValue(s);
    return;
  }

#define PRINT_PREFIX(prefix)              \
  for (uint32_t i = 0; i < prefix; i++) { \
    s << "  ";                            \
  }
  uint32_t current_idx = 0;
  uint32_t size = GetLength(ctx, val);
  if (IsJsArray(ctx, val)) {
    s << "[\n";
    while (current_idx < size) {
      PRINT_PREFIX(prefix)
      LEPUSValue prop = GetPropertyJsValue(ctx, val, current_idx);
      PrintValue(s, ctx, prop, prefix + 1);
      LEPUS_FreeValue(ctx, prop);
      if (++current_idx != size) {
        s << ",";
      }
      s << "\n";
    }
    PRINT_PREFIX(prefix - 1)
    s << "]";
  } else if (IsJsObject(val)) {
    s << "{\n";
    JSValueIteratorCallback print_jstable =
        [&s, &current_idx, &size, prefix](
            LEPUSContext* ctx, const LEPUSValue& key, const LEPUSValue& val) {
          PRINT_PREFIX(prefix)
          s << ToStdString(ctx, key) << ": ";
          PrintValue(s, ctx, val, prefix + 1);
          if (++current_idx != size) {
            s << ",";
          }
          s << "\n";
        };
    IteratorJsValue(ctx, val, &print_jstable);
    PRINT_PREFIX(prefix - 1)
    s << "}";
  }
#undef PRINT_PREFIX
#endif
}

void LEPUSValueHelper::Print(LEPUSContext* ctx, const LEPUSValue& val) {
#if ENABLE_PRINT_VALUE
  std::ostringstream s;
  PrintValue(s, ctx, val);
  LOGI(s.str() << std::endl);
#endif
}

}  // namespace lepus
}  // namespace lynx
