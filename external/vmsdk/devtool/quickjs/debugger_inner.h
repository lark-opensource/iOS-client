#ifndef QUICKJS_DEBUGGER_INNDER_H
#define QUICKJS_DEBUGGER_INNDER_H

#include "quickjs/include/quickjs-inner.h"
typedef struct LEPUSVarDef LEPUSVarDef;

#include "quickjs/include/debugger_struct.h"

typedef struct LEPUSProperty LEPUSProperty;
typedef struct LEPUSShape LEPUSShape;
struct LEPUSFunctionBytecode *LEPUS_GetFunctionBytecode(LEPUSValueConst val);

LEPUSScriptSource *GetBytecodeScript(struct LEPUSFunctionBytecode *b);

void GetPossibleBreakpointsByScriptId(LEPUSContext *ctx, int32_t script_id,
                                      int64_t start_line, int64_t start_col,
                                      int64_t end_line, int64_t end_col,
                                      LEPUSValue locations);

void GetCurrentLocation(LEPUSContext *ctx, struct LEPUSStackFrame *frame,
                        const uint8_t *cur_pc, int32_t &line, int64_t &column,
                        int32_t &script_id);

LEPUSValue *GetFrameThisObj(struct LEPUSStackFrame *frame);

LEPUSScriptSource *GetScriptByIndex(LEPUSContext *ctx, int32_t script_index);

const char *GetScriptSourceByScriptId(LEPUSContext *ctx, int32_t script_id);

LEPUSScriptSource *GetScriptByScriptURL(LEPUSContext *ctx,
                                        const char *filename);

LEPUSScriptSource *GetScriptByHash(LEPUSContext *ctx, const char *hash);

LEPUSValue GetGlobalVarObj(LEPUSContext *ctx);

struct LEPUSRegExp *lepus_get_regexp(LEPUSContext *ctx, LEPUSValueConst obj,
                                     int throw_error);
struct LEPUSString *GetRegExpPattern(struct LEPUSRegExp *re);

LEPUSValue get_date_string(LEPUSContext *ctx, LEPUSValueConst this_val,
                           int argc, LEPUSValueConst *argv, int magic);

#define QJSDebuggerClassIdDecl(V) \
  V(Map)                          \
  V(Set)                          \
  V(Date)                         \
  V(WeakMap)                      \
  V(WeakSet)                      \
  V(Proxy)                        \
  V(Generator)                    \
  V(GeneratorFunction)            \
  V(Promise)                      \
  V(WeakRef)                      \
  V(FinalizationRegistry)         \
  V(ArrayIterator)                \
  V(StringIterator)               \
  V(SetIterator)                  \
  V(MapIterator)                  \
  V(RegExpStringIterator)         \
  V(AsyncFunction)                \
  V(AsyncGenerator)               \
  V(AsyncGeneratorFunction)       \
  V(AsyncFunctionResolve)         \
  V(AsyncFunctionReject)          \
  V(AsyncFromSyncIterator)        \
  V(PromiseResolveFunction)       \
  V(PromiseRejectFunction)

#define DebuggerTypeDecl(name) uint8_t Is##name(LEPUSContext *, LEPUSValue);
QJSDebuggerClassIdDecl(DebuggerTypeDecl)
#undef DebuggerTypeDecl

    LEPUSValue
    lepus_map_get_size(LEPUSContext *ctx, LEPUSValueConst this_val, int magic);

struct LEPUSMapRecord *DebuggerMapFindIndex(LEPUSContext *ctx,
                                            LEPUSValue this_val, int32_t index,
                                            int32_t magic);

LEPUSValue GetMapRecordKey(struct LEPUSMapRecord *record);

LEPUSValue GetMapRecordValue(struct LEPUSMapRecord *record);

uint8_t IsGenerator(LEPUSContext *ctx, LEPUSValue value);

LEPUSValue GetGeneratorFuncName(LEPUSContext *ctx, LEPUSValue obj);

LEPUSValue GetGeneratorState(LEPUSContext *ctx, LEPUSValue obj);

LEPUSValue GetGeneratorFunction(LEPUSContext *ctx, LEPUSValue obj);

uint8_t IsGeneratorFunction(LEPUSContext *ctx, LEPUSValue value);

