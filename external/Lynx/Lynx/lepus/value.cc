// Copyright 2019 The Lynx Authors. All rights reserved.

#include "lepus/value.h"

#include <math.h>

#include <utility>

#include "base/log/logging.h"
#include "base/ref_counted.h"
#include "base/string/string_number_convert.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "lepus/array.h"
#include "lepus/context.h"
#include "lepus/function.h"
#include "lepus/jsvalue_helper.h"
#include "lepus/lepus_date.h"
#include "lepus/path_parser.h"
#include "lepus/regexp.h"
#include "lepus/string_util.h"
#include "lepus/table.h"
#include "lepus/value-inl.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/value_utils.h"

namespace lynx {
namespace lepus {

Value::Value(const Value& value) { Copy(value); }

Value::Value(Value&& value) noexcept {
  type_ = value.type_;
  val_uint64_t_ = value.val_uint64_t_;
  cell_ = value.cell_;

  value.type_ = Value_Nil;
  value.val_int64_t_ = 0;
  value.cell_ = nullptr;
}

Value::Value(lynx::base::scoped_refptr<lepus::StringImpl> data)
    : val_str_(data.Get()), type_(Value_String) {
  data.Get()->AddRef();
}

Value::Value(lynx::base::scoped_refptr<lepus::LEPUSObject> data)
    : val_jsobject_(data.Get()), type_(Value_JSObject) {
  data.Get()->AddRef();
}

Value::Value(lynx::base::scoped_refptr<lepus::ByteArray> data)
    : val_bytearray_(data.Get()), type_(Value_ByteArray) {
  data.Get()->AddRef();
}

Value::Value(const base::scoped_refptr<base::RefCountedThreadSafeStorage>& data)
    : val_ref_counted_(data.Get()), type_(Value_RefCounted) {
  data.Get()->AddRef();
}

Value::Value(bool val) : val_bool_(val), type_(Value_Bool) {}

Value::Value(const char* val) : type_(Value_String) {
  auto s = lepus::String(val).impl();
  val_str_ = s.Get();
  s->AddRef();
}

Value::Value(std::string str) : type_(Value_String) {
  auto s = lepus::StringImpl::Create(std::move(str));
  val_str_ = s.Get();
  s->AddRef();
}

Value::Value(void* data) : val_ptr_(data), type_(Value_CPointer) {}
Value::Value(CFunction val)
    : val_ptr_(reinterpret_cast<void*>(val)), type_(Value_CFunction) {}
Value::Value(bool for_nan, bool val) {
  if (for_nan) {
    val_nan_ = val;
    type_ = Value_NaN;
  }
}

#define NumberConstructor(name, type) \
  Value::Value(type val) : val_##type##_(val), type_(Value_##name) {}

NumberType(NumberConstructor)
#undef NumberConstructor

