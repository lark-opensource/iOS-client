// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_VALUE_H_
#define LYNX_LEPUS_VALUE_H_

#include <cstring>
#include <functional>
#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/closure.h"
#include "base/ref_counted.h"
#include "config/config.h"
#include "lepus/byte_array.h"
#include "lepus/js_object.h"
#include "lepus/lepus_date.h"
#include "lepus/lepus_string.h"
#include "lepus/marco.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace lepus {

using JSValueIteratorCallback =
    base::MoveOnlyClosure<void, LEPUSContext*, LEPUSValue&, LEPUSValue&>;

using LepusValueIterator =
    base::MoveOnlyClosure<void, const lepus::Value&, const lepus::Value&>;

typedef void* point_t;
#define NormalNumberType(V) \
  V(Double, double)         \
  V(Int32, int32_t)         \
  V(UInt32, uint32_t)       \
  V(UInt64, uint64_t)

#define NumberType(V) NormalNumberType(V) V(Int64, int64_t)

#define ReferenceType(V)      \
  V(String, string)           \
  V(Table, table)             \
  V(Array, array)             \
  V(Closure, closure)         \
  V(LEPUSObject, lepusobject) \
  V(ByteArray, bytearray)     \
  V(Date, date)

/*
LepusNG will add more types:
  1. JSValue
    It include:  type_ > Value_TypeCount || type_ < 0
    It make lepus::Value can hold quickjs JSValue type
*/
enum ValueType {
  Value_Nil,
  Value_Double,
  Value_Bool,
  Value_String,
  Value_Table,
  Value_Array,
  Value_Closure,
  Value_CFunction,
  Value_CPointer,
  Value_Int32,
  Value_Int64,
  Value_UInt32,
  Value_UInt64,
  Value_NaN,
  Value_CDate,
  Value_RegExp,
  Value_JSObject,
  Value_Undefined,
  Value_ByteArray,
  Value_RefCounted,
  // Value_TypeCount is used for encoding jsvalue tag,
  // Adding a new Value_type needs to be inserted before 'Value_TypeCount'
  Value_PrimJsValue,
  Value_TypeCount,
};
class Value;
class Context;
class CArray;
class Dictionary;
class Closure;
class RegExp;
class LEPUSValueHelper;
class ByteArray;
class QuickContext;

class ContextCell {
 public:
  ContextCell(lepus::QuickContext* qctx, LEPUSContext* ctx, LEPUSRuntime* rt)
      : qctx_(qctx), ctx_(ctx), rt_(rt){};
  lepus::QuickContext* qctx_;
  LEPUSContext* ctx_;
  LEPUSRuntime* rt_;
};

class CellManager {
 public:
  CellManager() : cells_(){};
  ~CellManager();
  ContextCell* AddCell(lepus::QuickContext* qctx);

 private:
  std::vector<ContextCell*> cells_;
};

typedef Value (*CFunction)(Context*);

class BASE_EXPORT_FOR_DEVTOOL Value {
 private:
  union {
    Dictionary* val_table_;
    lepus::StringImpl* val_str_;
    lepus::LEPUSObject* val_jsobject_;
    lepus::ByteArray* val_bytearray_;
    base::RefCountedThreadSafeStorage* val_ref_counted_;
    CArray* val_carray_;
#if !ENABLE_JUST_LEPUSNG
    lepus::CDate* val_date_;
    lepus::RegExp* val_regexp_;
    Closure* val_closure_;
#endif

#define NumberStorage(name, type) type val_##type##_;
    NumberType(NumberStorage)
#undef NumberStorage

        bool val_bool_;
    void* val_ptr_ = nullptr;
    bool val_nan_;
  };

  ContextCell* cell_ = nullptr;
  union {
    ValueType type_ = Value_Nil;
    int32_t tag_;
  };

#if !defined(__aarch64__) || defined(OS_WIN)
  static constexpr int LEPUS_TAG_ADJUST = Value_TypeCount - LEPUS_TAG_FIRST + 1;

#define EncodeJSTag(t) ((t) + LEPUS_TAG_ADJUST)
#define DecodeJSTag(t) ((t)-LEPUS_TAG_ADJUST)
#endif

