// Copyright 2019 The Vmsdk Authors. All rights reserved.

#include "jsb/module/vmsdk_module_callback.h"

namespace vmsdk {
namespace piper {

ModuleCallbackFunctionHolder::ModuleCallbackFunctionHolder(
    Napi::Function &&func)
    : function_(Napi::Persistent(std::move(func))) {}

ModuleCallback::ModuleCallback(int64_t callback_id)
    : callback_id_(callback_id) {}

}  // namespace piper
}  // namespace vmsdk