    Value::Value(uint8_t data)
    : val_uint32_t_(data), type_(Value_UInt32) {
}

Value::Value(lynx::base::scoped_refptr<Dictionary> data)
    : val_table_(data.Get()), type_(Value_Table) {
  data.Get()->AddRef();
}
Value::Value(base::scoped_refptr<CArray> data)
    : val_carray_(data.Get()), type_(Value_Array) {
  data.Get()->AddRef();
}

void Value::ConstructValueFromLepusRef(LEPUSContext* ctx,
                                       const LEPUSValue& val) {
  if (LEPUS_IsLepusRef(val)) {
    type_ = static_cast<ValueType>(LEPUS_GetLepusRefTag(val));
    val_ptr_ = LEPUS_GetLepusRefPoint(val);
    if (type_ == Value_Table) {
      reinterpret_cast<Dictionary*>(val_ptr_)->MarkFromRef();
      std::lock_guard<std::mutex> guard(Context::GetTableMutex());
      Context::GetLeakTable().emplace(reinterpret_cast<Dictionary*>(val_ptr_),
                                      kNotTraversed);
    } else if (type_ == Value_Array) {
      reinterpret_cast<CArray*>(val_ptr_)->MarkFromRef();
      std::lock_guard<std::mutex> guard(Context::GetArrayMutex());
      Context::GetLeakArray().emplace(reinterpret_cast<CArray*>(val_ptr_),
                                      kNotTraversed);
    }
    reinterpret_cast<base::RefCountedThreadSafeStorage*>(val_ptr_)->AddRef();
    LEPUSLepusRef* ref =
        reinterpret_cast<LEPUSLepusRef*>(LEPUS_VALUE_GET_PTR(val));
    LEPUS_FreeValue(ctx, ref->lepus_val);
    ref->lepus_val = LEPUS_UNDEFINED;
  }
}

Value::Value(LEPUSContext* ctx, const LEPUSValue& val) {
  if (LEPUS_IsLepusRef(val)) {
    ConstructValueFromLepusRef(ctx, val);
    return;
  }

  cell_ = Context::GetContextCellFromCtx(ctx);
#if defined(__aarch64__) && !defined(OS_WIN)
  type_ = Value_PrimJsValue;
#else
  tag_ = EncodeJSTag(LEPUS_VALUE_GET_TAG(val));
#endif
  val_int64_t_ = LEPUS_VALUE_GET_INT64(val);
  LEPUS_DupValue(ctx, val);
}

Value::Value(LEPUSContext* ctx, LEPUSValue&& val) {
  if (LEPUS_IsLepusRef(val)) {
    ConstructValueFromLepusRef(ctx, val);
    LEPUS_FreeValue(ctx, val);
    val = LEPUS_UNDEFINED;
    return;
  }
  cell_ = Context::GetContextCellFromCtx(ctx);
#if defined(__aarch64__) && !defined(OS_WIN)
  type_ = Value_PrimJsValue;
#else
  tag_ = EncodeJSTag(LEPUS_VALUE_GET_TAG(val));
#endif
  val_int64_t_ = LEPUS_VALUE_GET_INT64(val);
  val = LEPUS_UNDEFINED;
}

LEPUSValue Value::ToJSValue(LEPUSContext* ctx, bool deep_convert) const {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Value::ToJSValue");
  if (IsJSValue()) {
    LEPUSValue v = WrapJSValue();
    LEPUS_DupValue(ctx, v);
    return v;
  }
  if (IsInt32()) {
    return LEPUS_NewInt32(ctx, Int32());
  } else if (IsCPointer()) {
    return LEPUS_MKPTR(LEPUS_TAG_LEPUS_CPOINTER, val_ptr_);
  } else if (IsDouble()) {
    return LEPUS_NewFloat64(ctx, Double());
  }
  return LEPUSValueHelper::ToJsValue(ctx, *this, deep_convert);
}

Value Value::ToLepusValue() const {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Value::ToLepusValue");
  if (!IsJSValue()) {
    if (IsTable()) {
      for (auto& itr : *Table()) {
        itr.second.ToLepusValue();
      }
    } else if (IsArray()) {
      for (std::size_t i = 0; i < Array()->size(); ++i) {
        Array()->get(i).ToLepusValue();
      }
    }
    return *this;
  }
  return const_cast<lepus::Value&>(*this) =
             LEPUSValueHelper::ToLepusValue(cell_->ctx_, WrapJSValue());
}

Value::~Value() { this->FreeValue(); }

double Value::Number() const {
  switch (type_) {
#define NumberCase(name, type) \
  case Value_##name:           \
    return val_##type##_;

    NumberType(NumberCase)

#undef NumberCase
        default : if (IsJSNumber()) return LEPUSNumber();
  }
  return 0;
}

#if !ENABLE_JUST_LEPUSNG
Value::Value(lynx::base::scoped_refptr<lepus::Closure> data)
    : val_closure_(data.Get()), type_(Value_Closure) {
  data.Get()->AddRef();
}

Value::Value(lynx::base::scoped_refptr<lepus::CDate> data)
    : val_date_(data.Get()), type_(Value_CDate) {
  data.Get()->AddRef();
}

Value::Value(lynx::base::scoped_refptr<lepus::RegExp> data)
    : val_regexp_(data.Get()), type_(Value_RegExp) {
  data.Get()->AddRef();
}

lynx::base::scoped_refptr<lepus::RegExp> Value::RegExp() const {
  if (val_regexp_ != nullptr && type_ == Value_RegExp) {
    return val_regexp_;
  }
  return lepus::RegExp::Create("", "");
}

lynx::base::scoped_refptr<lepus::Closure> Value::GetClosure() const {
  if (val_closure_ != nullptr && type_ == Value_Closure) {
    return val_closure_;
  }
  return lepus::Closure::Create(nullptr);
}

lynx::base::scoped_refptr<lepus::CDate> Value::Date() const {
  if (val_date_ != nullptr && type_ == Value_CDate) {
    return val_date_;
  }
  return lepus::CDate::Create();
}

void Value::SetClosure(
    const lynx::base::scoped_refptr<lepus::Closure>& closure) {
  FreeValue();
  this->val_closure_ = closure.Get();
  this->type_ = Value_Closure;
  closure->AddRef();
}

void Value::SetDate(const lynx::base::scoped_refptr<lepus::CDate>& date) {
  FreeValue();
  this->val_date_ = date.Get();
  this->type_ = Value_CDate;
  date->AddRef();
}

void Value::SetRegExp(const lynx::base::scoped_refptr<lepus::RegExp>& regexp) {
  FreeValue();
  this->type_ = Value_RegExp;
  this->val_regexp_ = regexp.Get();
  regexp->AddRef();
}
#endif

lynx::base::scoped_refptr<lepus::StringImpl> Value::String() const {
  if (val_str_ != nullptr && type_ == Value_String) {
    return val_str_;
  }
  if (IsJSString()) {
    return GetJSString();
  } else if (type_ == Value_Bool) {
    return lepus::StringImpl::Create(val_bool_ ? "true" : "false");
  } else if (IsJSBool()) {
    return lepus::StringImpl::Create(LEPUSBool() ? "true" : "false");
  }
  return lepus::StringImpl::Create("");
}

lynx::base::scoped_refptr<lepus::LEPUSObject> Value::LEPUSObject() const {
  if (val_jsobject_ != nullptr && type_ == Value_JSObject) {
    return val_jsobject_;
  }
  return lepus::LEPUSObject::Create();
}

lynx::base::scoped_refptr<lepus::ByteArray> Value::ByteArray() const {
  if (val_bytearray_ != nullptr && type_ == Value_ByteArray) {
    return val_bytearray_;
  }
  return lepus::ByteArray::Create();
}

lynx::base::scoped_refptr<lepus::Dictionary> Value::Table() const {
  if (val_table_ != nullptr && type_ == Value_Table) {
    return val_table_;
  }
  return lepus::Dictionary::Create();
}

lynx::base::scoped_refptr<lepus::CArray> Value::Array() const {
  if (val_carray_ != nullptr && type_ == Value_Array) {
    return val_carray_;
  }
  return lepus::CArray::Create();
}

void* Value::CPoint() const {
  if (type_ == Value_CPointer) {
    return Ptr();
  }
  if (IsJSCPointer()) {
    return LEPUSCPointer();
  }
  return nullptr;
}

base::scoped_refptr<base::RefCountedThreadSafeStorage> Value::RefCounted()
    const {
  if (type_ == Value_RefCounted) {
    return val_ref_counted_;
  }
  return nullptr;
}

void Value::SetNan(bool value) {
  FreeValue();
  this->type_ = Value_NaN;
  this->val_nan_ = value;
}

void Value::SetCPoint(void* point) {
  FreeValue();
  this->type_ = Value_CPointer;
  this->val_ptr_ = point;
}

void Value::SetCFunction(CFunction func) {
  FreeValue();
  this->type_ = Value_CFunction;
  this->val_ptr_ = reinterpret_cast<void*>(func);
}

void Value::SetBool(bool value) {
  FreeValue();
  this->type_ = Value_Bool;
  this->val_bool_ = value;
}

void Value::SetString(const lynx::base::scoped_refptr<lepus::StringImpl>& str) {
  FreeValue();
  this->type_ = Value_String;
  this->val_str_ = str.Get();
  str->AddRef();
}

void Value::SetTable(
    const lynx::base::scoped_refptr<lepus::Dictionary>& dictionary) {
  FreeValue();
  this->val_table_ = dictionary.Get();
  this->type_ = Value_Table;
  dictionary->AddRef();
}

void Value::SetArray(const lynx::base::scoped_refptr<lepus::CArray>& ary) {
  FreeValue();
  this->val_carray_ = ary.Get();
  this->type_ = Value_Array;
  ary->AddRef();
}

void Value::SetJSObject(
    const lynx::base::scoped_refptr<lepus::LEPUSObject>& lepus_obj) {
  FreeValue();
  this->type_ = Value_JSObject;
  this->val_jsobject_ = lepus_obj.Get();
  lepus_obj->AddRef();
}

void Value::SetByteArray(
    const lynx::base::scoped_refptr<lepus::ByteArray>& src) {
  FreeValue();
  type_ = Value_ByteArray;
  val_bytearray_ = src.Get();
  src->AddRef();
}

int Value::GetLength() const {
  if (IsJSValue()) {
    return LEPUS_GetLength(cell_->ctx_, WrapJSValue());
  }

  switch (Type()) {
    case lepus::Value_Array:
      return static_cast<int>(Array()->size());
    case lepus::Value_Table:
      return static_cast<int>(Table()->size());
    case lepus::Value_String:
      return static_cast<int>(
          lepus::SizeOfUtf8(String()->c_str(), String()->length()));
    default:
      break;
  }

  return 0;
}

bool Value::IsEqual(const Value& value) const { return (*this == value); }

bool Value::SetProperty(uint32_t idx, const Value& val) {
  if (IsJSArray()) {
    return LEPUSValueHelper::SetProperty(cell_->ctx_, WrapJSValue(), idx, val);
  }

  if (IsArray()) {
    return Array()->set(idx, val);
  }
  return false;
}

bool Value::SetProperty(const lepus::String& key, const Value& val) {
  if (IsJSTable()) {
    return LEPUSValueHelper::SetProperty(cell_->ctx_, WrapJSValue(), key, val);
  }

  if (IsTable()) {
    return Table()->SetValue(key, val);
  }

  return false;
}

Value Value::GetProperty(uint32_t idx) const {
  if (IsJSArray()) {
    LEPUSContext* ctx = cell_->ctx_;
    return lepus::Value(
        ctx, LEPUSValueHelper::GetPropertyJsValue(ctx, WrapJSValue(), idx));
  }

  if (IsArray()) {
    return Array()->get(idx);
  } else if (IsString()) {
    if (String()->length() > idx) {
      char c = String()->c_str()[idx];
      std::stringstream ss;
      ss << c;
      return lepus::Value(lynx::lepus::StringImpl::Create(ss.str()));
    }
  }

  return Value();
}

Value Value::GetProperty(const lepus::String& key) const {
  if (IsJSTable()) {
    LEPUSContext* ctx = cell_->ctx_;
    return lepus::Value(ctx, LEPUSValueHelper::GetPropertyJsValue(
                                 ctx, WrapJSValue(), key.c_str()));
  }
  if (IsTable()) {
    return Table()->GetValue(key);
  }
  return Value();
}

bool Value::Contains(const lepus::String& key) const {
  if (IsJSTable()) {
    return LEPUSValueHelper::HasProperty(cell_->ctx_, WrapJSValue(), key);
  }
  if (IsTable()) {
    return Table()->Contains(key);
  }
  return false;
}

void Value::MergeValue(lepus::Value& target, const lepus::Value& update) {
  if (update.IsJSTable()) {
    // TODO: optimize it
    lepus::Value* target_ptr = &target;
    tasm::ForEachLepusValue(
        update, [target_ptr](const Value& key, const Value& val) {
          target_ptr->SetProperty(key.String(), val.ToLepusValue());
        });
    return;
  }
  // check target's first level variable.
  // 1. if update key is not path, simply add new k-v pair for the first level
  // 2. if update key is value path, clone the first level k-v pair and update
  //     the exact value.
  auto update_table = update.Table();
  for (auto it = update_table->begin(); it != update_table->end(); ++it) {
    auto result = lepus::ParseValuePath(it->first.c_str());
    if (result.size() == 1) {
      target.SetProperty(it->first, it->second);
    } else if (result.size() > 1) {
      if (target.IsTable()) {
        auto front_value = result.begin();
        lepus_value old_value = target.Table()->GetValue(front_value->c_str());
        if ((old_value.IsTable() && old_value.Table()->IsConst()) ||
            (old_value.IsArray() && old_value.Array()->IsConst())) {
          old_value = lepus_value::Clone(old_value);
        }
        result.erase(front_value);
        UpdateValueByPath(old_value, it->second, result);
        target.Table()->SetValue(front_value->c_str(), old_value);
      }
    }
  }
}

bool Value::UpdateValueByPath(lepus::Value& target, const lepus::Value& update,
                              std::vector<std::string>& path) {
  lepus::Value* ptr = &target;
  for (auto it = begin(path); it != end(path); ++it) {
    if (ptr->IsTable()) {
      auto key = it->c_str();
      if (!ptr->Table()->Contains(key)) {
        ptr->Table()->SetValue(key, lepus::Value());
      }
      ptr = &(const_cast<Value&>(ptr->Table()->GetValue(key)));
    } else if (ptr->IsArray()) {
      int index;
      if (lynx::base::StringToInt(*it, &index, 10)) {
        if (static_cast<size_t>(index) >= ptr->Array()->size()) {
          ptr->Array()->resize(index + 1);
        }
        ptr = &(const_cast<Value&>(ptr->Array()->get(index)));
      }
    }
  }
  *ptr = update;
  return true;
}

// don't support Closure, CFunction, Cpoint
Value Value::Clone(const Value& src, bool clone_as_jsvalue) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Value::Clone");
  if (src.IsJSValue()) {
    return LEPUSValueHelper::DeepCopyJsValue(src.cell_->ctx_, src.WrapJSValue(),
                                             clone_as_jsvalue);
  }
  ValueType type = src.Type();
  Value v;
  switch (type) {
    case Value_Nil:
      return Value();
    case Value_Undefined:
      v.SetUndefined();
      return v;
    case Value_Double: {
      double data = src.Number();
      return Value(data);
    }
    case Value_Int32:
      return Value(src.Int32());
    case Value_Int64:
      return Value(src.Int64());
    case Value_UInt32:
      return Value(src.UInt32());
    case Value_UInt64:
      return Value(src.UInt64());
    case Value_Bool:
      return Value(src.Bool());
    case Value_NaN:
      return Value(true, src.NaN());
    case Value_String: {
      auto str = StringImpl::Create(src.String()->c_str());
      return Value(str);
    }
    case Value_Table: {
      auto lepus_map = lepus::Dictionary::Create();
      auto it = src.Table()->begin();
      for (; it != src.Table()->end(); it++) {
        lepus::String key(it->first.c_str());
        lepus::Value value = Value::Clone(it->second);
        lepus_map->SetValue(key, value);
      }
      Value table_value(lepus_map);
      return table_value;
    }
    case Value_Array: {
      auto ary = CArray::Create();
      for (size_t i = 0; i < src.Array()->size(); ++i) {
        ary->push_back(Value::Clone(src.Array()->get(i)));
      }
      return Value(ary);
    }
    case Value_JSObject: {
      return Value(LEPUSObject::Create(src.LEPUSObject()->jsi_object_proxy()));
    }
    case Value_Closure:
    case Value_CFunction:
    case Value_CPointer:
    case Value_RefCounted:
      break;
#if !ENABLE_JUST_LEPUSNG
    case Value_CDate: {
      auto date = CDate::Create(src.Date()->get_date_(), src.Date()->get_ms_(),
                                src.Date()->get_language());
      return Value(date);
    }
#endif
    default:
      LOGE("!! Value::Clone unknow type: " << type);
      break;
  }
  return Value();
}

// copy the first level, and mark last as const.
Value Value::ShallowCopy(const Value& src, bool clone_as_jsvalue) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Value::ShallowCopy");
  if (src.IsJSValue()) {
    return LEPUSValueHelper::DeepCopyJsValue(src.cell_->ctx_, src.WrapJSValue(),
                                             clone_as_jsvalue);
  }
  ValueType type = src.Type();
  switch (type) {
    case Value_Table: {
      auto lepus_map = lepus::Dictionary::Create();
      auto it = src.Table()->begin();
      for (; it != src.Table()->end(); it++) {
        lepus::String key(it->first.c_str());
        if (it->second.MarkConst()) {
          lepus_map->SetValue(key, it->second);
        } else {
          lepus_map->SetValue(key, Value::Clone(it->second));
        }
      }
      Value table_value(lepus_map);
      return table_value;
    }
    case Value_Array: {
      auto ary = CArray::Create();
      for (size_t i = 0; i < src.Array()->size(); ++i) {
        if (src.Array()->get(i).MarkConst()) {
          ary->push_back(src.Array()->get(i));
        } else {
          ary->push_back(Value::Clone(src.Array()->get(i)));
        }
      }
      return Value(ary);
    }
    default:
      break;
  }
  return Value::Clone(src);
}

