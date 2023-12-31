// Copyright 2019 The Lynx Authors. All rights reserved.

#include "devtool/quickjs/debugger/debugger.h"

#include "devtool/quickjs/debugger/debugger_breakpoint.h"
#include "devtool/quickjs/debugger/debugger_callframe.h"
#include "devtool/quickjs/debugger/debugger_properties.h"
#include "devtool/quickjs/debugger/debugger_queue.h"
#include "devtool/quickjs/debugger_inner.h"
#include "devtool/quickjs/interface.h"
#include "devtool/quickjs/protocols.h"

typedef struct DebuggerParams DebuggerParams;

// send Debugger.paused event, do not call run_message_loop_on_pause
static void SendPausedEventWithoutPause(
    LEPUSContext *ctx, LEPUSDebuggerInfo *info, const uint8_t *cur_pc,
    LEPUSValue breakpoint_id, const char *reason, int32_t view_id = -1) {
  LEPUSValue paused_params = LEPUS_NewObject(ctx);
  if (LEPUS_IsException(paused_params)) {
    return;
  }
  // get call stack the virtual machine stopped on
  LEPUSValue callFrames = BuildBacktrace(ctx, cur_pc);
  if (!LEPUS_IsUndefined(callFrames)) {
    DebuggerSetPropertyStr(ctx, paused_params, "callFrames", callFrames);
  }
  LEPUSValue param_reason = LEPUS_NewString(ctx, reason);
  if (!LEPUS_IsException(param_reason)) {
    DebuggerSetPropertyStr(ctx, paused_params, "reason", param_reason);
  }

  if (!LEPUS_IsUndefined(breakpoint_id)) {
    LEPUSValue param_hit_breakpoints = LEPUS_NewArray(ctx);
    LEPUS_SetPropertyUint32(ctx, param_hit_breakpoints, 0,
                            LEPUS_DupValue(ctx, breakpoint_id));
    DebuggerSetPropertyStr(ctx, paused_params, "hitBreakpoints",
                           param_hit_breakpoints);
  }

  // remove breakpoint which specific location flag is true
  if (info->special_breakpoints) {
    int32_t bp_num = info->breakpoints_num;
    for (int32_t i = 0; i < bp_num; i++) {
      LEPUSBreakpoint *bp = info->bps + i;
      if (bp->specific_location) {
        // remove
        DeleteBreakpoint(info, i);
        break;
      }
    }
    info->special_breakpoints = 0;
  }

  // set "data" property if break by exception
  if (reason && strcmp(reason, "exception") == 0) {
    LEPUSValue exception = DebuggerDupException(ctx);
    LEPUSValue remote_object =
        GetRemoteObject(ctx, exception, 0, 0);  // free exception
    DebuggerSetPropertyStr(ctx, paused_params, "data", remote_object);
  }
  // send "Debugger.paused" event
  SendNotification(ctx, "Debugger.paused", paused_params, view_id);
}

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-paused
// send Debugger.paused event, and call run_message_loop_on_pause
void SendPausedEvent(LEPUSDebuggerInfo *info, const uint8_t *cur_pc,
                     LEPUSValue breakpoint_id, const char *reason) {
  LEPUSContext *ctx = info->ctx;
  // if already in pause state, do not need to generate PauseStateScope
  PauseStateScope ps(info);
  {
    SendPausedEventWithoutPause(ctx, info, cur_pc, breakpoint_id, reason);
    RunMessageLoopOnPause(ctx);
  }
}

void HandleDebuggerException(LEPUSContext *ctx) {
  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
  if (!info) return;
  // if no need to pause at exception, return
  if (!info->exception_breakpoint) return;
  const uint8_t *pc = GetInspectorCurrentPC(ctx);
  SendPausedEvent(info, pc, LEPUS_UNDEFINED, "exception");
  ProcessProtocolMessages(info);
}

static void FreeFixedShapeObj(LEPUSDebuggerInfo *info) {
  auto *ctx = info->ctx;
  auto &fixed_shape_obj = info->debugger_obj;
  if (fixed_shape_obj) {
    LEPUS_FreeValue(ctx, fixed_shape_obj->response);
    LEPUS_FreeValue(ctx, fixed_shape_obj->notification);
    LEPUS_FreeValue(ctx, fixed_shape_obj->breakpoint);
    LEPUS_FreeValue(ctx, fixed_shape_obj->bp_location);
    LEPUS_FreeValue(ctx, fixed_shape_obj->result);
    LEPUS_FreeValue(ctx, fixed_shape_obj->preview_prop);
  }
  lepus_free(ctx, fixed_shape_obj);
}

static void FreeStringPool(LEPUSDebuggerInfo *info) {
  auto *ctx = info->ctx;
  if (info->literal_pool) {
    auto *literal_pool = info->literal_pool;
#define DebuggerFreeStringPool(name, str) \
  LEPUS_FreeValue(ctx, literal_pool->name);
    QJSDebuggerStringPool(DebuggerFreeStringPool)
#undef DebuggerFreeStringPool
  }
  lepus_free(ctx, info->literal_pool);
}

static void InitializeShape(LEPUSContext *ctx, LEPUSObject *p, const char *key,
                            uint32_t idx) {
  LEPUSAtom atom = LEPUS_NewAtom(ctx, key);
  add_property(ctx, p, atom, LEPUS_PROP_C_W_E);
  SetFixedShapeObjValue(ctx, p, idx, LEPUS_UNDEFINED);
  LEPUS_FreeAtom(ctx, atom);
}

