// Copyright 2019 The Lynx Authors. All rights reserved.
#include "devtool/quickjs/debugger/debugger_breakpoint.h"

#include <string>

#include "devtool/quickjs/debugger/debugger.h"
#include "devtool/quickjs/debugger_inner.h"
#include "devtool/quickjs/interface.h"
#include "devtool/quickjs/protocols.h"

// get line and column number of breakpoint
static void GetBreakpointLineAndColumn(LEPUSContext *ctx, LEPUSValue param,
                                       int32_t &line_num, int64_t &column_num,
                                       int32_t &script_id) {
  LEPUSValue breakpoint_line_prop =
      LEPUS_GetPropertyStr(ctx, param, "lineNumber");
  LEPUS_ToInt32(ctx, &line_num, breakpoint_line_prop);

  LEPUSValue breakpoint_column_prop =
      LEPUS_GetPropertyStr(ctx, param, "columnNumber");
  if (LEPUS_IsUndefined(breakpoint_column_prop)) {
    column_num = -1;
  } else {
    LEPUS_ToInt64(ctx, &column_num, breakpoint_column_prop);
  }
  LEPUS_FreeValue(ctx, breakpoint_line_prop);
  LEPUS_FreeValue(ctx, breakpoint_column_prop);

  LEPUSValue param_script_id = LEPUS_GetPropertyStr(ctx, param, "scriptId");
  if (!LEPUS_IsUndefined(param_script_id)) {
    LEPUS_ToInt32(ctx, &script_id, param_script_id);
  }
  LEPUS_FreeValue(ctx, param_script_id);

  if (script_id == -1) {
    LEPUSValue param_script_hash =
        LEPUS_GetPropertyStr(ctx, param, "scriptHash");
    if (!LEPUS_IsUndefined(param_script_hash)) {
      const char *script_hash = LEPUS_ToCString(ctx, param_script_hash);
      LEPUSScriptSource *script = GetScriptByHash(ctx, script_hash);
      if (script) {
        script_id = script ? script->id : -1;
      }
      LEPUS_FreeCString(ctx, script_hash);
    }
    LEPUS_FreeValue(ctx, param_script_hash);
  }
}

/**
 * @brief generate unique breakpoint id
 * @param url script url
 * @return unique breakpoint id
 */
static char *GenerateBreakpointId(LEPUSContext *ctx, const char *url,
                                  const char *script_hash, int32_t line_number,
                                  int64_t column_number) {
  // breakpoint_id:   1:line_number:column_number:script_url
  std::string line_string = std::to_string(line_number);
  std::string column_string = std::to_string(column_number);
  const char *line_str = line_string.c_str();
  const char *column_str = column_string.c_str();

  const char *str = url ? url : "";
  // if url is "" and has hash, use hash to generate breakpoint id
  if (str[0] == '\0' && script_hash && script_hash[0] != '\0') {
    str = script_hash;
  }
  const int32_t other_str_len = 7;
  int32_t breakpoint_id_len =
      strlen(line_str) + strlen(str) + strlen(column_str) + other_str_len;
  char *breakpointId = static_cast<char *>(
      lepus_malloc(ctx, (sizeof(char) * breakpoint_id_len)));
  if (breakpointId) {
    *breakpointId = '\0';
    strcpy(breakpointId, "1:");
    strcat(breakpointId, line_str);
    strcat(breakpointId, ":");
    strcat(breakpointId, column_str);
    strcat(breakpointId, ":");
    strcat(breakpointId, str);
  }

  return breakpointId;
}

QJS_STATIC bool IsBreakpointEqual(LEPUSContext *ctx, LEPUSBreakpoint *a,
                                  int32_t script_id, int32_t line_number,
                                  int64_t column_number,
                                  LEPUSValue condition_b) {
  bool res1 = a->script_id == script_id && a->line == line_number &&
              a->column == column_number;
  if (res1) {
    LEPUSValue condition_a = a->condition;

    if ((LEPUS_IsNull(condition_a) ^ LEPUS_IsNull(condition_b))) {
      // one null, one has condition
      return false;
    } else {
      // both have condition
      if (!LEPUS_IsNull(condition_a)) {
        const char *condition1 = LEPUS_ToCString(ctx, condition_a);
        const char *condition2 = LEPUS_ToCString(ctx, condition_b);
        if (!condition1 || !condition2) return false;
        bool res2 = strcmp(condition1, condition2) == 0;
        LEPUS_FreeCString(ctx, condition1);
        LEPUS_FreeCString(ctx, condition2);
        return res2;
      } else {
        return true;
      }
    }
  } else {
    return false;
  }
}

