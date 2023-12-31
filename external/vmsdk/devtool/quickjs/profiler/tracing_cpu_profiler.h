// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef VMSDK_DEVTOOL_TRACING_CPU_PROFILER_H
#define VMSDK_DEVTOOL_TRACING_CPU_PROFILER_H

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif
#include "devtool/quickjs/profiler/cpu_profiler.h"

typedef struct DebuggerParams DebuggerParams;

const uint8_t *GetFrameCurPC(struct LEPUSStackFrame *sf);

uint8_t *GetFunctionBytecodeBuf(struct LEPUSFunctionBytecode *b);

uint8_t FunctionBytecodeHasDebug(struct LEPUSFunctionBytecode *b);

// deep clone functionbytecode for cpu profiler
LEPUSValue DeepCloneFuncFrameForProfiler(LEPUSContext *ctx,
                                         LEPUSContext *profiler_ctx,
                                         LEPUSValue frame_func);
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Profiler/#method-setSamplingInterval
void HandleSetSamplingInterval(DebuggerParams *);
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Profiler/#method-start
void HandleProfilerStart(DebuggerParams *);
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Profiler/#method-enable
void HandleProfilerEnable(DebuggerParams *);
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Profiler/#method-disable
void HandleProfilerDisable(DebuggerParams *);
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Profiler/#method-stop
void HandleProfilerStop(DebuggerParams *);
#endif