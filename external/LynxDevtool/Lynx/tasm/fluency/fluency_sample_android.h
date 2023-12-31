// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_FLUENCY_FLUENCY_SAMPLE_ANDROID_H_
#define LYNX_TASM_FLUENCY_FLUENCY_SAMPLE_ANDROID_H_
#include <jni.h>
#include <stdlib.h>

namespace lynx {
namespace tasm {
namespace android {
class FluencySample {
 public:
  static bool RegisterJNI(JNIEnv* env);
};

}  // namespace android
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_FLUENCY_FLUENCY_SAMPLE_ANDROID_H_