static void SetBps(LEPUSDebuggerInfo *debugger_info, int32_t capacity) {
  debugger_info->breakpoints_capacity = capacity;
  debugger_info->bps = static_cast<LEPUSBreakpoint *>(
      lepus_realloc(debugger_info->ctx, debugger_info->bps,
                    capacity * sizeof(LEPUSBreakpoint)));
}

/**
 * @brief add a breakpoint
 * @param url script url
 * @param line_number breakpoint line number
 * @param column_number  breakpoint column number
 */
QJS_STATIC LEPUSBreakpoint *AddBreakpoint(
    LEPUSDebuggerInfo *info, const char *url, const char *hash,
    int32_t line_number, int64_t column_number, int32_t script_id,
    const char *condition, uint8_t specific_location) {
  LEPUSContext *ctx = info->ctx;
  int32_t bp_num = info->breakpoints_num;
  LEPUSValue condition_val = (condition && condition[0] != '\0')
                                 ? LEPUS_NewString(ctx, condition)
                                 : LEPUS_NULL;
  // detect breakpoint existance
  for (int32_t idx = 0; idx < bp_num; idx++) {
    LEPUSBreakpoint *t = info->bps + idx;
    if (IsBreakpointEqual(ctx, t, script_id, line_number, column_number,
                          condition_val)) {
      return t;
    }
  }

  LEPUSBreakpoint *bp;
  const int32_t bp_capacity_increase_size = 8;
  int32_t current_capacity = info->breakpoints_capacity;
  if (bp_num + 1 > current_capacity) {
    SetBps(info, current_capacity + bp_capacity_increase_size);
    if (!info->bps) {
      // fail
      return NULL;
    }
  }

  char *bp_url = static_cast<char *>(
      lepus_malloc(ctx, sizeof(char) * ((url ? strlen(url) : 0) + 1)));
  if (bp_url) {
    strcpy(bp_url, url ? url : "");
  }

  bp = info->bps + bp_num;
  bp->breakpoint_id = LEPUS_UNDEFINED;
  bp->script_url = bp_url;
  bp->line = line_number;
  bp->column = column_number;
  bp->script_id = script_id;
  AdjustBreakpoint(info, url, hash, bp);
  bp->is_adjust = false;

  char *gen_breakpoint_id =
      GenerateBreakpointId(ctx, url, hash, line_number, column_number);
  if (gen_breakpoint_id) {
    LEPUSValue breakpoint_id = LEPUS_NewString(ctx, gen_breakpoint_id);
    lepus_free(ctx, gen_breakpoint_id);
    if (!LEPUS_IsException(breakpoint_id)) {
      bp->breakpoint_id = breakpoint_id;
    }
  }

  bp->specific_location = specific_location;
  bp->pc = NULL;
  bp->condition = condition_val;
  ++info->breakpoints_num;
  ++info->next_breakpoint_id;
  return bp;
}

static void SendBreakpointResponse(LEPUSContext *ctx, LEPUSValue message,
                                   LEPUSBreakpoint *bp,
                                   LEPUSValue breakpoint_id) {
  LEPUSValue locations_array = LEPUS_NewArray(ctx);
  if (LEPUS_IsException(locations_array)) {
    LEPUS_FreeValue(ctx, breakpoint_id);
    return;
  }

  // construct result message
  // ref:
  // https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setBreakpointByUrl
  auto *info = GetDebuggerInfo(ctx);
  LEPUSObject *p =
      DebuggerCreateObjFromShape(info, info->debugger_obj->breakpoint);
  uint32_t idx = 0;
  SetFixedShapeObjValue(ctx, p, idx++, breakpoint_id);
  LEPUSValue location = GetLocation(ctx, bp->line, bp->column, bp->script_id);
  LEPUS_SetPropertyUint32(ctx, locations_array, 0, location);
  SetFixedShapeObjValue(ctx, p, idx++, locations_array);
  SendResponse(ctx, message, LEPUS_MKPTR(LEPUS_TAG_OBJECT, p));
}

