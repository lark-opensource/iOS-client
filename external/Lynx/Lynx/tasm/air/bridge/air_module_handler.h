// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_AIR_BRIDGE_AIR_MODULE_HANDLER_H_
#define LYNX_TASM_AIR_BRIDGE_AIR_MODULE_HANDLER_H_

#include <memory>
#include <string>

#include "shell/lynx_actor.h"
#include "third_party/fml/thread.h"

namespace lynx {
namespace shell {
class LynxEngine;
}
namespace lepus {
class Value;
}
namespace air {
class AirModuleHandler {
 public:
  AirModuleHandler() = default;
  virtual ~AirModuleHandler() = default;

  virtual lepus::Value TriggerBridgeSync(
      const std::string &method_name, const lynx::lepus::Value &arguments) = 0;
  virtual void TriggerBridgeAsync(const std::string &method_name,
                                  const lynx::lepus::Value &arguments) = 0;
  virtual void SetEngineActor(
      std::shared_ptr<shell::LynxActor<shell::LynxEngine>> actor){};
};

}  // namespace air
}  // namespace lynx

#endif  // LYNX_TASM_AIR_BRIDGE_AIR_MODULE_HANDLER_H_
