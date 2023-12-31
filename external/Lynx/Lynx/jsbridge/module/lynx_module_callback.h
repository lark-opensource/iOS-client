// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_MODULE_LYNX_MODULE_CALLBACK_H_
#define LYNX_JSBRIDGE_MODULE_LYNX_MODULE_CALLBACK_H_

#include <jsbridge/jsi/jsi.h>

#include <string>

#include "config/config.h"
#include "jsbridge/module/lynx_module_timing.h"

namespace lynx {
namespace piper {

class ModuleCallbackFunctionHolder {
 public:
  ModuleCallbackFunctionHolder(piper::Function&& func);
  ~ModuleCallbackFunctionHolder() = default;
  piper::Function function_;
};

enum class ModuleCallbackType {
  Base,
  Request,
  Fetch,
};

class ModuleCallback {
 public:
  static constexpr int64_t kInvalidCallbackId = -1;
  explicit ModuleCallback(int64_t callback_id);
  virtual ~ModuleCallback() = default;
  virtual void Invoke(Runtime* runtime,
                      ModuleCallbackFunctionHolder* holder) = 0;
  int64_t callback_id() const { return callback_id_; }
  void SetModuleName(const std::string& module_name) {
    module_name_ = module_name;
  }
  void SetMethodName(const std::string& method_name) {
    method_name_ = method_name;
  }
  void SetFirstArg(const std::string& first_arg) { first_arg_ = first_arg; }
  std::string module_name_;
  std::string method_name_;
  // Some JSB implement such as XBridge will use first arg as JSB function name,
  // so we need first arg for tracing.
  std::string first_arg_;
  uint64_t start_time_ms_ = 0;
  const std::string& FirstArg() const { return first_arg_; }
  void SetStartTimeMS(uint64_t ms) { start_time_ms_ = ms; }
  uint64_t StartTimeMS() const { return start_time_ms_; }
  // We need callback flow id to bind CallJSB and InvokeCallback in tracing.
  uint64_t callback_flow_id_ = 0;
  void SetCallbackFlowId(uint64_t flow_id) { callback_flow_id_ = flow_id; }
  uint64_t CallbackFlowId() const { return callback_flow_id_; }

  NativeModuleInfoCollectorPtr timing_collector_;

#if ENABLE_ARK_RECORDER
  void SetRecordID(int64_t record_id);
#endif
  int64_t record_id_ = 0;

 private:
  const int64_t callback_id_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_MODULE_LYNX_MODULE_CALLBACK_H_
