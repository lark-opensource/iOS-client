// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_NAPI_BASE_WRAP_H_
#define LYNX_JSBRIDGE_NAPI_NAPI_BASE_WRAP_H_

#include <vector>

#include "jsbridge/napi/base.h"

namespace lynx {
namespace piper {

typedef Napi::MethodCallbackData<BridgeBase, BridgeBase::InstanceCallbackPtr>
    BridgeBaseMethodCallbackData;
typedef Napi::AccessorCallbackData<BridgeBase, BridgeBase::GetterCallbackPtr,
                                   BridgeBase::SetterCallbackPtr>
    BridgeBaseAccessorCallbackData;
typedef Napi::MethodCallbackData<BridgeBase, BridgeBase::StaticMethodCallback>
    BridgeBaseStaticMethodCallbackData;
typedef Napi::AccessorCallbackData<BridgeBase, BridgeBase::StaticMethodCallback,
                                   BridgeBase::StaticSetterCallback>
    BridgeBaseStaticAccessorCallbackData;

BASE_EXPORT napi_class DefineClass(napi_env env, const char* utf8name,
                                   napi_callback ctor, size_t props_count,
                                   const napi_property_descriptor* descriptors,
                                   void* data, napi_class super_class);

BASE_EXPORT napi_ref Wrap(napi_env env, napi_value obj, void* data,
                          napi_finalize finalize_cb, void* hint);

BASE_EXPORT napi_value InstanceMethodCallbackWrapper(napi_env env,
                                                     napi_callback_info info);
BASE_EXPORT napi_value InstanceGetterCallbackWrapper(napi_env env,
                                                     napi_callback_info info);
BASE_EXPORT napi_value InstanceSetterCallbackWrapper(napi_env env,
                                                     napi_callback_info info);
BASE_EXPORT napi_value StaticMethodCallbackWrapper(napi_env env,
                                                   napi_callback_info info);
BASE_EXPORT napi_value StaticGetterCallbackWrapper(napi_env env,
                                                   napi_callback_info info);
BASE_EXPORT napi_value StaticSetterCallbackWrapper(napi_env env,
                                                   napi_callback_info info);

BASE_EXPORT void AttachPropData(Napi::Object obj, size_t props_count,
                                const napi_property_descriptor* props);
BASE_EXPORT void FinalizeCallback(napi_env env, void* data, void* /*hint*/);
BASE_EXPORT bool CheckIsConstructorCall(napi_env env, Napi::CallbackInfo& info);

template <typename T>
class NapiBaseWrapped : public T, public Napi::Reference<Napi::Object> {
 public:
  typedef Napi::ClassPropertyDescriptor<T> PropertyDescriptor;
  typedef Napi::Value (T::*InstanceCallback)(const Napi::CallbackInfo& info);
  typedef void (T::*InstanceSetterCallback)(const Napi::CallbackInfo& info,
                                            const Napi::Value& value);
  typedef Napi::MethodCallbackData<T, InstanceCallback>
      InstanceMethodCallbackData;
  typedef Napi::AccessorCallbackData<T, InstanceCallback,
                                     InstanceSetterCallback>
      InstanceAccessorCallbackData;

  typedef Napi::Value (*StaticMethodCallback)(const Napi::CallbackInfo& info);
  typedef void (*StaticSetterCallback)(const Napi::CallbackInfo& info,
                                       const Napi::Value& value);
  using StaticMethodCallbackData =
      Napi::MethodCallbackData<T, StaticMethodCallback>;
  using StaticAccessorCallbackData =
      Napi::AccessorCallbackData<T, StaticMethodCallback, StaticSetterCallback>;

  BASE_EXPORT static PropertyDescriptor InstanceValue(
      const char* utf8name, napi_value value,
      napi_property_attributes attributes) {
    napi_property_descriptor desc = napi_property_descriptor();
    desc.utf8name = utf8name;
    desc.value = value;
    desc.attributes = attributes;
    return desc;
  }

  BASE_EXPORT static PropertyDescriptor InstanceValue(
      Napi::Name name, napi_value value, napi_property_attributes attributes) {
    napi_property_descriptor desc = napi_property_descriptor();
    desc.name = name;
    desc.value = value;
    desc.attributes = attributes;
    return desc;
  }

