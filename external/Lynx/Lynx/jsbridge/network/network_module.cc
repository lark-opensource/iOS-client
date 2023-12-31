// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/network/network_module.h"

#include <algorithm>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/lynx_env.h"
#include "base/no_destructor.h"
#include "base/timer/time_utils.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/module/lynx_module_binding.h"
#include "jsbridge/network/url_encoder.h"
#include "tasm/event_report_tracker.h"
#include "tasm/lynx_trace_event.h"
#include "third_party/modp_b64/modp_b64.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace piper {

namespace network {

// code signifies if the request is success
constexpr int kNetworkRequestSuccess = 1;
constexpr int kNetworkRequestFailure = 0;
// code corresponds to network lib's json parse failure
constexpr int kJSONParseFailure = -99;

namespace {
// These functions using settings will be removed after we fully switch
// to Lynx Network.
constexpr const char* kForceLynxNetwork = "FORCE_LYNX_NETWORK";
constexpr const char* kLynxNetworkAllowList = "FORCE_LYNX_NETWORK_ALLOWLIST";
constexpr const char* kLynxNetworkBlockList = "FORCE_LYNX_NETWORK_BLOCKLIST";

std::vector<std::string> ParseJsonArray(const std::string& json_array_str) {
  std::vector<std::string> ret;
  rapidjson::Document json_doc;
  json_doc.Parse(json_array_str);
  if (!json_doc.IsArray()) {
    return ret;
  }

  const auto& json_array = json_doc.GetArray();
  for (const auto& item : json_array) {
    if (item.IsString()) {
      ret.emplace_back(item.GetString());
    }
  }
  return ret;
}

bool IsTemplateUrlInSettingsList(const std::string& key,
                                 const std::string& url) {
  static base::NoDestructor<
      std::unordered_map<std::string, std::vector<std::string>>>
      cache;
  auto& cache_ref = *cache;

  auto& url_target_cache = cache_ref[key];
  if (url_target_cache.empty()) {
    const auto& json_array_str =
        base::LynxEnv::GetInstance().GetExperimentSettings(key);
    url_target_cache = ParseJsonArray(json_array_str);
  }

  for (const auto& target : url_target_cache) {
    if (url.find(target) != std::string::npos) {
      return true;
    }
  }
  return false;
}

bool GetForceLynxNetworkByDefault() {
  return base::LynxEnv::GetInstance().GetExperimentSettings(
             kForceLynxNetwork) == "true";
}

// Check whether should use Lynx Network by default:
//  1. If template url is in `FORCE_LYNX_NETWORK_BLOCKLIST`, default is disable
//  2. If template url is in `FORCE_LYNX_NETWORK_ALLOWLIST`, default is enable
//  3. If `FORCE_LYNX_NETWORK` switch on, default is enable
//  4. Otherwise, default is disable
bool ShouldForceLynxNetwork(const std::string& url) {
  if (IsTemplateUrlInSettingsList(kLynxNetworkBlockList, url)) {
    return false;
  }

  if (IsTemplateUrlInSettingsList(kLynxNetworkAllowList, url)) {
    return true;
  }

  return GetForceLynxNetworkByDefault();
}
}  // namespace

void RequestInterceptor::SetTemplateUrl(const std::string& url) {
  force_enable_ = ShouldForceLynxNetwork(url);
}

bool IsNetworkResponse(const ModuleCallback* callback) {
  return callback->module_name_ == "bridge" &&
         callback->method_name_ == "call" &&
         (callback->first_arg_ == "x.request" ||
          callback->first_arg_ == "fetch");
}

bool IsNetworkRequest(const std::string& module_name,
                      const std::string& method_name, Runtime* rt,
                      const piper::Value* args, size_t count) {
  if (module_name != "bridge" || method_name != "call") {
    return false;
  }
  if (count != 3 || args == nullptr) {
    return false;
  }
  if (!args[0].isString()) {
    return false;
  }
  std::string first_arg = args[0].getString(*rt).utf8(*rt);
  bool is_not_network_jsb = first_arg != "x.request" && first_arg != "fetch";
  if (is_not_network_jsb) {
    return false;
  }
  if (!args[1].isObject()) {
    return false;
  }
  auto data_opt = args[1].getObject(*rt).getProperty(*rt, "data");
  if (!data_opt || !data_opt->isObject()) {
    return false;
  }
  return true;
}

bool ShouldInterceptNetworkRequest(Runtime* rt,
                                   const std::optional<piper::Value>& data_opt,
                                   bool force_enable) {
  // two switches under 'data' will enable Lynx Network:
  // `enable_lynx_network` or `enable_lynx_network_with_url_encoded`

  TRACE_EVENT_INSTANT(
      LYNX_TRACE_CATEGORY_JSB, "NetworkModuleCalled",
      [&](lynx::perfetto::EventContext ctx) {
        auto url_object = data_opt->getObject(*rt).getProperty(*rt, "url");
        auto method_object =
            data_opt->getObject(*rt).getProperty(*rt, "method");

        if (url_object->isString()) {
          auto* debug = ctx.event()->add_debug_annotations();
          debug->set_name("url");
          debug->set_string_value(url_object->getString(*rt).utf8(*rt));
        }
        if (method_object->isString()) {
          auto* debug = ctx.event()->add_debug_annotations();
          debug->set_name("method");
          debug->set_string_value(method_object->getString(*rt).utf8(*rt));
        }
      });

  // `enable_lynx_network` is old switch for compatible usages
  // `enable_lynx_network_with_url_encoded` enable LynxNetwork with
  //    `urlencoded` as default content type
  //
  // If both switch isn't given by Front-End, we will use `force_enable`,
  // given by settings. Also, we don't want to incluence request using
  // prefetch or protobuf serialized by Host.
  // TODO(huzhanbo): remove force_enable when we fully switch to LynxNetwork
  auto enable =
      data_opt->getObject(*rt).getProperty(*rt, "enable_lynx_network");
  auto enable_with_url_encoded = data_opt->getObject(*rt).getProperty(
      *rt, "enable_lynx_network_with_url_encoded");

  if ((!enable || enable->isUndefined()) &&
      (!enable_with_url_encoded || enable_with_url_encoded->isUndefined())) {
    // Skip Host/Container-implemented prefetch API
    auto use_prefetch =
        data_opt->getObject(*rt).getProperty(*rt, "usePrefetch");
    if (use_prefetch && use_prefetch->isBool() && use_prefetch->getBool()) {
      return false;
    }

    // Skip protobuf serialized by Host.
    auto pb_extras = data_opt->getObject(*rt).getProperty(*rt, "pb_extras");
    if (pb_extras && pb_extras->isObject()) {
      auto pb_enable = pb_extras->getObject(*rt).getProperty(*rt, "enable");
      if (pb_enable && pb_enable->isBool() && pb_enable->getBool()) {
        return false;
      }
    }
    return force_enable;
  }

  return (enable->isBool() && enable->getBool()) ||
         (enable_with_url_encoded->isBool() &&
          enable_with_url_encoded->getBool());
}

bool IsValidRequestBody(Runtime* rt, const std::optional<piper::Value>& body,
                        const std::optional<piper::Value>& body_type) {
  if (body && body->isObject()) {
    return true;
  }

  if (body_type && body_type->isString() &&
      body_type->getString(*rt).utf8(*rt) == "base64") {
    return body && body->isString();
  }

  return false;
}

// serialize body as application/x-protobuf, if:
//  `bodyType` is `arraybuffer`, return it directly
//  `bodyType` is `base64`, decode it
std::string SerializeXProtobuf(Runtime* rt, const piper::Value& body,
                               const std::optional<piper::Value>& body_type) {
  // If front-end specifies body type, then use it. Otherwise, use `base64` as
  // default, since `arraybuffer` isn't supported on Android by `x.request`,
  // which means only in few cases `arraybuffer` can be used.
  if (body_type && body_type->isString() &&
      body_type->getString(*rt).utf8(*rt) == "arraybuffer") {
    auto array_buffer_obj = body.getObject(*rt);
    if (!array_buffer_obj.isArrayBuffer(*rt)) {
      rt->reportJSIException(
          JSINativeException("Serializing x-protobuf, bodyType is arraybuffer "
                             "but body is not arraybuffer"));
      return {};
    }
    auto array_buffer = array_buffer_obj.getArrayBuffer(*rt);
    return std::string(reinterpret_cast<const char*>(array_buffer.data(*rt)),
                       array_buffer.length(*rt));
  }

  if (!body.isString()) {
    rt->reportJSIException(
        JSINativeException("Serializing x-protobuf, bodyType is not "
                           "arraybuffer and body is not string"));
    return {};
  }
  auto body_string = body.getString(*rt).utf8(*rt);
  return modp_b64_decode(body_string);
}

// Create request body by its content-type
std::string SerializeRequestBody(Runtime* rt, const std::string& content_type,
                                 const piper::Value& body,
                                 const std::optional<piper::Value>& body_type) {
  std::string body_string;
  if (content_type.rfind("application/json") == 0) {
    // encode in JSON
    auto val_opt = body.toJsonString(*rt);
    if (val_opt && val_opt->isString()) {
      body_string = val_opt->getString(*rt).utf8(*rt);
    } else {
      rt->reportJSIException(JSINativeException(
          "network_module SerializeRequestBody error: try to convert "
          "js value to Json string by JSON.stringify fail!"));
    }
  } else if (content_type.rfind("application/x-www-form-urlencoded") == 0) {
    // encode in url-encoded
    body_string = UrlEncode(rt, body);
  } else if (content_type.rfind("application/x-protobuf") == 0) {
    // encode in x-protobuf
    body_string = SerializeXProtobuf(rt, body, body_type);
  } else {
    rt->reportJSIException(
        JSINativeException("network_module SerializeRequestBody error: "
                           "unsupported content-type : " +
                           content_type));
  }
  return body_string;
}

std::shared_ptr<LynxModule> CreateNetworkModule(LynxModuleBinding* binding) {
  // All network call will be redirect to the module called `__LynxNetwork`,
  // which should be registered in platform layer.
  return binding->GetModule("__LynxNetwork");
}

namespace {

std::optional<piper::Value> ObjectGetIgnoreCase(Runtime* rt,
                                                const piper::Object& object,
                                                const std::string& field) {
  auto object_keys_opt = object.getPropertyNames(*rt);
  if (!object_keys_opt) {
    rt->reportJSIException(JSINativeException("Get ObjectGetIgnoreCase fail."));
    return {};
  }
  for (int i = 0; i < object_keys_opt->size(*rt); i++) {
    auto object_key_opt = object_keys_opt->getValueAtIndex(*rt, i);
    if (!object_key_opt || !object_key_opt->isString()) {
      continue;
    }
    String value = object_key_opt->getString(*rt);
    std::string key = value.utf8(*rt);
    std::transform(key.begin(), key.end(), key.begin(), ::tolower);
    if (key == field) {
      return object.getProperty(*rt, value);
    }
  }
  return {};
}

// Get content-type by iterating through Http header, return "" when no
// vialable content-type.
std::string ContentTypeFromHeaders(const piper::Object& object, Runtime* rt) {
  auto content_type_value = ObjectGetIgnoreCase(rt, object, "content-type");
  if (content_type_value && content_type_value->isString()) {
    return content_type_value->getString(*rt).utf8(*rt);
  } else if (content_type_value && !content_type_value->isUndefined()) {
    rt->reportJSIException(JSINativeException(
        "network_module error: content-type's value in header "
        "is not string type."));
  }
  return "";
}

// Deserialize response body depending on its content-type, while
// consuming the original input
std::optional<piper::Value> DeserializeResponseBody(
    Runtime* rt, const std::string& content_type,
    const std::string& body_string) {
  if (content_type.rfind("application/json") == 0) {
    // content type is a json.
    auto val_opt = piper::Value::createFromJsonUtf8(
        *rt, reinterpret_cast<const uint8_t*>(body_string.data()),
        body_string.size());
    if (!val_opt) {
      rt->reportJSIException(JSINativeException(
          "network_module FillResponseBody error: try to create "
          "js value from Json string fail!"));
      return {};
    }
    return val_opt;
  } else if (content_type.rfind("application/x-www-form-urlencoded") == 0) {
    // content type is urlencoded
    auto val_opt = UrlDecode(rt, body_string);
    if (!val_opt) {
      rt->reportJSIException(JSINativeException(
          "network_module FillResponseBody error: try to create "
          "js value from url encoded form fail!"));
      return {};
    }
    return val_opt;
  } else if (content_type.rfind("application/x-protobuf") == 0) {
    // content type is x-protobuf, pass binary data as arraybuffer
    return piper::ArrayBuffer(
        *rt, reinterpret_cast<const uint8_t*>(body_string.data()),
        body_string.size());
  } else {
    // now we assume type is a plain text.
    return piper::String::createFromUtf8(
        *rt, reinterpret_cast<const uint8_t*>(body_string.data()),
        body_string.size());
  }
  return {};
}

// Will fill response with properties added by Host App instead of server side
void PolyfillResponse(Runtime* rt, const piper::Value& resp,
                      const Value& headers) {
  // In response header, there is a field named x-tt-logid/X-Tt-logid/X-TT-Logid
  // etc. This field is used for Front-End to track log. Due to its confusing
  // naming, JSB in Host extracts it in advance and uses `_AME_Header_RequestID`
  // to represent it. Now we will also support it to prevent missing ability of
  // tracking log.
  if (!headers.isObject()) {
    return;
  }

  const auto& log_id =
      ObjectGetIgnoreCase(rt, headers.getObject(*rt), "x-tt-logid");
  if (log_id && resp.isObject()) {
    resp.getObject(*rt).setProperty(*rt, "_AME_Header_RequestID", *log_id);
  }
}

// Convert response body to JS Object by its type
bool FillResponseBody(Runtime* rt, const Value& headers,
                      const std::string& body_data, piper::Object& data) {
  auto content_type = ContentTypeFromHeaders(headers.getObject(*rt), rt);
  piper::String body_string = piper::String::createFromAscii(*rt, body_data);
  data.setProperty(*rt, "rawResponse", body_string);
  auto body = DeserializeResponseBody(rt, content_type, body_data);
  if (!body) {
    data.setProperty(*rt, "clientCode", kJSONParseFailure);
    return false;
  }
  PolyfillResponse(rt, *body, headers);
  data.setProperty(*rt, "response", *body);
  if (content_type.rfind("application/x-protobuf") == 0) {
    data.setProperty(*rt, "responseType", "arraybuffer");
  }
  return true;
}

}  // namespace

// Extract content-type from headers and data
std::string GetContentType(Runtime* rt, const std::optional<Value>& headers,
                           const Value& data) {
  // if user defines content type, use it
  if (headers && headers->isObject()) {
    std::string header_content_type =
        ContentTypeFromHeaders(headers->getObject(*rt), rt);
    if (header_content_type != "") {
      return header_content_type;
    }
  }

  auto enable_switch =
      data.getObject(*rt).getProperty(*rt, "enable_lynx_network");
  auto enable =
      enable_switch && enable_switch->isBool() && enable_switch->getBool();
  // the default content-type is json with switch
  // `enable_lynx_network`, otherwise urlencoded, which
  // is conforming to other internal Http requests
  return enable ? "application/json; encoding=utf-8"
                : "application/x-www-form-urlencoded; encoding=utf-8";
}

void SetNetworkCallbackInfo(
    const std::string& module_name, const std::string& method_name, Runtime* rt,
    const piper::Value* args, size_t count,
    const NativeModuleInfoCollectorPtr& timing_collector) {
  if (network::IsNetworkRequest(module_name, method_name, rt, args, count)) {
    const auto& first_arg = args[0].getString(*rt).utf8(*rt);
    const auto& data = args[1].getObject(*rt).getProperty(*rt, "data");
    NetworkRequestInfo info;
    info.jsb_name_ = first_arg;
    info.http_url_ = network::GetBaseUrl(rt, *data);
    info.http_method_ = network::GetHttpMethod(rt, *data);
    timing_collector->SetNetworkRequestInfo(std::move(info));
  }
}

void ReportRequestSuccess(const NativeModuleInfoCollectorPtr& timing,
                          int32_t http_code, bool use_lynx_network) {
  auto info = tasm::PropBundle::Create();
  info->set_tag("lynxsdk_network_jsb_success");
  const auto& network_info = timing->GetNetworkRequestInfo();
  info->SetProps("jsb_name", network_info.jsb_name_.c_str());
  info->SetProps("http_url", network_info.http_url_.c_str());
  info->SetProps("http_method", network_info.http_method_.c_str());
  info->SetProps("request_duration", static_cast<unsigned int>(
                                         base::CurrentSystemTimeMilliseconds() -
                                         timing->GetFuncCallStart()));
  info->SetProps("http_code", http_code);
  info->SetProps("jsb_accomplished_by", use_lynx_network ? "Lynx" : "Host");

  tasm::EventReportTracker::Report(std::move(info));
}

std::string GetHttpMethod(Runtime* rt, const Value& data) {
  // GET is the default Http request type
  auto http_method_obj = data.getObject(*rt).getProperty(*rt, "method");
  if (http_method_obj && http_method_obj->isString()) {
    return http_method_obj->getString(*rt).utf8(*rt);
  }
  return "GET";
}

std::string GetBaseUrl(Runtime* rt, const Value& data) {
  auto url_object = data.getObject(*rt).getProperty(*rt, "url");
  if (url_object && url_object->isString()) {
    const std::string& full_url = url_object->getString(*rt).utf8(*rt);
    return full_url.substr(0, full_url.find("?"));
  }
  return "";
}

int32_t TryGetHttpCode(Runtime* rt, const piper::Value* args, size_t size) {
  if (size != 1 || !args[0].isObject()) {
    return 0;
  }

  const auto& resp = args[0].getObject(*rt);
  const auto& data = resp.getProperty(*rt, "data");
  if (!data || !data->isObject()) {
    return 0;
  }

  const auto& http_code_opt = data->getObject(*rt).getProperty(*rt, "httpCode");
  if (!http_code_opt || !http_code_opt->isNumber()) {
    return 0;
  }
  return http_code_opt->getNumber();
}

// Report network request information
void ReportNetworkRequestInfo(Runtime* rt, const std::string& first_arg,
                              const piper::Value& data, bool use_lynx_network) {
  auto info = tasm::PropBundle::Create();
  info->set_tag("lynxsdk_network_jsb");
  info->SetProps("jsb_name", first_arg.c_str());

  info->SetProps("jsb_accomplished_by", use_lynx_network ? "Lynx" : "Host");

  auto header_key = first_arg == "x.request" ? "header" : "headers";
  auto headers = data.getObject(*rt).getProperty(*rt, header_key);
  if (headers && headers->isObject()) {
    std::string header_content_type =
        ContentTypeFromHeaders(headers->getObject(*rt), rt);
    info->SetProps("content_type_original", header_content_type.c_str());
  } else {
    info->SetProps("content_type_original", "unknown");
  }
  info->SetProps("content_type", GetContentType(rt, headers, data).c_str());

  auto http_method = data.getObject(*rt).getProperty(*rt, "method");
  if (http_method && http_method->isString()) {
    info->SetProps("http_method_original",
                   http_method->getString(*rt).utf8(*rt).c_str());
  } else {
    info->SetProps("http_method_original", "unknown");
  }
  info->SetProps("http_method", GetHttpMethod(rt, data).c_str());

  auto url = GetBaseUrl(rt, data);
  info->SetProps("http_url", url != "" ? url.c_str() : "unknown");

  auto use_prefetch = data.getObject(*rt).getProperty(*rt, "usePrefetch");
  if (use_prefetch && use_prefetch->isBool()) {
    info->SetProps("use_prefetch", use_prefetch->getBool() ? "true" : "false");
  } else {
    info->SetProps("use_prefetch", "unknown");
  }

  auto pb_extras = data.getObject(*rt).getProperty(*rt, "pb_extras");
  info->SetProps("pb_enable", "unknown");
  if (pb_extras && pb_extras->isObject()) {
    auto pb_enable = pb_extras->getObject(*rt).getProperty(*rt, "enable");
    if (pb_enable && pb_enable->isBool()) {
      info->SetProps("pb_enable", pb_enable->getBool() ? "true" : "false");
    }
  }

  tasm::EventReportTracker::Report(std::move(info));
}

// Create return object for app fetch JSB
static Object CreateAppFetchCallbackObject(
    Runtime* rt, bool success, int32_t http_code, int32_t client_code,
    const std::string& error_message, const Value& headers,
    const std::optional<std::string>& body_data) {
  // TODO(huzhanbo): replace with link to Lynx official site
  /*  x-request response specification.
   interface JSBridgeResponse {
    code: number; // 1 | 0  1 success； 0 failure
    message: string;
    data?: {
        code: number; // 1 | 0  1 success； 0 failure
        httpCode?: number, // http status code
        header?: {[key:string]:any}, // response header
        response?: any // server response data
        raw?: any // reference of the same object as `response`
    }
  }*/
  piper::Object obj = piper::Object(*rt);
  piper::Object data = piper::Object(*rt);
  piper::Object raw = piper::Object(*rt);
  piper::String error_message_string =
      piper::String::createFromUtf8(*rt, error_message);
  obj.setProperty(*rt, "message", error_message_string);
  data.setProperty(*rt, "msg", error_message_string);
  data.setProperty(*rt, "httpCode", http_code);
  data.setProperty(*rt, "clientCode", client_code);
  if (success) {
    data.setProperty(*rt, "header", Value(*rt, headers));
    if (body_data) {
      const piper::String& body_string =
          piper::String::createFromAscii(*rt, *body_data);
      obj.setProperty(*rt, "_raw", body_string);
      auto content_type = ContentTypeFromHeaders(headers.getObject(*rt), rt);
      auto val_opt = DeserializeResponseBody(rt, content_type, *body_data);
      if (content_type.rfind("application/x-protobuf") == 0) {
        data.setProperty(*rt, "responseType", "arraybuffer");
      }
      success = val_opt && val_opt->isObject();
      if (!success) {
        rt->reportJSIException(
            JSINativeException("network_module error: try to create "
                               "js raw object for fetch fail!"));
        data.setProperty(*rt, "clientCode", kJSONParseFailure);
      } else {
        PolyfillResponse(rt, *val_opt, headers);
        raw = val_opt->getObject(*rt);
      }
    }
  }
  auto code = success ? kNetworkRequestSuccess : kNetworkRequestFailure;
  obj.setProperty(*rt, "code", code);
  data.setProperty(*rt, "code", code);
  data.setProperty(*rt, "response", raw);
  data.setProperty(*rt, "raw", raw);
  obj.setProperty(*rt, "data", data);
  return obj;
}

// Create return object for request JSB
Object CreateXRequestCallbackObject(
    Runtime* rt, bool success, int32_t http_code, int32_t client_code,
    const std::string& error_message, const Value& headers,
    const std::optional<std::string>& body_data) {
  // TODO(huzhanbo): replace with link to Lynx official site
  /*  x-request response specification.
   interface JSBridgeResponse {
    code: number; // 1 | 0  1 success； 0 failure
    msg?: string;
    data?: {
        httpCode?: number, // http status code
        clientCode?: number, // network lib error code
        header?: {[key:string]:any}, // response header
        response?: any // server response data
        responseType?: "base64" | "arraybuffer" // android only base64
        rawResponse?: string //
    }
  }*/
  piper::Object obj = piper::Object(*rt);
  piper::Object data = piper::Object(*rt);
  data.setProperty(*rt, "httpCode", http_code);
  data.setProperty(*rt, "clientCode", client_code);
  if (success) {
    data.setProperty(*rt, "header", headers);
    if (body_data) {
      success = FillResponseBody(rt, headers, *body_data, data);
    }
    obj.setProperty(*rt, "msg",
                    success
                        ? "success"
                        : "TTNetworkErrorCodeNetworkJsonResultNotDictionary");
  } else {
    piper::String error_message_string =
        piper::String::createFromUtf8(*rt, error_message);
    obj.setProperty(*rt, "msg", error_message_string);
    data.setProperty(*rt, "response", error_message_string);
  }
  obj.setProperty(*rt, "code",
                  success ? kNetworkRequestSuccess : kNetworkRequestFailure);
  obj.setProperty(*rt, "data", data);
  return obj;
}

Object CreateCallbackObject(ModuleCallbackType type, Runtime* rt, bool success,
                            int32_t http_code, int32_t client_code,
                            const std::string& error_message,
                            const Value& headers,
                            const std::optional<std::string>& body_data) {
  // When request uses invalid domain, TTNet gives -1 on iOS but 0 on Android,
  // other cases can't neither give same result on both iOS and Android. This
  // non standard Http code may confuse developers, thus use 0 instead.
  if (http_code < 100 || http_code > 599) {
    http_code = 0;
  }
  switch (type) {
    case ModuleCallbackType::Request:
      return CreateXRequestCallbackObject(rt, success, http_code, client_code,
                                          error_message, headers, body_data);
    case ModuleCallbackType::Fetch:
      return CreateAppFetchCallbackObject(rt, success, http_code, client_code,
                                          error_message, headers, body_data);
    default:
      return piper::Object(*rt);
  }
}

static void ResponseWithErrorMessage(Runtime* rt, Function func,
                                     const char* error_message) {
  piper::Scope scope(*rt);
  piper::Object obj = piper::Object(*rt);
  obj.setProperty(*rt, "code", 0);
  obj.setProperty(*rt, "msg", error_message);
  func.call(*rt, obj);
}

/**
  * args specification:
  * first argument: 'x.request' or 'app.fetch',
  * second argument: {"data":{
    "addCommonParams": true,  // only used in x.request
    "url": "string",
    "method": "string",
    "body": {},
    "params": {},
    "header": {}
    "enable_lynx_network": true
  }}
  * third argument: (res)=>{ }
  */
ModuleInterceptorResult RequestInterceptor::InterceptModuleMethod(
    LynxModule* module, LynxModule::MethodMetadata* method, Runtime* rt,
    const std::shared_ptr<piper::ModuleDelegate>& delegate,
    const piper::Value* args, size_t count) const {
  uint64_t jsb_func_call_start = lynx::base::CurrentSystemTimeMilliseconds();
  if (!IsNetworkRequest(module->name_, method->name, rt, args, count)) {
    return {false, Value::null()};
  }
  std::string first_arg = args[0].getString(*rt).utf8(*rt);
  auto data = args[1].getObject(*rt).getProperty(*rt, "data");

  bool useLynxNetwork = ShouldInterceptNetworkRequest(rt, data, force_enable_);
  ReportNetworkRequestInfo(rt, first_arg, data->getObject(*rt), useLynxNetwork);
  if (!useLynxNetwork) {
    return {false, Value::null()};
  }

  uint64_t start_time = lynx::base::CurrentTimeMilliseconds();
  uint64_t jsb_func_convert_params_start =
      lynx::base::CurrentSystemTimeMilliseconds();
  bool has_callback =
      (args + 2)->isObject() && (args + 2)->getObject(*rt).isFunction(*rt);
  if (!has_callback) {
    return {true, Value::null()};
  }

  Function function = (args + 2)->getObject(*rt).getFunction(*rt);

  auto url_object = data->getObject(*rt).getProperty(*rt, "url");
  if (!url_object || !url_object->isString()) {
    ResponseWithErrorMessage(rt, std::move(function), "http url not found.");
    return {true, Value::null()};
  }

  auto http_method = String::createFromUtf8(*rt, GetHttpMethod(rt, *data));

  String url = url_object->getString(*rt);
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "Network::SendNetworkRequest",
              [rt, &http_method, &url_object](perfetto::EventContext ctx) {
                auto* method = ctx.event()->add_debug_annotations();
                method->set_name("method");
                method->set_string_value(http_method.utf8(*rt));
                auto* url = ctx.event()->add_debug_annotations();
                url->set_name("url");
                url->set_string_value(url_object->getString(*rt).utf8(*rt));
              });
  ModuleCallbackType type = first_arg == "x.request"
                                ? ModuleCallbackType::Request
                                : ModuleCallbackType::Fetch;
  auto timing_collector = std::make_shared<piper::NativeModuleInfoCollector>(
      delegate, module->name_, method->name, first_arg);
  NetworkRequestInfo info = {first_arg, GetBaseUrl(rt, *data),
                             http_method.utf8(*rt)};
  timing_collector->SetNetworkRequestInfo(std::move(info));

#if ENABLE_ARK_RECORDER
  network_module_->StartRecordFunction(method->name);
#endif
  ModuleInterceptorResult interceptor_result = NetworkRequest(
      rt, timing_collector, *data, url, http_method, std::move(function),
      start_time, jsb_func_convert_params_start, jsb_func_call_start, type);
#if ENABLE_ARK_RECORDER
  Value res(*rt, interceptor_result.result);
  network_module_->EndRecordFunction(method->name, count, args, rt, res);
#endif
  return interceptor_result;
}

}  // namespace network

}  // namespace piper
}  // namespace lynx
