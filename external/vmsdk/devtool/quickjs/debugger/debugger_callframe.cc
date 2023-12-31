// Copyright 2019 The Lynx Authors. All rights reserved.

#include "devtool/quickjs/debugger/debugger_callframe.h"

#include "devtool/quickjs/debugger/debugger_properties.h"
#include "devtool/quickjs/debugger_inner.h"
#include "devtool/quickjs/interface.h"
#include "devtool/quickjs/protocols.h"

// evaluate an expression in the given callfarme id
LEPUSValue DebuggerEvaluate(LEPUSContext *ctx, const char *callframe_id,
                            LEPUSValue expression) {
  struct LEPUSStackFrame *stack_frame = NULL;
  int32_t frame_id = 0;
  int32_t stack_index = (int32_t)atol(callframe_id);
  for (stack_frame = GetStackFrame(ctx); stack_frame != NULL;
       stack_frame = GetPreFrame(stack_frame)) {
    if (frame_id < stack_index) {
      frame_id++;
      continue;
    }

    // find the right callframe
    LEPUSValue function = GetFrameFunction(stack_frame);
    LEPUSObject *f = LEPUS_VALUE_GET_OBJ(function);
    if (!f || !lepus_class_has_bytecode(LEPUS_GetClassID(ctx, function)))
      return LEPUS_UNDEFINED;

    int32_t scope_idx = GetFunctionVarDefs(f) ? 0 : -1;
    size_t len = 0;
    const char *str = LEPUS_ToCStringLen(ctx, &len, expression);
    if (str) {
      LEPUSValue ret;
      {
        PCScope ps(ctx);
        // evaluate the expression
        ret = LEPUS_EvalInternal(ctx, GetThisObj(stack_frame, f), str, len,
                                 "<debugger>", LEPUS_EVAL_TYPE_DIRECT,
                                 scope_idx, true, stack_frame);
      }
      LEPUS_FreeCString(ctx, str);
      return ret;
    }
  }
  return LEPUS_UNDEFINED;
}

static void GetEvaluateOnCallFrameParams(LEPUSContext *ctx, LEPUSValue params,
                                         const char **callframe_id,
                                         LEPUSValue *params_expression,
                                         uint8_t *silent, int32_t *need_preview,
                                         bool &throw_side_effect) {
  LEPUSValue params_callframe_id =
      LEPUS_GetPropertyStr(ctx, params, "callFrameId");
  *callframe_id = LEPUS_ToCString(ctx, params_callframe_id);
  LEPUS_FreeValue(ctx, params_callframe_id);
  *params_expression = LEPUS_GetPropertyStr(ctx, params, "expression");
  LEPUSValue params_silent = LEPUS_GetPropertyStr(ctx, params, "silent");
  if (!LEPUS_IsUndefined(params_silent)) {
    *silent = LEPUS_VALUE_GET_BOOL(params_silent);
  }
  LEPUSValue params_need_preview =
      LEPUS_GetPropertyStr(ctx, params, "generatePreview");
  *need_preview = LEPUS_ToBool(ctx, params_need_preview);
  LEPUSValue throw_on_side_effect =
      LEPUS_GetPropertyStr(ctx, params, "throwOnSideEffect");
  throw_side_effect = LEPUS_VALUE_GET_BOOL(throw_on_side_effect);
  LEPUS_FreeValue(ctx, params);
}

static LEPUSValue EvaluateOnCallFrame(LEPUSContext *ctx,
                                      const char *callframe_id,
                                      LEPUSValue params_expression,
                                      int32_t need_preview) {
  // get expression needed to be evaluated
  LEPUSValue ret;
  {
    PCScope ps(ctx);
    ret = DebuggerEvaluate(ctx, callframe_id, params_expression);
    if (LEPUS_IsException(ret)) {
      const char *expression = LEPUS_ToCString(ctx, params_expression);
      // do not send debugger.scriptparsed event
      ret = LEPUS_Eval(ctx, expression, strlen(expression), "<input>",
                       LEPUS_EVAL_TYPE_GLOBAL);
      LEPUS_FreeCString(ctx, expression);
    }
  }
  LEPUSValue remote_object = LEPUS_UNDEFINED;
  if (LEPUS_IsException(ret)) {
    LEPUSValue exception = DebuggerDupException(ctx);
    remote_object = GetRemoteObject(ctx, exception, need_preview,
                                    0);  // free exception
  } else {
    remote_object = GetRemoteObject(ctx, ret, need_preview, 0);  // free ret
  }
  return remote_object;
}

