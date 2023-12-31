#ifndef _UTILS_TT_LOG_H_
#define _UTILS_TT_LOG_H_

#ifdef __ANDROID__
#include <android/log.h>
#else
#include <stdio.h>
#endif

#define LOG_DEBUG_TAG "SMASH_DEBUG_LOG "
#define LOG_ERROR_TAG "SMASH_E_LOG "

// Bemember to keep the rule that printf is not recommended using in smash sdk.
// include this header printf and LOGD would do nothing in RELEASE version
#ifdef DEBUG
#ifdef __ANDROID__
#define LOGD(...) \
  __android_log_print(ANDROID_LOG_DEBUG, LOG_DEBUG_TAG, __VA_ARGS__)
#define LOGE(...) \
  __android_log_print(ANDROID_LOG_ERROR, LOG_ERROR_TAG, __VA_ARGS__)
#else
#define LOGD(...)        \
  printf(LOG_DEBUG_TAG); \
  printf(__VA_ARGS__)
#define LOGE(...)                 \
  fprintf(stderr, LOG_ERROR_TAG); \
  fprintf(stderr, __VA_ARGS__)
#endif  // DEBUG MODE
#else
#ifdef __ANDROID__
#define LOGE(...) \
  __android_log_print(ANDROID_LOG_ERROR, LOG_ERROR_TAG, __VA_ARGS__)
#define LOGD(...)
#define printf(...)
#else
#define LOGE(...)                 \
  fprintf(stderr, LOG_ERROR_TAG); \
  fprintf(stderr, __VA_ARGS__)
#define LOGD(...)
#define printf(...)
#endif  // RELEASE MODE
#endif

#endif  // _UTILS_TT_LOG_H_
