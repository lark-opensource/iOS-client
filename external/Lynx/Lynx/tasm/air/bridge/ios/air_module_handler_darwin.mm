// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/air/bridge/ios/air_module_handler_darwin.h"
#include "jsbridge/ios/lepus/lynx_lepus_module_darwin.h"
#include "tasm/air/runtime/air_runtime.h"

namespace lynx {
namespace air {
AirModuleHandlerDarwin::AirModuleHandlerDarwin(id<TemplateRenderCallbackProtocol> render)
    : AirModuleHandler(), render_(render) {}

lepus::Value AirModuleHandlerDarwin::TriggerBridgeSync(const std::string &method_name,
                                                       const lepus::Value &arguments) {
  return lynx::piper::TriggerLepusMethod(method_name, arguments, render_);
}

void AirModuleHandlerDarwin::TriggerBridgeAsync(const std::string &method_name,
                                                const lepus::Value &arguments) {
  lynx::piper::TriggerLepusMethodAsync(method_name, arguments, render_);
}

}  // namespace air
}  // namespace lynx
