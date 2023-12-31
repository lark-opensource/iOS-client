// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef QUICKJS_QUICKJS_RUNTIME_H
#define QUICKJS_QUICKJS_RUNTIME_H

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

typedef struct DebuggerParams DebuggerParams;
// handle runtime.enable protocol
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-enable
void HandleRuntimeEnable(DebuggerParams*);

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-discardConsoleEntries
void HandleDiscardConsoleEntries(DebuggerParams*);

// evaluate a script
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-evaluate
void HandleEvaluate(DebuggerParams*);

// compile a script
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-compileScript
void HandleCompileScript(DebuggerParams*);

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-callFunctionOn
void HandleCallFunctionOn(DebuggerParams*);

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-globalLexicalScopeNames
void HandleGlobalLexicalScopeNames(DebuggerParams*);

// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-runScript
void HandleRunScript(DebuggerParams*);

// handle runtime.enable protocol
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-disenable
void HandleRuntimeDisable(DebuggerParams*);

// given object id, return the real obj
LEPUSValue GetObjFromObjectId(LEPUSContext* ctx, const char* object_id_str,
                              uint64_t*);
#endif  // QUICKJS_QUICKJS_RUNTIME_H
