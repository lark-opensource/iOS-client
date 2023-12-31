// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REPLAY_LYNX_MODULE_BINDING_TESTBENCH_H_
#define LYNX_TASM_REPLAY_LYNX_MODULE_BINDING_TESTBENCH_H_

#include <set>
#include <string>

#include "jsbridge/jsi/jsi.h"
#include "jsbridge/module/lynx_module.h"
#include "jsbridge/module/lynx_module_manager.h"

namespace lynx {
namespace piper {

class LynxModuleBindingTestBench : public piper::HostObject {
 public:
  explicit LynxModuleBindingTestBench(
      const LynxModuleProviderFunction &moduleProvider);
  ~LynxModuleBindingTestBench() override = default;

  piper::Value get(Runtime *rt, const PropNameID &prop) override;

  void setLynxModuleManagerPtr(const LynxModuleBindingPtr moduleProvider);

 private:
  // replay module Manager
  LynxModuleProviderFunction moduleProvider_;
  // lynx module Manager's ptr
  LynxModuleBindingPtr moduleBindingPtrLynx_;

  // these modules will be called by moduleBindingPtrLynx_
  std::set<std::string> lynxModuleSet{"LynxUIMethodModule",
                                      "NavigationModule",
                                      "IntersectionObserverModule",
                                      "LynxSetModule",
                                      "DevtoolWebSocketModule",
                                      "NetworkingModule",
                                      "LynxTestModule",
                                      "BDLynxModule",
                                      "hybridMonitor",
                                      "JSBTestModule"};
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_TASM_REPLAY_LYNX_MODULE_BINDING_TESTBENCH_H_