/**
 * @brief call this function to handle "Debugger.evalueateOnCallFrame"
 */
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-evaluateOnCallFrame
void HandleEvaluateOnCallFrame(DebuggerParams *debugger_options) {
  LEPUSContext *ctx = debugger_options->ctx;
  LEPUSDebuggerInfo *info = GetDebuggerInfo(ctx);
  LEPUSValue message = debugger_options->message;
  LEPUSValue params = LEPUS_GetPropertyStr(ctx, message, "params");

  const char *callframe_id = NULL;
  LEPUSValue params_expression = LEPUS_UNDEFINED;
  uint8_t silent = 0;
  int32_t need_preview = 0;
  bool throw_side_effect = false;
  GetEvaluateOnCallFrameParams(ctx, params, &callframe_id, &params_expression,
                               &silent, &need_preview, throw_side_effect);

  {
    ExceptionBreakpointScope es(
        info, (silent || throw_side_effect) ? 0 : info->exception_breakpoint);
    // return evaluation result
    if (callframe_id) {
      LEPUSValue remote_object = EvaluateOnCallFrame(
          ctx, callframe_id, params_expression, need_preview);

      LEPUSObject *p =
          DebuggerCreateObjFromShape(info, info->debugger_obj->result);
      uint32_t idx = 0;
      SetFixedShapeObjValue(info->ctx, p, idx, remote_object);
      SendResponse(ctx, message, LEPUS_MKPTR(LEPUS_TAG_OBJECT, p));
    }
  }

  LEPUS_FreeCString(ctx, callframe_id);
  LEPUS_FreeValue(ctx, params_expression);
}

// save function name in the callframe
static void SaveFunctionName(LEPUSDebuggerInfo *info, LEPUSValue current_frame,
                             struct LEPUSStackFrame *sf) {
  LEPUSContext *ctx = info->ctx;
  const char *func_name_str = get_func_name(ctx, GetFrameFunction(sf));
  if (!func_name_str || func_name_str[0] == '\0') {
    DebuggerSetPropertyStr(ctx, current_frame, "functionName",
                           LEPUS_DupValue(ctx, info->literal_pool->anonymous));
  } else {
    DebuggerSetPropertyStr(ctx, current_frame, "functionName",
                           LEPUS_NewString(ctx, func_name_str));
  }
  LEPUS_FreeCString(ctx, func_name_str);
}

// save url, location info in the callframe
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-CallFrame
static void GetFrameLineAndCol(LEPUSContext *ctx, LEPUSValue current_frame,
                               LEPUSValue &location, struct LEPUSStackFrame *sf,
                               const uint8_t *cur_pc) {
  int32_t real_line_num = 0;
  int64_t real_column_num = 0;
  int32_t script_id = 0;
  GetCurrentLocation(ctx, sf, cur_pc, real_line_num, real_column_num,
                     script_id);
  LEPUSValue function = GetFrameFunction(sf);
  struct LEPUSFunctionBytecode *b = LEPUS_GetFunctionBytecode(function);
  // TODO: CHECK CFUNCTION
  LEPUSValue script_id_value = LEPUS_UNDEFINED;
  if (b) {
    LEPUSValue filename = lepus_function_proto_fileName(ctx, function);
    uint8_t is_lepusNG = 0;
    if ((!LEPUS_IsUndefined(filename))) {
      const char *url = LEPUS_ToCString(ctx, filename);
      if (url && url[0] == '\0') {
        // for lepusNG debug lepus.js
        LEPUSScriptSource *source = GetScriptByIndex(ctx, 0);
        const char *script_url = source ? source->url : nullptr;
        if (script_url && (strcmp(script_url, "lepus.js") == 0)) {
          is_lepusNG = 1;
          auto *info = GetDebuggerInfo(ctx);
          DebuggerSetPropertyStr(
              ctx, current_frame, "url",
              LEPUS_DupValue(ctx, info->literal_pool->lepus_js));
          script_id_value = LEPUS_NewInt32(ctx, source ? source->id : -1);
        }
      }

      if (!is_lepusNG) {
        DebuggerSetPropertyStr(ctx, current_frame, "url",
                               LEPUS_DupValue(ctx, filename));
        LEPUSScriptSource *source = GetBytecodeScript(b);
        script_id_value = LEPUS_NewInt32(ctx, source ? source->id : -1);
      }
      LEPUS_FreeCString(ctx, url);
      LEPUS_FreeValue(ctx, filename);
    }

    // b->script.id
    DebuggerSetPropertyStr(ctx, location, "scriptId",
                           LEPUS_ToString(ctx, script_id_value));
    DebuggerSetPropertyStr(ctx, location, "lineNumber",
                           LEPUS_NewInt64(ctx, real_line_num));
    DebuggerSetPropertyStr(ctx, location, "columnNumber",
                           LEPUS_NewInt64(ctx, real_column_num));
  }
}

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-Scope
static LEPUSValue GetScopeObj(LEPUSContext *ctx, const char *type,
                              int32_t obj_id) {
  LEPUSValue scope_info = LEPUS_NewObject(ctx);
  if (LEPUS_IsException(scope_info)) {
    return LEPUS_UNDEFINED;
  }
  DebuggerSetPropertyStr(ctx, scope_info, "type", LEPUS_NewString(ctx, type));
  LEPUSValue scope_obj = LEPUS_NewObject(ctx);
  if (LEPUS_IsException(scope_obj)) {
    LEPUS_FreeValue(ctx, scope_info);
    return LEPUS_UNDEFINED;
  }
  auto *info = GetDebuggerInfo(ctx);
  DebuggerSetPropertyStr(ctx, scope_obj, "type",
                         LEPUS_DupValue(ctx, info->literal_pool->object));
  std::string obj_id_with_scope = "scope:" + std::to_string(obj_id);
  DebuggerSetPropertyStr(ctx, scope_obj, "objectId",
                         LEPUS_NewString(ctx, obj_id_with_scope.c_str()));
  DebuggerSetPropertyStr(ctx, scope_info, "object", scope_obj);
  return scope_info;
}