  BASE_EXPORT static PropertyDescriptor InstanceMethod(
      const char* utf8name, InstanceCallback method,
      napi_property_attributes attributes = napi_default,
      void* data = nullptr) {
    InstanceMethodCallbackData* callbackData =
        new InstanceMethodCallbackData({method, data});

    napi_property_descriptor desc = napi_property_descriptor();
    desc.utf8name = utf8name;
    desc.method = InstanceMethodCallbackWrapper;
    desc.data = callbackData;
    desc.attributes = attributes;
    return desc;
  }

  BASE_EXPORT static PropertyDescriptor InstanceMethod(
      Napi::Name name, InstanceCallback method,
      napi_property_attributes attributes = napi_default,
      void* data = nullptr) {
    InstanceMethodCallbackData* callbackData =
        new InstanceMethodCallbackData({method, data});

    napi_property_descriptor desc = napi_property_descriptor();
    desc.name = name;
    desc.method = InstanceMethodCallbackWrapper;
    desc.data = callbackData;
    desc.attributes = attributes;
    return desc;
  }

  BASE_EXPORT static PropertyDescriptor InstanceAccessor(
      const char* utf8name, InstanceCallback getter,
      InstanceSetterCallback setter = nullptr,
      napi_property_attributes attributes = napi_default,
      void* data = nullptr) {
    InstanceAccessorCallbackData* callbackData =
        new InstanceAccessorCallbackData({getter, setter, data});

    napi_property_descriptor desc = napi_property_descriptor();
    desc.utf8name = utf8name;
    desc.getter = getter != nullptr ? InstanceGetterCallbackWrapper : nullptr;
    desc.setter = setter != nullptr ? InstanceSetterCallbackWrapper : nullptr;
    desc.data = callbackData;
    desc.attributes = attributes;
    return desc;
  }

  BASE_EXPORT static PropertyDescriptor InstanceAccessor(
      Napi::Name name, InstanceCallback getter,
      InstanceSetterCallback setter = nullptr,
      napi_property_attributes attributes = napi_default,
      void* data = nullptr) {
    InstanceAccessorCallbackData* callbackData =
        new InstanceAccessorCallbackData({getter, setter, data});

    napi_property_descriptor desc = napi_property_descriptor();
    desc.name = name;
    desc.getter = getter != nullptr ? InstanceGetterCallbackWrapper : nullptr;
    desc.setter = setter != nullptr ? InstanceSetterCallbackWrapper : nullptr;
    desc.data = callbackData;
    desc.attributes = attributes;
    return desc;
  }

  BASE_EXPORT static Napi::Class DefineClass(
      Napi::Env env, const char* utf8name,
      const std::initializer_list<PropertyDescriptor>& properties,
      void* data = nullptr, napi_class super_class = nullptr) {
    return DefineClass(
        env, utf8name, properties.size(),
        reinterpret_cast<const napi_property_descriptor*>(properties.begin()),
        data, super_class);
  }

  BASE_EXPORT static Napi::Class DefineClass(
      Napi::Env env, const char* utf8name,
      const std::vector<PropertyDescriptor>& properties, void* data = nullptr,
      napi_class super_class = nullptr) {
    return DefineClass(
        env, utf8name, properties.size(),
        reinterpret_cast<const napi_property_descriptor*>(properties.data()),
        data, super_class);
  }

  BASE_EXPORT static PropertyDescriptor StaticMethod(
      const char* utf8name, StaticMethodCallback method,
      napi_property_attributes attributes = napi_default,
      void* data = nullptr) {
    StaticMethodCallbackData* callbackData =
        new StaticMethodCallbackData({method, data});

    napi_property_descriptor desc = napi_property_descriptor();
    desc.utf8name = utf8name;
    desc.method = StaticMethodCallbackWrapper;
    desc.data = callbackData;
    desc.attributes =
        static_cast<napi_property_attributes>(attributes | napi_static);
    return desc;
  }

