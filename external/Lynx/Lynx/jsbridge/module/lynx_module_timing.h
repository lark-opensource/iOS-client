//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_MODULE_LYNX_MODULE_TIMING_H_
#define LYNX_JSBRIDGE_MODULE_LYNX_MODULE_TIMING_H_

#include <stdint.h>

#include <memory>
#include <string>

namespace lynx {
namespace piper {

class ModuleDelegate;

// Lynx & Web Status Code
enum class NativeModuleStatusCode {
  // Unknow error.
  FAILURE = 0,
  SUCCESS = 1,
  // JSB not authorized
  UNAUTHORIZED = -1,
  // JSB not registered
  UNREGISTERED = -2,
  PARAMETER_ERROR = -3,
  RETURN_ERROR = -5,
  // Not authorized by the system
  UNAUTHORIZED_BY_SYSTEM = -6
};

struct NetworkRequestInfo {
  std::string jsb_name_;
  std::string http_url_;
  std::string http_method_;
};

// This NativeModuleInfo is mainly used to store JSB timings.
struct NativeModuleInfo {
  NativeModuleInfo() = default;
  NativeModuleInfo(const NativeModuleInfo&) = delete;
  NativeModuleInfo& operator=(const NativeModuleInfo&) = delete;
  NativeModuleInfo(NativeModuleInfo&&) = default;
  NativeModuleInfo& operator=(NativeModuleInfo&&) = default;

  // 1. timestamp
  uint64_t jsb_func_call_start_ = 0;
  uint64_t jsb_func_call_end_ = 0;
  uint64_t jsb_callback_thread_switch_start_ = 0;
  uint64_t jsb_callback_thread_switch_end_ = 0;
  uint64_t jsb_callback_call_start_ = 0;
  uint64_t jsb_callback_call_end_ = 0;

  // 2. duration
  uint64_t jsb_call_ = 0;
  //    2.1 func
  uint64_t jsb_func_call_ = 0;
  uint64_t jsb_func_convert_params_ = 0;
  uint64_t jsb_func_platform_method_ = 0;
  //    2.2 callback
  uint64_t jsb_callback_thread_switch_ = 0;
  uint64_t jsb_callback_call_ = 0;
  uint64_t jsb_callback_convert_params_ = 0;
  uint64_t jsb_callback_invoke_ = 0;

  std::string module_name_;
  std::string method_name_;
  std::string method_first_arg_name_;
  NativeModuleStatusCode status_code_ = NativeModuleStatusCode::SUCCESS;

  NetworkRequestInfo network_request_info_;
};

class NativeModuleInfoCollector {
 public:
  NativeModuleInfoCollector(const std::shared_ptr<ModuleDelegate>& delegate,
                            const std::string& module_name,
                            const std::string& method_name,
                            const std::string& method_first_arg_name);
  ~NativeModuleInfoCollector();

  NativeModuleInfoCollector() = delete;
  NativeModuleInfoCollector(const NativeModuleInfoCollector&) = delete;
  NativeModuleInfoCollector& operator=(const NativeModuleInfoCollector&) =
      delete;
  NativeModuleInfoCollector(NativeModuleInfoCollector&&) = delete;
  NativeModuleInfoCollector& operator=(NativeModuleInfoCollector&&) = delete;

  void EndCallFunc(uint64_t start_time);
  void EndFuncParamsConvert(uint64_t start_time);
  void EndPlatformMethodInvoke(uint64_t start_time);
  void CallbackThreadSwitchStart();
  void EndCallCallback(uint64_t switch_end_time, uint64_t start_time);
  void EndCallbackInvoke(uint64_t convert_params_time, uint64_t invoke_start);
  void OnErrorOccurred(NativeModuleStatusCode status_code);
  uint64_t GetFuncCallStart() const;
  void SetNetworkRequestInfo(const NetworkRequestInfo& info);
  NetworkRequestInfo GetNetworkRequestInfo() const;

 private:
  NativeModuleInfo timing_;
  std::weak_ptr<ModuleDelegate> delegate_;
  bool enable_ = false;
};

using NativeModuleInfoCollectorPtr =
    std::shared_ptr<piper::NativeModuleInfoCollector>;

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_MODULE_LYNX_MODULE_TIMING_H_
