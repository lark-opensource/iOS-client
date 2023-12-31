// Copyright 2019 The Lynx Authors. All rights reserved./
#ifndef LYNX_LEPUS_DEBUGGER_BASE_H_
#define LYNX_LEPUS_DEBUGGER_BASE_H_

#include <string>

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace lepus {
class VMContext;
class Function;
class Context;

// base class of debugger
class DebuggerBase {
 public:
  DebuggerBase() = default;
  virtual ~DebuggerBase() = default;

  // process protocol message sent here when then paused
  virtual void ProcessPausedMessages(lepus::Context* context,
                                     const std::string& message) = 0;

  // lepus debugger interface
  virtual void ProcessDebuggerMessages(int32_t current_pc){};
  virtual void SetVMContext(VMContext* context){};
  // send messages to the debugger
  virtual void SendMessagesToDebugger(const std::string& message){};
  // get all the functions in this context
  virtual void GetAllFunctions(Function* r) {}
  virtual bool IsFuncsEmpty() { return true; }
  virtual void PrepareDebugInfo() {}
  virtual void SetDebugInfo(const std::string& debug_info) {}

  // lepusNG debugger interface
  virtual void DebuggerSendNotification(Context* context, const char* message) {
  }
  virtual void DebuggerSendResponse(Context* ctx, int32_t message_id,
                                    const char* message) {}
  virtual void DebuggerRunMessageLoopOnPause(Context* context) {}
  virtual void DebuggerQuitMessageLoopOnPause(Context* context) {}
  virtual void DebuggerGetMessages(Context* context) {}
  virtual void InspectorCheck(Context* context) {}
  // call if there is an exception during debug. we will send a paused
  virtual void DebuggerException(Context* context) {}
  virtual void DebuggerFree(Context* context) {}
  virtual void DebuggerInitialize(Context* context) {}
  virtual void DebuggerSendConsoleMessage(lepus::Context* ctx,
                                          LEPUSValue* message) {}
  virtual void DebuggerSendScriptParsedMessage(lepus::Context* ctx,
                                               LEPUSScriptSource* script) {}
  virtual void DebuggerSendScriptFailToParseMessage(lepus::Context* ctx,
                                                    LEPUSScriptSource* script) {
  }
};

}  // namespace lepus
}  // namespace lynx
#endif  // LYNX_LEPUS_DEBUGGER_BASE_H_