static void InitFixedShapeResult(LEPUSDebuggerInfo *info) {
  LEPUSContext *ctx = info->ctx;
  info->debugger_obj->result = LEPUS_NewObject(ctx);
  LEPUSObject *p = LEPUS_VALUE_GET_OBJ(info->debugger_obj->result);
  InitializeShape(ctx, p, "result", 0);
}

static void InitFixedShapePreviewProp(LEPUSDebuggerInfo *info) {
  LEPUSContext *ctx = info->ctx;
  info->debugger_obj->preview_prop = LEPUS_NewObject(ctx);
  LEPUSObject *p = LEPUS_VALUE_GET_OBJ(info->debugger_obj->preview_prop);
  InitializeShape(ctx, p, "name", 0);
  InitializeShape(ctx, p, "type", 1);
  InitializeShape(ctx, p, "value", 2);
}

static void InitFixedShapeBPLocation(LEPUSDebuggerInfo *info) {
  LEPUSContext *ctx = info->ctx;
  info->debugger_obj->bp_location = LEPUS_NewObject(ctx);
  LEPUSObject *p = LEPUS_VALUE_GET_OBJ(info->debugger_obj->bp_location);
  InitializeShape(ctx, p, "scriptId", 0);
  InitializeShape(ctx, p, "lineNumber", 1);
  InitializeShape(ctx, p, "columnNumber", 2);
}

static void InitFixedShapeBreakpoint(LEPUSDebuggerInfo *info) {
  LEPUSContext *ctx = info->ctx;
  info->debugger_obj->breakpoint = LEPUS_NewObject(ctx);
  LEPUSObject *p = LEPUS_VALUE_GET_OBJ(info->debugger_obj->breakpoint);
  InitializeShape(ctx, p, "breakpointId", 0);
  InitializeShape(ctx, p, "locations", 1);
}

static void InitFixedShapeNotification(LEPUSDebuggerInfo *info) {
  LEPUSContext *ctx = info->ctx;
  info->debugger_obj->notification = LEPUS_NewObject(ctx);
  LEPUSObject *p = LEPUS_VALUE_GET_OBJ(info->debugger_obj->notification);
  InitializeShape(ctx, p, "method", 0);
  InitializeShape(ctx, p, "params", 1);
}

static void InitFixedShapeResponse(LEPUSDebuggerInfo *info) {
  LEPUSContext *ctx = info->ctx;
  info->debugger_obj->response = LEPUS_NewObject(ctx);
  LEPUSObject *p = LEPUS_VALUE_GET_OBJ(info->debugger_obj->response);
  InitializeShape(ctx, p, "id", 0);
  InitializeShape(ctx, p, "result", 1);
}

static void InitializeFixedShapeObj(LEPUSDebuggerInfo *info) {
  LEPUSContext *ctx = info->ctx;
  info->debugger_obj = static_cast<struct DebuggerFixeShapeObj *>(
      lepus_mallocz_rt(LEPUS_GetRuntime(ctx), sizeof(DebuggerFixeShapeObj)));
  if (info->debugger_obj) {
    InitFixedShapeResponse(info);
    InitFixedShapeNotification(info);
    InitFixedShapeBreakpoint(info);
    InitFixedShapeBPLocation(info);
    InitFixedShapeResult(info);
    InitFixedShapePreviewProp(info);
  } else {
    printf("FAIL TO INITIALIZE DEBUGGER FIXED SHAPE OBJ\n");
    QJSDebuggerFree(ctx);
    DebuggerFree(ctx);
    SetDebuggerMode(0);
  }
}

static void InitializeStringPool(LEPUSDebuggerInfo *info) {
  auto *ctx = info->ctx;
  info->literal_pool = static_cast<struct DebuggerLiteralPool *>(
      lepus_mallocz_rt(LEPUS_GetRuntime(ctx), sizeof(DebuggerLiteralPool)));
  if (info->literal_pool) {
    auto *literal_pool = info->literal_pool;
#define DebuggerInitializeStringPool(name, str) \
  literal_pool->name = LEPUS_NewString(ctx, str);
    QJSDebuggerStringPool(DebuggerInitializeStringPool)
#undef DebuggerInitializeStringPool
  } else {
    printf("FAIL TO INITIALIZE DEBUGGER STRING LITERAL POOL\n");
    QJSDebuggerFree(ctx);
    DebuggerFree(ctx);
    SetDebuggerMode(0);
  }
}

// debugger info initialize
static void DebuggerInfoInitialize(LEPUSDebuggerInfo *info, LEPUSContext *ctx) {
  info->ctx = ctx;
  SetInspectorCurrentPC(ctx, NULL);
  info->breakpoints_num = 0;
  info->breakpoints_is_active = 0;
  info->exception_breakpoint = 0;
  info->step_type = 0;
  info->step_depth = -1;
  info->step_over_valid = 0;
  info->step_statement = false;
  info->next_statement_count = 0;
  info->step_location = static_cast<LEPUSDebuggerLocation *>(
      lepus_malloc_rt(LEPUS_GetRuntime(ctx), sizeof(LEPUSDebuggerLocation)));
  if (info->step_location) {
    info->step_location->line = -1;
    info->step_location->column = -1;
    info->step_location->script_id = -1;
  }
  info->max_async_call_stack_depth = 0;
  info->special_breakpoints = 0;
  info->source_code = NULL;
  info->end_line_num = -1;
  info->is_debugger_enabled = 0;
  info->is_runtime_enabled = 0;
  info->breakpoints_is_active_before = 0;
  info->exception_breakpoint_before = 0;
  info->script_num = 0;
  info->running_state.get_properties_array_len = 0;
  info->running_state.get_properties_array = LEPUS_NewArray(ctx);
  info->cpu_profiling_started = 0;
  info->is_profiling_enabled = 0;
  info->profiler_interval = 100;
  InitializeStringPool(info);
  InitializeFixedShapeObj(info);
}

