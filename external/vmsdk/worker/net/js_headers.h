#ifndef VMSDK_JS_HEADERS_H
#define VMSDK_JS_HEADERS_H
#include "basic/log/logging.h"
#include "napi.h"

namespace vmsdk {
namespace net {
class RequestWrap;
class HeadersWrap : public Napi::ScriptWrappable {
 public:
  HeadersWrap(const Napi::CallbackInfo& info) {
    if (info.Length() < 1) {
      headers.Reset(Napi::Object::New(info.Env()), 1);
    } else {
      auto headersWrap = Napi::ObjectWrap<net::HeadersWrap>::Unwrap(
          info[0].As<Napi::Object>());
      if (headersWrap) {
        headers.Reset(ToNapiValue(info.Env(), headersWrap).As<Napi::Object>(),
                      1);
      } else {
        headers.Reset(info[0].As<Napi::Object>(), 1);
      }
    }
  }
  virtual ~HeadersWrap() = default;
  static Napi::Class Create(Napi::Env env) {
    using Wrapped = Napi::ObjectWrap<HeadersWrap>;
    return Wrapped::DefineClass(
        env, "Headers",
        {Wrapped::InstanceMethod("append", &HeadersWrap::Append,
                                 napi_enumerable),
         Wrapped::InstanceMethod("delete", &HeadersWrap::Delete,
                                 napi_enumerable),
         Wrapped::InstanceMethod("get", &HeadersWrap::Get, napi_enumerable),
         Wrapped::InstanceMethod("has", &HeadersWrap::Has, napi_enumerable),
         Wrapped::InstanceMethod("set", &HeadersWrap::Set, napi_enumerable),
         Wrapped::InstanceMethod("keys", &HeadersWrap::Keys, napi_enumerable),
         Wrapped::InstanceMethod("values", &HeadersWrap::Values,
                                 napi_enumerable),
         Wrapped::InstanceMethod("entries", &HeadersWrap::Entries,
                                 napi_enumerable)});
  }
  static Napi::Value ToNapiValue(const Napi::Env& env, HeadersWrap* wrap) {
    Napi::EscapableHandleScope scp(env);
    Napi::ContextScope contextScope(env);

    std::string res;
    if (!wrap || wrap->headers.IsEmpty()) {
      return env.Undefined();
    } else {
      auto napiObj = Napi::Object::New(env);
      auto keys = wrap->headers.Value().GetPropertyNames();
      for (uint32_t i = 0; i < keys.Length(); ++i) {
        auto arr = wrap->headers.Value().Get(keys.Get(i)).As<Napi::Array>();
        napiObj.Set(keys.Get(i), Array2String(arr));
      }
      return scp.Escape(napiObj);
    }
  }

  static void UnWrapToNativeNapiValue(Napi::Object obj, const char* key) {
    auto headers = obj.As<Napi::Object>().Get(key);
    if (!headers.IsUndefined()) {
      auto headersWrap = Napi::ObjectWrap<net::HeadersWrap>::Unwrap(
          headers.As<Napi::Object>());
      if (headersWrap) {
        obj.As<Napi::Object>().Set(
            key, net::HeadersWrap::ToNapiValue(obj.Env(), headersWrap));
      }
    }
  }

 private:
  Napi::Value Append(const Napi::CallbackInfo& info) {
    if (info.Length() < 2) {
      return info.Env().Undefined();
    }
    Napi::Value name = info[0], value = info[1];
    if (!name.IsString() || !value.IsString()) {
      VLOGE("Headers append param0 is not a string or param1 is not an string");
      return info.Env().Undefined();
    }
    auto oldValue = headers.Value().Get(name);
    if (oldValue.IsUndefined()) {
      Napi::Array arr = Napi::Array::New(info.Env(), 1);
      arr.Set((uint32_t)0, value);
      headers.Value().Set(name, arr);
    } else {
      auto valueArr = oldValue.As<Napi::Array>();
      valueArr.Set(valueArr.Length(), value);
    }
    return info.Env().Undefined();
  }

  Napi::Value Delete(const Napi::CallbackInfo& info) {
    if (info.Length() < 1) {
      return info.Env().Undefined();
    }
    Napi::Value name = info[0];
    if (!name.IsString()) {
      VLOGE("Headers delete param0 is not a string");
    }
    headers.Value().Delete(name);
    return info.Env().Undefined();
  }

  Napi::Value Has(const Napi::CallbackInfo& info) {
    if (info.Length() < 1) {
      VLOGE("Headers has function expected 1 parameter but got 0");
      return info.Env().Undefined();
    }
    bool result = headers.Value().Has(info[0]);
    return Napi::Boolean::New(info.Env(), result);
  }

  Napi::Value Get(const Napi::CallbackInfo& info) {
    if (info.Length() < 1) {
      VLOGE("Headers get function expected 1 parameter but got 0");
      return info.Env().Undefined();
    }
    auto value = headers.Value().Get(info[0]);
    if (value.IsUndefined()) {
      return info.Env().Null();
    } else {
      return Array2String(value.As<Napi::Array>());
    }
  }

  static Napi::Value Array2String(const Napi::Array& arr) {
    std::string str;
    if (arr.Length() > 0) {
      str += arr.Get(uint32_t(0)).As<Napi::String>().Utf8Value();
      for (uint32_t i = 1; i < arr.Length(); ++i)
        str += ", " + arr.Get(i).As<Napi::String>().Utf8Value();
    }
    return Napi::String::New(arr.Env(), str);
  }

  Napi::Value Set(const Napi::CallbackInfo& info) {
    if (info.Length() < 2) {
      VLOGE("Headers set function expected 2 parameter but got less");
      return info.Env().Undefined();
    }
    Napi::Value name = info[0], newValue = info[1];
    auto arr = Napi::Array::New(info.Env(), 1);
    arr.Set((uint32_t)0, newValue);
    headers.Value().Set(name, arr);
    return info.Env().Undefined();
  }

  Napi::Value Keys(const Napi::CallbackInfo& info) {
    return headers.Value().GetPropertyNames();
  }

  Napi::Value Values(const Napi::CallbackInfo& info) {
    auto keys = headers.Value().GetPropertyNames();
    auto values = Napi::Array::New(info.Env());
    for (uint32_t i = 0; i < keys.Length(); ++i) {
      values.Set(
          i, Array2String(headers.Value().Get(keys.Get(i)).As<Napi::Array>()));
    }
    return values;
  }

  Napi::Value Entries(const Napi::CallbackInfo& info) {
    auto keys = headers.Value().GetPropertyNames();
    auto entries = Napi::Array::New(info.Env());
    for (uint32_t i = 0; i < keys.Length(); ++i) {
      Napi::Array pair = Napi::Array::New(info.Env(), 2);
      pair.Set(uint32_t(0), keys.Get(i));
      pair.Set(
          uint32_t(1),
          Array2String(headers.Value().Get(keys.Get(i)).As<Napi::Array>()));
      entries.Set(i, pair);
    }
    return entries;
  }
  Napi::ObjectReference headers;
  friend class RequestWrap;
};
}  // namespace net
}  // namespace vmsdk

#endif