// Copyright 2023 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_COMMON_WASM_ALOG_
#define JSB_WASM_COMMON_WASM_ALOG_

#if defined(OS_ANDROID) || defined(OS_IOS)
#include "basic/log/logging.h"
#else  // defined(OS_ANDROID) || defined(OS_IOS)
#include <sstream>
// These logs are only used offline.
#define WASM_STREAM_MSG(logger, msg)    \
  {                                     \
    std::stringstream stream;           \
    stream << msg;                      \
    logger("%s", stream.str().c_str()); \
  }
#define LOGD(msg) WASM_STREAM_MSG(WLOGD, msg)
#define LOGI(msg) WASM_STREAM_MSG(WLOGI, msg)
#define LOGW(msg) WASM_STREAM_MSG(WLOGW, msg)
#define LOGE(msg) WASM_STREAM_MSG(WLOGE, msg)
#endif  // cli

#endif  // JSB_WASM_COMMON_WASM_ALOG_