// debugger initialize
void QJSDebuggerInitialize(LEPUSContext *ctx) {
  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
  if (!info) return;
  info->message_queue = InitQueue();
  DebuggerInfoInitialize(info, ctx);
}

// when pause on debugger keyword, call this function to pause
void PauseOnDebuggerKeyword(LEPUSDebuggerInfo *info, const uint8_t *cur_pc) {
  LEPUSContext *ctx = info->ctx;
  // if already pause on this line due to step, skip this debugger keyword
  if (info->step_type) {
    int32_t line = -1;
    int64_t column = -1;
    int32_t script_id = 0;
    GetDebuggerCurrentLocation(ctx, cur_pc, line, column, script_id);

    auto *step_location = info->step_location;
    int32_t step_line = step_location ? step_location->line : -1;
    int32_t step_script_id = step_location ? step_location->script_id : -1;
    if (step_line == line && script_id == step_script_id) {
      return;
    }
  }
  SendPausedEvent(info, cur_pc, LEPUS_UNDEFINED, "debugCommand");
}

int32_t HandleStepOver(LEPUSDebuggerInfo *info, LEPUSContext *ctx,
                       const uint8_t *cur_pc) {
  // step over: stop if the line number is change or the depth is deeper. else
  // keep running
  int32_t line = -1;
  int64_t column = -1;
  int32_t script_id = 0;
  int32_t stack_depth = GetDebuggerStackDepth(ctx);
  GetDebuggerCurrentLocation(ctx, cur_pc, line, column, script_id);

  auto *step_location = info->step_location;
  int32_t step_line = step_location ? step_location->line : -1;
  int32_t step_script_id = step_location ? step_location->script_id : -1;
  int32_t step_depth = info->step_depth;

  // different script & no deeper stack: paused
  if (step_script_id != -1 && script_id != -1 && script_id != step_script_id &&
      stack_depth <= step_depth && !(line == 0 && column == 0)) {
    return LEPUS_DEBUGGER_PAUSED;
  }

  // stack deeper: keep running
  if (stack_depth > step_depth || (line == 0 && column == 0)) {
    info->step_statement = false;
    info->next_statement_count = 0;
    return LEPUS_DEBUGGER_RUN;
  }

  // same line: stack no deeper, statement start: pause after op_push_const &
  // op_drop
  if (info->step_statement) {
    info->step_statement = false;
    info->next_statement_count = 1;  // pass op_push_const statement
    goto done;
  }

  // pause at next pc after statement
  if (info->next_statement_count == 1) {
    info->next_statement_count = 2;  // pass op_drop
    goto done;
  }

  if (info->next_statement_count == 2) goto paused;

done:
  // different line, and stack no deeper: paused
  if (line != step_line && stack_depth <= step_depth) goto paused;
  if (line == step_line && stack_depth < step_depth) goto paused;

  return LEPUS_DEBUGGER_RUN;

paused:
  return LEPUS_DEBUGGER_PAUSED;
}

int32_t HandleStepIn(LEPUSDebuggerInfo *info, LEPUSContext *ctx,
                     const uint8_t *cur_pc) {
  // step in: paused when the depth changes, else process as StepOver
  if (info->step_depth == GetDebuggerStackDepth(ctx)) {
    return HandleStepOver(info, ctx, cur_pc);
  } else {
    return LEPUS_DEBUGGER_PAUSED;
  }
}

int32_t HandleStepOut(LEPUSDebuggerInfo *info, LEPUSContext *ctx,
                      const uint8_t *cur_pc) {
  // step out: if depth is smaller, stop. else keep running
  int32_t stack_depth = GetDebuggerStackDepth(ctx);
  int32_t step_depth = info->step_depth;
  if (stack_depth >= step_depth) {
    return LEPUS_DEBUGGER_RUN;
  }
  return LEPUS_DEBUGGER_PAUSED;
}

/**
 * @brief handle stepping method
 */
static int32_t HandleStepping(LEPUSDebuggerInfo *info, LEPUSContext *ctx,
                              const uint8_t *cur_pc) {
  SetDebuggerStepStatement(info, ctx, cur_pc);
  uint8_t step_type = info->step_type;
  int32_t res = LEPUS_DEBUGGER_RUN;
  if (step_type == DEBUGGER_STEP_CONTINUE) {
    info->step_type = 0;
    goto running;
  } else if (step_type == DEBUGGER_STEP_IN) {
    res = HandleStepIn(info, ctx, cur_pc);
    if (res == LEPUS_DEBUGGER_PAUSED) goto paused;
    goto running;
  } else if (step_type == DEBUGGER_STEP_OUT) {
    res = HandleStepOut(info, ctx, cur_pc);
    if (res == LEPUS_DEBUGGER_PAUSED) goto paused;
    goto running;
  } else if (step_type == DEBUGGER_STEP) {
    res = HandleStepOver(info, ctx, cur_pc);
    if (res == LEPUS_DEBUGGER_PAUSED) goto paused;
    goto running;
  }
paused:
  info->step_type = 0;
  info->step_statement = false;
  info->next_statement_count = 0;
  return LEPUS_DEBUGGER_PAUSED;
running:
  return LEPUS_DEBUGGER_RUN;
}

