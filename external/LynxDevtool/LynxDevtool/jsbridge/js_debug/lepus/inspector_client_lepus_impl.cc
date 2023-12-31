// Copyright 2021 The Lynx Authors. All rights reserved.

#include "jsbridge/js_debug/lepus/inspector_client_lepus_impl.h"

#include <map>
#include <memory>

#include "base/json/json_util.h"
#include "jsbridge/js_debug/debug_helper.h"
#include "jsbridge/js_debug/inspector_lepus_debugger.h"
#include "jsbridge/js_debug/lepus/lepus_debugger.h"
#include "jsbridge/js_debug/lepusng/debugger/lepusng_debugger.h"
#include "jsbridge/js_debug/script_manager.h"
#include "lepus/context.h"
#include "lepus/debugger_base.h"

namespace lynx {
namespace devtool {

LepusChannelImpl::LepusChannelImpl(lepus_inspector::LepusInspector *inspector) {
  if (inspector != nullptr) {
    session_ = inspector->connect(1, this, "");
  }
}

void LepusChannelImpl::sendResponse(int call_id, const std::string &message) {
  LOGI("lepus debug: LepusChannelImpl::sendResponse: " << message);
  SendResponseToClient(message, kDefaultViewID);
}

void LepusChannelImpl::sendNotification(const std::string &message) {
  LOGI("lepus debug: LepusChannelImpl::sendNotification: " << message);
  SendResponseToClient(message, kDefaultViewID);
}

InspectorClientLepusImpl::InspectorClientLepusImpl(ClientType type)
    : InspectorClientQuickJSBase(type) {
  script_manager_ = std::make_unique<ScriptManager>();
  LOGI("create InspectorClientLepusImpl");
}

InspectorClientLepusImpl::~InspectorClientLepusImpl() = default;

void InspectorClientLepusImpl::SetLepusDebugger(
    std::shared_ptr<InspectorLepusDebugger> debugger) {
  lepus_debugger_ = debugger;
}

void InspectorClientLepusImpl::SetLepusContext(
    const std::shared_ptr<lepus::Context> &context) {
  context_ = context;
  auto debugger = lepus_debugger_.lock();
  std::string debug_info;
  if (debugger != nullptr) {
    int target_num = debugger->GetTargetNum();
    target_id_ = kLepusTargetIdPrefix + std::to_string(target_num);
    session_id_ = kLepusSessionIdPrefix + std::to_string(target_num);

    debug_info = debugger->GetDebugInfo();
  }

// init lepus debugger
#if !ENABLE_JUST_LEPUSNG
  if (context->IsVMContext()) {
    std::shared_ptr<lepus::DebuggerBase> lepus_debugger =
        std::make_shared<lepus::Debugger>();
    lepus_debugger->SetDebugInfo(debug_info);
    context->SetDebugger(lepus_debugger);
    engine_type_ = kKeyEngineLepus;
  }
#endif
  if (context->IsLepusNGContext()) {
    std::shared_ptr<lepus::DebuggerBase> lepusng_debugger =
        std::make_shared<debug::LepusNGDebugger>();
    lepusng_debugger->SetDebugInfo(debug_info);
    context->SetDebugger(lepusng_debugger);
    engine_type_ = kKeyEngineLepusNG;
  }
  inspector_ = lepus_inspector::LepusInspector::create(context.get(), this);
  ConnectFrontend();
}

void InspectorClientLepusImpl::ConnectFrontend(int view_id) {
  channel_ = std::static_pointer_cast<Channel>(
      std::make_shared<LepusChannelImpl>(inspector_.get()));
  channel_->SetClient(shared_from_this());

  auto debugger = lepus_debugger_.lock();
  if (debugger != nullptr && debugger->IsEnableNeeded()) {
    debugger->ResponseFromJSEngine(
        GetMessageTargetCreated(target_id_, kLepusTargetTitle));
    debugger->ResponseFromJSEngine(
        GetMessageAttachedToTarget(target_id_, session_id_, kLepusTargetTitle));
  }
}

void InspectorClientLepusImpl::DisconnectFrontend(int view_id) {
  channel_.reset();
  inspector_.reset();

  auto debugger = lepus_debugger_.lock();
  if (debugger != nullptr && debugger->IsEnableNeeded()) {
    debugger->ResponseFromJSEngine(
        GetMessageDetachFromTarget(target_id_, session_id_));
    debugger->ResponseFromJSEngine(GetMessageTargetDestroyed(target_id_));
  }
}

void InspectorClientLepusImpl::DispatchMessageFromFrontend(
    const std::string &message, int view_id) {
  LOGI("lepus debug: InspectorClientLepusImpl::DispatchMessageFromFrontend: "
       << message);
  rapidjson::Document map_message;
  if (!ParseStrToJson(map_message, message)) {
    return;
  }
  auto messages = GetMessagePostedToJSEngine(map_message);
  std::lock_guard<std::mutex> lock(message_queue_mutex_);
  for (const auto &m : messages) {
    message_queue_.push(std::make_pair(view_id, m));
  }
  std::lock_guard<std::mutex> read_lock(mutex_);
  if (running_nested_loop_) {
    LOGI("lepus debug: condition signal");
    cv_.notify_all();
  } else {
    auto context = context_.lock();
    if (context != nullptr && context->HasFinishedExecution()) {
      InspectorLepusDebugger::RunOnMainThread([context]() {
        LEPUS_Eval(context->context(), kLepusTriggerScript,
                   strlen(kLepusTriggerScript), kLepusTriggerFileName,
                   LEPUS_EVAL_TYPE_GLOBAL);
      });
    }
  }
}

void InspectorClientLepusImpl::SendResponse(const std::string &message,
                                            int view_id) {
  auto lepus_debugger = lepus_debugger_.lock();
  auto messages = GetMessagePosterToChrome(message);
  if (lepus_debugger != nullptr) {
    for (const auto &m : messages) {
      lepus_debugger->ResponseFromJSEngine(m);
    }
  }
}

void InspectorClientLepusImpl::runMessageLoopOnPause(
    const std::string &context_group_id) {
  LOGI("lepus debug: InspectorClientLepusImpl::runMessageLoopOnPause");
  if (running_nested_loop_) return;
  Pause();
}

std::queue<std::string> InspectorClientLepusImpl::getMessageFromFrontend() {
  std::queue<std::string> mes;
  while (!message_queue_.empty()) {
    std::lock_guard<std::mutex> lock(message_queue_mutex_);
    mes.push(message_queue_.front().second);
    message_queue_.pop();
  }
  return mes;
}

const std::unique_ptr<ScriptManager>
    &InspectorClientLepusImpl::GetScriptManagerByViewId(int view_id) {
  return script_manager_;
}

const std::shared_ptr<Channel> &InspectorClientLepusImpl::GetChannelByViewId(
    int view_id) {
  return channel_;
}

std::vector<std::string> InspectorClientLepusImpl::GetMessagePosterToChrome(
    const std::string &message) {
  auto res = std::vector<std::string>();
  rapidjson::Document content;
  if (!ParseStrToJson(content, message)) {
    return res;
  }
  if (!session_id_.empty()) {
    content.AddMember(rapidjson::Value(kKeySessionId, content.GetAllocator()),
                      rapidjson::Value(session_id_, content.GetAllocator()),
                      content.GetAllocator());
  }

  if (content.FindMember(kKeyId) != content.MemberEnd() &&
      content[kKeyId].GetInt() == 0) {
    return res;
  } else if (content.FindMember(kKeyMethod) != content.MemberEnd() &&
             strcmp(content[kKeyMethod].GetString(),
                    kEventDebuggerScriptParsed) == 0 &&
             script_manager_ != nullptr) {
    std::string id = content[kKeyParams][kKeyScriptId].GetString();
    script_manager_->AddScriptId(id);
  } else if (content.FindMember(kKeyId) != content.MemberEnd() &&
             script_manager_ != nullptr) {
    script_manager_->SetBreakpointId(content);
  }

  if (content.FindMember(kKeyResult) != content.MemberEnd() &&
      content[kKeyResult].FindMember(kKeyDebuggerId) !=
          content[kKeyResult].MemberEnd()) {
    content[kKeyResult].AddMember(
        rapidjson::Value(kKeyEngineType, content.GetAllocator()),
        rapidjson::Value(engine_type_, content.GetAllocator()),
        content.GetAllocator());
  }
  if (script_manager_ != nullptr) {
    content = script_manager_->MapScriptId(content, true, false);
  }

  res.push_back(base::ToJson(content));
  return res;
}

std::vector<std::string> InspectorClientLepusImpl::GetMessagePostedToJSEngine(
    rapidjson::Value &message) {
  auto res = std::vector<std::string>();
  GetMessageWithoutSessionId(message);
  if (message.MemberCount() == 0) {
    return res;
  }
  rapidjson::Document map_message;
  if (script_manager_ != nullptr) {
    map_message = script_manager_->MapScriptId(message, false, true);
  }

  std::string method = map_message[kKeyMethod].GetString();
  if (method == kMethodDebuggerSetBreakpointsActive &&
      script_manager_ != nullptr) {
    bool active = map_message[kKeyParams][kKeyActive].GetBool();
    script_manager_->SetBreakpointsActive(active);
  } else if (method == kMethodDebuggerSetBreakpointByUrl &&
             script_manager_ != nullptr) {
    script_manager_->SetBreakpointDetail(map_message);
  } else if (method == kMethodDebuggerRemoveBreakpoint &&
             script_manager_ != nullptr) {
    script_manager_->RemoveBreakpoint(
        map_message[kKeyParams][kKeyBreakpointId].GetString());
  }
  res.push_back(base::ToJson(map_message));
  return res;
}

void InspectorClientLepusImpl::GetMessageWithoutSessionId(
    rapidjson::Value &message) {
  if (message.HasMember(kKeySessionId)) {
    message.RemoveMember(kKeySessionId);
  }
}

}  // namespace devtool
}  // namespace lynx
