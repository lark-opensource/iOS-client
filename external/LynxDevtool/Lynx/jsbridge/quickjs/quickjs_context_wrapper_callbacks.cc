// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/quickjs/quickjs_context_wrapper_callbacks.h"

#include "LynxDevtool/jsbridge/js_debug/lepusng/interface.h"
#include "LynxDevtool/jsbridge/js_debug/quickjs/quickjs_inspector_session_impl.h"
#include "base/lynx_env.h"
#include "jsbridge/quickjs/quickjs_context_wrapper.h"

namespace lynx {
namespace piper {

#define QJSDebuggerCallBack(V)         \
  V(0, RunMessageLoopOnPauseCB)        \
  V(1, QuitMessageLoopOnPauseCB)       \
  V(2, NULL)                           \
  V(3, SendResponseCB)                 \
  V(4, SendNotificationCB)             \
  V(5, FreeMessagesCB)                 \
  V(6, DebuggerExceptionCB)            \
  V(7, InspectorCheckCB)               \
  V(8, ConsoleMessageCB)               \
  V(9, ScriptParsedCB)                 \
  V(10, SendConsoleAPICalledCB)        \
  V(11, ScriptFailToParsedCB)          \
  V(12, DebuggerPauseCB)               \
  V(13, IsRuntimeDevtoolOnCB)          \
  V(14, SendResponseWithViewIDCB)      \
  V(15, SendNtfyWithViewIDCB)          \
  V(16, ScriptParsedWithViewIDCB)      \
  V(17, ScriptFailToParseWithViewIDCB) \
  V(18, SetSessionEnableStateCB)       \
  V(19, GetSessionStateCB)             \
  V(20, SendConsoleAPICalledWithRIDCB)

typedef enum ProtocolType {
  DEBUGGER_ENABLE,
  DEBUGGER_DISABLE,
  RUNTIME_ENABLE,
  RUNTIME_DISABLE,
  PROFILER_ENABLE,
  PROFILER_DISABLE
} ProtocolType;

static bool HasDebugger(QuickjsContextWrapper *qjs_context_wrapper) {
  return qjs_context_wrapper->GetInspector() &&
         qjs_context_wrapper->GetDebugger();
}

// debugger related callbacks
// pause the vm
static void RunMessageLoopOnPauseCB(LEPUSContext *ctx) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->DebuggerRunMessageLoopOnPause(
        qjs_context_wrapper);
  }
}

// quit pause
static void QuitMessageLoopOnPauseCB(LEPUSContext *ctx) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->DebuggerQuitMessageLoopOnPause(
        qjs_context_wrapper);
  }
}

// send response to front end
static void SendResponseCB(LEPUSContext *ctx, int32_t message_id,
                           const char *message) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->DebuggerSendResponse(
        qjs_context_wrapper, message_id, message);
  }
}

// send response to front end
static void SendResponseWithViewIDCB(LEPUSContext *ctx, int32_t message_id,
                                     const char *message, int32_t view_id) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->DebuggerSendResponseWithViewID(
        qjs_context_wrapper, message_id, message, view_id);
  }
}

// send notification to front end
static void SendNtfyWithViewIDCB(LEPUSContext *ctx, const char *message,
                                 int32_t view_id) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->DebuggerSendNotification(
        qjs_context_wrapper, message, view_id);
  }
}

// send notification to front end
static void SendNotificationCB(LEPUSContext *ctx, const char *message) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->DebuggerSendNotification(
        qjs_context_wrapper, message, -1);
  }
}

static void FreeMessagesCB(LEPUSContext *ctx, char **messages, int32_t size) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (qjs_context_wrapper->GetInspector()) {
    for (size_t m_i = 0; m_i < static_cast<size_t>(size); m_i++) {
      free(messages[m_i]);
    }
    free(messages);
  }
}

// for each opcode, do debugger related check
static void InspectorCheckCB(LEPUSContext *ctx) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->InspectorCheck(ctx);
  }
}

// call this function to handle exception
static void DebuggerExceptionCB(LEPUSContext *ctx) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->DebuggerException(ctx);
  }
}

bool IsQuickjsDebugOn() {
  return base::LynxEnv::GetInstance().IsQuickjsDebugEnabled();
}

// if devtool is connected & in quickjs debug mode, return true
static uint8_t IsRuntimeDevtoolOnCB(LEPUSRuntime *rt) {
  return (base::LynxEnv::GetInstance().IsDevtoolConnected() &&
          IsQuickjsDebugOn())
             ? 1
             : 0;
}

// print console.xxx messages
static void ConsoleMessageCB(LEPUSContext *ctx, int tag, LEPUSValueConst *argv,
                             int argc) {
  int i;
  const char *str;

  for (i = 0; i < argc; i++) {
    if (i != 0) putchar(' ');
    str = LEPUS_ToCString(ctx, argv[i]);
    if (!str) return;
    fputs(str, stdout);
    LEPUS_FreeCString(ctx, str);
  }
  putchar('\n');
}

// send Runtime.consoleAPICalled event for console.xxx
static void SendConsoleAPICalledCB(LEPUSContext *ctx, LEPUSValue *console_msg) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->ConsoleAPICalled(ctx, console_msg);
  }
}

// send Runtime.consoleAPICalled event for console.xxx, with runtime id for
// shared context debugger
static void SendConsoleAPICalledWithRIDCB(LEPUSContext *ctx,
                                          LEPUSValue *console_msg) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->ConsoleAPICalledMessageWithRID(
        ctx, console_msg);
  }
}

