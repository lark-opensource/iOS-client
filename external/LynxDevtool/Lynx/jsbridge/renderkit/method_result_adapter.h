// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_RENDERKIT_METHOD_RESULT_ADAPTER_H_
#define LYNX_JSBRIDGE_RENDERKIT_METHOD_RESULT_ADAPTER_H_

#include <memory>
#include <utility>

#include "jsbridge/renderkit/module_callback_desktop.h"
#include "jsbridge/renderkit/value_convert.h"
#include "shell/renderkit/public/method_result.h"

namespace lynx {
namespace piper {

class MethodResultImpl : public lynx::MethodResult {
 public:
  explicit MethodResultImpl(std::shared_ptr<NativeModuleCallbackWin> callback)
      : callback_(std::move(callback)) {}
  void Result(const EncodableList& result) override {
    callback_->SetArguments(result);
    auto delegate = callback_->delegate();
    delegate->RunOnJSThread([delegate = delegate, callback = callback_]() {
      delegate->CallJSCallback(callback);
    });
  }

 private:
  std::shared_ptr<NativeModuleCallbackWin> callback_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_METHOD_RESULT_ADAPTER_H_
