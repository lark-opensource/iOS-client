// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_JSC_JSC_HOST_OBJECT_H_
#define LYNX_JSBRIDGE_JSC_JSC_HOST_OBJECT_H_

#include <JavaScriptCore/JavaScript.h>

#include <atomic>
#include <memory>
#include <mutex>
#include <string>

#include "jsbridge/jsc/jsc_helper.h"
#include "jsbridge/jsc/jsc_runtime.h"
#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {
class JSCRuntime;
namespace detail {

struct JSCHostObjectProxyBase {
  JSCHostObjectProxyBase(JSCRuntime& rt, const std::shared_ptr<HostObject>& sho)
      : runtime(rt),
        hostObject(sho),
        is_runtime_destroyed_(rt.GetRuntimeDestroyedFlag()) {}

 public:
  JSCRuntime& runtime;
  std::shared_ptr<HostObject> hostObject;
  std::shared_ptr<bool> is_runtime_destroyed_;
  friend class JSCRuntime;
};

struct JSCHostObjectProxy : public JSCHostObjectProxyBase {
 public:
  JSCHostObjectProxy(JSCRuntime& rt, const std::shared_ptr<HostObject>& sho)
      : JSCHostObjectProxyBase(rt, sho) {}

  static JSValueRef getProperty(JSContextRef ctx, JSObjectRef object,
                                JSStringRef propertyName,
                                JSValueRef* exception);

  static bool setProperty(JSContextRef ctx, JSObjectRef object,
                          JSStringRef propertyName, JSValueRef value,
                          JSValueRef* exception);

  static void getPropertyNames(
      JSContextRef ctx, JSObjectRef object,
      JSPropertyNameAccumulatorRef propertyNames) noexcept;

  static void finalize(JSObjectRef obj);

  static Object createObject(JSCRuntime& rt, JSGlobalContextRef ctx,
                             std::shared_ptr<HostObject> ho);

  static JSClassRef getHostObjectClass();

  friend class JSCRuntime;
};

}  // namespace detail
}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_JSC_JSC_HOST_OBJECT_H_