static void ProcessSetBreakpoint(LEPUSContext *ctx, const char *script_url,
                                 const char *script_hash, int32_t script_id,
                                 int32_t line_number, int64_t column_number,
                                 LEPUSValue message, const char *condition) {
  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
  // TODO CHECK if other bp messages sent here!
  // add this new breakpoint to the info->breakpoints
  LEPUSBreakpoint *bp =
      AddBreakpoint(info, script_url, script_hash, line_number, column_number,
                    script_id, condition, 0);

  if (!bp) {
    return;
  }
  // generate breakpoint id
  char *breakpoint_id = GenerateBreakpointId(ctx, script_url, script_hash,
                                             line_number, column_number);
  if (!breakpoint_id) {
    return;
  }

  LEPUSValue breakpoint_id_value = LEPUS_NewString(ctx, breakpoint_id);
  SendBreakpointResponse(ctx, message, bp, breakpoint_id_value);

  lepus_free(ctx, breakpoint_id);
  breakpoint_id = NULL;
}

static void GetSetBpByURLParams(LEPUSContext *ctx, LEPUSValue params,
                                int32_t &line_number, int64_t &column_number,
                                int32_t &script_id, const char **script_url,
                                const char **script_hash,
                                const char **condition) {
  GetBreakpointLineAndColumn(ctx, params, line_number, column_number,
                             script_id);
  LEPUSValue param_url = LEPUS_GetPropertyStr(ctx, params, "url");
  if (!LEPUS_IsUndefined(param_url)) {
    const char *script_url_cstr = LEPUS_ToCString(ctx, param_url);
    *script_url = lepus_strdup(ctx, script_url_cstr);
    LEPUS_FreeCString(ctx, script_url_cstr);
  }

  // lynx js thread: get script id from script url
  if (*script_url && script_id == -1) {
    LEPUSScriptSource *script = GetScriptByScriptURL(ctx, *script_url);
    if (script) {
      script_id = script ? script->id : -1;
    }
  }

  // script url is ""
  if (!(*script_url)) {
    *script_url = GetScriptURLByScriptId(ctx, script_id);
    *script_url =
        *script_url ? lepus_strdup(ctx, *script_url) : lepus_strdup(ctx, "");
  }
  LEPUS_FreeValue(ctx, param_url);
  LEPUSValue param_script_hash =
      LEPUS_GetPropertyStr(ctx, params, "scriptHash");

  if (!LEPUS_IsUndefined(param_script_hash)) {
    *script_hash = LEPUS_ToCString(ctx, param_script_hash);
  }
  LEPUS_FreeValue(ctx, param_script_hash);
  LEPUSValue params_condition = LEPUS_GetPropertyStr(ctx, params, "condition");

  if (!LEPUS_IsUndefined(params_condition)) {
    *condition = LEPUS_ToCString(ctx, params_condition);
  }
  LEPUS_FreeValue(ctx, params_condition);
  LEPUS_FreeValue(ctx, params);
}

// handle "Debugger.setBreakpointByUrl"
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setBreakpointByUrl
void SetBreakpointByURL(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  LEPUSValue message = debugger_options->message;
  if (!CheckEnable(ctx, message, DEBUGGER_ENABLE)) return;
  LEPUSValue params = LEPUS_GetPropertyStr(ctx, message, "params");

  int32_t line_number = -1;
  int64_t column_number = -1;
  int32_t script_id = -1;
  const char *script_url = NULL;
  const char *script_hash = NULL;
  const char *condition = NULL;
  GetSetBpByURLParams(ctx, params, line_number, column_number, script_id,
                      &script_url, &script_hash, &condition);
  if (condition && condition[0] == '\0') {
    LEPUS_FreeCString(ctx, condition);
    condition = NULL;
  }
  ProcessSetBreakpoint(ctx, script_url, script_hash, script_id, line_number,
                       column_number, message, condition);

  LEPUS_FreeCString(ctx, condition);
  lepus_free_rt(LEPUS_GetRuntime(ctx), const_cast<char *>(script_url));
  LEPUS_FreeCString(ctx, script_hash);
}

