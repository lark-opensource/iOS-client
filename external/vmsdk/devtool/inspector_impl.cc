#include "devtool/inspector_impl.h"

#include <utility>

#include "basic/log/logging.h"
namespace vmsdk {
namespace devtool {

InspectorImpl::~InspectorImpl() = default;

#if defined(OS_ANDROID)
InspectorImpl::InspectorImpl(jobject inspector_client,
                             std::shared_ptr<runtime::TaskRunner> taskRunner)
    : taskRunner_(std::move(taskRunner)) {
  inspector_bridge_android_ =
      std::make_unique<android::InspectorBridgeAndroid>(inspector_client, this);
}
#endif
#if defined(OS_IOS)
// after call InspectorImpl, when use inspector_bridge_iOS_, remember to call
// initInspectorImpl first
InspectorImpl::InspectorImpl(
    std::shared_ptr<iOS::VMSDKDebugICBase> inspector_client,
    std::shared_ptr<runtime::TaskRunner> taskRunner)
    : taskRunner_(std::move(taskRunner)) {
  inspector_bridge_iOS_.reset();
  //    inspector_bridge_iOS_ =
  //    std::make_unique<iOS::InspectorBridgeiOS>(inspector_client, this);
}

/**
 * shared_from_this() should be used after class's constructor
 * after new InspectorImpl class, must call this function to init
 * inspector_bridge_iOS_(which is done in inspector_factory_impl)
 */
void InspectorImpl::initInspectorImpl(
    std::shared_ptr<iOS::VMSDKDebugICBase> inspector_client) {
  inspector_bridge_iOS_ =
      createInspectorBridge(inspector_client, shared_from_this());
}
#endif

// js engine to HDT
void InspectorImpl::SendResponseMessage(const std::string &message) {
#if defined(OS_ANDROID)
  inspector_bridge_android_->SendResponseMessage(message);
#endif
#if defined(OS_IOS)
  inspector_bridge_iOS_->SendResponseMessage(message);
#endif
}

// HDT to js engine
void InspectorImpl::DispatchMessage(const std::string &message) {
#ifdef JS_ENGINE_V8
  if (v8_inspector_handle_) {
    v8_inspector_handle_->DispatchMessage(message);
  }
#endif

#ifdef JS_ENGINE_QJS
  if (qjs_inspector_handle_) {
    qjs_inspector_handle_->DispatchMessage(message, taskRunner_);
  }
#endif
}

#ifdef JS_ENGINE_V8
void InspectorImpl::AttachIsolate(::v8::Isolate *isolate) {
  v8_inspector_handle_ = std::make_unique<v8::V8InspectorHandle>(isolate, this);
}
void InspectorImpl::DetachIsolate(::v8::Isolate *isolate) {
  v8_inspector_handle_.reset();
}
void InspectorImpl::ContextCreated(::v8::Local<::v8::Context> context) {
  if (v8_inspector_handle_) {
    v8_inspector_handle_->ContextCreated(context);
  }
}
void InspectorImpl::ContextDestroyed(::v8::Local<::v8::Context> context) {
  if (v8_inspector_handle_) {
    v8_inspector_handle_->ContextDestroyed(context);
  }
}
#endif

#ifdef JS_ENGINE_QJS
void InspectorImpl::QjsAttachRuntime(LEPUSRuntime *qjs_runtime) {
  qjs_inspector_handle_ =
      std::make_unique<qjs::QjsInspectorHandle>(qjs_runtime, this);
}
void InspectorImpl::QjsDetachRuntime() { qjs_inspector_handle_.reset(); }
void InspectorImpl::QjsContextCreated(LEPUSContext *qjs_context_) {
  if (qjs_inspector_handle_) {
    qjs_inspector_handle_->ContextCreated(qjs_context_);
  }
}
void InspectorImpl::QjsContextDestroyed() {
  if (qjs_inspector_handle_) {
    qjs_inspector_handle_->ContextDestroyed();
  }
}
#endif

}  // namespace devtool
}  // namespace vmsdk