// -4: need run next pc directly
// -3: do not need pause bud need process message
// -2: need pause because stepping
// breakorderid: hit breakpoint
int32_t DebuggerNeedProcess(LEPUSDebuggerInfo *info, LEPUSContext *ctx,
                            LEPUSBreakpoint *&hit_bp) {
  uint8_t step_type = info->step_type;
  int32_t breakpoint_active = info->breakpoints_is_active;

  if (breakpoint_active || step_type) {
    const uint8_t *cur_pc = GetInspectorCurrentPC(ctx);
    if (step_type) {
      int32_t line = -1;
      int64_t column = -1;
      int32_t script_id = 0;
      GetDebuggerCurrentLocation(ctx, cur_pc, line, column, script_id);
      int32_t stack_depth = GetDebuggerStackDepth(ctx);

      LEPUSDebuggerLocation *step_location = info->step_location;
      int32_t step_line = step_location ? step_location->line : -1,
              step_depth = info->step_depth,
              step_script_id = step_location ? step_location->script_id : -1;
      int64_t step_column = step_location ? step_location->column : -1;

      if ((stack_depth == step_depth && line == step_line &&
           column == step_column && script_id == step_script_id &&
           info->step_over_valid) ||
          (line == 0 && column == 0)) {
        return LEPUS_DEBUGGER_RUN;
      }
      info->step_over_valid = 0;
    }

    if (breakpoint_active) {
      // if current position is a breakpoint
      hit_bp = CheckBreakpoint(info, ctx, cur_pc);
      if (hit_bp) return 0;
    }

    if (step_type) {
      // if not a breakpoint, handle stepping
      return HandleStepping(info, ctx, cur_pc);
    }
  }
  return LEPUS_DEBUGGER_PROCESS_MESSAGE;
}

// return current frame stack depth
uint32_t GetDebuggerStackDepth(LEPUSContext *ctx) {
  uint32_t stack_depth = 0;
  struct LEPUSStackFrame *sf = GetStackFrame(ctx);
  while (sf != NULL) {
    sf = GetPreFrame(sf);
    stack_depth++;
  }
  return stack_depth;
}

// given current pc, return line and column number
void GetDebuggerCurrentLocation(LEPUSContext *ctx, const uint8_t *cur_pc,
                                int32_t &line, int64_t &column,
                                int32_t &script_id) {
  struct LEPUSStackFrame *sf = GetStackFrame(ctx);
  if (!sf) return;
  GetCurrentLocation(ctx, sf, cur_pc, line, column, script_id);
}

/**
 * @brief construct scriptParsed message
 */
LEPUSValue GetMultiScriptParsedInfo(LEPUSContext *ctx,
                                    LEPUSScriptSource *script) {
  LEPUSValue script_parsed_params = LEPUS_NewObject(ctx);
  if (LEPUS_IsException(script_parsed_params)) {
    return LEPUS_UNDEFINED;
  }
  int32_t script_id = script ? script->id : -1;
  DebuggerSetPropertyStr(ctx, script_parsed_params, "scriptId",
                         LEPUS_ToString(ctx, LEPUS_NewInt32(ctx, script_id)));
  const char *url = script ? script->url : nullptr;
  char *ret_url = (char *)"";
  int32_t has_source_url = 0;
  if (url && url[0] != '\0') {
    ret_url = (char *)url;
    has_source_url = 1;
  }
  DebuggerSetPropertyStr(ctx, script_parsed_params, "url",
                         LEPUS_NewString(ctx, ret_url));
  DebuggerSetPropertyStr(ctx, script_parsed_params, "hasSourceURL",
                         LEPUS_NewBool(ctx, has_source_url));

  DebuggerSetPropertyStr(ctx, script_parsed_params, "startLine",
                         LEPUS_NewInt32(ctx, 0));
  DebuggerSetPropertyStr(
      ctx, script_parsed_params, "endLine",
      LEPUS_NewInt32(ctx, script ? script->end_line + 1 : 0));
  DebuggerSetPropertyStr(ctx, script_parsed_params, "startColumn",
                         LEPUS_NewInt32(ctx, 0));
  DebuggerSetPropertyStr(ctx, script_parsed_params, "endColumn",
                         LEPUS_NewInt32(ctx, 0));
  int32_t execution_context_id = GetExecutionContextId(ctx);
  DebuggerSetPropertyStr(ctx, script_parsed_params, "executionContextId",
                         LEPUS_NewInt32(ctx, execution_context_id));
  const char *script_hash = script ? script->hash : nullptr;
  if (script_hash) {
    DebuggerSetPropertyStr(ctx, script_parsed_params, "hash",
                           LEPUS_NewString(ctx, script_hash));
  }
  const char *script_source = script ? script->source : nullptr;
  DebuggerSetPropertyStr(
      ctx, script_parsed_params, "length",
      LEPUS_NewInt32(ctx, script_source ? (int32_t)strlen(script_source) : 0));
  DebuggerSetPropertyStr(
      ctx, script_parsed_params, "scriptLanguage",
      LEPUS_DupValue(ctx,
                     GetDebuggerInfo(ctx)->literal_pool->capital_javascript));
  char *source_map_url = script->source_map_url;

  if (!source_map_url) {
    source_map_url = (char *)"";
  }
  DebuggerSetPropertyStr(ctx, script_parsed_params, "sourceMapURL",
                         LEPUS_NewString(ctx, source_map_url));
  return script_parsed_params;
}

