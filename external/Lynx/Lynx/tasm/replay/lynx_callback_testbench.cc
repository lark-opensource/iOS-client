// Copyright 2021 The Lynx Authors. All rights reserved.
#include "tasm/replay/lynx_callback_testbench.h"

namespace lynx {
namespace piper {

ModuleCallbackTestBench::ModuleCallbackTestBench(int64_t callback_id)
    : ModuleCallback(callback_id) {}

void ModuleCallbackTestBench::Invoke(Runtime *runtime,
                                     ModuleCallbackFunctionHolder *holder) {
  if (runtime == nullptr) {
    LOGE("lynx ModuleCallbackDarwin has null runtime or null function");
    return;
  }
  piper::Runtime *rt = runtime;
  holder->function_.call(*rt, argument);
}
}  // namespace piper
}  // namespace lynx
