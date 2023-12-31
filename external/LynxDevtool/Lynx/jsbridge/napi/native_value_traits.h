// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_NATIVE_VALUE_TRAITS_H_
#define LYNX_JSBRIDGE_NAPI_NATIVE_VALUE_TRAITS_H_

#include <memory>
#include <string>
#include <vector>

#include "base/base_export.h"
#include "jsbridge/napi/base.h"
#include "jsbridge/napi/exception_message.h"
#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace piper {

class ArrayBufferView;

#define IDLTypedArrayDecl(CLAZZ, NAPI_TYPE, C_TYPE) \
  struct IDL##CLAZZ {};

struct IDLBoolean {};
struct IDLNumber {};
struct IDLString {};
struct IDLUnrestrictedFloat {};
struct IDLFloat {};
struct IDLUnrestrictedDouble {};
struct IDLDouble {};
struct IDLObject {};
struct IDLTypedArray {};
struct IDLArrayBuffer {};
struct IDLArrayBufferView {};
NAPI_FOR_EACH_TYPED_ARRAY(IDLTypedArrayDecl)
#undef IDLTypedArrayDecl

BASE_EXPORT void InvalidType(const Napi::Env& env, int32_t index,
                             const char* expecting);

BASE_EXPORT Napi::Value GetArgument(const Napi::CallbackInfo& info,
                                    int32_t index);

template <typename T, typename SFINAEHelper = void>
struct NativeValueTraits {};

// boolean
template <>
struct NativeValueTraits<IDLBoolean> {
  BASE_EXPORT static Napi::Boolean NativeValue(Napi::Value value,
                                               int32_t index = 0);
  BASE_EXPORT static Napi::Boolean NativeValue(const Napi::CallbackInfo& info,
                                               int32_t index = 0);
};

// number
template <>
struct NativeValueTraits<IDLNumber> {
  BASE_EXPORT static Napi::Number NativeValue(Napi::Value value,
                                              int32_t index = 0);
  BASE_EXPORT static Napi::Number NativeValue(const Napi::CallbackInfo& info,
                                              int32_t index = 0);
};

// unrestricted float
template <>
struct NativeValueTraits<IDLUnrestrictedFloat> {
  BASE_EXPORT static float NativeValue(Napi::Value value, int32_t index = 0);
  BASE_EXPORT static float NativeValue(const Napi::CallbackInfo& info,
                                       int32_t index = 0);
};

// restricted float
template <>
struct NativeValueTraits<IDLFloat> {
  BASE_EXPORT static float NativeValue(Napi::Value value, int32_t index = 0);
  BASE_EXPORT static float NativeValue(const Napi::CallbackInfo& info,
                                       int32_t index = 0);
};

// unrestricted double
template <>
struct NativeValueTraits<IDLUnrestrictedDouble> {
  BASE_EXPORT static double NativeValue(Napi::Value value, int32_t index = 0);
  BASE_EXPORT static double NativeValue(const Napi::CallbackInfo& info,
                                        int32_t index = 0);
};

// restricted double
template <>
struct NativeValueTraits<IDLDouble> {
  BASE_EXPORT static double NativeValue(Napi::Value value, int32_t index = 0);
  BASE_EXPORT static double NativeValue(const Napi::CallbackInfo& info,
                                        int32_t index = 0);
};

// string
template <>
struct NativeValueTraits<IDLString> {
  BASE_EXPORT static Napi::String NativeValue(Napi::Value value,
                                              int32_t index = 0);
  BASE_EXPORT static Napi::String NativeValue(const Napi::CallbackInfo& info,
                                              int32_t index = 0);
};

// callback function
template <typename T>
struct IDLFunction {};

template <typename T>
struct NativeValueTraits<IDLFunction<T>> {
  BASE_EXPORT static std::unique_ptr<T> NativeValue(Napi::Value value,
                                                    int32_t index = 0) {
    if (value.IsFunction()) {
      return std::make_unique<T>(value.As<Napi::Function>());
    } else {
      InvalidType(value.Env(), index, "Callback Function");
      return nullptr;
    }
  }

  BASE_EXPORT static std::unique_ptr<T> NativeValue(
      const Napi::CallbackInfo& info, int32_t index = 0) {
    Napi::Value value = GetArgument(info, index);
    return NativeValue(value, index);
  }
};

// object
template <>
struct NativeValueTraits<IDLObject> {
  BASE_EXPORT static Napi::Object NativeValue(Napi::Value value,
                                              int32_t index = 0);
  BASE_EXPORT static Napi::Object NativeValue(const Napi::CallbackInfo& info,
                                              int32_t index = 0);
};

// arraybuffer
template <>
struct NativeValueTraits<IDLArrayBuffer> {
  BASE_EXPORT static Napi::ArrayBuffer NativeValue(Napi::Value value,
                                                   int32_t index = 0);
  BASE_EXPORT static Napi::ArrayBuffer NativeValue(
      const Napi::CallbackInfo& info, int32_t index = 0);
};

// arraybufferview
template <>
struct NativeValueTraits<IDLArrayBufferView> {
  BASE_EXPORT static ArrayBufferView NativeValue(Napi::Value value,
                                                 int32_t index = 0);
  BASE_EXPORT static ArrayBufferView NativeValue(const Napi::CallbackInfo& info,
                                                 int32_t index = 0);
};

