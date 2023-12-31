// Copyright 2019 The Lynx Authors. All rights reserved.
#include "devtool/quickjs/protocols.h"

#include "devtool/quickjs/debugger/debugger.h"
#include "devtool/quickjs/debugger/debugger_breakpoint.h"
#include "devtool/quickjs/debugger/debugger_callframe.h"
#include "devtool/quickjs/debugger/debugger_properties.h"
#include "devtool/quickjs/debugger/debugger_queue.h"
#include "devtool/quickjs/debugger_inner.h"
#include "devtool/quickjs/heapprofiler/heapprofiler.h"
#include "devtool/quickjs/interface.h"
#include "devtool/quickjs/runtime/runtime.h"
#ifdef ENABLE_QUICKJS_CPU_PROFILER
#include "devtool/quickjs/profiler/tracing_cpu_profiler.h"
#endif

typedef void (*func_ptr)(struct DebuggerParams *);
using debug_function_type =
    std::unordered_map<const char *, func_ptr, hash_func, cmp>;
using debug_step_type =
    std::unordered_map<const char *, uint8_t, hash_func, cmp>;

unsigned int DEKHash(const char *str, unsigned int length) {
  unsigned int hash = length;
  unsigned int i = 0;

  for (i = 0; i < length; ++str, ++i) {
    hash = ((hash << 5) ^ (hash >> 27)) ^ (*str);
  }

  return hash;
}

const debug_function_type &GetDebugFunctionMap() {
  static const debug_function_type debugger_function_map = {
      {"Debugger.getPossibleBreakpoints", HandleGetPossibleBreakpoints},
      {"Debugger.setBreakpointsActive", HandleSetBreakpointActive},
      {"Debugger.setBreakpoint", SetBreakpointByURL},
      {"Debugger.setBreakpointByUrl", SetBreakpointByURL},
      {"Debugger.evaluateOnCallFrame", HandleEvaluateOnCallFrame},
      {"Debugger.removeBreakpoint", HandleRemoveBreakpoint},
      {"Debugger.stepInto", HandleStep},
      {"Debugger.stepOver", HandleStep},
      {"Debugger.stepOut", HandleStep},
      {"Debugger.resume", HandleResume},
      {"Debugger.enable", HandleEnable},
      {"Debugger.stopAtEntry", HandleStopAtEntry},
      {"Debugger.getScriptSource", HandleGetScriptSource},
      {"Debugger.pause", HandlePause},
      {"Debugger.disable", HandleDisable},
      {"Debugger.continueToLocation", HandleContinueToLocation},
      {"Debugger.setAsyncCallStackDepth", HandleSetAsyncCallStackDepth},
      {"Debugger.setVariableValue", HandleSetVariableValue},
      {"Debugger.setPauseOnExceptions", HandleSetPauseOnExceptions},
      {"Debugger.setSkipAllPauses", HandleSkipAllPauses},
      {"Runtime.getProperties", HandleGetProperties},
      {"Runtime.evaluate", HandleEvaluate},
      {"Runtime.callFunctionOn", HandleCallFunctionOn},
      {"Runtime.enable", HandleRuntimeEnable},
      {"Runtime.disable", HandleRuntimeDisable},
      {"Runtime.discardConsoleEntries", HandleDiscardConsoleEntries},
      {"Runtime.compileScript", HandleCompileScript},
      {"Runtime.globalLexicalScopeNames", HandleGlobalLexicalScopeNames},
      {"Runtime.runScript", HandleRunScript},
      {"Runtime.setAsyncCallStackDepth", HandleSetAsyncCallStackDepth},
      // HeapProfiler begin
      {"HeapProfiler.takeHeapSnapshot", HandleHeapProfilerProtocols},
  // HeapProfiler end
#ifdef ENABLE_QUICKJS_CPU_PROFILER
      {"Profiler.setSamplingInterval", HandleSetSamplingInterval},
      {"Profiler.start", HandleProfilerStart},
      {"Profiler.stop", HandleProfilerStop},
      {"Profiler.enable", HandleProfilerEnable},
      {"Profiler.disable", HandleProfilerDisable},
#endif
  };
  return debugger_function_map;
}

