// Copyright 2021 The Lynx Authors. All rights reserved.

#include "jsbridge/napi/callback_helper.h"

namespace lynx {
namespace piper {

// static
void CallbackHelper::ReportException(Napi::Object error_obj) {
  Napi::Value app_id = error_obj.Env().Global()["currentAppId"];
  uint32_t current_id = app_id.As<Napi::Number>().Uint32Value();
  Napi::Value apps = error_obj.Env().Global()["multiApps"];
  Napi::Object apps_obj = apps.As<Napi::Object>();
  Napi::Value app_proxy = apps_obj[current_id];

  // Return if app_proxy is null or undefined after card destroy
  if (app_proxy.IsNull() || app_proxy.IsUndefined()) {
    return;
  }
  Napi::Object app_proxy_obj = app_proxy.As<Napi::Object>();

  // Run JS ReportError USER_RUNTIME_ERROR
  Napi::Object lynx_obj;
  if (app_proxy_obj.Has("lynx")) {
    Napi::Value lynx = app_proxy_obj["lynx"];
    lynx_obj = lynx.As<Napi::Object>();
  }

  if (lynx_obj.Has("reportError")) {
    Napi::Value report_error = lynx_obj["reportError"];
    if (report_error.IsFunction()) {
      report_error.As<Napi::Function>().Call({error_obj});
    }
  }
}

// static
void CallbackHelper::Invoke(const Napi::FunctionReference& cb,
                            Napi::Value& result,
                            std::function<void(Napi::Env)> handler,
                            const std::initializer_list<napi_value>& args) {
  Napi::ContextScope cs(cb.Env());
  Napi::HandleScope hs(cb.Env());
  if (cb.IsEmpty() || !cb.Value().IsFunction()) {
    ReportException(Napi::TypeError::New(
        cb.Env(), "The OnLoadCallback callback is not callable."));
    return;
  }
  result = cb.Value().Call(args);
  if (cb.Env().IsExceptionPending()) {
    if (handler) {
      handler(cb.Env());
      return;
    }
    ReportException(cb.Env().GetAndClearPendingException().As<Napi::Object>());
    return;
  }
}

bool CallbackHelper::PrepareForCall(Napi::Function& callback_function) {
  if (callback_function.IsEmpty() || !callback_function.IsFunction()) {
    Napi::TypeError error = Napi::TypeError::New(
        callback_function.Env(), "The provided callback is not callable.");
    ReportException(error);
    return false;
  }
  function_ = Napi::Persistent(callback_function);
  return true;
}

bool CallbackHelper::PrepareForCall(Napi::Object& callback_interface,
                                    const char* property_name,
                                    bool single_operation) {
  bool is_callable = true;
  if (callback_interface.IsEmpty()) {
    is_callable = false;
  }

  if (single_operation && callback_interface.IsFunction()) {
    function_ = Napi::Persistent(callback_interface.As<Napi::Function>());
  } else {
    Napi::Value function = callback_interface[property_name];
    if (!function.IsFunction()) {
      is_callable = false;
    } else {
      function_ = Napi::Persistent(function.As<Napi::Function>());
    }
  }
  if (!is_callable) {
    Napi::TypeError error = Napi::TypeError::New(
        callback_interface.Env(), "The provided callback is not callable.");
    ReportException(error);
    return false;
  }
  return true;
}

Napi::Value CallbackHelper::Call(
    const std::initializer_list<napi_value>& args) {
  Napi::Value result;
  result = function_.Value().Call(args);
  if (function_.Env().IsExceptionPending()) {
    Napi::Object error =
        function_.Env().GetAndClearPendingException().As<Napi::Object>();
    ReportException(error);
  }
  return result;
}

Napi::Value CallbackHelper::CallWithThis(
    napi_value recv, const std::initializer_list<napi_value>& args) {
  Napi::Value result;
  result = function_.Value().Call(recv, args);
  if (function_.Env().IsExceptionPending()) {
    Napi::Object error =
        function_.Env().GetAndClearPendingException().As<Napi::Object>();
    ReportException(error);
  }
  return result;
}

}  // namespace piper
}  // namespace lynx
