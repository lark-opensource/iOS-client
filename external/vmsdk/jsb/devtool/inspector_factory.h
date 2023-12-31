// Copyright 2021 The vmsdk Authors. All rights reserved.

#ifndef JSB_DEVTOOL_INSPECTOR_FACTORY_H
#define JSB_DEVTOOL_INSPECTOR_FACTORY_H

#include <memory>

#if defined(OS_ANDROID)
#include <jni.h>
#include <jsb/runtime/task_runner.h>

#endif

#if defined(OS_IOS)
#include <jsb/runtime/task_runner.h>

#include "devtool/iOS/VMSDKDebugICBase.h"  // for use vmsdk::devtool::VMSDKDebugICBase
#endif

#if defined(JS_ENGINE_V8)
#include "v8-inspector.h"
#endif

#include "jsb/devtool/inspector.h"

namespace vmsdk {
namespace devtool {

class InspectorFactory {
 public:
  InspectorFactory() = default;

  static void SetInstance(InspectorFactory *instance);

  static InspectorFactory *GetInstance();

#if defined(OS_ANDROID)
  virtual std::unique_ptr<Inspector> Create(
      jobject inspector_client,
      std::shared_ptr<runtime::TaskRunner> taskRunner) = 0;
#endif
#if defined(OS_IOS)
  virtual std::shared_ptr<Inspector> Create(
      std::shared_ptr<iOS::VMSDKDebugICBase> inspector_client,
      std::shared_ptr<runtime::TaskRunner> taskRunner) = 0;
#endif

 private:
  static InspectorFactory *GetOrSetInstance(
      InspectorFactory *instance = nullptr);

  InspectorFactory(const InspectorFactory &) = delete;
  InspectorFactory &operator=(const InspectorFactory &) = delete;
};

}  // namespace devtool
}  // namespace vmsdk
#endif  // JSB_DEVTOOL_INSPECTOR_FACTORY_H