 public:
  explicit Value() = default;
  BASE_EXPORT_FOR_DEVTOOL Value(const Value& value);
  BASE_EXPORT_FOR_DEVTOOL explicit Value(
      lynx::base::scoped_refptr<lepus::StringImpl> data);
  BASE_EXPORT_FOR_DEVTOOL explicit Value(
      lynx::base::scoped_refptr<Dictionary> data);
  BASE_EXPORT_FOR_DEVTOOL explicit Value(base::scoped_refptr<CArray> data);
  explicit Value(lynx::base::scoped_refptr<lepus::LEPUSObject> data);
  explicit Value(lynx::base::scoped_refptr<lepus::ByteArray> data);
  explicit Value(
      const base::scoped_refptr<base::RefCountedThreadSafeStorage>& data);
  BASE_EXPORT_FOR_DEVTOOL explicit Value(bool val);
  BASE_EXPORT_FOR_DEVTOOL explicit Value(const char* val);
  BASE_EXPORT_FOR_DEVTOOL explicit Value(std::string str);
  explicit Value(void* data);
  explicit Value(CFunction val);
  explicit Value(bool for_nan, bool val);
  Value(Value&& value) noexcept;

#if !ENABLE_JUST_LEPUSNG
  explicit Value(lynx::base::scoped_refptr<Closure> data);
  explicit Value(lynx::base::scoped_refptr<CDate> data);
  explicit Value(base::scoped_refptr<RegExp> data);
  inline bool IsCDate() const { return type_ == Value_CDate; }
  inline bool IsRegExp() const { return type_ == Value_RegExp; }

  BASE_EXPORT_FOR_DEVTOOL lynx::base::scoped_refptr<lepus::Closure> GetClosure()
      const;
  BASE_EXPORT_FOR_DEVTOOL lynx::base::scoped_refptr<lepus::CDate> Date() const;
  BASE_EXPORT_FOR_DEVTOOL lynx::base::scoped_refptr<lepus::RegExp> RegExp()
      const;

  void SetClosure(const lynx::base::scoped_refptr<lepus::Closure>&);
  void SetRegExp(const lynx::base::scoped_refptr<lepus::RegExp>&);
  void SetDate(const lynx::base::scoped_refptr<lepus::CDate>&);
#endif

  inline void DupValue() const;
  BASE_EXPORT_FOR_DEVTOOL void FreeValue();

  inline bool IsClosure() const { return type_ == Value_Closure; }
  inline bool IsCallable() const { return IsClosure() || IsJSFunction(); }

// add for compile
#define NumberConstructor(name, type) \
  BASE_EXPORT_FOR_DEVTOOL explicit Value(type data);

  NumberType(NumberConstructor)

      BASE_EXPORT_FOR_DEVTOOL explicit Value(uint8_t data);
#undef NumberConstructor

#define SetNumberDefine(name, type) \
  void SetNumber(type value) {      \
    FreeValue();                    \
    val_##type##_ = value;          \
    type_ = Value_##name;           \
  }

  NumberType(SetNumberDefine)
#undef SetNumberDefine

      inline ValueType Type() const {
    return type_;
  }

  static inline Value MakeInt(int value) { return Value((int64_t)value); }

  static Value Clone(const Value& src, bool clone_as_jsvalue = false);

  static Value ShallowCopy(const Value& src, bool clone_as_jsvalue = false);

  inline bool IsReference() const {
    return (type_ > Value_Bool && type_ < Value_CFunction) ||
           ((type_ >= Value_CDate && type_ <= Value_RefCounted &&
             type_ != Value_Undefined));
  }
  inline void* Ptr() const { return val_ptr_; }

