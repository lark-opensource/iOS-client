// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_COMMON_WASM_LOG_
#define JSB_WASM_COMMON_WASM_LOG_

#include <stdio.h>

#define LOG_LEVEL_VERBOSE 5
#define LOG_LEVEL_DEBUG 4
#define LOG_LEVEL_INFO 3
#define LOG_LEVEL_ERROR 2
#define LOG_LEVEL_FATAL 1

#ifndef LOG_LEVEL
#define LOG_LEVEL LOG_LEVEL_ERROR
#endif

#if OS_ANDROID  // android
#include <android/log.h>

#define WASM_LOGD(format, ...) \
  __android_log_print(ANDROID_LOG_DEBUG, "WasmDebug", format, ##__VA_ARGS__)
#define WASM_LOGI(format, ...) \
  __android_log_print(ANDROID_LOG_INFO, "WasmInfo", format, ##__VA_ARGS__)
#define WASM_LOGE(format, ...) \
  __android_log_print(ANDROID_LOG_ERROR, "WasmError", format, ##__VA_ARGS__)
#define WASM_LOGW(format, ...) \
  __android_log_print(ANDROID_LOG_WARN, "WasmWarn", format, ##__VA_ARGS__)
#else

#include <cstdlib>

#define WASM_LOGD(format, ...) \
  fprintf(stderr, "[WasmDebug] " format "\n", ##__VA_ARGS__)
#define WASM_LOGI(format, ...) \
  fprintf(stderr, "[WasmInfo] " format "\n", ##__VA_ARGS__)
#define WASM_LOGW(format, ...) \
  fprintf(stderr, "[WasmWarn] " format "\n", ##__VA_ARGS__)
#define WASM_LOGE(format, ...) \
  fprintf(stderr, "[WasmError] " format "\n", ##__VA_ARGS__)

#endif  // OS_ANDROID

#if !defined(WLOGD) && (LOG_LEVEL >= LOG_LEVEL_VERBOSE)
#define WLOGD(format, ...) WASM_LOGD(format, ##__VA_ARGS__)
#else
#define WLOGD(format, ...)
#endif

#if !defined(WLOGI) && (LOG_LEVEL >= LOG_LEVEL_INFO)
#define WLOGI(format, ...) WASM_LOGI(format, ##__VA_ARGS__)
#else
#define WLOGI(format, ...)
#endif

#if !defined(WLOGW) && (LOG_LEVEL >= LOG_LEVEL_ERROR)
#define WLOGW(format, ...) WASM_LOGW(format, ##__VA_ARGS__)
#else
#define WLOGW(format, ...)
#endif

#if !defined(WLOGE) && (LOG_LEVEL >= LOG_LEVEL_ERROR)
#define WLOGE(format, ...) WASM_LOGE(format, ##__VA_ARGS__)
#else
#define WLOGE(format, ...)
#endif

#ifndef DCHECK
#if DEBUG
#define DCHECK(condition) assert(condition)
#else
#define DCHECK(condition) ((void)0)
#endif  // DEBUG
#endif  // DCHECK

// definition for alog in android/ios
#include "common/wasm_alog.h"

#endif  // JSB_WASM_COMMON_WASM_LOG_