/**
 * @brief handle "Debugger.setBreakpointsActive" protocol
 */
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setBreakpointsActive
void HandleSetBreakpointActive(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  LEPUSValue message = debugger_options->message;
  if (!CheckEnable(ctx, message, DEBUGGER_ENABLE)) return;
  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
  LEPUSValue params = LEPUS_GetPropertyStr(ctx, message, "params");
  LEPUSValue active = LEPUS_GetPropertyStr(ctx, params, "active");
  int32_t is_active = LEPUS_VALUE_GET_BOOL(active);
  LEPUS_FreeValue(ctx, params);

  info->breakpoints_is_active = is_active ? 1 : 0;

  LEPUSValue result = LEPUS_NewObject(ctx);
  if (LEPUS_IsException(result)) {
    return;
  }
  SendResponse(ctx, message, result);
}

// delete breakpoint of index bp_index from breakpoint list
void DeleteBreakpoint(LEPUSDebuggerInfo *info, uint32_t bp_index) {
  LEPUSContext *ctx = info->ctx;
  LEPUSBreakpoint *bp = info->bps + bp_index;
  LEPUSValue id_str = bp->breakpoint_id;
  char *bp_script_url = bp->script_url;
  LEPUSValue condition = bp->condition;
  LEPUS_FreeValue(ctx, id_str);
  LEPUS_FreeValue(ctx, condition);
  lepus_free(ctx, bp_script_url);
  int32_t move = info->breakpoints_num - bp_index - 1;
  if (move > 0) {
    // just move, no delete. use breakpoint number to control
    memmove(bp, info->bps + (bp_index + 1), move * sizeof(LEPUSBreakpoint));
  }
  // breakpoint num -1
  info->breakpoints_num -= 1;
}

/**
 * @brief delete breakpoint using breakpoint id
 * @param deleted_breakpoint_id breakpoint id needed to be deleted
 */
static void DeleteBreakpointById(LEPUSDebuggerInfo *info,
                                 const char *deleted_breakpoint_id) {
  LEPUSContext *ctx = info->ctx;
  if (ctx && deleted_breakpoint_id) {
    int32_t bp_num = info->breakpoints_num;
    for (int32_t i = 0; i < bp_num; i++) {
      LEPUSBreakpoint *bp = info->bps + i;
      LEPUSValue id_str = bp->breakpoint_id;
      const char *current_breakpoint_id = LEPUS_ToCString(ctx, id_str);
      if (current_breakpoint_id) {
        if (strcmp(current_breakpoint_id, deleted_breakpoint_id) == 0) {
          DeleteBreakpoint(info, i);
          LEPUS_FreeCString(ctx, current_breakpoint_id);
          return;
        } else {
          LEPUS_FreeCString(ctx, current_breakpoint_id);
        }
      }
    }
  }
}

/**
 * @brief call this function to handle "Debugger.removeBreakpoint"
 */
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-removeBreakpoint
void HandleRemoveBreakpoint(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
  LEPUSValue message = debugger_options->message;
  if (!CheckEnable(ctx, message, DEBUGGER_ENABLE)) return;
  LEPUSValue params = LEPUS_GetPropertyStr(ctx, message, "params");
  LEPUSValue param_breakpoint_id =
      LEPUS_GetPropertyStr(ctx, params, "breakpointId");
  LEPUS_FreeValue(ctx, params);

  const char *deleted_breakpoint_id = LEPUS_ToCString(ctx, param_breakpoint_id);
  LEPUS_FreeValue(ctx, param_breakpoint_id);

  DeleteBreakpointById(info, deleted_breakpoint_id);
  LEPUS_FreeCString(ctx, deleted_breakpoint_id);

  LEPUSValue result = LEPUS_NewObject(ctx);
  if (LEPUS_IsException(result)) {
    return;
  }
  SendResponse(ctx, message, result);
}

/**
 * @brief send "Debugger.breakpointResolved" event
 */
