//  Copyright 2022 The Lynx Authors. All rights reserved.

#include <jni.h>

#include "base/android/scoped_java_ref.h"
#include "tasm/lepus_api_actor/lepus_api_actor.h"

#ifndef LYNX_TASM_LEPUS_API_ACTOR_ANDROID_LEPUS_API_ACTOR_ANDROID_H_
#define LYNX_TASM_LEPUS_API_ACTOR_ANDROID_LEPUS_API_ACTOR_ANDROID_H_

namespace lynx {
namespace tasm {
class LepusApiActorAndroid : public LepusApiActor {
 public:
  static bool RegisterJNI(JNIEnv *env);
  LepusApiActorAndroid(JNIEnv *env, jobject impl) : impl_(env, impl) {}
  virtual ~LepusApiActorAndroid() override = default;
  void InvokeLepusApiCallback(JNIEnv *env, jobject jcaller, jlong nativePtr,
                              jint callbackID, jstring entryName, jobject data);

 private:
  base::android::ScopedWeakGlobalJavaRef<jobject> impl_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_LEPUS_API_ACTOR_ANDROID_LEPUS_API_ACTOR_ANDROID_H_