/**
 * @brief get scope chain of the callframe given frame id
 */
static void GetScopeChain(LEPUSContext *ctx, LEPUSValue current_frame,
                          int32_t frame_id) {
  LEPUSValue scope_chain = LEPUS_NewArray(ctx);
  if (LEPUS_IsException(scope_chain)) {
    return;
  }

  // biggest closure size: 20
  int32_t scope_id = 0;
  int32_t max_size = DEBUGGER_MAX_SCOPE_LEVEL;
  int32_t global_obj_id = (frame_id * max_size) + 0,
          local_obj_id = (frame_id * max_size) + 1,
          closure_obj_id = (frame_id * max_size) + 2;

  int32_t closure_size = 0;
  LEPUSValue global_obj;

  auto *info = GetDebuggerInfo(ctx);
  LEPUSValue local_obj = GetScopeObj(ctx, "local", local_obj_id);
  if (LEPUS_IsUndefined(local_obj)) {
    goto done;
  }
  LEPUS_SetPropertyUint32(ctx, scope_chain, scope_id++, local_obj);

  closure_size = GetClosureSize(ctx, frame_id);
  for (int32_t i = 0; i < closure_size; i++) {
    LEPUSValue closure_obj = GetScopeObj(ctx, "closure", closure_obj_id++);
    if (LEPUS_IsUndefined(closure_obj)) {
      goto done;
    }
    LEPUS_SetPropertyUint32(ctx, scope_chain, scope_id++, closure_obj);
  }

  global_obj = GetScopeObj(ctx, "global", global_obj_id);
  if (LEPUS_IsUndefined(global_obj)) {
    goto done;
  }
  LEPUS_SetPropertyUint32(ctx, scope_chain, scope_id++, global_obj);
done:
  DebuggerSetPropertyStr(ctx, current_frame, "scopeChain", scope_chain);
}

// construct this object of current frame
void FrameThisObj(LEPUSContext *ctx, LEPUSValue current_frame,
                  LEPUSValue current_frame_this_obj, const char *description) {
  LEPUSValue this_obj = LEPUS_NewObject(ctx);
  auto *info = GetDebuggerInfo(ctx);
  DebuggerSetPropertyStr(ctx, this_obj, "type",
                         LEPUS_DupValue(ctx, info->literal_pool->object));
  DebuggerSetPropertyStr(ctx, this_obj, "className",
                         LEPUS_DupValue(ctx, info->literal_pool->object));

  DebuggerSetPropertyStr(ctx, this_obj, "description",
                         LEPUS_NewString(ctx, description));
  DebuggerSetPropertyStr(ctx, this_obj, "objectId",
                         GenerateUniqueObjId(ctx, current_frame_this_obj));
  DebuggerSetPropertyStr(ctx, current_frame, "this", this_obj);
}

void GetConsoleStackTrace(LEPUSContext *ctx, LEPUSValue *ret) {
  LEPUSValue callframes =
      BuildConsoleBacktrace(ctx, GetInspectorCurrentPC(ctx));
  DebuggerSetPropertyStr(ctx, *ret, "callFrames", callframes);
}

