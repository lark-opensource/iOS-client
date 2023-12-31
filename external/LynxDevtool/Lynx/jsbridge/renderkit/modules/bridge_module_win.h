// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_RENDERKIT_MODULES_BRIDGE_MODULE_WIN_H_
#define LYNX_JSBRIDGE_RENDERKIT_MODULES_BRIDGE_MODULE_WIN_H_

#include <memory>
#include <string>
#include <vector>

#include "jsbridge/renderkit/jsi_value_reader.h"
#include "jsbridge/renderkit/lynx_module_desktop.h"
#include "jsbridge/renderkit/modules/bridge_module_impl_win.h"

namespace lynx {
namespace piper {

class BridgeModuleWin : public LynxModuleDesktop {
 public:
  BridgeModuleWin(const std::string &name,
                  const std::shared_ptr<ModuleDelegate> &delegate);

  std::optional<lynx::piper::Value> call(Runtime *rt,
                                         const lynx::piper::Value *args,
                                         size_t count);

 private:
  std::vector<std::unique_ptr<BridgeModuleImplWin>> bridge_module_impls_;
  BridgeMethodsMap methods_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_MODULES_BRIDGE_MODULE_WIN_H_
