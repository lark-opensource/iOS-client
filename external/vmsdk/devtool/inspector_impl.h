#ifndef DEVTOOL_INSPECTOR_IMPL_H
#define DEVTOOL_INSPECTOR_IMPL_H

#include <jsb/runtime/task_runner.h>

#include <memory>

#include "jsb/devtool/inspector.h"
#if defined(OS_ANDROID)
#include "devtool/android/inspector_bridge_android.h"
#endif
#if defined(OS_IOS)
#include "devtool/iOS/inspector_bridge_iOS.h"
#define JS_ENGINE_QJS
#endif

#if defined(JS_ENGINE_V8)
#include "devtool/v8/v8_inspector_handle.h"
#endif

#if defined(JS_ENGINE_QJS)
#include "devtool/quickjs/qjs_inspector_handle.h"
#endif

namespace vmsdk {
namespace devtool {

class InspectorImpl : public Inspector,
                      public std::enable_shared_from_this<InspectorImpl> {
 public:
  virtual ~InspectorImpl() override;

#if defined(OS_ANDROID)
  InspectorImpl(jobject inspector_client,
                std::shared_ptr<runtime::TaskRunner> taskRunner);
#endif
#if defined(OS_IOS)
  InspectorImpl(std::shared_ptr<iOS::VMSDKDebugICBase> inspector_client,
                std::shared_ptr<runtime::TaskRunner> taskRunner);
  void initInspectorImpl(
      std::shared_ptr<iOS::VMSDKDebugICBase> inspector_client);
#endif

  void SendResponseMessage(const std::string &message);
  void DispatchMessage(const std::string &message);

#ifdef JS_ENGINE_V8
  void AttachIsolate(::v8::Isolate *isolate) override;
  void DetachIsolate(::v8::Isolate *isolate) override;
  void ContextCreated(::v8::Local<::v8::Context> context) override;
  void ContextDestroyed(::v8::Local<::v8::Context> context) override;
#endif

#ifdef JS_ENGINE_QJS
  void QjsAttachRuntime(LEPUSRuntime *qjs_runtime) override;
  void QjsDetachRuntime() override;
  void QjsContextCreated(LEPUSContext *qjs_context_) override;
  void QjsContextDestroyed() override;
#endif

 private:
#if defined(OS_ANDROID)
  std::unique_ptr<android::InspectorBridgeAndroid> inspector_bridge_android_;
#endif
#if defined(OS_IOS)
  std::shared_ptr<iOS::InspectorBridgeiOS> inspector_bridge_iOS_;
#endif
#if defined(JS_ENGINE_V8)
  std::unique_ptr<v8::V8InspectorHandle> v8_inspector_handle_;
#endif

#if defined(JS_ENGINE_QJS)
  std::unique_ptr<qjs::QjsInspectorHandle> qjs_inspector_handle_;
#endif

  std::shared_ptr<runtime::TaskRunner> taskRunner_;
};
#if defined(OS_IOS)
std::shared_ptr<iOS::InspectorBridgeiOS> createInspectorBridge(
    std::shared_ptr<iOS::VMSDKDebugICBase> inspector_client,
    std::shared_ptr<InspectorImpl> devtool);
#endif

}  // namespace devtool
}  // namespace vmsdk
#endif  // DEVTOOL_INSPECTOR_IMPL_H
