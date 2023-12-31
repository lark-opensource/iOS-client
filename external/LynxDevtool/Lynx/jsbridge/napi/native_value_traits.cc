// Copyright 2021 The Lynx Authors. All rights reserved.

#include "jsbridge/napi/native_value_traits.h"

#include <cmath>

#include "jsbridge/napi/array_buffer_view.h"

namespace lynx {
namespace piper {

void InvalidType(const Napi::Env &env, int32_t index, const char *expecting) {
  char pretty_name[12];
  std::snprintf(pretty_name, 12, "argument %d", index);
  ExceptionMessage::InvalidType(env, pretty_name, expecting);
}

Napi::Value GetArgument(const Napi::CallbackInfo &info, int32_t index) {
  return info[index];
}

// boolean
Napi::Boolean NativeValueTraits<IDLBoolean>::NativeValue(Napi::Value value,
                                                         int32_t index) {
  return value.ToBoolean();
}

Napi::Boolean NativeValueTraits<IDLBoolean>::NativeValue(
    const Napi::CallbackInfo &info, int32_t index) {
  Napi::Value value = GetArgument(info, index);
  return value.ToBoolean();
}

// number
Napi::Number NativeValueTraits<IDLNumber>::NativeValue(Napi::Value value,
                                                       int32_t index) {
  if (value.IsNumber()) {
    return value.As<Napi::Number>();
  }
  return value.ToNumber();
}

Napi::Number NativeValueTraits<IDLNumber>::NativeValue(
    const Napi::CallbackInfo &info, int32_t index) {
  Napi::Value value = GetArgument(info, index);
  return NativeValue(value, index);
}

// unrestricted float
float NativeValueTraits<IDLUnrestrictedFloat>::NativeValue(Napi::Value value,
                                                           int32_t index) {
  Napi::Number value_ = NativeValueTraits<IDLNumber>::NativeValue(value);
  return value_.FloatValue();
}

float NativeValueTraits<IDLUnrestrictedFloat>::NativeValue(
    const Napi::CallbackInfo &info, int32_t index) {
  Napi::Value value = GetArgument(info, index);
  return NativeValue(value, index);
}

// restricted float
float NativeValueTraits<IDLFloat>::NativeValue(Napi::Value value,
                                               int32_t index) {
  Napi::Number value_ = NativeValueTraits<IDLNumber>::NativeValue(value);
  float result = value_.FloatValue();
  if (std::isnan(result) || std::isinf(result)) {
    InvalidType(value.Env(), index, "restricted float");
    return 0;
  }
  return result;
}
float NativeValueTraits<IDLFloat>::NativeValue(const Napi::CallbackInfo &info,
                                               int32_t index) {
  Napi::Value value = GetArgument(info, index);
  return NativeValue(value, index);
}
// unrestricted double
double NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(Napi::Value value,
                                                             int32_t index) {
  Napi::Number value_ = NativeValueTraits<IDLNumber>::NativeValue(value);
  return value_.DoubleValue();
}

double NativeValueTraits<IDLUnrestrictedDouble>::NativeValue(
    const Napi::CallbackInfo &info, int32_t index) {
  Napi::Value value = GetArgument(info, index);
  return NativeValue(value, index);
}

// restricted double
double NativeValueTraits<IDLDouble>::NativeValue(Napi::Value value,
                                                 int32_t index) {
  Napi::Number value_ = NativeValueTraits<IDLNumber>::NativeValue(value);
  double result = value_.DoubleValue();
  if (std::isnan(result) || std::isinf(result)) {
    InvalidType(value.Env(), index, "Restricted Double");
    return 0;
  }
  return result;
}

double NativeValueTraits<IDLDouble>::NativeValue(const Napi::CallbackInfo &info,
                                                 int32_t index) {
  Napi::Value value = GetArgument(info, index);
  return NativeValue(value, index);
}

// string
Napi::String NativeValueTraits<IDLString>::NativeValue(Napi::Value value,
                                                       int32_t index) {
  if (value.IsString()) {
    return value.As<Napi::String>();
  }
  return value.ToString();
}

Napi::String NativeValueTraits<IDLString>::NativeValue(
    const Napi::CallbackInfo &info, int32_t index) {
  Napi::Value value = GetArgument(info, index);
  return NativeValue(value, index);
}

// object
Napi::Object NativeValueTraits<IDLObject>::NativeValue(Napi::Value value,
                                                       int32_t index) {
  if (value.IsObject()) {
    return value.As<Napi::Object>();
  } else {
    InvalidType(value.Env(), index, "Object");
    return Napi::Object();
  }
}

Napi::Object NativeValueTraits<IDLObject>::NativeValue(
    const Napi::CallbackInfo &info, int32_t index) {
  Napi::Value value = GetArgument(info, index);
  return NativeValue(value, index);
}

// typedarray
#define TypedArrayNativeValueTraitsImpl(CLAZZ, NAPI_TYPE, C_TYPE)           \
  Napi::CLAZZ NativeValueTraits<IDL##CLAZZ>::NativeValue(Napi::Value value, \
                                                         int32_t index) {   \
    if (value.Is##CLAZZ()) {                                                \
      return value.As<Napi::CLAZZ>();                                       \
    } else {                                                                \
      InvalidType(value.Env(), index, #CLAZZ);                              \
      return Napi::CLAZZ();                                                 \
    }                                                                       \
  }                                                                         \
                                                                            \
  Napi::CLAZZ NativeValueTraits<IDL##CLAZZ>::NativeValue(                   \
      const Napi::CallbackInfo &info, int32_t index) {                      \
    Napi::Value value = GetArgument(info, index);                           \
    return NativeValue(value, index);                                       \
  }

NAPI_FOR_EACH_TYPED_ARRAY(TypedArrayNativeValueTraitsImpl)
#undef TypedArrayNativeValueTraitsImpl

// arraybuffer
Napi::ArrayBuffer NativeValueTraits<IDLArrayBuffer>::NativeValue(
    Napi::Value value, int32_t index) {
  if (value.IsArrayBuffer()) {
    return value.As<Napi::ArrayBuffer>();
  } else {
    InvalidType(value.Env(), index, "ArrayBuffer");
    return Napi::ArrayBuffer();
  }
}

Napi::ArrayBuffer NativeValueTraits<IDLArrayBuffer>::NativeValue(
    const Napi::CallbackInfo &info, int32_t index) {
  Napi::Value value = GetArgument(info, index);
  return NativeValue(value, index);
}

// arraybufferview
ArrayBufferView NativeValueTraits<IDLArrayBufferView>::NativeValue(
    Napi::Value value, int32_t index) {
  if (value.IsTypedArray() || value.IsDataView()) {
    if (value.IsTypedArray()) {
      return ArrayBufferView::From(value.As<Napi::TypedArray>());
    } else {
      return ArrayBufferView::From(value.As<Napi::DataView>());
    }
  } else {
    InvalidType(value.Env(), index, "ArrayBufferView");
    return ArrayBufferView();
  }
}

ArrayBufferView NativeValueTraits<IDLArrayBufferView>::NativeValue(
    const Napi::CallbackInfo &info, int32_t index) {
  Napi::Value value = GetArgument(info, index);
  return NativeValue(value, index);
}

}  // namespace piper
}  // namespace lynx
