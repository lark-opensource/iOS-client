//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/network/request_interceptor_darwin.h"
#include "base/timer/time_utils.h"
#include "base/trace_event/trace_event.h"
#include "jsbridge/ios/piper/lynx_module_darwin.h"
#include "jsbridge/module/lynx_module_timing.h"
#include "jsbridge/utils/utils.h"
#include "tasm/lynx_trace_event.h"

#import "LynxHttpRequest.h"
#include "config/config.h"

#if ENABLE_ARK_RECORDER
#include "jsbridge/jsi/jsi.h"
#include "tasm/recorder/native_module_recorder.h"
#endif

// BINARY_KEEP_SOURCE_FILE

namespace lynx {
namespace piper {
namespace network {

namespace {

LynxHttpRequest *CreateHttpRequest(ModuleCallbackType type, Runtime *rt, Value &data, String &url,
                                   String &http_method) {
  auto header_key = type == ModuleCallbackType::Request ? "header" : "headers";
  auto headers = data.getObject(*rt).getProperty(*rt, header_key);
  auto body_key = type == ModuleCallbackType::Request ? "body" : "data";
  auto body = data.getObject(*rt).getProperty(*rt, body_key);
  auto params = data.getObject(*rt).getProperty(*rt, "params");
  auto add_common_params = data.getObject(*rt).getProperty(*rt, "addCommonParams");
  auto body_type = data.getObject(*rt).getProperty(*rt, "bodyType");
  std::string content_type = GetContentType(rt, headers, data);
  LynxHttpRequest *request = [[LynxHttpRequest alloc] init];
  request.URL = [NSURL URLWithString:convertJSIStringToNSString(*rt, url)];

  if (headers && headers->isObject()) {
    headers->getObject(*rt).setProperty(*rt, "Content-Type", content_type);
    std::unique_ptr<std::vector<piper::Object>> pre_object_vector =
        std::make_unique<std::vector<piper::Object>>();

    request.allHTTPHeaderFields =
        convertJSIObjectToNSDictionary(*rt, headers->getObject(*rt), *pre_object_vector);
    if (request.allHTTPHeaderFields == nil) {
      LOGE("[CreateHttpRequest] There is an error happened in convertJSIObjectToNSDictionary when "
           "convert JS headers to objc value.");
    }
  } else {
    request.allHTTPHeaderFields =
        @{@"Content-Type" : [[NSString alloc] initWithUTF8String:content_type.c_str()]};
  }
  request.HTTPMethod = convertJSIStringToNSString(*rt, http_method);

  // make body string
  if (IsValidRequestBody(rt, body, body_type)) {
    auto body_string = SerializeRequestBody(rt, content_type, *body, body_type);

    request.HTTPBody = [NSData dataWithBytesNoCopy:body_string.data()
                                            length:body_string.length()
                                      freeWhenDone:NO];
  }
  if (add_common_params && add_common_params->isBool()) {
    request.addCommonParams = add_common_params->getBool();
  } else {
    request.addCommonParams = YES;
  }

  if (params && params->isObject()) {
    std::unique_ptr<std::vector<piper::Object>> pre_object_vector =
        std::make_unique<std::vector<piper::Object>>();
    request.params =
        convertJSIObjectToNSDictionary(*rt, params->getObject(*rt), *pre_object_vector);
    if (request.params == nil) {
      LOGE("[CreateHttpRequest] There is an error happened in convertJSIObjectToNSDictionary when "
           "convert JS params body to objc value.");
    }
  }
  return request;
}

}  // namespace

void ModuleCallbackRequest::Invoke(Runtime *rt, ModuleCallbackFunctionHolder *holder) {
  uint64_t convert_params_start = lynx::base::CurrentSystemTimeMilliseconds();
  LynxHttpResponse *response = argument;
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "ModuleCallbackRequest::Invoke",
              [response](lynx::perfetto::EventContext ctx) {
                auto *method = ctx.event()->add_debug_annotations();
                method->set_name("url");
                method->set_string_value(response.URL.absoluteString.UTF8String);
              });
  piper::Scope scope(*rt);
  Object obj = Object(*rt);
  Value headers = Value::null();
  std::optional<std::string> body_data = {};
  int32_t http_code = static_cast<int32_t>(response.statusCode);
  int32_t client_code = static_cast<int32_t>(response.clientCode);
  bool success = response.error == nil && http_code == 200;

  if (success) {
    // success
    Object data = Object(*rt);
    auto headers_opt = convertNSDictionaryToJSIObject(*rt, response.allHeaderFields);
    if (!headers_opt) {
      rt->reportJSIException(JSINativeException(
          "request_interceptor_darwin error: convert NSDictionary to js object fail."));
      return;
    } else {
      headers = std::move(*headers_opt);
    }
    if (response.body != nil) {
      NSData *body = response.body;
      body_data = std::string(static_cast<const char *>(body.bytes), (size_t)body.length);
    }
  }
  obj = CreateCallbackObject(type_, rt, success, http_code, client_code,
                             response.error ? response.error.localizedDescription.UTF8String : "",
                             headers, body_data);
  uint64_t convert_params_end = lynx::base::CurrentSystemTimeMilliseconds();
#if ENABLE_ARK_RECORDER
  Value value(*rt, obj);
  tasm::recorder::NativeModuleRecorder::RecordCallback("bridge", "call", value, rt, callback_id(),
                                                       record_id_);
#endif
  holder->function_.call(*rt, obj);
  if (timing_collector_ != nullptr) {
    timing_collector_->EndCallbackInvoke((convert_params_end - convert_params_start),
                                         convert_params_end);
    ReportRequestSuccess(timing_collector_, http_code, true);
  }
}

ModuleInterceptorResult RequestInterceptorDarwin::NetworkRequest(
    Runtime *rt, std::shared_ptr<piper::NativeModuleInfoCollector> timing_collector, Value &data,
    String &url, String &http_method, Function &&function, uint64_t start_time,
    uint64_t jsb_func_convert_params_start, uint64_t jsb_func_call_start,
    ModuleCallbackType type) const {
  LynxHttpRequest *request = CreateHttpRequest(type, rt, data, url, http_method);

  auto *module_darwin = static_cast<LynxModuleDarwin *>(network_module_.get());
  LynxCallbackBlock block = module_darwin->ConvertJSIFunctionToCallback(
      *rt, std::move(function), "call", nullptr, type, start_time, timing_collector);
  timing_collector->EndFuncParamsConvert(jsb_func_convert_params_start);

  SEL selector = NSSelectorFromString(module_darwin->methodLookup[@"call"]);
  NSMethodSignature *methodSignature =
      [[module_darwin->instance_ class] instanceMethodSignatureForSelector:selector];
  NSInvocation *inv = [NSInvocation invocationWithMethodSignature:methodSignature];
  [inv setSelector:selector];
  [inv setArgument:(void *)&request atIndex:2];
  [inv setArgument:(void *)&block atIndex:3];

  uint64_t jsb_func_platform_method_start = lynx::base::CurrentSystemTimeMilliseconds();
  auto res_opt = PerformMethodInvocation(*rt, inv, module_darwin->instance_);
  timing_collector->EndPlatformMethodInvoke(jsb_func_platform_method_start);
  timing_collector->EndCallFunc(jsb_func_call_start);
  if (!res_opt) {
    rt->reportJSIException(JSINativeException("request_interceptor_darwin error: There may be "
                                              "error when convert return ObjcValue to JSValue."));
    return {true, Value::null()};
  }
  return {true, std::move(*res_opt)};
}

}  // namespace network
}  // namespace piper
}  // namespace lynx
