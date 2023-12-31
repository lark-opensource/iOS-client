// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_AIR_BRIDGE_ANDROID_AIR_MODULE_HANDLER_ANDROID_H_
#define LYNX_TASM_AIR_BRIDGE_ANDROID_AIR_MODULE_HANDLER_ANDROID_H_
#include <memory>
#include <string>

#include "base/android/scoped_java_ref.h"
#include "tasm/air/bridge/air_module_handler.h"

namespace lynx {
namespace air {
class AirModuleHandlerAndroid : public AirModuleHandler {
 public:
  static void RegisterJNI(JNIEnv *env);
  AirModuleHandlerAndroid(JNIEnv *env, jobject impl);
  ~AirModuleHandlerAndroid() override;

  lepus::Value TriggerBridgeSync(const std::string &method_name,
                                 const lynx::lepus::Value &arguments) override;

  void TriggerBridgeAsync(const std::string &method_name,
                          const lynx::lepus::Value &arguments) override;

  void InvokeAirModuleCallback(JNIEnv *env, jobject jcaller, jlong nativePtr,
                               jint callbackID, jstring entryName,
                               jobject data);

  void SetEngineActor(std::shared_ptr<shell::LynxActor<lynx::shell::LynxEngine>>
                          actor) override {
    engine_actor_ = actor;
  }

 private:
  base::android::ScopedWeakGlobalJavaRef<jobject> jni_object_;
  std::shared_ptr<shell::LynxActor<shell::LynxEngine>> engine_actor_;
  void Destroy();
};
}  // namespace air
}  // namespace lynx

#endif  // LYNX_TASM_AIR_BRIDGE_ANDROID_AIR_MODULE_HANDLER_ANDROID_H_
