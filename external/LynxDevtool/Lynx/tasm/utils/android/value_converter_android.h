// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_UTILS_ANDROID_VALUE_CONVERTER_ANDROID_H_
#define LYNX_TASM_UTILS_ANDROID_VALUE_CONVERTER_ANDROID_H_

#include <jni.h>

#include "base/android/java_only_array.h"
#include "base/android/java_only_map.h"
#include "lepus/value.h"

namespace lynx {
namespace tasm {
namespace android {
class ValueConverterAndroid {
 public:
  // Convert lepus::Value To JavaOnlyMap
  static base::android::JavaOnlyMap ConvertLepusToJavaOnlyMap(
      const lepus::Value &value);
  // Convert lepus::Value To JavaOnlyArray
  static base::android::JavaOnlyArray ConvertLepusToJavaOnlyArray(
      const lepus::Value &value);
  // Convert JavaOnlyArray jobject to lepus::Value
  static lepus::Value ConvertJavaOnlyArrayToLepus(JNIEnv *env, jobject array);
  // Convert JavaOnlyMap jobject to lepus::Value
  static lepus::Value ConvertJavaOnlyMapToLepus(JNIEnv *env, jobject map);
};

}  // namespace android
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_UTILS_ANDROID_VALUE_CONVERTER_ANDROID_H_