const debug_step_type &GetDebuggerStepMap() {
  static const debug_step_type debugger_step_map = {
      {"Debugger.stepInto", DEBUGGER_STEP_IN},
      {"Debugger.stepOver", DEBUGGER_STEP},
      {"Debugger.stepOut", DEBUGGER_STEP_OUT}};
  return debugger_step_map;
}

void DoInspectorCheck(LEPUSContext *ctx) {
  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
  if (!info) return;

  int32_t status = LEPUS_DEBUGGER_RUN;
  if (info->is_debugger_enabled) {
    LEPUSBreakpoint *bp = NULL;
    status = DebuggerNeedProcess(info, ctx, bp);
    if (!(status == LEPUS_DEBUGGER_RUN ||
          status == LEPUS_DEBUGGER_PROCESS_MESSAGE)) {
      const uint8_t *cur_pc = GetInspectorCurrentPC(ctx);
      if (status == LEPUS_DEBUGGER_PAUSED) {  // pause because of stepping
        SendPausedEvent(info, cur_pc, LEPUS_UNDEFINED, "debugCommand");
      } else {  // pause because of breakpoints
        PauseAtBreakpoint(info, bp, cur_pc);
      }
    }
  }

  if (info->message_queue &&
      (status == LEPUS_DEBUGGER_RUN ||
       status == LEPUS_DEBUGGER_PROCESS_MESSAGE)) {  // process normal
    //     get messages from front end and process it
    GetProtocolMessages(ctx);
    ProcessProtocolMessages(info);
  }
}

// for shared context qjs debugger: send script parsed event with view id
void SendScriptParsedNotificationWithViewID(LEPUSContext *ctx,
                                            LEPUSScriptSource *script,
                                            int32_t view_id) {
  LEPUSValue script_parsed_params = GetMultiScriptParsedInfo(ctx, script);
  if (!LEPUS_IsUndefined(script_parsed_params)) {
    SendNotification(ctx, "Debugger.scriptParsed", script_parsed_params,
                     view_id);
  }
}

// when compile a script success, send scriptparsed notification
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-scriptParsed
void SendScriptParsedNotification(LEPUSContext *ctx,
                                  LEPUSScriptSource *script) {
  LEPUSValue script_parsed_params = GetMultiScriptParsedInfo(ctx, script);
  if (!LEPUS_IsUndefined(script_parsed_params)) {
    SendNotification(ctx, "Debugger.scriptParsed", script_parsed_params);
  }
}

// for shared context qjs debugger: send script fail to parse event with view id
void SendScriptFailToParseNotificationWithViewID(LEPUSContext *ctx,
                                                 LEPUSScriptSource *script,
                                                 int32_t view_id) {
  LEPUSValue script_failed_parse_param = GetMultiScriptParsedInfo(ctx, script);
  DebuggerFreeScript(ctx, script);
  if (!LEPUS_IsUndefined(script_failed_parse_param)) {
    SendNotification(ctx, "Debugger.scriptFailedToParse",
                     script_failed_parse_param, view_id);
  }
}

void SendScriptFailToParseNotification(LEPUSContext *ctx,
                                       LEPUSScriptSource *script) {
  LEPUSValue script_failed_parse_param = GetMultiScriptParsedInfo(ctx, script);
  DebuggerFreeScript(ctx, script);
  if (!LEPUS_IsUndefined(script_failed_parse_param)) {
    SendNotification(ctx, "Debugger.scriptFailedToParse",
                     script_failed_parse_param);
  }
}

// handle protocols using function map
void HandleProtocols(LEPUSContext *ctx, LEPUSValue message,
                     const char *method) {
  if (!method) return;
  struct DebuggerParams params = {ctx, message, 0};
  auto debugger_step_map = GetDebuggerStepMap();
  auto step_iter = debugger_step_map.find(method);
  if (step_iter != debugger_step_map.end()) {
    params.type = step_iter->second;
  }
  auto debugger_function_map = GetDebugFunctionMap();
  auto func_iter = debugger_function_map.find(method);
  if (func_iter != debugger_function_map.end()) {
    func_iter->second(&params);
  } else {
    LEPUSValue result = LEPUS_NewObject(ctx);
    if (!LEPUS_IsException(result)) {
      SendResponse(ctx, message, result);
    }
  }
}

