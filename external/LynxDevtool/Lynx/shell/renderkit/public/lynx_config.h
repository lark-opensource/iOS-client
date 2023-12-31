// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_CONFIG_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_CONFIG_H_
#include <list>
#include <memory>
#include <string>
#include <utility>

#include "lynx_export.h"
#include "shell/renderkit/public/bridge_native_module.h"
#include "shell/renderkit/public/common_native_module.h"

namespace lynx {

class LynxConfigImpl;

class LYNX_EXPORT LynxConfig {
 public:
  LynxConfig();
  LynxConfig(const LynxConfig& config);

  ~LynxConfig();
  bool RegisterModule(const std::shared_ptr<BridgeNativeModule>& module);
  bool RegisterModule(const std::shared_ptr<CommonNativeModule>& module);

  //  bool RegisterModule(
  //      const std::shared_ptr<NativeModuleBaseT<EncodableValue>>& module);
  //  bool RegisterModule(
  //      const std::shared_ptr<NativeModuleBaseT<std::string>>& module);

 protected:
  friend class LynxTemplateRender;
  std::unique_ptr<LynxConfigImpl> impl_;
};
}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_CONFIG_H_