  BASE_EXPORT static PropertyDescriptor StaticMethod(
      Napi::Name name, StaticMethodCallback method,
      napi_property_attributes attributes = napi_default,
      void* data = nullptr) {
    StaticMethodCallbackData* callbackData =
        new StaticMethodCallbackData({method, data});

    napi_property_descriptor desc = napi_property_descriptor();
    desc.name = name;
    desc.method = StaticMethodCallbackWrapper;
    desc.data = callbackData;
    desc.attributes =
        static_cast<napi_property_attributes>(attributes | napi_static);
    return desc;
  }

  BASE_EXPORT static PropertyDescriptor StaticAccessor(
      const char* utf8name, StaticMethodCallback getter,
      StaticSetterCallback setter,
      napi_property_attributes attributes = napi_default,
      void* data = nullptr) {
    StaticAccessorCallbackData* callbackData =
        new StaticAccessorCallbackData({getter, setter, data});

    napi_property_descriptor desc = napi_property_descriptor();
    desc.utf8name = utf8name;
    desc.getter = getter != nullptr ? StaticGetterCallbackWrapper : nullptr;
    desc.setter = setter != nullptr ? StaticSetterCallbackWrapper : nullptr;
    desc.data = callbackData;
    desc.attributes =
        static_cast<napi_property_attributes>(attributes | napi_static);
    return desc;
  }

  BASE_EXPORT static PropertyDescriptor StaticAccessor(
      Napi::Name name, StaticMethodCallback getter, StaticSetterCallback setter,
      napi_property_attributes attributes = napi_default,
      void* data = nullptr) {
    StaticAccessorCallbackData* callbackData =
        new StaticAccessorCallbackData({getter, setter, data});

    napi_property_descriptor desc = napi_property_descriptor();
    desc.name = name;
    desc.getter = getter != nullptr ? StaticGetterCallbackWrapper : nullptr;
    desc.setter = setter != nullptr ? StaticSetterCallbackWrapper : nullptr;
    desc.data = callbackData;
    desc.attributes =
        static_cast<napi_property_attributes>(attributes | napi_static);
    return desc;
  }

  BASE_EXPORT static PropertyDescriptor StaticValue(
      const char* utf8name, napi_value value,
      napi_property_attributes attributes = napi_default) {
    napi_property_descriptor desc = napi_property_descriptor();
    desc.utf8name = utf8name;
    desc.value = value;
    desc.attributes =
        static_cast<napi_property_attributes>(attributes | napi_static);
    return desc;
  }

  BASE_EXPORT static PropertyDescriptor StaticValue(
      Napi::Name name, napi_value value,
      napi_property_attributes attributes = napi_default) {
    napi_property_descriptor desc = napi_property_descriptor();
    desc.name = name;
    desc.value = value;
    desc.attributes =
        static_cast<napi_property_attributes>(attributes | napi_static);
    return desc;
  }

 private:
  NapiBaseWrapped(const Napi::CallbackInfo& callbackInfo) : T(callbackInfo) {
    napi_env env = callbackInfo.Env();
    napi_value wrapper = callbackInfo.This();

    static_assert(std::is_base_of<Napi::ScriptWrappable, T>::value,
                  "T must inherit ScriptWrappable");
    void* ptr = static_cast<Napi::ScriptWrappable*>(this);

    napi_ref ref = Wrap(env, wrapper, ptr, FinalizeCallback, nullptr);

    Napi::Reference<Napi::Object>* instanceRef = this;
    *instanceRef = Napi::Reference<Napi::Object>(env, ref);
  }

  BASE_EXPORT static napi_value ConstructorCallbackWrapper(
      napi_env env, napi_callback_info info) {
    Napi::CallbackInfo callbackInfo(env, info);

    if (!CheckIsConstructorCall(env, callbackInfo)) {
      return nullptr;
    }

    new NapiBaseWrapped<T>(callbackInfo);

    return callbackInfo.This();
  }

  BASE_EXPORT static Napi::Class DefineClass(
      Napi::Env env, const char* utf8name, const size_t props_count,
      const napi_property_descriptor* props, void* data,
      napi_class super_class) {
    Napi::Class clazz(
        env, lynx::piper::DefineClass(env, utf8name, ConstructorCallbackWrapper,
                                      props_count, props, data, super_class));
    auto fun = clazz.Get(env);
    AttachPropData(fun, props_count, props);
    return clazz;
  }
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_NAPI_BASE_WRAP_H_