// push msg to message queue, and process it
void PushAndProcessProtocolMessages(LEPUSDebuggerInfo *info, const char *msg) {
  struct queue *debugger_queue = GetDebuggerMessageQueue(info);
  if (debugger_queue) {
    PushBackQueue(debugger_queue, msg);
    ProcessProtocolMessages(info);
  }
}

static bool NeedStackFrameExist(LEPUSContext *ctx, const char *method,
                                LEPUSValue message, LEPUSValue message_method) {
  bool res = strcmp(method, "Debugger.stopAtEntry") == 0;
  if (res) {
    LEPUS_FreeCString(ctx, method);
    LEPUS_FreeValue(ctx, message_method);
  }
  return res;
}

enum ProcessMessageResult { MESSAGE_NULL, NEED_FIRST_STACK_FRAME, SUCCESS };

static ProcessMessageResult ProcessMessage(LEPUSContext *ctx,
                                           LEPUSStackFrame *sf, queue *mq,
                                           LEPUSValue message) {
  LEPUSValue message_method = LEPUS_GetPropertyStr(ctx, message, "method");
  const char *method = LEPUS_ToCString(ctx, message_method);
  // handle protocol messages
  if (!method) {
    LEPUS_FreeValue(ctx, message_method);
    PopFrontQueue(mq);
    return MESSAGE_NULL;
  }
  if (!sf && NeedStackFrameExist(ctx, method, message, message_method)) {
    return NEED_FIRST_STACK_FRAME;
  } else {
    PopFrontQueue(mq);
  }

  // handle protocol messages
  HandleProtocols(ctx, message, method);

  LEPUS_FreeCString(ctx, method);
  LEPUS_FreeValue(ctx, message_method);
  return SUCCESS;
}

// for shared context qjs debugger: need to send this view_id to front end
// through sendResponse
void ProcessProtocolMessagesWithViewID(LEPUSDebuggerInfo *info,
                                       int32_t view_id) {
  // get protocol message from message queue
  auto *mq = GetDebuggerMessageQueue(info);
  LEPUSContext *ctx = info->ctx;
  auto *sf = GetStackFrame(ctx);
  while (!QueueIsEmpty(mq)) {
    char *message_str = GetFrontQueue(mq);
    if (message_str && message_str[0] != '\0') {
      LEPUSValue message =
          LEPUS_ParseJSON(ctx, message_str, strlen(message_str), "");

      LEPUS_SetPropertyStr(ctx, message, "view_id",
                           LEPUS_NewInt32(ctx, view_id));
      auto process_result = ProcessMessage(ctx, sf, mq, message);
      LEPUS_FreeValue(ctx, message);
      if (process_result == MESSAGE_NULL) {
        continue;
      } else if (process_result == NEED_FIRST_STACK_FRAME) {
        return;
      }
    }
    free(message_str);
    message_str = NULL;
  }
}

/**
 * get a protocol from message queue, process it
 * read the protocol head and dispatch to different handler
 */
void ProcessProtocolMessages(LEPUSDebuggerInfo *info) {
  // get protocol message from message queue
  auto *mq = GetDebuggerMessageQueue(info);
  LEPUSContext *ctx = info->ctx;
  auto *sf = GetStackFrame(ctx);
  while (!QueueIsEmpty(mq)) {
    char *message_str = GetFrontQueue(mq);
    if (message_str) {
      LEPUSValue message =
          LEPUS_ParseJSON(ctx, message_str, strlen(message_str), "");
      auto process_result = ProcessMessage(ctx, sf, mq, message);
      LEPUS_FreeValue(ctx, message);
      if (process_result == MESSAGE_NULL) {
        continue;
      } else if (process_result == NEED_FIRST_STACK_FRAME) {
        return;
      }
    }
    free(message_str);
    message_str = NULL;
  }
}

