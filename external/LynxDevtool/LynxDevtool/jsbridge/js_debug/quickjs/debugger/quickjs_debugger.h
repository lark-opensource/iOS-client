// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LEPUS_QUICKJS_DEBUGGER_H
#define LEPUS_QUICKJS_DEBUGGER_H

#include "Lynx/jsbridge/quickjs/quickjs_context_wrapper.h"
#include "Lynx/lepus/debugger_base.h"
#include "jsbridge/js_debug/lepus/lepus_inspector_session_impl.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace piper {
class QuickjsContextWrapper;
}

namespace debug {

// for quickjs debugger
class QuickjsDebugger : public QuickjsDebuggerBase {
 public:
  QuickjsDebugger();
  virtual ~QuickjsDebugger() = default;

  // send protocol notification
  void DebuggerSendNotification(
      piper::QuickjsContextWrapper* qjs_context_wrapper, const char* message,
      int32_t view_id) override;
  // send protocol response
  void DebuggerSendResponse(piper::QuickjsContextWrapper* qjs_context_wrapper,
                            int32_t message_id, const char* message) override;
  // pause the vm
  void DebuggerRunMessageLoopOnPause(
      piper::QuickjsContextWrapper* qjs_context_wrapper) override;

  // quit pause and run the vm
  void DebuggerQuitMessageLoopOnPause(
      piper::QuickjsContextWrapper* qjs_context_wrapper) override;

  // for each pc, first call this function for debugging
  void InspectorCheck(LEPUSContext* ctx) override;

  // when there is an exception, call this function for debugger
  void DebuggerException(LEPUSContext* ctx) override;

  // free debugger info
  void DebuggerFree(LEPUSContext* ctx, LEPUSDebuggerInfo* info) override;

  // process protocol message sent here when then paused
  void ProcessPausedMessages(LEPUSContext* ctx, const std::string& message,
                             int32_t view_id) override;

  // initialize related debugger info
  void DebuggerInitialize(LEPUSContext* ctx) override;

  // send console messages
  void ConsoleAPICalled(LEPUSContext* ctx, LEPUSValue* message) override;

  // send script parsed notification
  void ScriptParsed(LEPUSContext* ctx, LEPUSScriptSource* script) override;

  // send script fail to parse notification
  void ScriptFailToParse(LEPUSContext* ctx, LEPUSScriptSource* script) override;

  // send protocol response
  void DebuggerSendResponseWithViewID(
      piper::QuickjsContextWrapper* qjs_context_wrapper, int32_t message_id,
      const char* message, int32_t view_id) override;

  // send console messages with runtime id
  void ConsoleAPICalledMessageWithRID(LEPUSContext* ctx,
                                      LEPUSValue* message) override;

  // send script parsed event with runtime id
  void ScriptParsedWithViewID(LEPUSContext* ctx, LEPUSScriptSource* script,
                              int32_t view_id) override;

  // send script failt to parse event with runtime id
  void ScriptFailToParseWithViewID(LEPUSContext* ctx, LEPUSScriptSource* script,
                                   int32_t view_id) override;

  // get session paused state
  bool GetSessionPaused(
      piper::QuickjsContextWrapper* qjs_context_wrapper) override;

  // pause on debugger keyword
  void DebuggerPauseOnDebuggerKeyword(LEPUSContext* ctx,
                                      const uint8_t* pc) override;
};
}  // namespace debug
}  // namespace lynx
#endif  // LEPUS_QUICKJS_DEBUGGER_H
