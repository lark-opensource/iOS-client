// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REPLAY_LYNX_MODULE_MANAGER_TESTBENCH_H_
#define LYNX_TASM_REPLAY_LYNX_MODULE_MANAGER_TESTBENCH_H_
#include <memory>
#include <string>
#include <unordered_map>

#include "tasm/replay/lynx_module_binding_testbench.h"
#include "tasm/replay/lynx_module_testbench.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace piper {

using ModuleTestBenchPtr = std::shared_ptr<lynx::piper::ModuleTestBench>;
using LynxModuleBindingPtrTestBench =
    std::shared_ptr<lynx::piper::LynxModuleBindingTestBench>;

class ModuleManagerTestBench {
 public:
  ModuleManagerTestBench();
  void initRecordModuleData(piper::Value &module, piper::Runtime &js_runtime);
  void Destroy();
  void initBindingPtr(std::weak_ptr<ModuleManagerTestBench> weak_manager,
                      const std::shared_ptr<ModuleDelegate> &delegate,
                      LynxModuleBindingPtr lynxPtr);
  LynxModuleBindingPtrTestBench bindingPtr;

 protected:
  LynxModuleProviderFunction BindingFunc(
      std::weak_ptr<ModuleManagerTestBench> weak_manager,
      const std::shared_ptr<ModuleDelegate> &delegate);

 private:
  ModuleTestBenchPtr getModule(const std::string &name,
                               const std::shared_ptr<ModuleDelegate> &delegate);
  rapidjson::Document recordData;
  std::unordered_map<std::string, ModuleTestBenchPtr> moduleMap;
  rapidjson::Document jsb_ignored_info_;
  rapidjson::Document jsb_settings_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_TASM_REPLAY_LYNX_MODULE_MANAGER_TESTBENCH_H_
