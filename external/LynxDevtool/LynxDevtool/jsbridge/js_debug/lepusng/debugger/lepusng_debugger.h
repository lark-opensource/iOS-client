// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LEPUS_LEPUSNG_DEBUGGER_H
#define LEPUS_LEPUSNG_DEBUGGER_H

#include "jsbridge/js_debug/lepus/lepus_inspector_session_impl.h"
#include "lepus/context.h"
#include "lepus/debugger_base.h"
#include "third_party/rapidjson/document.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace lepus {
class QuickContext;
class Context;
};  // namespace lepus

namespace debug {
// for lepusNG debugger
class LepusNGDebugger : public lepus::DebuggerBase {
 public:
  LepusNGDebugger();
  ~LepusNGDebugger() = default;

  // get debugger info for lepusNG
  void SetDebugInfo(const std::string& debug_info) override;

  void PrepareDebugInfo() override;

  // send protocol notification
  void DebuggerSendNotification(lepus::Context* context,
                                const char* message) override;
  // send protocol response
  void DebuggerSendResponse(lepus::Context* context, int32_t message_id,
                            const char* message) override;
  // pause the vm
  void DebuggerRunMessageLoopOnPause(lepus::Context* context) override;

  // quit pause and run the vm
  void DebuggerQuitMessageLoopOnPause(lepus::Context* context) override;

  // get messages when vm is running
  void DebuggerGetMessages(lepus::Context* context) override;

  // for each pc, first call this function for debugging
  void InspectorCheck(lepus::Context* context) override;

  // when there is an exception, call this function for debugger
  void DebuggerException(lepus::Context* context) override;

  // free debugger info
  void DebuggerFree(lepus::Context* context) override;

  // process protocol message sent here when then paused
  void ProcessPausedMessages(lepus::Context* context,
                             const std::string& message) override;

  // initialize related debugger info
  void DebuggerInitialize(lepus::Context* context) override;
  void DebuggerSendConsoleMessage(lepus::Context* ctx,
                                  LEPUSValue* message) override;

  void DebuggerSendScriptParsedMessage(lepus::Context* ctx,
                                       LEPUSScriptSource* script) override;

  void DebuggerSendScriptFailToParseMessage(lepus::Context* ctx,
                                            LEPUSScriptSource* script) override;

 private:
  lepus::Context* context_;
  // debuginfo
  std::string debug_info_;
};
}  // namespace debug
}  // namespace lynx
#endif  // LEPUS_LEPUSNG_DEBUGGER_H
