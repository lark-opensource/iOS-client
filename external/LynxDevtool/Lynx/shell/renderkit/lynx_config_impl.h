// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_LYNX_CONFIG_IMPL_H_
#define LYNX_SHELL_RENDERKIT_LYNX_CONFIG_IMPL_H_

#include <list>
#include <memory>

#include "Lynx/shell/renderkit/bridge_native_module_adapter.h"
#include "Lynx/shell/renderkit/common_native_module_adapter.h"
#include "jsbridge/renderkit/method_invoker.h"

namespace lynx {

// class CommonNativeModuleAdapter;

class LynxConfigImpl {
 public:
  bool RegisterModule(
      const std::shared_ptr<BridgeNativeModuleAdapter>& module) {
    auto ite = std::find_if(
        invokers_.begin(), invokers_.end(),
        [&module](const auto& item) { return module->Name() == item->Name(); });
    if (ite != invokers_.end()) {
      return false;
    }

    auto invoker = std::make_shared<lynx::piper::MethodInvokerTX>(module);
    invokers_.template emplace_back(invoker);
    return true;
  }

  bool RegisterModuleX(
      const std::shared_ptr<CommonNativeModuleAdapter>& module) {
    auto ite = std::find_if(
        invokersX_.begin(), invokersX_.end(),
        [&module](const auto& item) { return module->Name() == item->Name(); });
    if (ite != invokersX_.end()) {
      return false;
    }

    auto invoker = std::make_shared<lynx::piper::MethodInvokerTX>(module);
    invokersX_.template emplace_back(invoker);
    return true;
  }

  auto Modules() { return invokers_; }

  auto ModulesX() { return invokersX_; }

 protected:
  std::list<std::shared_ptr<lynx::piper::MethodInvoker>> invokers_;
  std::list<std::shared_ptr<lynx::piper::MethodInvoker>> invokersX_;
};

}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_LYNX_CONFIG_IMPL_H_