// stop at first bytecode
void HandleStopAtEntry(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
  SendPausedEvent(info, GetInspectorCurrentPC(ctx), LEPUS_UNDEFINED,
                  "stopAtEntry");
}
/**
 * @brief handle "Debugger.enable"
 */
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-enable
void HandleEnable(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  if (ctx) {
    LEPUSValue message = debugger_options->message;
    LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);

    LEPUSValue result = LEPUS_NewObject(ctx);
    if (LEPUS_IsException(result)) {
      return;
    }
    DebuggerSetPropertyStr(ctx, result, "debuggerId",
                           LEPUS_DupValue(ctx, info->literal_pool->minus_one));

    LEPUSValue view_id_val = LEPUS_GetPropertyStr(ctx, message, "view_id");
    int32_t view_id = -1;
    if (!LEPUS_IsUndefined(view_id_val)) {
      LEPUS_ToInt32(ctx, &view_id, view_id_val);
      LEPUS_FreeValue(ctx, view_id_val);
    }

    bool is_already_enabled = false;
    bool is_paused = false;
    info->breakpoints_is_active = 1;
    if (view_id != -1) {
      // get if session is enabled and if session is paused
      GetSessionState(ctx, view_id, &is_already_enabled, &is_paused);
      // set session enable state
      SetSessionEnableState(ctx, view_id, DEBUGGER_ENABLE);
    } else {
      is_already_enabled = !!(info->is_debugger_enabled);
    }
    // send response for debugger.enable
    SendResponse(ctx, message, result);
    // if the session is already enabled, do not send Debugger.scriptParsed
    // event
    if (!is_already_enabled) {
      info->is_debugger_enabled += 1;
      int32_t script_num = info->script_num;
      for (int32_t index = 0; index < script_num; ++index) {
        LEPUSScriptSource *script = GetScriptByIndex(ctx, index);
        if (!script) continue;
        const char *url = script ? script->url : nullptr;
        if (url && strcmp(url, "<input>") == 0) {
          continue;
        }
        SendScriptParsedNotificationWithViewID(ctx, script, view_id);
      }
    }
    // if the session is paused, send Debugger.paused event
    if (is_paused) {
      SendPausedEventWithoutPause(ctx, info, GetInspectorCurrentPC(ctx),
                                  LEPUS_UNDEFINED, "debugCommand", view_id);
    }
  }
}

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setSkipAllPauses
void HandleSkipAllPauses(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  if (ctx) {
    LEPUSValue message = debugger_options->message;
    LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
    LEPUSValue params = LEPUS_GetPropertyStr(ctx, message, "params");
    LEPUSValue params_skip = LEPUS_GetPropertyStr(ctx, params, "skip");
    int32_t is_skip = LEPUS_VALUE_GET_BOOL(params_skip);
    LEPUS_FreeValue(ctx, params);
    if (is_skip) {
      info->breakpoints_is_active_before = info->breakpoints_is_active;
      info->exception_breakpoint_before = info->exception_breakpoint;
      info->breakpoints_is_active = 0;
      info->exception_breakpoint = 0;
    } else {
      info->breakpoints_is_active = info->breakpoints_is_active_before;
      info->exception_breakpoint = info->exception_breakpoint_before;
    }
    LEPUSValue result = LEPUS_NewObject(ctx);
    if (LEPUS_IsException(result)) {
      return;
    }
    SendResponse(ctx, message, result);
  }
}

/**
 * @brief handle "Debugger.getScriptSource" protocol
 */
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-getScriptSource
void HandleGetScriptSource(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  if (ctx) {
    LEPUSValue message = debugger_options->message;
    if (!CheckEnable(ctx, message, DEBUGGER_ENABLE)) return;
    LEPUSValue params = LEPUS_GetPropertyStr(ctx, message, "params");
    LEPUSValue params_scriptId = LEPUS_GetPropertyStr(ctx, params, "scriptId");
    int32_t script_id;
    LEPUS_ToInt32(ctx, &script_id, params_scriptId);
    LEPUS_FreeValue(ctx, params_scriptId);
    LEPUS_FreeValue(ctx, params);

    const char *script_source = GetScriptSourceByScriptId(ctx, script_id);

    if (script_source) {
      LEPUSValue result = LEPUS_NewObject(ctx);
      if (LEPUS_IsException(result)) {
        return;
      }
      DebuggerSetPropertyStr(ctx, result, "scriptSource",
                             LEPUS_NewString(ctx, script_source));
      SendResponse(ctx, message, result);
    }
  }
}

/**
 * @brief handle "Debugger.pause" protocol
 */
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-pause
void HandlePause(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  if (ctx) {
    LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
    LEPUSValue message = debugger_options->message;
    if (!CheckEnable(ctx, message, DEBUGGER_ENABLE)) return;
    const uint8_t *cur_pc = GetInspectorCurrentPC(ctx);
    LEPUSValue result = LEPUS_NewObject(ctx);
    if (LEPUS_IsException(result)) {
      return;
    }
    SendResponse(ctx, message, result);
    SendPausedEvent(info, cur_pc, LEPUS_UNDEFINED, "other");
  }
}