LEPUSValue BuildConsoleBacktrace(LEPUSContext *ctx, const uint8_t *cur_pc) {
  // get call frame array
  struct LEPUSStackFrame *stack_frame = NULL;
  LEPUSValue ret = LEPUS_NewArray(ctx);
  if (LEPUS_IsException(ret)) {
    return LEPUS_UNDEFINED;
  }
  uint32_t frame_id = 0;
  auto *info = GetDebuggerInfo(ctx);
  // callframe stack
  for (stack_frame = GetPreFrame(GetStackFrame(ctx)); stack_frame != NULL;
       stack_frame = GetPreFrame(stack_frame)) {
    LEPUSValue current_frame = LEPUS_NewObject(ctx);
    if (LEPUS_IsException(current_frame)) {
      LEPUS_FreeValue(ctx, ret);
      ret = LEPUS_UNDEFINED;
      return ret;
    }
    // function name
    SaveFunctionName(info, current_frame, stack_frame);
    // callframeID && location && url && call frames
    LEPUSValue location = LEPUS_NewObject(ctx);
    GetFrameLineAndCol(ctx, current_frame, location, stack_frame, cur_pc);
    DebuggerSetPropertyStr(ctx, current_frame, "columnNumber",
                           LEPUS_GetPropertyStr(ctx, location, "columnNumber"));
    DebuggerSetPropertyStr(ctx, current_frame, "lineNumber",
                           LEPUS_GetPropertyStr(ctx, location, "lineNumber"));
    DebuggerSetPropertyStr(ctx, current_frame, "scriptId",
                           LEPUS_GetPropertyStr(ctx, location, "scriptId"));
    LEPUS_FreeValue(ctx, location);
    LEPUS_SetPropertyUint32(ctx, ret, frame_id++, current_frame);
  }
  return ret;
}

// build callframe backtrace
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-paused
LEPUSValue BuildBacktrace(LEPUSContext *ctx, const uint8_t *cur_pc) {
  // get call frame array
  struct LEPUSStackFrame *stack_frame = NULL;
  LEPUSValue ret = LEPUS_NewArray(ctx);
  if (LEPUS_IsException(ret)) {
    return LEPUS_UNDEFINED;
  }

  uint32_t frame_id = 0;
  LEPUSValue undef = LEPUS_NewObject(ctx);
  if (LEPUS_IsException(undef)) {
    return LEPUS_UNDEFINED;
  }
  auto *info = GetDebuggerInfo(ctx);
  DebuggerSetPropertyStr(ctx, undef, "type",
                         LEPUS_DupValue(ctx, info->literal_pool->undefined));
  // callframe stack
  for (stack_frame = GetStackFrame(ctx); stack_frame != NULL;
       stack_frame = GetPreFrame(stack_frame)) {
    LEPUSValue current_frame = LEPUS_NewObject(ctx);
    if (LEPUS_IsException(current_frame)) {
      LEPUS_FreeValue(ctx, ret);
      ret = LEPUS_UNDEFINED;
      return ret;
    }
    LEPUSValue frame_id_num = LEPUS_NewInt32(ctx, frame_id);
    DebuggerSetPropertyStr(ctx, current_frame, "callFrameId",
                           LEPUS_ToString(ctx, frame_id_num));

    // function name
    SaveFunctionName(info, current_frame, stack_frame);
    // callframeID && location && url && call frames
    LEPUSValue location = LEPUS_NewObject(ctx);
    GetFrameLineAndCol(ctx, current_frame, location, stack_frame, cur_pc);
    DebuggerSetPropertyStr(ctx, current_frame, "location", location);
    // socpechain : array of scopeinfo
    GetScopeChain(ctx, current_frame, frame_id);

    // thisobj: this object for this call frame
    LEPUSValue *frame_this_obj = GetFrameThisObj(stack_frame);
    if (frame_this_obj && LEPUS_IsObject(*frame_this_obj)) {
      // dup, need to free
      LEPUSValue global_obj = LEPUS_GetGlobalObject(ctx);
      if (LEPUS_VALUE_GET_OBJ(*frame_this_obj) ==
          LEPUS_VALUE_GET_OBJ(global_obj)) {
        FrameThisObj(ctx, current_frame, *frame_this_obj, "Global");
      } else {
        FrameThisObj(ctx, current_frame, *frame_this_obj, "Object");
      }
      LEPUS_FreeValue(ctx, global_obj);
    } else if (!frame_this_obj || LEPUS_IsUndefined(*frame_this_obj)) {
      DebuggerSetPropertyStr(ctx, current_frame, "this",
                             LEPUS_DupValue(ctx, undef));
    }
    LEPUS_SetPropertyUint32(ctx, ret, frame_id++, current_frame);
  }
  LEPUS_FreeValue(ctx, undef);
  return ret;
}
