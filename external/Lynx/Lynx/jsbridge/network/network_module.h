// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NETWORK_NETWORK_MODULE_H_
#define LYNX_JSBRIDGE_NETWORK_NETWORK_MODULE_H_

#include <memory>
#include <string>

#include "jsbridge/module/lynx_module.h"
namespace lynx {
namespace piper {

class LynxModuleBinding;

namespace network {

// Check whether a JSB response is a network response, conditions are:
// 1. module name is 'bridge'
// 2. module method name is 'call'
// 3. module method first argument is 'x.request' or 'fetch
//
bool IsNetworkResponse(const ModuleCallback* callback);

// Check whether a JSB request is a network request,
// network request should at least has these properties:
// 1. module name is 'bridge'
// 2. module method name is 'call'
// 3. module method has 3 arguments:
//    first argument is 'x.request' or 'fetch'
//    second argument is 'data'
//    third argument is callback function
bool IsNetworkRequest(const std::string& module_name,
                      const std::string& method_name, Runtime* rt,
                      const piper::Value* args, size_t count);

// Check if request body is valid, return true if it meets:
//  1. body is an JS Object
//  2. body is an JS String and body type is base64
bool IsValidRequestBody(Runtime* rt, const std::optional<piper::Value>& body,
                        const std::optional<piper::Value>& body_type);

std::shared_ptr<LynxModule> CreateNetworkModule(LynxModuleBinding* binding);

// Create request body by its content-type:
// Input:
//      "application/json" or "application/x-www-form-urlencoded" content-type
//      http request body in JS Object
// Output:
//      serialized body in std::string
// Exemple:
//    {
//     "a" : 123,
//     "b" : "abc"
//    }
//
//  with "application/json":
//    "{\"a\" : 123, \"b\" : \"abc\"}"
//
//  with "application/x-www-form-urlencoded":
//    "a=123&b=abc"
//
std::string SerializeRequestBody(Runtime* rt, const std::string& content_type,
                                 const piper::Value& body,
                                 const std::optional<piper::Value>& body_type);

// Extract content-type from headers and data
// Input:
//    headers: request headers as JS Object
//    data: request data used to find switch
//    `enable_lynx_network_with_url_encoded`
// Output: content-type value
//
std::string GetContentType(Runtime* rt, const std::optional<Value>& headers,
                           const Value& data);

// Extract `method` from `data`, GET is the default Http request type
// if `data` doesn't contain `method` key
std::string GetHttpMethod(Runtime* rt, const Value& data);

// If JSB is a network request, set network request information into
// timing_collector hold by callback, these information are needed
// when the request has succedded. Otherwise, ignore this step.
void SetNetworkCallbackInfo(
    const std::string& module_name, const std::string& method_name, Runtime* rt,
    const piper::Value* args, size_t count,
    const NativeModuleInfoCollectorPtr& timing_collector);

// Extract base url from `data`, retrieve `url` from `data`, and return
// the url without url params
std::string GetBaseUrl(Runtime* rt, const Value& data);

// Try extracting HttpCode from JSB response of x.request or app.fetch.
// The common path is `data.httpCode`, return it if it exists
int32_t TryGetHttpCode(Runtime* rt, const piper::Value* args, size_t size);

// Report network response information
void ReportRequestSuccess(const NativeModuleInfoCollectorPtr& timing,
                          int32_t http_code, bool use_lynx_network);

Object CreateCallbackObject(ModuleCallbackType type, Runtime* rt, bool success,
                            int32_t http_code, int32_t client_code,
                            const std::string& error_message,
                            const Value& headers,
                            const std::optional<std::string>& body_data);

class RequestInterceptor : public ModuleMethodInterceptor {
 public:
  virtual ModuleInterceptorResult InterceptModuleMethod(
      LynxModule* module, LynxModule::MethodMetadata* method, Runtime* rt,
      const std::shared_ptr<piper::ModuleDelegate>& delegate,
      const piper::Value* args, size_t count) const override final;

  virtual ModuleInterceptorResult NetworkRequest(
      Runtime* rt,
      std::shared_ptr<piper::NativeModuleInfoCollector> timing_collector,
      Value& data, String& url, String& http_method, Function&& function,
      uint64_t start_time, uint64_t jsb_func_convert_params_start,
      uint64_t jsb_func_call_start, ModuleCallbackType type) const = 0;
  void SetTemplateUrl(const std::string& url) override final;
  std::shared_ptr<LynxModule> network_module_;

 private:
  bool force_enable_;
};
}  // namespace network

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NETWORK_NETWORK_MODULE_H_
