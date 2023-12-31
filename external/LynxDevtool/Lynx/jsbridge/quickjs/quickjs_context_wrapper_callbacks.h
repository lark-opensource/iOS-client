// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_CONTEXT_WRAPPER_CALLBACKS_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_CONTEXT_WRAPPER_CALLBACKS_H_

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace piper {

// get all the qjs debugger callbacks
void **GetQJSCallbackFuncs(int32_t &callback_size);

// if quickjs debug is enabled
bool IsQuickjsDebugOn();
}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_CONTEXT_WRAPPER_CALLBACKS_H_
