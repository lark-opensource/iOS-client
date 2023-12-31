// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef QUICKJS_DEBUGGER_CALLFRAMES_H
#define QUICKJS_DEBUGGER_CALLFRAMES_H

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

#include "devtool/quickjs/debugger/debugger.h"

/**
 * @brief call this function to handle "Debugger.evalueateOnCallFrame"
 */
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-evaluateOnCallFrame
void HandleEvaluateOnCallFrame(DebuggerParams *);

// when vm paused, call this function to get callframe stack
LEPUSValue BuildBacktrace(LEPUSContext *ctx, const uint8_t *cur_pc);

// when console.xxx is called, use this function to get stack trace
LEPUSValue BuildConsoleBacktrace(LEPUSContext *ctx, const uint8_t *cur_pc);

#endif