/**
 * @brief given result, send response protocols
 * @param message use this message to get message id.
 * @param result response result
 */
void SendResponse(LEPUSContext *ctx, LEPUSValue message, LEPUSValue result) {
  LEPUSValue id = LEPUS_GetPropertyStr(ctx, message, "id");
  int32_t message_id = 0;
  LEPUS_ToInt32(ctx, &message_id, id);
  auto *info = GetDebuggerInfo(ctx);
  LEPUSObject *p =
      DebuggerCreateObjFromShape(info, info->debugger_obj->response);
  uint32_t idx = 0;
  SetFixedShapeObjValue(ctx, p, idx++, id);
  SetFixedShapeObjValue(ctx, p, idx++, result);
  LEPUSValue response = LEPUS_MKPTR(LEPUS_TAG_OBJECT, p);

  LEPUSValue lepus_response = LEPUS_ToJSON(ctx, response, 0);
  const char *response_message = LEPUS_ToCString(ctx, lepus_response);
  LEPUS_FreeValue(ctx, lepus_response);
  LEPUS_FreeValue(ctx, response);
  LEPUSValue view_id_val = LEPUS_GetPropertyStr(ctx, message, "view_id");
  int32_t view_id = -1;
  if (!LEPUS_IsUndefined(view_id_val)) {
    LEPUS_ToInt32(ctx, &view_id, view_id_val);
    LEPUS_FreeValue(ctx, view_id_val);
  }
  if (!response_message) {
    return;
  }
  if (view_id != -1) {
    SendProtocolResponseWithViewID(ctx, message_id, response_message, view_id);
  } else {
    SendProtocolResponse(ctx, message_id, response_message);
  }

  LEPUS_FreeCString(ctx, response_message);
}

/**
 * @brief given result, send notification protocols
 * @param method nofitication method
 * @param params nofitication parameters
 */
void SendNotification(LEPUSContext *ctx, const char *method, LEPUSValue params,
                      int32_t view_id) {
  auto *info = GetDebuggerInfo(ctx);
  LEPUSObject *p =
      DebuggerCreateObjFromShape(info, info->debugger_obj->notification);
  uint32_t idx = 0;
  SetFixedShapeObjValue(ctx, p, idx++, LEPUS_NewString(ctx, method));
  SetFixedShapeObjValue(ctx, p, idx++, params);
  LEPUSValue notification = LEPUS_MKPTR(LEPUS_TAG_OBJECT, p);
  LEPUSValue notification_json = LEPUS_ToJSON(ctx, notification, 0);
  const char *ntf_msg = LEPUS_ToCString(ctx, notification_json);
  LEPUS_FreeValue(ctx, notification);
  LEPUS_FreeValue(ctx, notification_json);
  if (ntf_msg) {
    if (view_id == -1) {
      SendProtocolNotification(ctx, ntf_msg);
    } else {
      SendProtocolNotificationWithViewID(ctx, ntf_msg, view_id);
    }
    LEPUS_FreeCString(ctx, ntf_msg);
  }
}

bool CheckEnable(LEPUSContext *ctx, LEPUSValue message, ProtocolType protocol) {
  LEPUSValue view_id_val = LEPUS_GetPropertyStr(ctx, message, "view_id");
  int32_t view_id = -1;
  if (!LEPUS_IsUndefined(view_id_val)) {
    LEPUS_ToInt32(ctx, &view_id, view_id_val);
    LEPUS_FreeValue(ctx, view_id_val);
  }

  bool ret = true;
  if (view_id != -1) {
    GetSessionEnableState(ctx, view_id, static_cast<int32_t>(protocol), &ret);
    return ret;
  }

  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
  switch (protocol) {
    case DEBUGGER_ENABLE:
    case DEBUGGER_DISABLE:
      ret = info->is_debugger_enabled > 0;
      break;
    case RUNTIME_DISABLE:
    case RUNTIME_ENABLE:
      ret = info->is_runtime_enabled > 0;
      break;
    case PROFILER_ENABLE:
    case PROFILER_DISABLE:
      ret = info->is_profiling_enabled > 0;
      break;
    default:
      break;
  }
  return ret;
}
