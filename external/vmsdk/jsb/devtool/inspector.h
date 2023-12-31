// Copyright 2021 The vmsdk Authors. All rights reserved.

#ifndef JSB_DEVTOOL_INSPECTOR_H
#define JSB_DEVTOOL_INSPECTOR_H

#if defined(OS_IOS)
#define JS_ENGINE_QJS
#endif

#ifdef JS_ENGINE_V8
#include "v8-inspector.h"
#endif

#ifdef JS_ENGINE_QJS
#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif  // __cplusplus
#endif  // JS_ENGINE_QJS

namespace vmsdk {
namespace devtool {

class Inspector {
 public:
  virtual ~Inspector() = default;
#ifdef JS_ENGINE_V8
  virtual void AttachIsolate(::v8::Isolate *isolate) = 0;
  virtual void DetachIsolate(::v8::Isolate *isolate) = 0;
  virtual void ContextCreated(::v8::Local<::v8::Context> context) = 0;
  virtual void ContextDestroyed(::v8::Local<::v8::Context> context) = 0;
#endif

#ifdef JS_ENGINE_QJS
  virtual void QjsAttachRuntime(LEPUSRuntime *rt) = 0;
  virtual void QjsDetachRuntime() = 0;
  virtual void QjsContextCreated(LEPUSContext *ctx) = 0;
  virtual void QjsContextDestroyed() = 0;
#endif
};

}  // namespace devtool
}  // namespace vmsdk
#endif  // JSB_DEVTOOL_INSPECTOR_H
