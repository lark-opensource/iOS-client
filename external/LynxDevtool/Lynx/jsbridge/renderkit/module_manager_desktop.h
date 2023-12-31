// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_JSBRIDGE_RENDERKIT_MODULE_MANAGER_DESKTOP_H_
#define LYNX_JSBRIDGE_RENDERKIT_MODULE_MANAGER_DESKTOP_H_

#include <memory>
#include <string>
#include <unordered_map>

#include "jsbridge/module/lynx_module_manager.h"
#include "jsbridge/renderkit/lynx_module_desktop.h"

namespace lynx {
namespace piper {
using LynxModuleDesktopPtr = std::shared_ptr<lynx::piper::LynxModuleDesktop>;

class ModuleManagerDesktop : public LynxModuleManager {
 public:
  ModuleManagerDesktop() = default;
  ~ModuleManagerDesktop() override = default;
  void Destroy() override;

  using ModuleCreator = std::function<LynxModuleDesktopPtr()>;
  bool RegisterModule(std::string name, ModuleCreator creator);
  void UnregisterModule(const std::string& name);

 protected:
  LynxModuleProviderFunction BindingFunc(
      std::weak_ptr<ModuleManagerDesktop> weak_manager,
      const std::shared_ptr<ModuleDelegate>& delegate);

 private:
  std::unordered_map<std::string, ModuleCreator> module_creators_;
  std::unordered_map<std::string, LynxModuleDesktopPtr> modules_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RENDERKIT_MODULE_MANAGER_DESKTOP_H_