  inline bool IsBool() const { return type_ == Value_Bool || IsJSBool(); }

  inline bool IsString() const { return type_ == Value_String || IsJSString(); }

  inline bool IsInt64() const { return type_ == Value_Int64 || IsJSInteger(); }

  inline bool IsNumber() const {
    return (type_ == Value_Double) ||
           (type_ >= Value_Int32 && type_ <= Value_UInt64) || IsJSNumber();
  }

  inline bool IsDouble() const { return type_ == Value_Double; }

  inline bool IsArray() const { return type_ == Value_Array; }

  inline bool IsTable() const { return type_ == Value_Table; }

  inline bool IsObject() const {
    if (IsTable()) return true;
    if (IsJSValue()) return IsJSTable();
    return false;
  }

  inline bool IsArrayOrJSArray() const {
    if (IsArray()) return true;
    if (IsJSValue()) return IsJSArray();
    return false;
  }

  inline bool IsCPointer() const {
    return type_ == Value_CPointer || IsJSCPointer();
  }

  inline bool IsRefCounted() const { return type_ == Value_RefCounted; }

  inline bool IsInt32() const { return type_ == Value_Int32; }
  inline bool IsUInt32() const { return type_ == Value_UInt32; }
  inline bool IsUInt64() const { return type_ == Value_UInt64; }
  inline bool IsNil() const { return (type_ == Value_Nil) || IsJsNull(); }
  inline bool IsUndefined() const {
    return type_ == Value_Undefined || IsJSUndefined();
  }
  inline bool IsCFunction() const { return type_ == Value_CFunction; }
  inline bool IsJSObject() const { return type_ == Value_JSObject; }
  inline bool IsByteArray() const { return type_ == Value_ByteArray; }
  inline bool IsNaN() const { return type_ == Value_NaN; }

  inline bool Bool() const {
    if (type_ != Value_Bool) return !IsFalse();
    return val_bool_;
  }
  inline bool NaN() const { return type_ == Value_NaN && val_nan_; }

  BASE_EXPORT_FOR_DEVTOOL double Number() const;

  inline Value& operator=(const Value& value);
  inline Value& operator=(Value&& value) noexcept;

#define NumberValue(name, type) BASE_EXPORT_FOR_DEVTOOL type name() const;
  NumberType(NumberValue)
#undef NumberValue

      BASE_EXPORT_FOR_DEVTOOL
      lynx::base::scoped_refptr<lepus::StringImpl> String() const;
  BASE_EXPORT_FOR_DEVTOOL lynx::base::scoped_refptr<lepus::Dictionary> Table()
      const;
  BASE_EXPORT_FOR_DEVTOOL lynx::base::scoped_refptr<lepus::CArray> Array()
      const;
  lynx::base::scoped_refptr<lepus::LEPUSObject> LEPUSObject() const;
  lynx::base::scoped_refptr<lepus::ByteArray> ByteArray() const;

  inline CFunction Function() const;
  void* CPoint() const;
  base::scoped_refptr<base::RefCountedThreadSafeStorage> RefCounted() const;

  void SetBool(bool);
  void SetString(const lynx::base::scoped_refptr<lepus::StringImpl>&);

  void SetTable(const lynx::base::scoped_refptr<lepus::Dictionary>&);
  void SetArray(const lynx::base::scoped_refptr<lepus::CArray>&);

  void SetJSObject(const lynx::base::scoped_refptr<lepus::LEPUSObject>&);
  void SetByteArray(const lynx::base::scoped_refptr<lepus::ByteArray>&);

  bool SetProperty(uint32_t idx, const Value& val);
  BASE_EXPORT_FOR_DEVTOOL bool SetProperty(const lepus::String& key,
                                           const Value& val);

  Value GetProperty(uint32_t idx) const;
  BASE_EXPORT_FOR_DEVTOOL Value GetProperty(const lepus::String& key) const;