// typedarray
#define TypedArrayNativeValueTraitsDecl(CLAZZ, NAPI_TYPE, C_TYPE)              \
  template <>                                                                  \
  struct NativeValueTraits<IDL##CLAZZ> {                                       \
    BASE_EXPORT static Napi::CLAZZ NativeValue(Napi::Value value,              \
                                               int32_t index = 0);             \
    BASE_EXPORT static Napi::CLAZZ NativeValue(const Napi::CallbackInfo& info, \
                                               int32_t index = 0);             \
  };

NAPI_FOR_EACH_TYPED_ARRAY(TypedArrayNativeValueTraitsDecl)
#undef TypedArrayNativeValueTraitsDecl

// dictionary
template <typename T>
struct IDLDictionary {};

template <typename T>
struct NativeValueTraits<IDLDictionary<T>> {
  typedef decltype(T::ToImpl(Napi::Value())) ImplType;
  BASE_EXPORT static ImplType NativeValue(Napi::Value value,
                                          int32_t index = 0) {
    ImplType result = T::ToImpl(value);
    if (value.Env().IsExceptionPending()) {
      return nullptr;
    }
    return result;
  }
  BASE_EXPORT static ImplType NativeValue(const Napi::CallbackInfo& info,
                                          int32_t index = 0) {
    Napi::Value value = GetArgument(info, index);
    return NativeValue(value, index);
  }
};

// wrapped object
template <typename T>
struct NativeValueTraits<
    T, typename std::enable_if_t<std::is_base_of<BridgeBase, T>::value>> {
  typedef decltype(Napi::ObjectWrap<T>::Unwrap(Napi::Object())
                       ->ToImplUnsafe()) ImplType;
  BASE_EXPORT static ImplType NativeValue(Napi::Value value,
                                          int32_t index = 0) {
    if (value.IsObject() &&
        value.As<Napi::Object>().InstanceOf(T::Constructor(value.Env()))) {
      return Napi::ObjectWrap<T>::Unwrap(value.As<Napi::Object>())
          ->ToImplUnsafe();
    } else {
      InvalidType(value.Env(), index, T::InterfaceName());
      return nullptr;
    }
  }
  BASE_EXPORT static ImplType NativeValue(const Napi::CallbackInfo& info,
                                          int32_t index = 0) {
    Napi::Value value = GetArgument(info, index);
    return NativeValue(value, index);
  }
};

// sequence
template <typename T>
struct IDLSequence {};

template <typename T>
struct NativeValueTraits<IDLSequence<T>> {
  typedef decltype(NativeValueTraits<T>::NativeValue(Napi::Value(),
                                                     int32_t())) ElementType;
  static std::vector<ElementType> NativeValue(Napi::Value value,
                                              int32_t index = 0) {
    if (value.IsArray()) {
      std::vector<ElementType> dst;
      auto array = value.As<Napi::Array>();
      auto len = array.Length();
      dst.resize(len);
      for (uint32_t i = 0; i < len; i++) {
        Napi::Value val = array[i];
        dst[i] = NativeValueTraits<T>::NativeValue(val, index);
        if (val.Env().IsExceptionPending()) {
          return std::vector<ElementType>();
        }
      }
      return dst;
    } else {
      InvalidType(value.Env(), index, "Array");
      return std::vector<ElementType>();
    }
  }
  BASE_EXPORT static std::vector<ElementType> NativeValue(
      const Napi::CallbackInfo& info, int32_t index = 0) {
    Napi::Value value = GetArgument(info, index);
    return NativeValue(value, index);
  }
};

// nullable
template <typename T>
struct IDLNullable {
  typedef decltype(NativeValueTraits<T>::NativeValue(Napi::Value(),
                                                     int32_t())) ImplType;
};

// nullable sequence, dictionary, typedarray, arraybuffer, arraybufferview,
// object, string, function, number
template <typename T>
struct NativeValueTraits<IDLNullable<T>,
                         typename std::enable_if_t<!std::is_pointer<
                             typename IDLNullable<T>::ImplType>::value>> {
  using ImplType =
      typename std::conditional<std::is_same<T, IDLString>::value, std::string,
                                typename IDLNullable<T>::ImplType>::type;
  BASE_EXPORT static ImplType NativeValue(Napi::Value value,
                                          int32_t index = 0) {
    if (value.IsNull() || value.IsUndefined()) {
      return ImplType();
    } else {
      return NativeValueTraits<T>::NativeValue(value, index);
    }
  }
  BASE_EXPORT static ImplType NativeValue(const Napi::CallbackInfo& info,
                                          int32_t index = 0) {
    Napi::Value value = GetArgument(info, index);
    return NativeValue(value, index);
  }
};

// nullable wrapped object
template <typename T>
struct NativeValueTraits<IDLNullable<T>,
                         typename std::enable_if_t<std::is_pointer<
                             typename IDLNullable<T>::ImplType>::value>> {
  typedef typename IDLNullable<T>::ImplType ImplType;
  static ImplType NativeValue(Napi::Value value, int32_t index = 0) {
    if (value.IsNull() || value.IsUndefined()) {
      return nullptr;
    } else {
      return NativeValueTraits<T>::NativeValue(value, index);
    }
  }
  BASE_EXPORT static ImplType NativeValue(const Napi::CallbackInfo& info,
                                          int32_t index = 0) {
    Napi::Value value = GetArgument(info, index);
    return NativeValue(value, index);
  }
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_NATIVE_VALUE_TRAITS_H_