// send Debugger.scriptFailedToParse when vm fails to parse the script
static void ScriptFailToParseWithViewIDCB(LEPUSContext *ctx,
                                          LEPUSScriptSource *script,
                                          int32_t view_id) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->ScriptFailToParseWithViewID(ctx, script,
                                                                    view_id);
  }
}

// send Debugger.scriptParsed event when vm parses script
static void ScriptParsedWithViewIDCB(LEPUSContext *ctx,
                                     LEPUSScriptSource *script,
                                     int32_t view_id) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->ScriptParsedWithViewID(ctx, script,
                                                               view_id);
  }
}

// send Debugger.scriptFailedToParse when vm fails to parse the script
static void ScriptFailToParsedCB(LEPUSContext *ctx, LEPUSScriptSource *script) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->ScriptFailToParse(ctx, script);
  }
}

static void DebuggerPauseCB(LEPUSContext *ctx, const uint8_t *pc) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->DebuggerPauseOnDebuggerKeyword(ctx, pc);
  }
}

// send Debugger.scriptParsed event when vm parses script
static void ScriptParsedCB(LEPUSContext *ctx, LEPUSScriptSource *script) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    qjs_context_wrapper->GetDebugger()->ScriptParsed(ctx, script);
  }
}

// set session enable state given view id
// if the protocol is Debugger.disable and all the session is in disable mode,
// quit pause
static void SetSessionEnableStateCB(LEPUSContext *ctx, int32_t view_id,
                                    int32_t method_type) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    switch (method_type) {
      case DEBUGGER_ENABLE: {
        // Debugger.enable
        qjs_context_wrapper->SetDebuggerEnableState(view_id, true);
        break;
      }
      case DEBUGGER_DISABLE: {
        // Debugger.disable
        qjs_context_wrapper->SetDebuggerEnableState(view_id, false);
        auto session_enable_map = qjs_context_wrapper->GetEnableMap();
        bool all_session_disable = true;
        for (const auto &session : session_enable_map) {
          if (session.second[0]) {
            all_session_disable = false;
            break;
          }
        }
        // if current context is paused and all the sessions are in disable
        // mode, quit message loop on pause
        bool is_paused = qjs_context_wrapper->paused();
        if (all_session_disable && is_paused) {
          const char *resume_msg = "{'method':'Debugger.resumed', 'params':{}}";
          SendNtfyWithViewIDCB(ctx, resume_msg, view_id);
          QuitMessageLoopOnPauseCB(ctx);
        }
        break;
      }
      case RUNTIME_ENABLE: {
        // Runtime.enable
        qjs_context_wrapper->SetRuntimeEnableState(view_id, true);
        break;
      }
      case RUNTIME_DISABLE: {
        // Runtime.disable
        qjs_context_wrapper->SetRuntimeEnableState(view_id, false);
        break;
      }
      case PROFILER_ENABLE: {
        // Profiler.enable
        qjs_context_wrapper->SetProfilerEnableState(view_id, true);
        break;
      }
      case PROFILER_DISABLE: {
        // Profiler.disable
        qjs_context_wrapper->SetProfilerEnableState(view_id, false);
        break;
      }
      default:
        break;
    }
  }
}

// get session debugger enable state and pause state given view id
static void GetSessionStateCB(LEPUSContext *ctx, int32_t view_id,
                              bool *already_enabled, bool *is_paused) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    auto session_enable_map = qjs_context_wrapper->GetEnableMap();
    *already_enabled = session_enable_map[view_id][0];
    *is_paused = qjs_context_wrapper->GetDebugger()->GetSessionPaused(
        qjs_context_wrapper);
  }
}

// get Debugger/Runtime/ enable state
static __attribute__((unused)) void GetSessionEnableStateCB(LEPUSContext *ctx,
                                                            int32_t view_id,
                                                            int32_t type,
                                                            bool *ret) {
  auto *qjs_context_wrapper = QuickjsContextWrapper::GetFromJsContext(ctx);
  if (HasDebugger(qjs_context_wrapper)) {
    switch (type) {
      case DEBUGGER_ENABLE:
      case DEBUGGER_DISABLE: {
        // debugger
        *ret = qjs_context_wrapper->GetDebuggerEnableState(view_id);
        break;
      }
      case RUNTIME_ENABLE:
      case RUNTIME_DISABLE: {
        // Runtime
        *ret = qjs_context_wrapper->GetRuntimeEnableState(view_id);
        break;
      }
      case PROFILER_ENABLE:
      case PROFILER_DISABLE: {
        // Profiler
        *ret = qjs_context_wrapper->GetProfilerEnableState(view_id);
        break;
      }
      default:
        *ret = true;
        break;
    }
  }
}

// get qjs debugger related callbacks
void **GetQJSCallbackFuncs(int32_t &callback_size) {
  callback_size = 21;
  void **funcs = static_cast<void **>(malloc(sizeof(void *) * callback_size));
  if (!funcs) {
    callback_size = 0;
    return nullptr;
  }
#define CallbackName(index, callback_name) \
  funcs[index] = reinterpret_cast<void *>(callback_name);
  QJSDebuggerCallBack(CallbackName)
#undef CallbackName
      return funcs;
}
}  // namespace piper
}  // namespace lynx
