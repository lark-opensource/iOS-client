// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_RENDERKIT_MODULES_BRIDGE_MODULE_IMPL_WIN_H_
#define LYNX_JSBRIDGE_RENDERKIT_MODULES_BRIDGE_MODULE_IMPL_WIN_H_

#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>

#include "jsbridge/jsi/jsi.h"
#include "jsbridge/module/module_delegate.h"

namespace lynx {
namespace piper {

using BridgeMethod = std::function<lynx::piper::Value(
    Runtime *rt, const lynx::piper::Value *args, size_t count)>;
using BridgeMethodsMap = std::unordered_map<std::string, BridgeMethod>;

class BridgeModuleImplWin {
 public:
  explicit BridgeModuleImplWin(std::shared_ptr<ModuleDelegate> delegate)
      : delegate_(std::move(delegate)) {}
  virtual ~BridgeModuleImplWin() = default;
  virtual BridgeMethodsMap Methods() = 0;

 protected:
  const std::shared_ptr<ModuleDelegate> delegate_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_MODULES_BRIDGE_MODULE_IMPL_WIN_H_
