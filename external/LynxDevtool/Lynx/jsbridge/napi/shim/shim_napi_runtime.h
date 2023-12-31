// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_SHIM_SHIM_NAPI_RUNTIME_H_
#define LYNX_JSBRIDGE_NAPI_SHIM_SHIM_NAPI_RUNTIME_H_

#ifdef OS_IOS
#include <vmsdk/napi_runtime.h>
#else
#include "third_party/napi/include/napi_runtime.h"
#endif

#endif  // LYNX_JSBRIDGE_NAPI_SHIM_SHIM_NAPI_RUNTIME_H_