Value Value::CreateObject(Context* ctx) {
  if (ctx && ctx->IsLepusNGContext()) {
    LEPUSContext* lctx = ctx->context();
    return lepus::Value(lctx, LEPUS_NewObject(lctx));
  }
  return Value(lepus::Dictionary::Create());
}

bool operator==(const Value& left, const Value& right) {
  if (&left == &right) {
    return true;
  }
  // process JSValue type
  if (left.IsJSValue() && right.IsJSValue()) {
    return LEPUSValueHelper::IsJsValueEqualJsValue(
        left.context(), left.WrapJSValue(), right.WrapJSValue());
  } else if (right.IsJSValue()) {
    return LEPUSValueHelper::IsLepusEqualJsValue(right.cell_->ctx_, left,
                                                 right.WrapJSValue());
  } else if (left.IsJSValue()) {
    return LEPUSValueHelper::IsLepusEqualJsValue(left.cell_->ctx_, right,
                                                 left.WrapJSValue());
  }
  if (left.IsNumber() && right.IsNumber()) {
    return fabs(left.Number() - right.Number()) < 0.000001;
  }
  if (left.type_ != right.type_) return false;
  switch (left.type_) {
    case Value_Nil:
      return true;
    case Value_Undefined:
      return true;
    case Value_Double:
      return fabs(left.Number() - right.Number()) < 0.000001;
    case Value_Bool:
      return left.Bool() == right.Bool();
    case Value_NaN:
      return false;
    case Value_String:
      return left.String() == right.String() ||
             ((left.String() && right.String()) &&
              left.String()->IsEqual(right.String().Get()));
    case Value_CFunction:
      return left.Ptr() == right.Ptr();
    case Value_CPointer:
      return left.Ptr() == right.Ptr();
    case Value_RefCounted:
      return left.RefCounted() == right.RefCounted();
    case Value_Table:
      return *(left.Table().Get()) == *(right.Table().Get());
    case Value_Array:
      return *(left.Array().Get()) == *(right.Array().Get());
#if !ENABLE_JUST_LEPUSNG
    case Value_Closure:
      return left.GetClosure() == right.GetClosure();
    case Value_CDate:
      return *(left.Date().Get()) == *(right.Date().Get());
    case Value_RegExp:
      return left.RegExp()->get_pattern() == right.RegExp()->get_pattern() &&
             left.RegExp()->get_flags() == right.RegExp()->get_flags();
#endif
    case Value_Int32:
    case Value_Int64:
    case Value_UInt32:
    case Value_UInt64:
      // handled, ignore
      break;
    case Value_JSObject:
      return *(left.LEPUSObject().Get()) == *(right.LEPUSObject().Get());
    default:
      break;
  }
  return false;
}

