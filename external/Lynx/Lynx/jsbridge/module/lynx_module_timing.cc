//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/module/lynx_module_timing.h"

#include <utility>

#include "base/timer/time_utils.h"
#include "jsbridge/module/module_delegate.h"

namespace lynx {
namespace piper {

NativeModuleInfoCollector::NativeModuleInfoCollector(
    const std::shared_ptr<ModuleDelegate>& delegate,
    const std::string& module_name, const std::string& method_name,
    const std::string& method_first_arg_name)
    : delegate_(delegate) {
  timing_.module_name_ = module_name;
  timing_.method_name_ = method_name;
  timing_.method_first_arg_name_ = method_first_arg_name;
  // TODO: - @limeng.amer
  //  "bridge.call" is supported in the first stage, and other methods will be
  //  added later. eg:
  //  LynxIntersectionObserverModule、LynxUIMethodModule、LynxSetModule...
  enable_ = (module_name == "bridge" && method_name == "call" &&
             !method_first_arg_name.empty());
}

void NativeModuleInfoCollector::EndCallFunc(uint64_t start_time) {
  if (!enable_) {
    return;
  }
  timing_.jsb_func_call_start_ = start_time;
  timing_.jsb_func_call_end_ = base::CurrentSystemTimeMilliseconds();
  timing_.jsb_func_call_ = timing_.jsb_func_call_end_ - start_time;
}

void NativeModuleInfoCollector::EndFuncParamsConvert(uint64_t start_time) {
  if (!enable_) {
    return;
  }
  timing_.jsb_func_convert_params_ =
      base::CurrentSystemTimeMilliseconds() - start_time;
}

void NativeModuleInfoCollector::EndPlatformMethodInvoke(uint64_t start_time) {
  if (!enable_) {
    return;
  }
  timing_.jsb_func_platform_method_ =
      base::CurrentSystemTimeMilliseconds() - start_time;
}

void NativeModuleInfoCollector::CallbackThreadSwitchStart() {
  if (!enable_) {
    return;
  }
  timing_.jsb_callback_thread_switch_start_ =
      base::CurrentSystemTimeMilliseconds();
}

void NativeModuleInfoCollector::EndCallbackInvoke(uint64_t convert_params_time,
                                                  uint64_t invoke_start) {
  if (!enable_) {
    return;
  }
  timing_.jsb_callback_convert_params_ = convert_params_time;
  timing_.jsb_callback_invoke_ =
      base::CurrentSystemTimeMilliseconds() - invoke_start;
}

void NativeModuleInfoCollector::EndCallCallback(uint64_t switch_end_time,
                                                uint64_t start_time) {
  if (!enable_) {
    return;
  }
  timing_.jsb_callback_thread_switch_end_ = switch_end_time;
  timing_.jsb_callback_call_start_ = start_time;
  timing_.jsb_callback_call_end_ = base::CurrentSystemTimeMilliseconds();
  timing_.jsb_callback_call_ = timing_.jsb_callback_call_end_ - start_time;
}

void NativeModuleInfoCollector::OnErrorOccurred(
    NativeModuleStatusCode status_code) {
  if (!enable_ && timing_.status_code_ != NativeModuleStatusCode::SUCCESS) {
    return;
  }
  timing_.status_code_ = status_code;
}

uint64_t NativeModuleInfoCollector::GetFuncCallStart() const {
  return timing_.jsb_func_call_start_;
}

void NativeModuleInfoCollector::SetNetworkRequestInfo(
    const NetworkRequestInfo& info) {
  timing_.network_request_info_ = info;
}

NetworkRequestInfo NativeModuleInfoCollector::GetNetworkRequestInfo() const {
  return timing_.network_request_info_;
}

// ModuleCallback & LynxModule
// ModuleCallback and LynxModule jointly hold NativeModuleInfoCollector.
// NativeModuleInfoCollector will destruct When both a and b are released.
NativeModuleInfoCollector::~NativeModuleInfoCollector() {
  if (!enable_) {
    return;
  }
  auto delegate = delegate_.lock();
  if (delegate == nullptr) {
    return;
  }
  // Calculate timing data
  timing_.jsb_callback_thread_switch_ =
      timing_.jsb_callback_thread_switch_end_ -
      timing_.jsb_callback_thread_switch_start_;
  if (timing_.jsb_func_call_end_ >= timing_.jsb_callback_call_end_) {
    timing_.jsb_call_ = timing_.jsb_func_call_;
  } else {
    timing_.jsb_call_ =
        timing_.jsb_callback_call_end_ - timing_.jsb_func_call_start_;
  }
  // flush data
  delegate->FlushJSBTiming(std::move(timing_));
}
}  // namespace piper
}  // namespace lynx
