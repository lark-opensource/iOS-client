// Copyright 2019 The Lynx Authors. All rights reserved./
#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_DEBUGGER_BASE_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_DEBUGGER_BASE_H_

#include <stdint.h>

#include <string>

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace piper {
class QuickjsContextWrapper;
}
namespace debug {

class QuickjsDebuggerBase {
 public:
  QuickjsDebuggerBase() = default;
  ~QuickjsDebuggerBase() = default;

  // debugger related function to interact with lynx devtool
  // send protocol notification to front end
  virtual void DebuggerSendNotification(
      piper::QuickjsContextWrapper* qjs_context_wrapper, const char* message,
      int32_t view_id) {}
  // send protocol response to front end
  virtual void DebuggerSendResponse(
      piper::QuickjsContextWrapper* qjs_context_wrapper, int32_t message_id,
      const char* message) {}
  // pause the vm
  virtual void DebuggerRunMessageLoopOnPause(
      piper::QuickjsContextWrapper* qjs_context_wrapper) {}
  // quit pause
  virtual void DebuggerQuitMessageLoopOnPause(
      piper::QuickjsContextWrapper* qjs_context_wrapper) {}
  // get protocol messages from front end when vm is running
  virtual void DebuggerGetMessages(
      piper::QuickjsContextWrapper* qjs_context_wrapper) {}
  // for each opcode, do inspector check for debugging
  virtual void InspectorCheck(LEPUSContext* ctx) {}
  // handle exception for debugging
  virtual void DebuggerException(LEPUSContext* ctx) {}
  virtual void DebuggerFree(LEPUSContext* ctx, LEPUSDebuggerInfo* info) {}
  // debugger related data structure initialization
  virtual void DebuggerInitialize(LEPUSContext* ctx) {}
  // send Runtime.consoleAPICalled event for console.xxx
  virtual void ConsoleAPICalled(LEPUSContext* ctx, LEPUSValue* message) {}
  // send Debugger.scriptParsed event when vm parses script
  virtual void ScriptParsed(LEPUSContext* ctx, LEPUSScriptSource* script) {}
  // process protocol messages when vm is paused
  virtual void ProcessPausedMessages(LEPUSContext* ctx,
                                     const std::string& message, int32_t){};
  // send Debugger.scriptFailedToParse when vm fails to parse the script
  virtual void ScriptFailToParse(LEPUSContext* ctx, LEPUSScriptSource* script) {
  }

  // send protocol response to front end
  virtual void DebuggerSendResponseWithViewID(
      piper::QuickjsContextWrapper* qjs_context_wrapper, int32_t message_id,
      const char* message, int32_t view_id) {}

  // send console api called event with runtime id
  virtual void ConsoleAPICalledMessageWithRID(LEPUSContext* ctx,
                                              LEPUSValue* message) {}

  // send Debugger.scriptParsed event when vm parses script with view id
  virtual void ScriptParsedWithViewID(LEPUSContext* ctx,
                                      LEPUSScriptSource* script,
                                      int32_t view_id) {}
  // send Debugger.scriptFailedToParse when vm fails to parse the script with
  // view id
  virtual void ScriptFailToParseWithViewID(LEPUSContext* ctx,
                                           LEPUSScriptSource* script,
                                           int32_t view_id) {}
  // get session pause state
  virtual bool GetSessionPaused(
      piper::QuickjsContextWrapper* qjs_context_wrapper) {
    return false;
  }

  // pause on debugger keyword
  virtual void DebuggerPauseOnDebuggerKeyword(LEPUSContext* ctx,
                                              const uint8_t* pc) {}
};
}  // namespace debug
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_DEBUGGER_BASE_H_