void Value::Print() const {
  std::ostringstream s;
  PrintValue(s);
  LOGE(s.str() << std::endl);
}

void Value::PrintValue(std::ostream& output, bool ignore_other,
                       bool pretty) const {
  if (IsJSValue()) {
    LEPUSValueHelper::PrintValue(output, cell_->ctx_, WrapJSValue());
    return;
  }
  switch (Type()) {
    case Value_Nil:
      if (ignore_other) {
        output << "";
      } else {
        output << "null";
      }
      break;
    case Value_Undefined:
      if (ignore_other) {
        output << "";
      } else {
        output << "undefined";
      }
      break;
    case Value_Double:
      output << StringConvertHelper::DoubleToString(Number());
      break;
    case Value_Int32:
      output << Int32();
      break;
    case Value_Int64:
      output << Int64();
      break;
    case Value_UInt32:
      output << UInt32();
      break;
    case Value_UInt64:
      output << UInt64();
      break;
    case Value_Bool:
      output << (Bool() ? "true" : "false");
      break;
    case Value_String:
      if (pretty) {
        output << "\"" << String()->c_str() << "\"";
      } else {
        output << String()->c_str();
      }
      break;
    case Value_Table:
      output << "{";
      for (auto it = Table()->begin(); it != Table()->end(); it++) {
        if (it != Table()->begin()) {
          output << ",";
        }
        if (pretty) {
          output << "\"" << it->first.str() << "\""
                 << ":";
        } else {
          output << it->first.str() << ":";
        }
        it->second.PrintValue(output, ignore_other);
      }
      output << "}";
      break;
    case Value_Array:
      output << "[";
      for (size_t i = 0; i < Array()->size(); i++) {
        Array()->get(i).PrintValue(output, ignore_other);
        if (i != (Array()->size() - 1)) {
          output << ",";
        }
      }
      output << "]";
      break;
    case Value_Closure:
    case Value_CFunction:
    case Value_CPointer:
    case Value_RefCounted:
      if (ignore_other) {
        output << "";
      } else {
        output << "closure/cfunction/cpointer/refcounted" << std::endl;
      }
      break;
#if !ENABLE_JUST_LEPUSNG
    case Value_CDate:
      if (ignore_other) {
        output << "";
      } else {
        Date()->print(output);
      }
      break;
    case Value_RegExp:
      if (ignore_other) {
        output << "";
      } else {
        output << "regexp" << std::endl;
        output << "pattern: " << RegExp()->get_pattern().str() << std::endl;
        output << "flags: " << RegExp()->get_flags().str() << std::endl;
      }
      break;
#endif
    case Value_NaN:
      if (ignore_other) {
        output << "";
      } else {
        output << "NaN";
      }
      break;
    case Value_JSObject:
      if (ignore_other) {
        output << "";
      } else {
        output << "LEPUSObject id=" << LEPUSObject()->JSIObjectID();
      }
      break;
    case Value_ByteArray:
      if (ignore_other) {
        output << "";
      } else {
        output << "ByteArray";
      }
      break;
    default:
      if (ignore_other) {
        output << "";
      } else {
        output << "unknow type";
      }
      break;
  }
}