void DeleteConsoleMessageWithRID(LEPUSContext *ctx, int32_t rid) {
  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
  if (!info) {
    return;
  }
  LEPUSValue msg = info->console.messages;
  int32_t msg_len = info->console.length;
  LEPUSValue new_msg = LEPUS_NewArray(ctx);
  int32_t new_msg_len = 0;

  for (int32_t i = 0; i < msg_len; i++) {
    LEPUSValue console_message = LEPUS_GetPropertyUint32(ctx, msg, i);
    if (!LEPUS_IsUndefined(console_message)) {
      LEPUSValue rid_val = LEPUS_GetPropertyStr(ctx, console_message, "rid");
      if (!LEPUS_IsUndefined(rid_val)) {
        int32_t each_rid = -1;
        LEPUS_ToInt32(ctx, &each_rid, rid_val);
        LEPUS_FreeValue(ctx, rid_val);
        if (each_rid != rid) {
          LEPUS_SetPropertyUint32(ctx, new_msg, new_msg_len++,
                                  LEPUS_DupValue(ctx, console_message));
        }
      } else {
        LEPUS_SetPropertyUint32(ctx, new_msg, new_msg_len++,
                                LEPUS_DupValue(ctx, console_message));
      }
      LEPUS_FreeValue(ctx, console_message);
    }
  }
  LEPUS_FreeValue(ctx, msg);
  info->console.messages = new_msg;
  info->console.length = new_msg_len;
}

void SendConsoleAPICalled(LEPUSContext *ctx, LEPUSValue *msg, bool has_rid) {
  uint32_t argc = LEPUS_GetLength(ctx, *msg);
  LEPUSValue params = LEPUS_NewObject(ctx);
  LEPUSValue args = LEPUS_NewArray(ctx);
  DebuggerSetPropertyStr(ctx, params, "type",
                         LEPUS_GetPropertyStr(ctx, *msg, "tag"));
  int32_t execution_context_id = GetExecutionContextId(ctx);
  DebuggerSetPropertyStr(ctx, params, "executionContextId",
                         LEPUS_NewInt32(ctx, execution_context_id));
  DebuggerSetPropertyStr(ctx, params, "timestamp",
                         LEPUS_GetPropertyStr(ctx, *msg, "timestamp"));
  DebuggerSetPropertyStr(ctx, params, "args", args);
  LEPUSValue stack_trace = LEPUS_GetPropertyStr(ctx, *msg, "stackTrace");
  if (!LEPUS_IsUndefined(stack_trace)) {
    DebuggerSetPropertyStr(ctx, params, "stackTrace", stack_trace);
  }

  int rid = -1;
  const char *gid = nullptr;
  bool is_lepus_console = false;
  if (has_rid) {
    LEPUSValue rid_val = LEPUS_GetPropertyStr(ctx, *msg, "rid");
    if (!LEPUS_IsUndefined(rid_val)) {
      LEPUS_ToInt32(ctx, &rid, rid_val);
    }
    LEPUSValue gid_val = LEPUS_GetPropertyStr(ctx, *msg, "gid");
    if (!LEPUS_IsUndefined(gid_val)) {
      gid = LEPUS_ToCString(ctx, gid_val);
      LEPUS_FreeValue(ctx, gid_val);
    }
    LEPUSValue lepus_console = LEPUS_GetPropertyStr(ctx, *msg, "lepusConsole");
    if (!LEPUS_IsUndefined(lepus_console)) {
      is_lepus_console = true;
    }
  }
  for (int idx = 0; idx < argc; idx++) {
    LEPUSValue v = LEPUS_GetPropertyUint32(ctx, *msg, idx);
    LEPUSValue v2 = GetRemoteObject(ctx, v, 0, 0);  // free v
    LEPUS_SetPropertyUint32(ctx, args, idx, v2);
  }
  if (has_rid) {
    if (rid != -1) {
      DebuggerSetPropertyStr(ctx, params, "runtimeId",
                             LEPUS_NewInt32(ctx, rid));
    }
    if (gid) {
      DebuggerSetPropertyStr(ctx, params, "groupId", LEPUS_NewString(ctx, gid));
      LEPUS_FreeCString(ctx, gid);
    }
    if (is_lepus_console) {
      DebuggerSetPropertyStr(ctx, params, "consoleTag",
                             LEPUS_NewString(ctx, "lepus"));
    }
  }
  SendNotification(ctx, "Runtime.consoleAPICalled", params, -1);
}

void SendConsoleAPICalledNotificationWithRID(LEPUSContext *ctx,
                                             LEPUSValue *msg) {
  SendConsoleAPICalled(ctx, msg, true);
}

/**
 * @brief send console-message notification to devtools frontend
 * ref:
 * https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#event-consoleAPICalled
 */
void SendConsoleAPICalledNotification(LEPUSContext *ctx, LEPUSValue *msg) {
  SendConsoleAPICalled(ctx, msg);
}

/**
 * @brief use this function to handle "Debugger.stepInto", "Debugger.stepOver",
 * "Debugger.stepOut" etc
 */
void HandleStep(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  LEPUSValue message = debugger_options->message;
  if (!CheckEnable(ctx, message, DEBUGGER_ENABLE)) return;
  const uint8_t *cur_pc = GetInspectorCurrentPC(ctx);
  uint8_t step_mode = debugger_options->type;
  if (ctx) {
    LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
    info->step_type = step_mode;
    if (step_mode) {
      info->step_over_valid = 1;
    }
    // record the location and stack depth
    int32_t line = -1;
    int64_t column = -1;
    int32_t script_id = 0;
    int32_t stack_depth = GetDebuggerStackDepth(ctx);
    GetDebuggerCurrentLocation(ctx, cur_pc, line, column, script_id);

    if (info->step_location) {
      info->step_location->line = line;
      info->step_location->column = column;
    }
    if (info->step_location) {
      info->step_location->script_id = script_id;
    }
    info->step_depth = stack_depth;

    LEPUSValue result = LEPUS_NewObject(ctx);
    if (LEPUS_IsException(result)) {
      return;
    }
    SendResponse(ctx, message, result);

    LEPUSValue resumed_params = LEPUS_NewObject(ctx);
    if (LEPUS_IsException(resumed_params)) {
      return;
    }
    // continue running
    // send "Debugger.resumed" event
    // ref:
    // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-resumed
    SendNotification(ctx, "Debugger.resumed", resumed_params);
    QuitMessageLoopOnPause(ctx);
  }
}