const char *GetScriptURLByScriptId(LEPUSContext *ctx, int32_t script_id);

LEPUSValue lepus_array_buffer_get_byteLength(LEPUSContext *ctx,
                                             LEPUSValueConst this_val,
                                             int class_id);

LEPUSValue lepus_typed_array_get_byteLength(LEPUSContext *ctx,
                                            LEPUSValueConst this_val,
                                            int is_dataview);

LEPUSValue LEPUS_EvalFunctionWithThisObj(LEPUSContext *ctx, LEPUSValue func_obj,
                                         LEPUSValueConst this_obj, int argc,
                                         LEPUSValue *argv);

LEPUSValue lepus_function_proto_fileName(LEPUSContext *ctx,
                                         LEPUSValueConst this_val);

LEPUSValueConst LEPUS_GetActiveFunction(LEPUSContext *ctx);

LEPUSValue lepus_function_toString(LEPUSContext *ctx, LEPUSValueConst this_val,
                                   int argc, LEPUSValueConst *argv);

int32_t GetScriptIdByFunctionBytecode(LEPUSContext *ctx,
                                      struct LEPUSFunctionBytecode *b);

struct LEPUSFunctionBytecode *GetFunctionBytecodeByScriptId(LEPUSContext *ctx,
                                                            int32_t script_id);

void SetInspectorCurrentPC(LEPUSContext *ctx, const uint8_t *pc);

LEPUSValue GetFrameFunction(struct LEPUSStackFrame *frame);

int32_t GetClosureSize(LEPUSContext *ctx, int32_t stack_index);

LEPUSValue GetFrameClosureVariables(LEPUSContext *ctx, int32_t stack_index,
                                    int32_t closure_level);

LEPUSAtom lepus_symbol_to_atom(LEPUSContext *ctx, LEPUSValue val);

LEPUSContext *GetContextByContextId(LEPUSRuntime *rt, int32_t id);

int lepus_is_regexp(LEPUSContext *ctx, LEPUSValueConst obj);

void DebuggerFreeScript(LEPUSContext *ctx, LEPUSScriptSource *script);

LEPUSValue GetDebuggerObjectGroup(LEPUSDebuggerInfo *info);
// given the stack depth, return the local variables
LEPUSValue GetLocalVariables(LEPUSContext *ctx, int32_t stack_index);

// quickjs debugger evaluation
LEPUSValue DebuggerEval(LEPUSContext *ctx, LEPUSValueConst this_obj,
                        struct LEPUSStackFrame *sf, const char *input,
                        size_t input_len, const char *filename, int32_t flags,
                        int32_t scope_idx);

// call this function to get protocol messages sent by front end
void GetProtocolMessages(LEPUSContext *ctx);

// make virtual machine continue running
void QuitMessageLoopOnPause(LEPUSContext *ctx);

// send response message to front end
void SendProtocolResponse(LEPUSContext *ctx, int message_id,
                          const char *response_message);
// send notification message to front end
void SendProtocolNotification(LEPUSContext *ctx, const char *response_message);

// make vritual machine pause
void RunMessageLoopOnPause(LEPUSContext *ctx);

const uint8_t *GetInspectorCurrentPC(LEPUSContext *ctx);

struct LEPUSStackFrame *GetStackFrame(LEPUSContext *ctx);

struct LEPUSStackFrame *GetPreFrame(struct LEPUSStackFrame *frame);

LEPUSVarDef *GetFunctionVarDefs(LEPUSObject *obj);

LEPUSValueConst GetThisObj(struct LEPUSStackFrame *sf, LEPUSObject *p);

LEPUSValue GetAtomGetValue(LEPUSContext *ctx);

LEPUSValue GetAtomSetValue(LEPUSContext *ctx);

// for shared context qjs debugger: send response message to front end with view
// id
void SendProtocolResponseWithViewID(LEPUSContext *ctx, int message_id,
                                    const char *response_message,
                                    int32_t view_id);

// for shared context qjs debugger: send notification message to front end with
// view id
void SendProtocolNotificationWithViewID(LEPUSContext *ctx,
                                        const char *response_message,
                                        int32_t view_id);