// static void SendBreakpointResolvedEvent(LEPUSDebuggerInfo *info,
//                                        LEPUSValue breakpoint, char *reason) {
//  LEPUSContext *ctx = GetContext(info);
//  LEPUSValue hit_breakpoint_info = LEPUS_NewObject(ctx);
//  if (LEPUS_IsException(hit_breakpoint_info)) {
//    return;
//  }
//  LEPUS_SetPropertyStr(ctx, hit_breakpoint_info, "breakpointId",
//                       LEPUS_GetPropertyStr(ctx, breakpoint, "breakpointId"));
//  LEPUSValue hit_breakpoint_location = LEPUS_NewObject(ctx);
//  if (LEPUS_IsException(hit_breakpoint_location)) {
//    LEPUS_FreeValue(ctx, hit_breakpoint_info);
//    return;
//  }
//
//  LEPUS_SetPropertyStr(ctx, hit_breakpoint_location, "scriptId",
//                       LEPUS_GetPropertyStr(ctx, breakpoint, "scriptId"));
//  LEPUS_SetPropertyStr(ctx, hit_breakpoint_location, "lineNumber",
//                       LEPUS_GetPropertyStr(ctx, breakpoint, "lineNumber"));
//  LEPUS_SetPropertyStr(ctx, hit_breakpoint_location, "columnNumber",
//                       LEPUS_GetPropertyStr(ctx, breakpoint, "columnNumber"));
//  LEPUS_SetPropertyStr(ctx, hit_breakpoint_info, "locations",
//                       hit_breakpoint_location);
//  SendNotification(ctx, "Debugger.breakpointResolved", hit_breakpoint_info);
//}

// given the pc needed to pause, send Debugger.breakpointResolved event and
// Debugger.paused event
void PauseAtBreakpoint(LEPUSDebuggerInfo *info, LEPUSBreakpoint *bp,
                       const uint8_t *cur_pc) {
  //  LEPUSContext *ctx = GetContext(info);
  // reaching a breakpoint resets any existing stepping.
  info->step_type = 0;
  // TODO CHECK IF THERE NEED BREAKPOINTRESOLVED EVENT
  // debugger.paused event
  LEPUSValue breakpoint_id = bp->breakpoint_id;
  SendPausedEvent(info, cur_pc, breakpoint_id, "debugCommand");
}

// for debugger.getpossiblebreakpoints, get start line, start column, end line,
// end column from the protocol
void GetRange(LEPUSContext *ctx, LEPUSValue params, int32_t &start_line,
              int64_t &start_column, int32_t &end_line, int64_t &end_column,
              int32_t &script_id) {
  LEPUSValue start = LEPUS_GetPropertyStr(ctx, params, "start");
  GetBreakpointLineAndColumn(ctx, start, start_line, start_column, script_id);
  LEPUSValue end = LEPUS_GetPropertyStr(ctx, params, "end");
  if (LEPUS_IsUndefined(end)) {
    end_line = -1;
    end_column = -1;
  } else {
    GetBreakpointLineAndColumn(ctx, end, end_line, end_column, script_id);
  }

  LEPUS_FreeValue(ctx, start);
  LEPUS_FreeValue(ctx, end);
}

/**
 * @brief handle "Debugger.getPossibleBreakpoints" protocol
 */
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-getPossibleBreakpoints
void HandleGetPossibleBreakpoints(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  LEPUSValue message = debugger_options->message;
  LEPUSValue params = LEPUS_GetPropertyStr(ctx, message, "params");

  int32_t start_line_num = -1, end_line_num = -1;
  int64_t start_column_num = -1, end_column_num = -1;
  int32_t script_id = -1;
  GetRange(ctx, params, start_line_num, start_column_num, end_line_num,
           end_column_num, script_id);
  LEPUS_FreeValue(ctx, params);
  if (script_id == -1) {
    // error
    return;
  }

  LEPUSValue locations = LEPUS_NewArray(ctx);
  if (LEPUS_IsException(locations)) {
    return;
  }
  GetPossibleBreakpointsByScriptId(ctx, script_id, start_line_num,
                                   start_column_num, end_line_num,
                                   end_column_num, locations);
  LEPUSValue result = LEPUS_NewObject(ctx);
  if (LEPUS_IsException(result)) {
    LEPUS_FreeValue(ctx, locations);
    return;
  }
  DebuggerSetPropertyStr(ctx, result, "locations", locations);
  SendResponse(ctx, message, result);
}

bool SatisfyCondition(LEPUSDebuggerInfo *info, LEPUSContext *ctx,
                      LEPUSBreakpoint *bp) {
  LEPUSValue bp_condition = bp->condition;
  if (!LEPUS_IsNull(bp_condition)) {
    bool result = false;
    const char *condition = LEPUS_ToCString(ctx, bp_condition);
    if (condition && condition[0] == '\0') {
      LEPUS_FreeCString(ctx, condition);
      return result;
    }
    LEPUSValue ret;
    {
      // no exception pause during evaluate breakpoint condition
      ExceptionBreakpointScope es(info, 0);
      const uint8_t *cur_pc = GetInspectorCurrentPC(ctx);
      ret = DebuggerEvaluate(ctx, "0", bp_condition);
      SetInspectorCurrentPC(ctx, cur_pc);
    }
    if (LEPUS_IsBool(ret)) {
      if (LEPUS_VALUE_GET_BOOL(ret)) {
        result = true;
      }
    }
    LEPUS_FreeValue(ctx, ret);
    LEPUS_FreeCString(ctx, condition);
    return result;
  }
  return true;
}