bool Value::MarkConst() const {
  if (IsTable()) {
    lynx::base::scoped_refptr<lepus::Dictionary> table = Table();
    if (table->IsConst()) {
      return true;
    }
    for (auto& it : *table) {
      if (!it.second.MarkConst()) {
        return false;
      }
    }
    table->MarkConst();
    return true;
  } else if (IsArray()) {
    lynx::base::scoped_refptr<lepus::CArray> array = Array();
    if (array->IsConst()) {
      return true;
    }
    for (size_t i = 0; i < array->size(); i++) {
      if (!array->get(i).MarkConst()) return false;
    }
    array->MarkConst();
    return true;
  } else if (IsJSValue()) {
    return false;
  }
  // is primitive type
  return true;
}

void Value::Copy(const Value& value) {
  // avoid self-assignment
  if (this == &value) {
    return;
  }
  value.DupValue();
  FreeValue();
  val_uint64_t_ = value.val_uint64_t_;
  type_ = value.Type();

  cell_ = value.cell_;
}

void Value::DupValue() const {
  if (IsJSValue()) {
    LEPUSValue val = WrapJSValue();
    LEPUS_DupValueRT(cell_->rt_, val);
    return;
  }
  if (!IsReference() || !val_ptr_) return;
  reinterpret_cast<base::RefCountedThreadSafeStorage*>(val_ptr_)->AddRef();
  return;
}

