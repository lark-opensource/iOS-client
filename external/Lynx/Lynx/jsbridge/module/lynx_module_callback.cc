// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/module/lynx_module_callback.h"

#include <utility>

namespace lynx {
namespace piper {

// BINARY_KEEP_SOURCE_FILE
ModuleCallbackFunctionHolder::ModuleCallbackFunctionHolder(Function&& func)
    : function_(std::move(func)) {}

ModuleCallback::ModuleCallback(int64_t callback_id)
    : callback_id_(callback_id) {}

#if ENABLE_ARK_RECORDER
void ModuleCallback::SetRecordID(int64_t record_id) { record_id_ = record_id; }
#endif

}  // namespace piper
}  // namespace lynx
