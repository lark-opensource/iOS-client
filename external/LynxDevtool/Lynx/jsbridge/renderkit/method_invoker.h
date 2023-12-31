// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_RENDERKIT_METHOD_INVOKER_H_
#define LYNX_JSBRIDGE_RENDERKIT_METHOD_INVOKER_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/module/module_delegate.h"
#include "jsbridge/renderkit/method_result_adapter.h"
#include "jsbridge/renderkit/module_callback_desktop.h"
#include "jsbridge/renderkit/value_convert.h"
#include "shell/renderkit/native_module.h"
#include "shell/renderkit/public/encodable_value.h"

namespace lynx {
namespace piper {

class MethodInvoker {
 public:
  virtual ~MethodInvoker() = default;
  virtual std::optional<Value> InvokeNativeMethod(
      void *lynx_view, const std::shared_ptr<ModuleDelegate> &delegate,
      const std::string &name, Runtime *rt, const Value *args,
      size_t count) = 0;
  virtual std::string Name() = 0;
  virtual std::vector<std::string> MethodNames() = 0;
};

class MethodInvokerTX : public MethodInvoker {
 public:
  explicit MethodInvokerTX(std::shared_ptr<lynx::NativeModuleBase> module)
      : module_(std::move(module)) {}
  std::optional<Value> InvokeNativeMethod(
      void *lynx_view, const std::shared_ptr<ModuleDelegate> &delegate,
      const std::string &name, Runtime *rt, const Value *args,
      size_t count) override;

  std::string Name() override { return module_->Name(); }
  std::vector<std::string> MethodNames() override {
    return module_->MethodNames();
  }

 private:
  std::shared_ptr<NativeModuleBase> module_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_METHOD_INVOKER_H_