void Value::FreeValue() {
  if (IsJSValue()) {
    if (unlikely(!cell_->rt_)) return;
    LEPUSValue val = WrapJSValue();
    LEPUS_FreeValueRT(cell_->rt_, val);
    return;
  }
  if (!IsReference() || !val_ptr_) return;
  reinterpret_cast<base::RefCountedThreadSafeStorage*>(val_ptr_)->Release();
  return;
}

#define NumberValue(name, type)  \
  type Value::name() const {     \
    if (type_ != Value_##name) { \
      return 0;                  \
    }                            \
    return val_##type##_;        \
  }
NormalNumberType(NumberValue)
#undef NumberValue

    int64_t Value::Int64() const {
  if (type_ == Value_Int64) return val_int64_t_;
  if (IsJSInteger()) {
    return JSInteger();
  }
  return 0;
}

bool Value::IsJSArray() const {
  if (unlikely(!cell_)) return false;
  LEPUSValue temp_val = WrapJSValue();
  return LEPUS_IsArray(cell_->ctx_, temp_val) ||
         (LEPUS_GetLepusRefTag(temp_val) == Value_Array);
}

bool Value::IsJSTable() const {
  if (unlikely(!cell_)) return false;
  LEPUSValue temp_val = WrapJSValue();
  return LEPUS_IsObject(temp_val) ||
         (LEPUS_GetLepusRefTag(temp_val) == Value_Table);
}

