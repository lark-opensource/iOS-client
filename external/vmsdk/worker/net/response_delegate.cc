#include "worker/net/response_delegate.h"

#include "basic/log/logging.h"
#include "worker/js_worker.h"

namespace vmsdk {
namespace net {

void ResponseDelegate::resolve(Napi::Value response) {
  Napi::HandleScope scp(env_);
  Napi::ContextScope contextScope(env_);

  VLOGE("fetch resolve callback...");
  defered_.Resolve(response);

  std::string msg;
#if defined(OS_ANDROID) && defined(DEBUG)
  if (runtime::JSRuntimeUtils::CheckAndGetException2(env_, msg)) {
#else
  if (runtime::JSRuntimeUtils::CheckAndGetExceptionMsg(env_, msg)) {
#endif
    worker_->CallOnErrorCallback("fetch resolve response exception: " + msg);
  }
}

void ResponseDelegate::reject(Napi::Value reject) {
  Napi::HandleScope scp(env_);
  Napi::ContextScope contextScope(env_);

  VLOGE("fetch reject callback...");
  defered_.Reject(reject);

  std::string msg;
#if defined(OS_ANDROID) && defined(DEBUG)
  if (runtime::JSRuntimeUtils::CheckAndGetException2(env_, msg)) {
#else
  if (runtime::JSRuntimeUtils::CheckAndGetExceptionMsg(env_, msg)) {
#endif
    worker_->CallOnErrorCallback("fetch reject exception: " + msg);
  }
}

Napi::Value ResponseDelegate::getBodyText(Napi::ArrayBuffer &body) {
  auto napiEnv = body.Env();
  Napi::EscapableHandleScope scp(napiEnv);
  Napi::ContextScope contextScope(napiEnv);

  if (body.IsEmpty() || !body.IsArrayBuffer())
    return Napi::String::New(napiEnv, "");
  auto text = Napi::String::New(napiEnv, (const char *)(body.Data()),
                                body.ByteLength());
  return scp.Escape(text);
}

Napi::Value ResponseDelegate::getBodyJson(Napi::ArrayBuffer &body) {
  auto napiEnv = body.Env();
  Napi::EscapableHandleScope scp(napiEnv);
  Napi::ContextScope contextScope(napiEnv);

  Napi::Value text = getBodyText(body).As<Napi::String>();
  Napi::Value json = napiEnv.Global()["JSON"];
  Napi::Function parse =
      json.As<Napi::Object>().Get("parse").As<Napi::Function>();
  auto obj = parse.Call({text});
  std::string exception;
  if (runtime::JSRuntimeUtils::CheckAndGetExceptionMsg(napiEnv, exception)) {
    VLOGE("JSON.parse failed: %s, original string is %s\n", exception.c_str(),
          text.As<Napi::String>().Utf8Value().c_str());
    return scp.Escape(Napi::Object::New(napiEnv));
  }
  return scp.Escape(obj);
}

Napi::Value ResponseDelegate::json(const Napi::CallbackInfo &info) {
  worker::Worker *worker = reinterpret_cast<worker::Worker *>(info.Data());
  if (!worker || !worker->running_) {
    return info.Env().Undefined();
  }

  Napi::Env napiEnv = info.Env();
  Napi::EscapableHandleScope scp(napiEnv);
  Napi::ContextScope contextScope(napiEnv);
  Napi::Object response = info.This().As<Napi::Object>();

  auto body = response.Get("body").As<Napi::ArrayBuffer>();
  Napi::ObjectReference body_ref =
      Napi::Persistent(getBodyJson(body).As<Napi::Object>());

  auto deferred = Napi::Promise::Deferred::New(napiEnv);
  auto promise = deferred.Promise();
  deferred.Resolve(body_ref.Value());

  return scp.Escape(promise);
}

Napi::Value ResponseDelegate::text(const Napi::CallbackInfo &info) {
  worker::Worker *worker = reinterpret_cast<worker::Worker *>(info.Data());
  if (!worker || !worker->running_) {
    return info.Env().Undefined();
  }
  Napi::Env napiEnv = info.Env();
  Napi::EscapableHandleScope scp(napiEnv);
  Napi::ContextScope contextScope(napiEnv);
  Napi::Object response = info.This().As<Napi::Object>();
  auto body = response.Get("body").As<Napi::ArrayBuffer>();
  std::string bodyString = getBodyText(body).As<Napi::String>().Utf8Value();

  auto deferred = Napi::Promise::Deferred::New(napiEnv);
  auto promise = deferred.Promise();
  deferred.Resolve(Napi::String::New(info.Env(), bodyString));

  return scp.Escape(promise);
}

}  // namespace net
}  // namespace vmsdk