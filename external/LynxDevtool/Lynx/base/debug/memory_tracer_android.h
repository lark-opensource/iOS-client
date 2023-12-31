// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_DEBUG_MEMORY_TRACER_ANDROID_H_
#define LYNX_BASE_DEBUG_MEMORY_TRACER_ANDROID_H_

#include <jni.h>

namespace lynx {
namespace base {

class MemoryTracerAndroid {
 public:
  static bool RegisterJNIUtils(JNIEnv *env);
};

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_DEBUG_MEMORY_TRACER_ANDROID_H_