bool Value::IsJSInteger() const {
  if (!IsJSValue()) return false;
  LEPUSValue temp_val = WrapJSValue();
  if (LEPUS_IsInteger(temp_val)) return true;
  if (LEPUS_IsNumber(temp_val)) {
    double val;
    LEPUS_ToFloat64(cell_->ctx_, &val, temp_val);
    if (StringConvertHelper::IsInt64Double(val)) {
      return true;
    }
  }
  return false;
}

bool Value::IsJSFunction() const {
  if (!IsJSValue()) return false;
  return LEPUS_IsFunction(cell_->ctx_, WrapJSValue());
}

int Value::GetJSLength() const {
  if (!IsJSValue()) return 0;
  LEPUSValue temp_val = WrapJSValue();
  return LEPUS_GetLength(cell_->ctx_, temp_val);
}

bool Value::IsJSFalse() const {
  if (!IsJSValue()) return false;

  return IsJSUndefined() || IsJsNull() ||
         (LEPUS_VALUE_IS_UNINITIALIZED(WrapJSValue())) ||
         (IsJSBool() && !LEPUSBool()) || (IsJSInteger() && JSInteger() == 0) ||
         (IsJSString() && GetJSLength() == 0);
}

int64_t Value::JSInteger() const {
  if (!IsJSValue()) return false;
  LEPUSValue temp_val = WrapJSValue();
  if (LEPUS_VALUE_GET_TAG(temp_val) == LEPUS_TAG_INT) {
    return LEPUS_VALUE_GET_INT(temp_val);
  }
  if (LEPUS_IsInteger(temp_val)) {
    int64_t val;
    LEPUS_ToInt64(cell_->ctx_, &val, temp_val);
    return val;
  } else {
    DCHECK(LEPUS_IsNumber(temp_val));
    double val;
    LEPUS_ToFloat64(cell_->ctx_, &val, temp_val);
    return static_cast<int64_t>(val);
  }
}

