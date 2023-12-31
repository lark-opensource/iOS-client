// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_RENDERKIT_MODULE_CALLBACK_DESKTOP_H_
#define LYNX_JSBRIDGE_RENDERKIT_MODULE_CALLBACK_DESKTOP_H_

#include <memory>
#include <utility>
#include <vector>

#include "jsbridge/module/lynx_module_callback.h"
#include "jsbridge/module/module_delegate.h"
#include "jsbridge/renderkit/value_convert.h"
#include "shell/renderkit/public/encodable_value.h"

namespace lynx {
namespace piper {

class ModuleCallbackDesktop : public ModuleCallback {
 public:
  ModuleCallbackDesktop(int64_t callbackId,
                        const std::shared_ptr<ModuleDelegate> &delegate);

  void Invoke(Runtime *runtime, ModuleCallbackFunctionHolder *holder) override;
  void SetArguments(
      std::vector<std::unique_ptr<lynx::piper::Value>> arguments) {
    arguments_ = std::move(arguments);
  }
  std::shared_ptr<ModuleDelegate> delegate() { return delegate_; }

 private:
  std::shared_ptr<ModuleDelegate> delegate_;
  std::vector<std::unique_ptr<lynx::piper::Value>> arguments_;
};

class NativeModuleCallbackWin : public ModuleCallbackDesktop {
 public:
  static std::shared_ptr<NativeModuleCallbackWin> createCallbackImpl(
      int64_t callback_id, const std::shared_ptr<ModuleDelegate> &delegate) {
    return std::make_shared<NativeModuleCallbackWin>(callback_id, delegate);
  }
  using ModuleCallbackDesktop::ModuleCallbackDesktop;

  void Invoke(Runtime *runtime, ModuleCallbackFunctionHolder *holder) override {
    std::vector<piper::Value> piper_args;
    for (const auto &arg : arguments_) {
      if (auto value = Convert(*runtime, arg)) {
        piper_args.emplace_back(std::move(*value));
      } else {
        return;
      }
    }
    holder->function_.call(*runtime,
                           static_cast<const Value *>(piper_args.data()),
                           piper_args.size());
  }

  void SetArguments(EncodableList arguments) {
    arguments_ = std::move(arguments);
  }

 private:
  EncodableList arguments_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_MODULE_CALLBACK_DESKTOP_H_
