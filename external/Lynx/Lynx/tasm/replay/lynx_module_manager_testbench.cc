// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/replay/lynx_module_manager_testbench.h"

#include <utility>

namespace lynx {
namespace piper {

ModuleManagerTestBench::ModuleManagerTestBench() {
  moduleMap = std::unordered_map<std::string, ModuleTestBenchPtr>();
}

void ModuleManagerTestBench::Destroy() {}

// Get record Data from ReplayDataModule and store with json format
void ModuleManagerTestBench::initRecordModuleData(piper::Value &module,
                                                  piper::Runtime &js_runtime) {
  auto getRecordData =
      module.getObject(js_runtime).getProperty(js_runtime, "getRecordData");
  if (!getRecordData) {
    return;
  }
  auto function_call_opt = getRecordData->getObject(js_runtime)
                               .getFunction(js_runtime)
                               .call(js_runtime);
  if (function_call_opt && function_call_opt->isString()) {
    recordData.Parse(
        function_call_opt->getString(js_runtime).utf8(js_runtime).c_str());
  }

  // get additional info by value
  auto getJsbIgnoredInfo =
      module.getObject(js_runtime).getProperty(js_runtime, "getJsbIgnoredInfo");
  if (!getJsbIgnoredInfo) {
    return;
  }

  auto function_call_opt_get_ignore_info =
      getJsbIgnoredInfo->getObject(js_runtime)
          .getFunction(js_runtime)
          .call(js_runtime);
  if (function_call_opt_get_ignore_info &&
      function_call_opt_get_ignore_info->isString()) {
    jsb_ignored_info_.Parse(
        function_call_opt_get_ignore_info->getString(js_runtime)
            .utf8(js_runtime)
            .c_str());
  }

  // get jsb settings by value
  auto getJsbSettings =
      module.getObject(js_runtime).getProperty(js_runtime, "getJsbSettings");
  if (!getJsbSettings) {
    return;
  }

  auto function_call_opt_get_jsb_settings =
      getJsbSettings->getObject(js_runtime)
          .getFunction(js_runtime)
          .call(js_runtime);
  if (function_call_opt_get_jsb_settings &&
      function_call_opt_get_jsb_settings->isString()) {
    jsb_settings_.Parse(
        function_call_opt_get_jsb_settings->getString(js_runtime)
            .utf8(js_runtime)
            .c_str());
  }
}

// init bindingptr, at the same time, get the bindingPtr(lynxPtr) from class
// ModuleManagerDarwin.
void ModuleManagerTestBench::initBindingPtr(
    std::weak_ptr<ModuleManagerTestBench> weak_manager,
    const std::shared_ptr<ModuleDelegate> &delegate,
    LynxModuleBindingPtr lynxPtr) {
  bindingPtr = std::make_shared<lynx::piper::LynxModuleBindingTestBench>(
      BindingFunc(weak_manager, delegate));
  // be used to call modules from Lynx SDK.
  bindingPtr->setLynxModuleManagerPtr(lynxPtr);
}

LynxModuleProviderFunction ModuleManagerTestBench::BindingFunc(
    std::weak_ptr<ModuleManagerTestBench> weak_manager,
    const std::shared_ptr<ModuleDelegate> &delegate) {
  return [weak_manager, &delegate](const std::string &name) {
    auto manager = weak_manager.lock();
    if (manager) {
      auto ptr = manager->getModule(name, delegate);
      if (ptr.get() != nullptr) {
        return ptr;
      }
    }
    return ModuleTestBenchPtr(nullptr);
  };
}

ModuleTestBenchPtr ModuleManagerTestBench::getModule(
    const std::string &name, const std::shared_ptr<ModuleDelegate> &delegate) {
  // step 1. try to get module from moduleMap
  auto p = moduleMap.find(name);
  if (p != moduleMap.end()) {
    return p->second;
  }
  // step 2. try to find correct module from recordData
  if (recordData.HasMember(name.c_str())) {
    ModuleTestBenchPtr module =
        std::make_shared<ModuleTestBench>(name, delegate);
    module.get()->initModuleData(recordData[name.c_str()], &jsb_ignored_info_,
                                 &jsb_settings_, recordData.GetAllocator());
    moduleMap.insert(std::pair<std::string, ModuleTestBenchPtr>(name, module));
    return module;
  }
  // step 3. have no correct module, thus return nullptr
  return ModuleTestBenchPtr(nullptr);
}

}  // namespace piper
}  // namespace lynx
