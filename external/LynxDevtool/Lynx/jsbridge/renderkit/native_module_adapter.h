// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_RENDERKIT_NATIVE_MODULE_ADAPTER_H_
#define LYNX_JSBRIDGE_RENDERKIT_NATIVE_MODULE_ADAPTER_H_

#include <memory>
#include <string>

#include "jsbridge/renderkit/lynx_module_desktop.h"
#include "jsbridge/renderkit/method_invoker.h"
#include "jsbridge/renderkit/method_result_adapter.h"
#include "jsbridge/renderkit/module_callback_desktop.h"
#include "shell/renderkit/native_module.h"

namespace lynx {
namespace piper {

class NativeModuleAdapter : public LynxModuleDesktop {
 public:
  NativeModuleAdapter(const std::shared_ptr<MethodInvoker> &module,
                      const std::shared_ptr<ModuleDelegate> &delegate);
  NativeModuleAdapter(void *lynx_view,
                      const std::shared_ptr<MethodInvoker> &module,
                      const std::shared_ptr<ModuleDelegate> &delegate);

  std::optional<piper::Value> call(Runtime *rt, const lynx::piper::Value *args,
                                   size_t count);

 protected:
  std::optional<Value> InvokeNativeMethod(std::string &name, Runtime *rt,
                                          const Value *args, size_t count);

  Value getAttributeValue(Runtime *rt, std::string prop_name) override {
    return LynxModuleDesktop::getAttributeValue(rt, prop_name);
  }

 private:
  std::shared_ptr<MethodInvoker> invoker_;
};

class NativeModuleAdapterX : public LynxModuleDesktop {
 public:
  NativeModuleAdapterX(const std::shared_ptr<MethodInvoker> &module,
                       const std::shared_ptr<ModuleDelegate> &delegate);
  NativeModuleAdapterX(void *lynx_view,
                       const std::shared_ptr<MethodInvoker> &invoker,
                       const std::shared_ptr<ModuleDelegate> &delegate);

 protected:
  std::optional<Value> InvokeNativeMethod(const std::string &name, Runtime *rt,
                                          const Value *args, size_t count);
  Value getAttributeValue(Runtime *rt, std::string prop_name) override {
    return LynxModuleDesktop::getAttributeValue(rt, prop_name);
  }

 private:
  std::shared_ptr<MethodInvoker> invoker_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_NATIVE_MODULE_ADAPTER_H_
