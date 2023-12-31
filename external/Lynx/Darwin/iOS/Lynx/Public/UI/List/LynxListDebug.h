// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxLog.h"

#ifndef LYNX_LIST_DEBUG
#define LYNX_LIST_DEBUG 0
#define LYNX_LIST_DEBUG_LABEL 0
#if LYNX_LIST_DEBUG
#define LYNX_LIST_DEBUG_LOG(FORMAT, ...) \
  LYNX_DEBUG_LOG(LynxListDebug, FORMAT, ##__VA_ARGS__)

#define LYNX_LIST_DEBUG_COND_LOG(COND, FORMAT, ...) \
  do {                                              \
    if (COND) {                                     \
      LYNX_LIST_DEBUG_LOG(FORMAT, ##__VA_ARGS__)    \
    }                                               \
  } while (0)

#else
#define LYNX_LIST_DEBUG_LOG(FORMAT, ...)
#define LYNX_LIST_DEBUG_COND_LOG(COND, FORMAT, ...)
#endif  // #if LYNX_LIST_DEBUG
#endif  // #ifndef LYNX_LIST_DEBUG