  int GetLength() const;
  bool Contains(const lepus::String& key) const;
  static void MergeValue(lepus::Value& target, const lepus::Value& update);
  static bool UpdateValueByPath(lepus::Value& target,
                                const lepus::Value& update,
                                std::vector<std::string>& path);

  static lepus::Value CreateObject(Context* ctx = nullptr);
  bool MarkConst() const;

  Value(LEPUSContext* ctx, const LEPUSValue& val);
  Value(LEPUSContext* ctx, LEPUSValue&& val);
  BASE_EXPORT_FOR_DEVTOOL bool IsJSValue() const;

  LEPUSContext* context() const { return cell_ ? cell_->ctx_ : nullptr; }

  LEPUSValue ToJSValue(LEPUSContext* ctx, bool deep_convert = false) const;
  Value ToLepusValue() const;

  inline LEPUSValue WrapJSValue() const {
    if (!IsJSValue()) return LEPUS_UNDEFINED;
#if defined(__aarch64__) && !defined(OS_WIN)
    return (LEPUSValue){.as_int64 = val_int64_t_};
#else
    return LEPUS_MKPTR(DecodeJSTag(tag_), val_ptr_);
#endif
  }

  inline bool IsJSCPointer() const {
    return IsJSValue() && LEPUS_VALUE_IS_LEPUS_CPOINTER(WrapJSValue());
  }

  inline void* LEPUSCPointer() const {
    DCHECK(IsJSCPointer());
    return LEPUS_VALUE_GET_PTR(WrapJSValue());
  }

  bool IsJSArray() const;
  BASE_EXPORT_FOR_DEVTOOL bool IsJSTable() const;

  inline bool IsJSBool() const {
    return IsJSValue() && LEPUS_VALUE_IS_BOOL(WrapJSValue());
  }
  inline bool LEPUSBool() const {
    if (!IsJSBool()) return false;
    return LEPUS_VALUE_GET_BOOL(WrapJSValue());
  }
  inline bool IsJSString() const {
    return IsJSValue() && LEPUS_IsString(WrapJSValue());
  }

  inline bool IsJSUndefined() const {
    return IsJSValue() && LEPUS_VALUE_IS_UNDEFINED(WrapJSValue());
  }

  inline bool IsJSNumber() const {
    return IsJSValue() &&
           (LEPUS_IsNumber(WrapJSValue()) || LEPUS_IsInteger(WrapJSValue()));
  }

  inline bool IsJsNull() const {
    return IsJSValue() && LEPUS_VALUE_IS_NULL(WrapJSValue());
  }

  double LEPUSNumber() const;
  BASE_EXPORT_FOR_DEVTOOL bool IsJSInteger() const;
  bool IsJSFunction() const;
  BASE_EXPORT_FOR_DEVTOOL int GetJSLength() const;
  BASE_EXPORT_FOR_DEVTOOL bool IsJSFalse() const;
  BASE_EXPORT_FOR_DEVTOOL int64_t JSInteger() const;
  StringImpl* GetJSString() const;
  std::string ToString() const;
  // #endif

  void SetCPoint(void*);
  void SetCFunction(CFunction);
  void SetNan(bool);
  BASE_EXPORT_FOR_DEVTOOL ~Value();

  bool IsTrue() const { return !IsFalse(); }

  bool IsFalse() const {
    return type_ == Value_Nil || type_ == Value_NaN ||
           type_ == Value_Undefined || (type_ == Value_Bool && !Bool()) ||
           (IsNumber() && Number() == 0) ||
           (type_ == Value_String && strcmp(String()->c_str(), "") == 0) ||
           IsJSFalse();
  }
  inline bool IsEmpty() const {
    return (type_ == Value_Nil) || (type_ == Value_Undefined) ||
           IsJSUndefined() || IsJsNull();
  }
  inline void SetNil();
  bool IsEqual(const Value& value) const;
  inline void SetUndefined();
  BASE_EXPORT_FOR_DEVTOOL friend bool operator==(const Value& left,
                                                 const Value& right);