StringImpl* Value::GetJSString() const {
  if (!IsJSString()) return nullptr;
  LEPUSValue temp_val = WrapJSValue();
  void* cache = LEPUS_GetStringCache(temp_val);
  if (cache) {
    return reinterpret_cast<StringImpl*>(cache);
  } else {
    StringImpl* ptr = StringImpl::RawCreate(ToString());
    LEPUS_SetStringCache(cell_->ctx_, temp_val, ptr);
    ptr->Release();
    return ptr;
  }
}

std::string Value::ToString() const {
  if (!IsJSValue()) {
    // judge whether it is a lepus string type
    if (IsString()) {
      return String()->str();
    }
    // it is not string then return ""
    return "";
  }
  const char* chr;
  LEPUSValue temp_val = WrapJSValue();
  if (IsJSUndefined()) {
    return "";
  }
  DCHECK(cell_);
  LEPUSContext* ctx_ = cell_->ctx_;
  if (!IsJSString()) {
    LEPUSValue val = LEPUS_ToString(ctx_, temp_val);
    chr = LEPUS_ToCString(ctx_, val);
    LEPUS_FreeValue(ctx_, val);
  } else {
    chr = LEPUS_ToCString(ctx_, temp_val);
  }
  std::string str(chr);
  LEPUS_FreeCString(ctx_, chr);
  return str;
}

void Value::IteratorJSValue(const LepusValueIterator& callback) const {
  if (LEPUSValueHelper::IsJsObject(WrapJSValue())) {
    JSValueIteratorCallback callback_wrap =
        [&callback](LEPUSContext* ctx, LEPUSValue& key, LEPUSValue& value) {
          lepus::Value keyWrap(ctx, key);
          lepus::Value valueWrap(ctx, value);
          callback(keyWrap, valueWrap);
        };
    LEPUSValueHelper::IteratorJsValue(cell_->ctx_, WrapJSValue(),
                                      &callback_wrap);
  }
}

bool Value::IsJSValue() const {
#if defined(__aarch64__) && !defined(OS_WIN)
  return type_ == Value_PrimJsValue;
#else
  return cell_ && (type_ > Value_TypeCount || type_ < 0);
#endif
}

double Value::LEPUSNumber() const {
  DCHECK(IsJSNumber());
  if (unlikely(!cell_)) return 0;
  LEPUSValue temp_val = WrapJSValue();
  double val;
  LEPUS_ToFloat64(cell_->ctx_, &val, temp_val);
  return val;
}
// #endif
}  // namespace lepus
}  // namespace lynx
