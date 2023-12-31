// Copyright 2019 The Lynx Authors. All rights reserved.

#include "inspector_client.h"

#include <mutex>
#include <unordered_map>

#include "base/json/json_util.h"
#include "base/no_destructor.h"
#include "base/threading/thread_local.h"
#include "jsbridge/js_debug/debug_helper.h"
#include "jsbridge/js_debug/inspector_js_env_provider.h"
#include "jsbridge/js_debug/lepus/inspector_lepus_env_provider.h"
#include "jsbridge/js_debug/quickjs/inspector_quickjs_env_provider.h"

#if defined(OS_ANDROID) || defined(OS_WIN)
#include "jsbridge/js_debug/v8/inspector_v8_env_provider.h"
#endif  // defined(OS_ANDROID) || defined(OS_WIN)

namespace lynx {
namespace devtool {
InspectorJsEnvProvider* InspectorClient::v8_provider_ = nullptr;
InspectorJsEnvProvider* InspectorClient::qjs_provider_ = nullptr;
InspectorJsEnvProvider* InspectorClient::lepus_provider_ = nullptr;

std::shared_ptr<InspectorClient> InspectorClientProvider::CreateInspectorClient(
    DebugType debug_type, ClientType client_type, bool shared_vm) {
  static base::NoDestructor<std::mutex> map_lock;
  std::lock_guard<std::mutex> lock(*map_lock);
  switch (debug_type) {
    case lepus_debug:
      return InspectorClient::CreateInspectorClient(debug_type, client_type);
    case v8_debug:
      static base::NoDestructor<
          std::unordered_map<std::string, std::shared_ptr<InspectorClient>>>
          shared_vm_v8_client_;
      if (shared_vm && client_type != JsWorkerClient) {
        auto thread_type = kThreadJS;
        if (shared_vm_v8_client_->find(thread_type) ==
            shared_vm_v8_client_->end()) {
          (*shared_vm_v8_client_)[thread_type] =
              InspectorClient::CreateInspectorClient(debug_type, client_type);
        }
        return (*shared_vm_v8_client_)[thread_type];
      } else {
        return InspectorClient::CreateInspectorClient(debug_type, client_type);
      }
    case quickjs_debug: {
      if (client_type == JsWorkerClient) {
        return InspectorClient::CreateInspectorClient(debug_type, client_type);
      }
      static base::NoDestructor<
          std::unordered_map<std::string, std::shared_ptr<InspectorClient>>>
          shared_vm_qjs_client_;
      auto thread_type = kThreadJS;
      if (shared_vm_qjs_client_->find(thread_type) ==
          shared_vm_qjs_client_->end()) {
        (*shared_vm_qjs_client_)[thread_type] =
            InspectorClient::CreateInspectorClient(debug_type, client_type);
      }
      return (*shared_vm_qjs_client_)[thread_type];
    }
    default:
      return nullptr;
  }
}

std::shared_ptr<InspectorClient> InspectorClient::CreateInspectorClient(
    DebugType debug_type, ClientType client_type) {
  if (debug_type == lepus_debug) {
    if (!GetLepusEnvProvider()) {
      LOGI("InspectorLepusEnvProvider not set, return default nullptr");
      return nullptr;
    }
    return GetLepusEnvProvider()->MakeInspectorClient(client_type);
  } else {
    if (!GetJsEnvProvider(debug_type)) {
      LOGI("InspectorJSEnvProvider not set, return default nullptr");
      return nullptr;
    }
    return GetJsEnvProvider(debug_type)->MakeInspectorClient(client_type);
  }
}

void InspectorClient::CreateJsEnvProvider(DebugType type) {
#if defined(OS_ANDROID) || defined(OS_WIN)
  if (type == v8_debug && v8_provider_ == nullptr) {
    v8_provider_ = new InspectorV8EnvProvider();
  }
#endif
#if defined(OS_ANDROID) || \
    (defined(OS_IOS) && !(defined(__i386__) || defined(__arm__)))
  if (type == quickjs_debug && qjs_provider_ == nullptr) {
    qjs_provider_ = new InspectorQuickjsEnvProvider();
  }
#endif
}

void InspectorClient::CreateLepusEnvProvider() {
  if (lepus_provider_ == nullptr) {
    lepus_provider_ = new InspectorLepusEnvProvider();
  }
}

void InspectorClient::SetJsEnvProvider(InspectorJsEnvProvider* c) {
  v8_provider_ = c;
}

InspectorJsEnvProvider* InspectorClient::GetJsEnvProvider(DebugType type) {
  if (type == v8_debug) {
    return v8_provider_;
  } else {
    return qjs_provider_;
  }
}

InspectorJsEnvProvider* InspectorClient::GetLepusEnvProvider() {
  return lepus_provider_;
}

void InspectorClient::DispatchMessageEnable(int view_id, bool runtime_enable) {
  DispatchMessageFromFrontendSync(GetSimpleMessage(kMethodDebuggerEnable),
                                  view_id);
  if (runtime_enable) {
    DispatchMessageFromFrontendSync(GetSimpleMessage(kMethodRuntimeEnable),
                                    view_id);
  }
  DispatchMessageFromFrontendSync(GetSimpleMessage(kMethodProfilerEnable),
                                  view_id);

  SendMessageProfileEnabled(view_id);
  SetBreakpointWhenReload(view_id);
}

void InspectorClient::DispatchDebuggerDisable(int view_id) {
  DispatchMessageFromFrontend(GetSimpleMessage(kMethodDebuggerDisable),
                              view_id);
}

std::string InspectorClient::GetSimpleMessage(const std::string& method,
                                              int message_id) {
  rapidjson::Document document(rapidjson::kObjectType);
  document.AddMember(rapidjson::Value(kKeyId, document.GetAllocator()),
                     rapidjson::Value(message_id), document.GetAllocator());
  document.AddMember(rapidjson::Value(kKeyMethod, document.GetAllocator()),
                     rapidjson::Value(method, document.GetAllocator()),
                     document.GetAllocator());
  return base::ToJson(document);
}

std::string InspectorClient::GetMessageSetBreakpointsActive(bool active,
                                                            int message_id) {
  rapidjson::Document content(rapidjson::kObjectType);
  content.AddMember(rapidjson::Value(kKeyId, content.GetAllocator()),
                    rapidjson::Value(message_id), content.GetAllocator());
  content.AddMember(rapidjson::Value(kKeyMethod, content.GetAllocator()),
                    rapidjson::Value(kMethodDebuggerSetBreakpointsActive,
                                     content.GetAllocator()),
                    content.GetAllocator());
  rapidjson::Document params(rapidjson::kObjectType);
  params.AddMember(rapidjson::Value(kKeyActive, params.GetAllocator()),
                   rapidjson::Value(active), params.GetAllocator());
  content.AddMember(rapidjson::Value(kKeyParams, content.GetAllocator()),
                    params, content.GetAllocator());
  return base::ToJson(content);
}

rapidjson::Document InspectorClient::GetTargetInfo(const std::string& target_id,
                                                   const std::string& title) {
  rapidjson::Document info(rapidjson::kObjectType);
  info.AddMember(rapidjson::Value(kKeyTargetId, info.GetAllocator()),
                 rapidjson::Value(target_id, info.GetAllocator()),
                 info.GetAllocator());
  info.AddMember(rapidjson::Value(kKeyType, info.GetAllocator()),
                 rapidjson::Value("worker", info.GetAllocator()),
                 info.GetAllocator());
  info.AddMember(rapidjson::Value(kKeyTitle, info.GetAllocator()),
                 rapidjson::Value(title, info.GetAllocator()),
                 info.GetAllocator());
  info.AddMember(rapidjson::Value(kKeyUrl, info.GetAllocator()),
                 rapidjson::Value("", info.GetAllocator()),
                 info.GetAllocator());
  info.AddMember(rapidjson::Value(kKeyAttached, info.GetAllocator()),
                 rapidjson::Value(false), info.GetAllocator());
  info.AddMember(rapidjson::Value(kKeyCanAccessOpener, info.GetAllocator()),
                 rapidjson::Value(false), info.GetAllocator());
  return info;
}

std::string InspectorClient::GetMessageTargetCreated(
    const std::string& target_id, const std::string& title) {
  rapidjson::Document document(rapidjson::kObjectType);
  document.AddMember(
      rapidjson::Value(kKeyMethod, document.GetAllocator()),
      rapidjson::Value(kEventTargetCreated, document.GetAllocator()),
      document.GetAllocator());
  rapidjson::Document params(rapidjson::kObjectType);
  auto info = GetTargetInfo(target_id, title);
  params.AddMember(rapidjson::Value(kKeyTargetInfo, params.GetAllocator()),
                   info, params.GetAllocator());
  document.AddMember(rapidjson::Value(kKeyParams, document.GetAllocator()),
                     params, document.GetAllocator());

  return base::ToJson(document);
}

std::string InspectorClient::GetMessageAttachedToTarget(
    const std::string& target_id, const std::string& session_id,
    const std::string& title) {
  rapidjson::Document document(rapidjson::kObjectType);
  document.AddMember(
      rapidjson::Value(kKeyMethod, document.GetAllocator()),
      rapidjson::Value(kEventAttachedToTarget, document.GetAllocator()),
      document.GetAllocator());
  rapidjson::Document params(rapidjson::kObjectType);
  auto info = GetTargetInfo(target_id, title);
  info[kKeyAttached] = true;
  params.AddMember(rapidjson::Value(kKeySessionId, params.GetAllocator()),
                   rapidjson::Value(session_id, params.GetAllocator()),
                   params.GetAllocator());
  params.AddMember(rapidjson::Value(kKeyTargetInfo, params.GetAllocator()),
                   info, params.GetAllocator());
  params.AddMember(
      rapidjson::Value(kKeyWaitingForDebugger, params.GetAllocator()),
      rapidjson::Value(true), params.GetAllocator());
  document.AddMember(rapidjson::Value(kKeyParams, document.GetAllocator()),
                     params, document.GetAllocator());

  return base::ToJson(document);
}

std::string InspectorClient::GetMessageTargetDestroyed(
    const std::string& target_id) {
  rapidjson::Document document(rapidjson::kObjectType);
  document.AddMember(
      rapidjson::Value(kKeyMethod, document.GetAllocator()),
      rapidjson::Value(kEventTargetDestroyed, document.GetAllocator()),
      document.GetAllocator());
  rapidjson::Document params(rapidjson::kObjectType);
  params.AddMember(rapidjson::Value(kKeyTargetId, params.GetAllocator()),
                   rapidjson::Value(target_id, params.GetAllocator()),
                   params.GetAllocator());
  document.AddMember(rapidjson::Value(kKeyParams, document.GetAllocator()),
                     params, document.GetAllocator());

  return base::ToJson(document);
}

std::string InspectorClient::GetMessageDetachFromTarget(
    const std::string& target_id, const std::string& session_id) {
  rapidjson::Document document(rapidjson::kObjectType);
  document.AddMember(
      rapidjson::Value(kKeyMethod, document.GetAllocator()),
      rapidjson::Value(kEventDetachedFromTarget, document.GetAllocator()),
      document.GetAllocator());
  rapidjson::Document params(rapidjson::kObjectType);
  params.AddMember(rapidjson::Value(kKeySessionId, params.GetAllocator()),
                   rapidjson::Value(session_id, params.GetAllocator()),
                   params.GetAllocator());
  params.AddMember(rapidjson::Value(kKeyTargetId, params.GetAllocator()),
                   rapidjson::Value(target_id, params.GetAllocator()),
                   params.GetAllocator());
  document.AddMember(rapidjson::Value(kKeyParams, document.GetAllocator()),
                     params, document.GetAllocator());

  return base::ToJson(document);
}

bool InspectorClient::ParseStrToJson(rapidjson::Document& json_mes,
                                     const std::string& mes) {
  json_mes = base::strToJson(mes.c_str());
  if (json_mes.HasParseError()) {
    LOGE("js debug: parse json str error! original str: " << mes);
    return false;
  }
  return true;
}

}  // namespace devtool
}  // namespace lynx