  BASE_EXPORT_FOR_DEVTOOL friend bool operator!=(const Value& left,
                                                 const Value& right) {
    return !(left == right);
  }

  friend Value operator+(const Value& left, const Value& right) {
    Value value;
    if (left.IsNumber() && right.IsNumber()) {
      if (left.IsInt64() && right.IsInt64()) {
        value.SetNumber(left.Int64() + right.Int64());
      } else {
        value.SetNumber(left.Number() + right.Number());
      }
    }
    return value;
  }

  friend Value operator-(const Value& left, const Value& right) {
    Value value;
    if (left.IsNumber() && right.IsNumber()) {
      if (left.IsInt64() && right.IsInt64()) {
        value.SetNumber(left.Int64() - right.Int64());
      } else {
        value.SetNumber(left.Number() - right.Number());
      }
    }
    return value;
  }

  friend Value operator*(const Value& left, const Value& right) {
    Value value;
    if (left.IsNumber() && right.IsNumber()) {
      if (left.IsInt64() && right.IsInt64()) {
        value.SetNumber(left.Int64() * right.Int64());
      } else {
        value.SetNumber(left.Number() * right.Number());
      }
    }
    return value;
  }

  friend Value operator/(const Value& left, const Value& right) {
    Value value;
    if (left.IsNumber() && right.IsNumber()) {
      if (left.IsInt64() && right.IsInt64()) {
        value.SetNumber(left.Int64() / right.Int64());
      } else {
        value.SetNumber(left.Number() / right.Number());
      }
    }
    return value;
  }

  friend Value operator%(const Value& left, const Value& right) {
    Value value;
    if (left.IsNumber() && right.IsNumber()) {
      value.SetNumber((int64_t)(left.Number()) % ((int64_t)right.Number()));
    }
    return value;
  }

  Value& operator+=(const Value& value) {
    if (IsNumber() && value.IsNumber()) {
      if (IsInt64() && value.IsInt64()) {
        SetNumber(Int64() + value.Int64());
      } else {
        SetNumber(Number() + value.Number());
      }
    }
    return *this;
  }

  Value& operator-=(const Value& value) {
    if (IsNumber() && value.IsNumber()) {
      if (IsInt64() && value.IsInt64()) {
        SetNumber(Int64() - value.Int64());
      } else {
        SetNumber(Number() - value.Number());
      }
    }
    return *this;
  }

  Value& operator*=(const Value& value) {
    if (IsNumber() && value.IsNumber()) {
      if (IsInt64() && value.IsInt64()) {
        SetNumber(Int64() * value.Int64());
      } else {
        SetNumber(Number() * value.Number());
      }
    }
    return *this;
  }

  Value& operator/=(const Value& value) {
    if (IsNumber() && value.IsNumber()) {
      if (IsInt64() && value.IsInt64()) {
        SetNumber(Int64() / value.Int64());
      } else {
        SetNumber(Number() / value.Number());
      }
    }
    return *this;
  }

  Value& operator%=(const Value& value) {
    if (IsNumber() && value.IsNumber()) {
      SetNumber((int64_t)Number() % (int64_t)value.Number());
    }
    return *this;
  }

  void Print() const;
  void PrintValue(std::ostream& output, bool ignore_other = false,
                  bool pretty = false) const;
  friend std::ostream& operator<<(std::ostream& output, const lepus::Value& v) {
    v.PrintValue(output);
    return output;
  }

  void IteratorJSValue(const LepusValueIterator& callback) const;
  friend lepus::LEPUSValueHelper;

 private:
  BASE_EXPORT_FOR_DEVTOOL void Copy(const Value& value);

  void ConstructValueFromLepusRef(LEPUSContext* ctx, const LEPUSValue& val);
};
}  // namespace lepus
}  // namespace lynx
typedef lynx::lepus::Value lepus_value;
#endif  // LYNX_LEPUS_VALUE_H_
