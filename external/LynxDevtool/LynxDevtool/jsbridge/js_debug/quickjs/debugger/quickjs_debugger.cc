// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/js_debug/quickjs/debugger/quickjs_debugger.h"

#include "Lynx/lepus/lepus_inspector.h"
#include "jsbridge/js_debug/lepusng/interface.h"
#include "jsbridge/js_debug/quickjs/quickjs_inspector_session_impl.h"

#define CAST_SESSION(SESSION) \
  static_cast<lepus_inspector::QJSInspectorSessionImpl*>(SESSION)
#define CAST_INSPECTOR(INSPECTOR) \
  static_cast<lepus_inspector::QJSInspectorImpl*>(INSPECTOR)

namespace lynx {
namespace debug {

QuickjsDebugger::QuickjsDebugger() = default;

void QuickjsDebugger::DebuggerSendNotification(
    piper::QuickjsContextWrapper* qjs_context_wrapper, const char* message,
    int32_t view_id) {
  auto enable_map = qjs_context_wrapper->GetEnableMap();
  if (view_id == -1) {
    // only send to session with is not null and enabled
    for (const auto& session : qjs_context_wrapper->GetSessions()) {
      if (session.second && enable_map[session.first][0]) {
        CAST_SESSION(session.second)->sendProtocolNotification(message);
      }
    }
  } else {
    auto session = qjs_context_wrapper->GetSession(view_id);
    // if session is not null and enabled, send this protocol message
    if (session && enable_map[view_id][0]) {
      CAST_SESSION(session)->sendProtocolNotification(message);
    }
  }
}

void QuickjsDebugger::DebuggerSendResponse(
    piper::QuickjsContextWrapper* qjs_context_wrapper, int32_t message_id,
    const char* message) {
  auto enable_map = qjs_context_wrapper->GetEnableMap();
  for (const auto& session : qjs_context_wrapper->GetSessions()) {
    if (session.second && enable_map[session.first][0]) {
      CAST_SESSION(session.second)->sendProtocolResponse(message_id, message);
    }
  }
}

void QuickjsDebugger::DebuggerRunMessageLoopOnPause(
    piper::QuickjsContextWrapper* qjs_context_wrapper) {
  auto* inspector = qjs_context_wrapper->GetInspector();
  if (inspector) {
    qjs_context_wrapper->set_paused(true);
    CAST_INSPECTOR(inspector)->Client()->runMessageLoopOnPause(
        CAST_INSPECTOR(inspector)->GetGroupID());
    qjs_context_wrapper->set_paused(false);
  }
}

void QuickjsDebugger::DebuggerQuitMessageLoopOnPause(
    piper::QuickjsContextWrapper* qjs_context_wrapper) {
  auto* inspector = qjs_context_wrapper->GetInspector();
  if (inspector) {
    qjs_context_wrapper->set_paused(false);
    CAST_INSPECTOR(inspector)->Client()->quitMessageLoopOnPause();
  }
}

// for each pc, first call this function for debugging
void QuickjsDebugger::InspectorCheck(LEPUSContext* ctx) {
  DoInspectorCheck(ctx);
}

void QuickjsDebugger::DebuggerException(LEPUSContext* ctx) {
  HandleDebuggerException(ctx);
}

void QuickjsDebugger::DebuggerFree(LEPUSContext* ctx, LEPUSDebuggerInfo* info) {
  QJSDebuggerFree(ctx);
}

void QuickjsDebugger::DebuggerInitialize(LEPUSContext* ctx) {
  QJSDebuggerInitialize(ctx);
}

void QuickjsDebugger::ProcessPausedMessages(LEPUSContext* ctx,
                                            const std::string& message,
                                            int32_t view_id) {
  LEPUSDebuggerInfo* info = GetDebuggerInfo(ctx);
  if (!info) return;
  if (message != "") {
    PushBackQueue(GetDebuggerMessageQueue(info), message.c_str());
  }
  ProcessProtocolMessagesWithViewID(info, view_id);
}

void QuickjsDebugger::ConsoleAPICalled(LEPUSContext* ctx, LEPUSValue* message) {
  SendConsoleAPICalledNotification(ctx, message);
}

void QuickjsDebugger::ScriptParsed(LEPUSContext* ctx,
                                   LEPUSScriptSource* script) {
  SendScriptParsedNotification(ctx, script);
}

void QuickjsDebugger::ScriptFailToParse(LEPUSContext* ctx,
                                        LEPUSScriptSource* script) {
  SendScriptFailToParseNotification(ctx, script);
}

// for shared context debugger: send response message with view id
void QuickjsDebugger::DebuggerSendResponseWithViewID(
    piper::QuickjsContextWrapper* qjs_context_wrapper, int32_t message_id,
    const char* message, int32_t view_id) {
  auto* session = qjs_context_wrapper->GetSession(view_id);
  if (session) {
    CAST_SESSION(session)->sendProtocolResponse(message_id, message);
  }
}

// for shared context debugger: send console api called event with runtime id
void QuickjsDebugger::ConsoleAPICalledMessageWithRID(LEPUSContext* ctx,
                                                     LEPUSValue* message) {
  SendConsoleAPICalledNotificationWithRID(ctx, message);
}

bool QuickjsDebugger::GetSessionPaused(
    piper::QuickjsContextWrapper* qjs_context_wrapper) {
  return qjs_context_wrapper->paused();
}

// for shared context debugger: send script parsed event with view id
void QuickjsDebugger::ScriptParsedWithViewID(LEPUSContext* ctx,
                                             LEPUSScriptSource* script,
                                             int32_t view_id) {
  SendScriptParsedNotificationWithViewID(ctx, script, view_id);
}

// for shared context debugger: send script fail to parse with view id
void QuickjsDebugger::ScriptFailToParseWithViewID(LEPUSContext* ctx,
                                                  LEPUSScriptSource* script,
                                                  int32_t view_id) {
  SendScriptFailToParseNotificationWithViewID(ctx, script, view_id);
}

void QuickjsDebugger::DebuggerPauseOnDebuggerKeyword(LEPUSContext* ctx,
                                                     const uint8_t* pc) {
  PauseOnDebuggerKeyword(GetDebuggerInfo(ctx), pc);
}
}  // namespace debug
}  // namespace lynx
