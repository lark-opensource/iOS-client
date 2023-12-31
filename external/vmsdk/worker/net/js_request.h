#ifndef VMSDK_JS_REQUEST_H
#define VMSDK_JS_REQUEST_H

#include "basic/log/logging.h"
#include "napi.h"
#include "worker/net/js_headers.h"

namespace vmsdk {
namespace net {
class RequestWrap : public Napi::ScriptWrappable {
 public:
  RequestWrap(const Napi::CallbackInfo& info) {
    if (info.Length() < 1) {
      VLOGE("Request constructor requires at least a parameter");
    } else {
      auto init = info[0];
      if (init.IsString()) {       // url init
        if (info.Length() == 1) {  // only init with url
          auto resObj = Napi::Object::New(info.Env());
          resObj.Set("url", init);
          resObj.Set("method", "GET");
          resObj.Set("mode", "cors");
          request.Reset(resObj, 1);
        } else {  // init with url and config object
          if (info[1].IsObject()) {
            auto resObj = info[1].As<Napi::Object>();
            resObj.Set("url", init);
            request.Reset(resObj, 1);
          } else {
            VLOGE("Request constructor param1 is not a object");
          }
        }
      } else if (init.IsObject()) {
        RequestWrap* requestWrap =
            Napi::ObjectWrap<RequestWrap>::Unwrap(init.As<Napi::Object>());
        if (!requestWrap) {
          VLOGE("Request constructor param0 is not a Request object");
        } else {
          request.Reset(init.As<Napi::Object>(), 1);
        }
      } else {
        VLOGE("Request constructor param0 is not a string or a object");
      }
    }
  }
  virtual ~RequestWrap() = default;
  static Napi::Class Create(Napi::Env env) {
    using Wrapped = Napi::ObjectWrap<RequestWrap>;
    return Wrapped::DefineClass(
        env, "Request",
        {Wrapped::InstanceAccessor("url", &RequestWrap::GetUrl, nullptr,
                                   napi_enumerable),
         Wrapped::InstanceAccessor("method", &RequestWrap::GetMethod, nullptr,
                                   napi_enumerable),
         Wrapped::InstanceAccessor("mode", &RequestWrap::GetMode, nullptr,
                                   napi_enumerable),
         Wrapped::InstanceAccessor("headers", &RequestWrap::GetHeaders, nullptr,
                                   napi_enumerable)});
  }
  static Napi::Value ToNapiValue(const Napi::Env& env, RequestWrap* wrap) {
    std::string res;
    if (!wrap || wrap->request.IsEmpty()) {
      return env.Undefined();
    } else {
      Napi::Object resObj = wrap->request.Value();

      auto heaaders = resObj.Get("headers");
      HeadersWrap* headersWrap =
          Napi::ObjectWrap<HeadersWrap>::Unwrap(heaaders.As<Napi::Object>());
      if (headersWrap) {
        resObj.Set("headers", net::HeadersWrap::ToNapiValue(env, headersWrap));
      }
      return resObj;
    }
  }

 private:
  Napi::Value GetUrl(const Napi::CallbackInfo& info) {
    return request.Value().Get("url");
  }

  Napi::Value GetMethod(const Napi::CallbackInfo& info) {
    return request.Value().Get("method");
  }

  Napi::Value GetMode(const Napi::CallbackInfo& info) {
    return request.Value().Get("mode");
  }

  Napi::Value GetHeaders(const Napi::CallbackInfo& info) {
    Napi::Object headers = request.Value().Get("headers").As<Napi::Object>();
    HeadersWrap* wrap = Napi::ObjectWrap<HeadersWrap>::Unwrap(headers);
    if (wrap) {
      return headers;
    } else {
      Napi::Function constructor =
          info.Env().Global().Get("Headers").As<Napi::Function>();
      auto headersWrap = constructor.Call({headers});
      request.Value().Set("headers", headersWrap);
      return headersWrap;
    }
  }
  Napi::ObjectReference request;
};

}  // namespace net
}  // namespace vmsdk

#endif