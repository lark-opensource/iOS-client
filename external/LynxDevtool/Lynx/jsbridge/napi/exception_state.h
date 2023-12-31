// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_EXCEPTION_STATE_H_
#define LYNX_JSBRIDGE_NAPI_EXCEPTION_STATE_H_

#include <cstdio>
#include <string>

#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace piper {

class ExceptionState {
 public:
  ExceptionState(Napi::Env env) : env_(env) {}
  ExceptionState(Napi::Env env, const std::string& message)
      : env_(env), message_(message) {}

  ExceptionState(const ExceptionState&) = delete;
  ExceptionState& operator=(const ExceptionState&) = delete;

  ~ExceptionState() {
    if (HadException()) {
      exception_.Value().ThrowAsJavaScriptException();
    }
  }

  bool HadException() { return !exception_.IsEmpty(); }

  enum ErrorType { kTypeError, kRangeError, kError };

  void SetException(const std::string& message, ErrorType error_type = kError) {
    message_ = message;
    switch (error_type) {
      case kTypeError:
        exception_ = Napi::Persistent(static_cast<Napi::Error>(
            Napi::TypeError::New(env_, message_.c_str())));
        break;
      case kRangeError:
        exception_ = Napi::Persistent(static_cast<Napi::Error>(
            Napi::RangeError::New(env_, message_.c_str())));
        break;
      default:
        exception_ = Napi::Persistent(Napi::Error::New(env_, message_.c_str()));
        break;
    }
  }
  const std::string& Message() const { return message_; }

 private:
  Napi::Env env_;
  std::string message_;
  Napi::Reference<Napi::Error> exception_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_EXCEPTION_STATE_H_
