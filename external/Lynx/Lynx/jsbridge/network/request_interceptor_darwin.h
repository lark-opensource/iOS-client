// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NETWORK_REQUEST_INTERCEPTOR_DARWIN_H_
#define LYNX_JSBRIDGE_NETWORK_REQUEST_INTERCEPTOR_DARWIN_H_

#include <memory>

#include "jsbridge/ios/piper/lynx_callback_darwin.h"
#include "jsbridge/network/network_module.h"

namespace lynx {
namespace piper {

namespace network {
class RequestInterceptorDarwin : public RequestInterceptor {
 public:
  virtual ModuleInterceptorResult NetworkRequest(
      Runtime* rt,
      std::shared_ptr<piper::NativeModuleInfoCollector> timing_collector,
      Value& data, String& url, String& http_method, Function&& function,
      uint64_t start_time, uint64_t jsb_func_convert_params_start,
      uint64_t jsb_func_call_start, ModuleCallbackType type) const;
};

class ModuleCallbackRequest : public ModuleCallbackDarwin {
 public:
  ModuleCallbackRequest(int64_t callback_id, ModuleCallbackType type)
      : ModuleCallbackDarwin(callback_id), type_(type) {}
  void Invoke(Runtime* runtime, ModuleCallbackFunctionHolder* holder) override;

 private:
  const ModuleCallbackType type_;
};

}  // namespace network
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NETWORK_REQUEST_INTERCEPTOR_DARWIN_H_
