// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/js_debug/quickjs_base/inspector_client_quickjs_base.h"

#include <map>
#include <memory>

#include "base/json/json_util.h"
#include "jsbridge/js_debug/debug_helper.h"
#include "jsbridge/js_debug/script_manager.h"

namespace lynx {
namespace devtool {
void Channel::SetClient(const std::shared_ptr<InspectorClient>& sp) {
  client_wp_ = sp;
}

void Channel::DispatchProtocolMessage(const std::string& message) {
  if (session_ != nullptr) {
    session_->dispatchProtocolMessage(message);
  }
}

void Channel::SchedulePauseOnNextStatement(const std::string& reason) {
  if (session_ != nullptr) {
    session_->schedulePauseOnNextStatement(reason, reason);
  }
}

void Channel::CancelPauseOnNextStatement() {
  if (session_ != nullptr) {
    session_->cancelPauseOnNextStatement();
  }
}

void Channel::SendResponseToClient(const std::string& message, int view_id) {
  auto sp = client_wp_.lock();
  if (sp != nullptr) {
    sp->SendResponse(message, view_id);
  }
}

InspectorClientQuickJSBase::InspectorClientQuickJSBase(ClientType type)
    : InspectorClient(type) {}

void InspectorClientQuickJSBase::SetBreakpointWhenReload(int view_id) {
  auto& script_manager = GetScriptManagerByViewId(view_id);
  if (script_manager != nullptr) {
    std::map<std::string, Breakpoint> breakpoint =
        script_manager->GetBreakpoint();
    if (breakpoint.empty()) {
      return;
    }
    for (const auto& bp : breakpoint) {
      rapidjson::Document content(rapidjson::kObjectType);
      content.AddMember(rapidjson::Value(kKeyId, content.GetAllocator()),
                        rapidjson::Value(0), content.GetAllocator());
      content.AddMember(rapidjson::Value(kKeyMethod, content.GetAllocator()),
                        rapidjson::Value(kMethodDebuggerSetBreakpointByUrl,
                                         content.GetAllocator()),
                        content.GetAllocator());
      rapidjson::Document params(rapidjson::kObjectType);
      params.AddMember(
          rapidjson::Value(kKeyUrl, params.GetAllocator()),
          rapidjson::Value(bp.second.url_.c_str(), params.GetAllocator()),
          params.GetAllocator());
      params.AddMember(
          rapidjson::Value(kKeyCondition, params.GetAllocator()),
          rapidjson::Value(bp.second.condition_.c_str(), params.GetAllocator()),
          params.GetAllocator());
      params.AddMember(rapidjson::Value(kKeyLineNumber, params.GetAllocator()),
                       rapidjson::Value(bp.second.line_number_),
                       params.GetAllocator());
      params.AddMember(
          rapidjson::Value(kKeyColumnNumber, params.GetAllocator()),
          rapidjson::Value(bp.second.column_number_), params.GetAllocator());
      content.AddMember(rapidjson::Value(kKeyParams, content.GetAllocator()),
                        params, content.GetAllocator());
      DispatchMessageFromFrontendSync(base::ToJson(content), view_id);
    }
    auto active_mes =
        GetMessageSetBreakpointsActive(script_manager->GetBreakpointsActive());
    DispatchMessageFromFrontendSync(active_mes, view_id);
  }
}

void InspectorClientQuickJSBase::DispatchMessageStop(int view_id) {
  auto& script_manager = GetScriptManagerByViewId(view_id);
  if (script_manager != nullptr) {
    script_manager->ClearScriptId();
  }
  rapidjson::Document content(rapidjson::kObjectType);
  rapidjson::Document params(rapidjson::kObjectType);
  content.AddMember(rapidjson::Value(kKeyId, content.GetAllocator()),
                    rapidjson::Value(0), content.GetAllocator());
  content.AddMember(
      rapidjson::Value(kKeyMethod, content.GetAllocator()),
      rapidjson::Value(kMethodDebuggerSetSkipAllPauses, content.GetAllocator()),
      content.GetAllocator());
  params.AddMember(rapidjson::Value(kKeySkip, params.GetAllocator()),
                   rapidjson::Value(true), params.GetAllocator());
  content.AddMember(rapidjson::Value(kKeyParams, content.GetAllocator()),
                    params, content.GetAllocator());
  DispatchMessageFromFrontend(base::ToJson(content), view_id);
  if (!running_nested_loop_) return;
  content.AddMember(
      rapidjson::Value(kKeyMethod, content.GetAllocator()),
      rapidjson::Value(kMethodDebuggerResume, content.GetAllocator()),
      content.GetAllocator());
  content.RemoveMember(kKeyParams);
  DispatchMessageFromFrontend(base::ToJson(content), view_id);
}

void InspectorClientQuickJSBase::DispatchMessageFromFrontendSync(
    const std::string& message, int view_id) {
  auto& channel = GetChannelByViewId(view_id);
  if (channel != nullptr) {
    channel->DispatchProtocolMessage(message);
  }
}

void InspectorClientQuickJSBase::quitMessageLoopOnPause() { QuitPause(); }

void InspectorClientQuickJSBase::Pause() {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    running_nested_loop_ = true;
    waiting_for_message_ = true;
  }

  while (waiting_for_message_) {
    FlushMessageQueue();
    if (waiting_for_message_) {
      std::unique_lock<std::mutex> lock(mutex_);
      cv_.wait(lock);
    }
  }
}

void InspectorClientQuickJSBase::QuitPause() {
  std::lock_guard<std::mutex> lock(mutex_);
  running_nested_loop_ = false;
  waiting_for_message_ = false;
}

void InspectorClientQuickJSBase::FlushMessageQueue() {
  while (!message_queue_.empty()) {
    std::string mes = "";
    int view_id;
    {
      std::lock_guard<std::mutex> lock(message_queue_mutex_);
      const auto& pair = message_queue_.front();
      view_id = pair.first;
      mes = pair.second;
      message_queue_.pop();
    }
    DispatchMessageFromFrontendSync(mes, view_id);
  }
}

void InspectorClientQuickJSBase::SetStopAtEntry(bool stop_at_entry,
                                                int view_id) {
  const auto& channel = GetChannelByViewId(view_id);
  if (channel != nullptr) {
    if (stop_at_entry) {
      channel->SchedulePauseOnNextStatement(kStopAtEntryReason);
    } else {
      channel->CancelPauseOnNextStatement();
    }
  }
}

}  // namespace devtool
}  // namespace lynx
