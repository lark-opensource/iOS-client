// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef QUICKJS_DEBUGGER_BREAKPOINT_H
#define QUICKJS_DEBUGGER_BREAKPOINT_H

#include "devtool/quickjs/debugger/debugger.h"

// handle protocol: Debugger.setBreakpoints. set a breakpoint in the script
void SetBreakpointByURL(DebuggerParams *);

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-getPossibleBreakpoints
void HandleGetPossibleBreakpoints(DebuggerParams *);

// handle protocol: Debugger.setBreakpointActive. make all the breakpoint active
void HandleSetBreakpointActive(DebuggerParams *);

// handle protocol: Debugger.removeBreakpoint. remove a breakpoint by breakpoint
// id
void HandleRemoveBreakpoint(DebuggerParams *);

// when pause because of breakpoints, return Debugger.paused event and
// Debugger.breakpointResolved event
// ref:https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-breakpointResolved
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#event-paused
void PauseAtBreakpoint(LEPUSDebuggerInfo *info, LEPUSBreakpoint *bp,
                       const uint8_t *cur_pc);

/**
 * @brief check if current position is a breakpoint
 * @param cur_pc current pc
 * @return if current position is a breakpoint, return the breakpoint, else
 * return NULL
 */
LEPUSBreakpoint *CheckBreakpoint(LEPUSDebuggerInfo *, LEPUSContext *ctx,
                                 const uint8_t *cur_pc);

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-continueToLocation
void HandleContinueToLocation(DebuggerParams *);

// delete breakpoint of index bp_index
void DeleteBreakpoint(LEPUSDebuggerInfo *info, uint32_t bp_index);

#endif
