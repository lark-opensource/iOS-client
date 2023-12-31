// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef QUICKJS_QUICKJS_DEBUGGER_H
#define QUICKJS_QUICKJS_DEBUGGER_H

#ifdef __cplusplus
extern "C" {
#endif

#include "quickjs/include/quickjs.h"

#ifdef __cplusplus
}
#endif

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "devtool/quickjs/debugger_inner.h"

// debugger step mode: step over, step in, step out and continue
enum DebuggerStepMode {
  DEBUGGER_STEP = 1,
  DEBUGGER_STEP_IN,
  DEBUGGER_STEP_OUT,
  DEBUGGER_STEP_CONTINUE
};

enum DebuggerStatus {
  LEPUS_DEBUGGER_RUN = -4,         // run next pc directly
  LEPUS_DEBUGGER_PROCESS_MESSAGE,  // do not need pause but need process
  // messages
  LEPUS_DEBUGGER_PAUSED,  // need to pause because step_type
};

struct DebuggerParams {
  LEPUSContext *ctx;
  LEPUSValue message;
  uint8_t type;
};
typedef struct DebuggerParams DebuggerParams;

// given current pc, return the line, column position of this pc, the script id
void GetDebuggerCurrentLocation(LEPUSContext *ctx, const uint8_t *cur_pc,
                                int32_t &line, int64_t &column,
                                int32_t &script_id);

// return current frame stack depth
uint32_t GetDebuggerStackDepth(LEPUSContext *ctx);

// return if the system need to paused because of breakpoints or stepping
int32_t DebuggerNeedProcess(LEPUSDebuggerInfo *info, LEPUSContext *ctx,
                            LEPUSBreakpoint *&hit_bp);

// handle debugger.enable
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-enable
void HandleEnable(DebuggerParams *);

// handle debugger.getscriptsource
// get script source given a script id
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-getScriptSource
void HandleGetScriptSource(DebuggerParams *);

// handle debugger.pause
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-pause
void HandlePause(DebuggerParams *params);

// handle debugger.stepxx
void HandleStep(DebuggerParams *);

// handle debugger.resume
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-resume
void HandleResume(DebuggerParams *);

// handle setPauseOnexceptions
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setPauseOnExceptions
void HandleSetPauseOnExceptions(DebuggerParams *);

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setSkipAllPauses
void HandleSkipAllPauses(DebuggerParams *);

// handle debugger.disable
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-disable
void HandleDisable(DebuggerParams *);

// given the script, return the script info need by Debugger.ScriptParsed
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-scriptParsed
LEPUSValue GetMultiScriptParsedInfo(LEPUSContext *ctx,
                                    LEPUSScriptSource *script);

// stop at first pc
void HandleStopAtEntry(DebuggerParams *debugger_options);

// adjust breakpoint location to the nearest bytecode
void AdjustBreakpoint(LEPUSDebuggerInfo *info, const char *url,
                      const char *hash, LEPUSBreakpoint *bp);

LEPUSValue DebuggerEvaluate(LEPUSContext *ctx, const char *callframe_id,
                            LEPUSValue expression);

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setAsyncCallStackDepth
void HandleSetAsyncCallStackDepth(DebuggerParams *);

// get location
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#type-Location
LEPUSValue GetLocation(LEPUSContext *ctx, int32_t line, int64_t column,
                       int32_t script_id);

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-setVariableValue
void HandleSetVariableValue(DebuggerParams *);

// send console api called event. if has_rid = true, put rid in the response
// message
void SendConsoleAPICalled(LEPUSContext *ctx, LEPUSValue *msg,
                          bool has_rid = false);
#endif  // QUICKJS_QUICKJS_DEBUGGER_H