// for shared context qjs debugger: set session with view_id enable state
void SetSessionEnableState(LEPUSContext *ctx, int32_t view_id,
                           int32_t protocol_type);

// for shared context qjs debugger: get session with view_id state of enable and
// paused
void GetSessionState(LEPUSContext *ctx, int32_t view_id,
                     bool *is_already_enabled, bool *is_paused);

// for shared context qjs debugger: get session enable state for Debugger,
// Runtime, Profiler, etc
void GetSessionEnableState(LEPUSContext *ctx, int32_t view_id, int32_t type,
                           bool *ret);

LEPUSValue DebuggerGetPromiseProperties(LEPUSContext *ctx, LEPUSValue val);

LEPUSValue DebuggerGetProxyProperties(LEPUSContext *ctx, LEPUSValue val);

LEPUSValue LEPUS_EvalInternal(LEPUSContext *ctx, LEPUSValueConst this_obj,
                              const char *input, size_t input_len,
                              const char *filename, int flags, int scope_idx,
                              bool debugger_type = false,
                              LEPUSStackFrame *sf = NULL);

void DebuggerSetPropertyStr(LEPUSContext *ctx, LEPUSValueConst this_obj,
                            const char *prop, LEPUSValue val);

void SetDebuggerMode(LEPUSContext *ctx);

void DebuggerFree(LEPUSContext *ctx);

void SetFixedShapeObjValue(LEPUSContext *ctx, LEPUSObject *p, uint32_t idx,
                           LEPUSValue val);

LEPUSValue LEPUS_NewObjectFromShape(LEPUSContext *ctx, LEPUSShape *sh,
                                    LEPUSClassID class_id);

LEPUSShape *lepus_dup_shape(LEPUSShape *sh);

LEPUSObject *DebuggerCreateObjFromShape(LEPUSDebuggerInfo *info,
                                        LEPUSValue obj);

LEPUSValue DebuggerDupException(LEPUSContext *ctx);

LEPUSValue GetAnonFunc(LEPUSFunctionBytecode *b);

void SetDebuggerStepStatement(LEPUSDebuggerInfo *info, LEPUSContext *ctx,
                              const uint8_t *cur_pc);

void SetIsProfilerCtx(LEPUSContext *ctx, uint8_t val);

void InitQJSDebugger(LEPUSContext *ctx);

void LEPUS_FreeContextRegistry(LEPUSContext *ctx);

LEPUS_BOOL LEPUS_LepusRefIsTable(LEPUSRuntime *rt, LEPUSValue v);

LEPUS_BOOL LEPUS_LepusRefIsArray(LEPUSRuntime *rt, LEPUSValue v);

class PCScope {
 public:
  PCScope(LEPUSContext *ctx) : ctx_(ctx) { pc_ = GetInspectorCurrentPC(ctx_); }

  ~PCScope() { SetInspectorCurrentPC(ctx_, pc_); }

 private:
  LEPUSContext *ctx_;
  const uint8_t *pc_;
};

class ExceptionBreakpointScope {
 public:
  ExceptionBreakpointScope(LEPUSDebuggerInfo *info, uint32_t tmp_val) {
    exception_breakpoint_val_ = info->exception_breakpoint;
    info_ = info;
    info->exception_breakpoint = tmp_val;
  }
  ~ExceptionBreakpointScope() {
    info_->exception_breakpoint = exception_breakpoint_val_;
  }

 private:
  LEPUSDebuggerInfo *info_;
  uint8_t exception_breakpoint_val_;
};

class PauseStateScope {
 public:
  PauseStateScope(LEPUSDebuggerInfo *info) {
    info_ = info;
    auto &state = info_->pause_state;
    state.get_properties_array = LEPUS_NewArray(info->ctx);
    state.get_properties_array_len = 0;
  }
  ~PauseStateScope() {
    auto &state = info_->pause_state;
    LEPUS_FreeValue(info_->ctx, state.get_properties_array);
    state.get_properties_array = LEPUS_UNDEFINED;
    state.get_properties_array_len = 0;
  }

 private:
  LEPUSDebuggerInfo *info_;
};

#ifdef QJS_UNITTEST
#define QJS_STATIC
#else
#define QJS_STATIC static
#endif

#endif  // QUICKJS_DEBUGGER_INNDER_H