/**
 * @brief handle "Debugger.resume" protocol
 */
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-resume
void HandleResume(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  if (ctx) {
    LEPUSValue message = debugger_options->message;
    if (!CheckEnable(ctx, message, DEBUGGER_ENABLE)) return;
    const uint8_t *cur_pc = GetInspectorCurrentPC(ctx);
    LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
    info->step_type = DEBUGGER_STEP_CONTINUE;
    info->step_over_valid = 1;
    if (info->step_location) {
      int32_t line = -1;
      int64_t column = -1;
      int32_t script_id = 0;
      GetDebuggerCurrentLocation(ctx, cur_pc, line, column, script_id);

      info->step_location->line = line;
      info->step_location->column = column;
      info->step_location->script_id = script_id;
    }
    info->step_depth = GetDebuggerStackDepth(ctx);

    LEPUSValue result = LEPUS_NewObject(ctx);
    if (LEPUS_IsException(result)) {
      return;
    }
    SendResponse(ctx, message, result);

    LEPUSValue resumed_params = LEPUS_NewObject(ctx);
    if (LEPUS_IsException(resumed_params)) {
      return;
    }
    // send "Debugger.resumed" event
    // ref:
    // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-resumed
    SendNotification(ctx, "Debugger.resumed", resumed_params);
    QuitMessageLoopOnPause(ctx);
  }
}

/**
 * @brief if there is an exception, send paused event
 */
void HandleSetPauseOnExceptions(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  if (ctx) {
    LEPUSValue message = debugger_options->message;
    LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
    LEPUSValue params = LEPUS_GetPropertyStr(ctx, message, "params");
    LEPUSValue params_state = LEPUS_GetPropertyStr(ctx, params, "state");
    const char *state = LEPUS_ToCString(ctx, params_state);
    LEPUS_FreeValue(ctx, params);
    LEPUS_FreeValue(ctx, params_state);
    if (state) {
      if (strcmp("uncaught", state) == 0 || strcmp("all", state) == 0) {
        info->exception_breakpoint = 1;
      } else if (strcmp("none", state) == 0) {
        info->exception_breakpoint = 0;
      }
      LEPUS_FreeCString(ctx, state);

      LEPUSValue result = LEPUS_NewObject(ctx);
      if (LEPUS_IsException(result)) {
        return;
      }
      SendResponse(ctx, message, result);
    }
  }
}

/**
 * @brief handle "Debugger.disable"
 */
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-disable
void HandleDisable(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  if (ctx) {
    LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
    LEPUSValue message = debugger_options->message;
    if (!CheckEnable(ctx, message, DEBUGGER_ENABLE)) return;
    // end debugging mode
    // when get debugger.disable, quit pause
    LEPUSValue result = LEPUS_NewObject(ctx);
    if (LEPUS_IsException(result)) {
      return;
    }
    LEPUSValue view_id_val = LEPUS_GetPropertyStr(ctx, message, "view_id");
    int32_t view_id = -1;
    if (!LEPUS_IsUndefined(view_id_val)) {
      LEPUS_ToInt32(ctx, &view_id, view_id_val);
    }
    bool is_already_enabled = false;
    bool is_paused = false;

    if (view_id != -1) {
      GetSessionState(ctx, view_id, &is_already_enabled, &is_paused);
      if (is_already_enabled) {
        info->is_debugger_enabled -= 1;
      }
      // set session enable state
      SetSessionEnableState(ctx, view_id, DEBUGGER_DISABLE);
    } else {
      if (info->is_debugger_enabled) {
        info->is_debugger_enabled -= 1;
      }
      SendNotification(ctx, "Debugger.resumed", LEPUS_NewObject(ctx));
      QuitMessageLoopOnPause(ctx);
    }
    SendResponse(ctx, message, result);
  }
}

// free debugger
void QJSDebuggerFree(LEPUSContext *ctx) {
  LEPUS_FreeContextRegistry(ctx);
  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
  if (!info) return;
  struct queue *debugger_queue = GetDebuggerMessageQueue(info);
  if (debugger_queue) {
    DeleteQueue(debugger_queue);
  }
  info->message_queue = NULL;

  for (int32_t i = 0; i < info->breakpoints_num;) {
    DeleteBreakpoint(info, i);
  }
  lepus_free(ctx, info->bps);
  // free running state
  auto &state = info->running_state;
  LEPUS_FreeValue(ctx, state.get_properties_array);
  state.get_properties_array = LEPUS_UNDEFINED;
  state.get_properties_array_len = 0;
  LEPUS_FreeValue(ctx, info->console.messages);
  lepus_free_rt(LEPUS_GetRuntime(ctx), info->step_location);
  FreeFixedShapeObj(info);
  FreeStringPool(info);
}

