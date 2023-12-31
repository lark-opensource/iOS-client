// Copyright 2022 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_HEADLESS_MODULE_CALLBACK_HEADLESS_H_
#define LYNX_JSBRIDGE_HEADLESS_MODULE_CALLBACK_HEADLESS_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "jsbridge/module/lynx_module_callback.h"
#include "jsbridge/module/module_delegate.h"

namespace lynx {
namespace headless {

class ModuleCallbackHeadless : public piper::ModuleCallback {
 public:
  ModuleCallbackHeadless(
      int64_t callbackId,
      const std::shared_ptr<piper::ModuleDelegate> &delegate);

  void Invoke(piper::Runtime *runtime,
              piper::ModuleCallbackFunctionHolder *holder) override;
  void SetArguments(std::vector<std::string> arguments) {
    arguments_ = std::move(arguments);
  }
  std::shared_ptr<piper::ModuleDelegate> delegate() { return delegate_; }

 private:
  std::shared_ptr<piper::ModuleDelegate> delegate_;
  std::vector<std::string> arguments_;
};

}  // namespace headless
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_HEADLESS_MODULE_CALLBACK_HEADLESS_H_