static bool BreakpointInSameScript(LEPUSContext *ctx, int32_t script_id,
                                   LEPUSBreakpoint *bp) {
  int32_t bp_script_id = bp->script_id;
  if (bp_script_id == -1) {
    const char *current_script_url = GetScriptURLByScriptId(ctx, script_id);
    return (current_script_url &&
            strcmp(current_script_url, bp->script_url) == 0);
  } else {
    return bp_script_id == script_id;
  }
}

// breakpoint_id: hit breakpoint id
// return value: if breakpoint hit
LEPUSBreakpoint *CheckBreakpoint(LEPUSDebuggerInfo *info, LEPUSContext *ctx,
                                 const uint8_t *cur_pc) {
  int32_t bp_num = info->breakpoints_num;
  if (bp_num == 0) return NULL;
  // if current script is equal to 0, return false;
  int32_t line = -1;
  int64_t column = -1;
  int32_t script_id = 0;
  GetDebuggerCurrentLocation(ctx, cur_pc, line, column, script_id);

  if (script_id == 0) {
    // error
    return NULL;
  }

  for (int32_t i = 0; i < bp_num; i++) {
    LEPUSBreakpoint *bp = info->bps + i;
    if (!BreakpointInSameScript(ctx, script_id, bp) || bp->line != line) {
      continue;
    }

    int64_t bp_column = bp->column;
    if (bp_column == 0 && !bp->is_adjust) {
      // if bp column number equals zero, adjust breakpoint column number
      AdjustBreakpoint(info, bp->script_url, "", bp);
      bp_column = bp->column;
    }

    if (bp_column == column) {
      const uint8_t *hit_pc = bp->pc;
      if ((!hit_pc || cur_pc == hit_pc) && SatisfyCondition(info, ctx, bp)) {
        bp->pc = cur_pc;
        return bp;
      }
    }
  }
  return NULL;
}

static void GetContinueToLocationParams(LEPUSContext *ctx, LEPUSValue params,
                                        int32_t &line_number,
                                        int64_t &column_number,
                                        int32_t &script_id,
                                        const char *&target_callframes) {
  LEPUSValue params_location = LEPUS_GetPropertyStr(ctx, params, "location");
  GetBreakpointLineAndColumn(ctx, params_location, line_number, column_number,
                             script_id);
  LEPUS_FreeValue(ctx, params_location);

  LEPUSValue params_target_callframes =
      LEPUS_GetPropertyStr(ctx, params, "targetCallFrames");
  if (!LEPUS_IsUndefined(params_target_callframes)) {
    target_callframes = LEPUS_ToCString(ctx, params_target_callframes);
  }
  LEPUS_FreeValue(ctx, params_target_callframes);
  LEPUS_FreeValue(ctx, params);
}

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-continueToLocation
void HandleContinueToLocation(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  LEPUSValue message = debugger_options->message;
  if (!CheckEnable(ctx, message, DEBUGGER_ENABLE)) return;
  LEPUSValue params = LEPUS_GetPropertyStr(ctx, message, "params");
  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);

  int32_t line_number = -1;
  int64_t column_number = -1;
  int32_t script_id = -1;
  const char *target_callframes = NULL;

  GetContinueToLocationParams(ctx, params, line_number, column_number,
                              script_id, target_callframes);
  LEPUS_FreeCString(ctx, target_callframes);

  info->special_breakpoints = 1;
  const char *url = GetScriptURLByScriptId(ctx, script_id);

  // set brekapoint active is 1
  info->breakpoints_is_active = 1;

  // add this new breakpoint to the info->breakpoints, set specific_condition
  // true
  AddBreakpoint(info, url, "", line_number, column_number, script_id, NULL, 1);
  LEPUSValue result = LEPUS_NewObject(ctx);
  SendResponse(ctx, message, result);
  // continue to run
  QuitMessageLoopOnPause(ctx);
}
