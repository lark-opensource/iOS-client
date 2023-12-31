// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_AIR_BRIDGE_IOS_AIR_MODULE_HANDLER_DARWIN_H_
#define LYNX_TASM_AIR_BRIDGE_IOS_AIR_MODULE_HANDLER_DARWIN_H_

#include <memory>
#include <string>

#import "TemplateRenderCallbackProtocol.h"
#include "tasm/air/bridge/air_module_handler.h"

namespace lynx {
namespace air {
class AirModuleHandlerDarwin : public AirModuleHandler {
 public:
  AirModuleHandlerDarwin(id<TemplateRenderCallbackProtocol> render);

  lepus::Value TriggerBridgeSync(const std::string &method_name,
                                 const lynx::lepus::Value &arguments) override;

  void TriggerBridgeAsync(const std::string &method_name,
                          const lynx::lepus::Value &arguments) override;

 private:
  __weak id<TemplateRenderCallbackProtocol> render_;
};
}  // namespace air
}  // namespace lynx

#endif  // LYNX_TASM_AIR_BRIDGE_IOS_AIR_MODULE_HANDLER_DARWIN_H_
