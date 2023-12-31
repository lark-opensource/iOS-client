// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REPLAY_LYNX_CALLBACK_TESTBENCH_H_
#define LYNX_TASM_REPLAY_LYNX_CALLBACK_TESTBENCH_H_
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/module/lynx_module_callback.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace piper {

class ModuleCallbackTestBench : public ModuleCallback {
 public:
  ModuleCallbackTestBench(int64_t callback_id);
  ~ModuleCallbackTestBench() override = default;
  piper::Value argument;
  void Invoke(Runtime *runtime, ModuleCallbackFunctionHolder *holder) override;
};
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_TASM_REPLAY_LYNX_CALLBACK_TESTBENCH_H_