// process protocol message sent here when then paused
void ProcessPausedMessages(LEPUSContext *ctx, const char *message) {
  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
  if (!info) return;
  if (message && message[0] != '\0') {
    PushBackQueue(GetDebuggerMessageQueue(info), message);
  }
  ProcessProtocolMessages(info);
}

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setAsyncCallStackDepth
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-setAsyncCallStackDepth
void HandleSetAsyncCallStackDepth(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  if (ctx) {
    LEPUSValue message = debugger_options->message;
    if (!CheckEnable(ctx, message, DEBUGGER_ENABLE) &&
        !CheckEnable(ctx, message, RUNTIME_ENABLE))
      return;
    LEPUSValue param = LEPUS_GetPropertyStr(ctx, message, "params");
    LEPUSValue param_max_depth = LEPUS_GetPropertyStr(ctx, param, "maxDepth");

    int32_t max_depth = 0;
    LEPUS_ToInt32(ctx, &max_depth, param_max_depth);
    GetDebuggerInfo(ctx)->max_async_call_stack_depth = max_depth;
    LEPUS_FreeValue(ctx, param);
    LEPUS_FreeValue(ctx, param_max_depth);
    LEPUSValue result = LEPUS_NewObject(ctx);
    if (LEPUS_IsException(result)) {
      return;
    }
    SendResponse(ctx, message, result);
  }
}

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-Location
LEPUSValue GetLocation(LEPUSContext *ctx, int32_t line, int64_t column,
                       int32_t script_id) {
  LEPUSValue ret = LEPUS_NewObject(ctx);
  DebuggerSetPropertyStr(ctx, ret, "lineNumber", LEPUS_NewInt32(ctx, line));
  DebuggerSetPropertyStr(ctx, ret, "columnNumber", LEPUS_NewInt64(ctx, column));
  LEPUSValue column_num = LEPUS_NewInt32(ctx, script_id);
  DebuggerSetPropertyStr(ctx, ret, "scriptId", LEPUS_ToString(ctx, column_num));
  return ret;
}

static void GetExpression(char *expression, LEPUSValue new_value,
                          const char *variable_name, const char *value) {
  *expression = '\0';
  strcat(expression, variable_name);
  strcat(expression, "=");
  if (LEPUS_IsString(new_value)) {
    // string, add ""
    strcat(expression, "\"");
  }
  strcat(expression, value);
  if (LEPUS_IsString(new_value)) {
    strcat(expression, "\"");
  }
}

static void GetSetVariableValueParams(LEPUSContext *ctx, LEPUSValue params,
                                      int32_t *scope_num,
                                      const char **variable_name,
                                      LEPUSValue *new_value,
                                      const char **new_value_str,
                                      const char **frame_id) {
  LEPUSValue param_scope_num = LEPUS_GetPropertyStr(ctx, params, "scopeNumber");
  LEPUS_ToInt32(ctx, scope_num, param_scope_num);
  LEPUS_FreeValue(ctx, param_scope_num);

  LEPUSValue param_variable_name =
      LEPUS_GetPropertyStr(ctx, params, "variableName");
  *variable_name = LEPUS_ToCString(ctx, param_variable_name);
  LEPUS_FreeValue(ctx, param_variable_name);

  LEPUSValue param_new_value = LEPUS_GetPropertyStr(ctx, params, "newValue");
  *new_value = LEPUS_GetPropertyStr(ctx, param_new_value, "value");
  LEPUS_FreeValue(ctx, param_new_value);

  LEPUSValue param_call_frame_id =
      LEPUS_GetPropertyStr(ctx, params, "callFrameId");
  *frame_id = LEPUS_ToCString(ctx, param_call_frame_id);
  LEPUS_FreeValue(ctx, param_call_frame_id);

  LEPUSValue value_str = LEPUS_ToString(ctx, *new_value);
  *new_value_str = LEPUS_ToCString(ctx, value_str);
  LEPUS_FreeValue(ctx, value_str);
  LEPUS_FreeValue(ctx, params);
}

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setVariableValue
void HandleSetVariableValue(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  if (ctx) {
    LEPUSValue message = debugger_options->message;
    if (!CheckEnable(ctx, message, DEBUGGER_ENABLE)) return;
    LEPUSValue params = LEPUS_GetPropertyStr(ctx, message, "params");
    int32_t scope_num = 0;
    const char *variable_name = NULL;
    LEPUSValue new_value = LEPUS_UNDEFINED;
    const char *new_value_str = NULL;
    const char *frame_id = NULL;
    GetSetVariableValueParams(ctx, params, &scope_num, &variable_name,
                              &new_value, &new_value_str, &frame_id);

    int32_t expression_len = strlen(variable_name) + strlen(new_value_str) + 6;
    char *expression =
        static_cast<char *>(lepus_malloc(ctx, (sizeof(char) * expression_len)));
    if (expression) {
      GetExpression(expression, new_value, variable_name, new_value_str);
      LEPUSValue expression_val = LEPUS_NewString(ctx, expression);
      {
        PCScope ps(ctx);
        LEPUSValue ret = DebuggerEvaluate(ctx, frame_id, expression_val);
        LEPUS_FreeValue(ctx, ret);
      }
      LEPUS_FreeValue(ctx, expression_val);
    }
    lepus_free(ctx, expression);

    LEPUS_FreeCString(ctx, new_value_str);
    LEPUS_FreeCString(ctx, frame_id);
    LEPUS_FreeCString(ctx, variable_name);
    LEPUS_FreeValue(ctx, new_value);

    LEPUSValue result = LEPUS_NewObject(ctx);
    SendResponse(ctx, message, result);
  }
}
