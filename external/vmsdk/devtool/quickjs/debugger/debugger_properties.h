// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef QUICKJS_DEBUGGER_PROPERTIES_H
#define QUICKJS_DEBUGGER_PROPERTIES_H

#include "devtool/quickjs/debugger/debugger.h"

typedef LEPUSValue (*GetPropertyCallback)(LEPUSContext *ctx,
                                          LEPUSValue property_name,
                                          LEPUSValue &property_value,
                                          int writeable, int configurable,
                                          int enumerable);

typedef LEPUSValue (*GetEntryCallback)(LEPUSContext *ctx,
                                       LEPUSValue &entry_value,
                                       int32_t writeable, int32_t configurable,
                                       int32_t enumerable);
/**
 * @brief handle "Runtime.getProperties" protocol
 */
// ref:
// https://chromedevtools.github.io/devtools-protocol/tot/Runtime/#method-getProperties
void HandleGetProperties(DebuggerParams *);

LEPUSValue GetSideEffectResult(LEPUSContext *ctx);

// Gets the value of an object property
LEPUSValue GetRemoteObject(LEPUSContext *ctx, LEPUSValue &property_value,
                           int32_t need_preview, int32_t return_by_value);

// generate unique object id for obj
LEPUSValue GenerateUniqueObjId(LEPUSContext *ctx, LEPUSValue obj);

LEPUSValue GetExceptionDescription(LEPUSContext *ctx, LEPUSValue exception);

#endif
