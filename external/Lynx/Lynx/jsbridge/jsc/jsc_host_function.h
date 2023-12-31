// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_JSC_JSC_HOST_FUNCTION_H_
#define LYNX_JSBRIDGE_JSC_JSC_HOST_FUNCTION_H_

#include <JavaScriptCore/JavaScript.h>

#include <atomic>
#include <memory>
#include <mutex>
#include <string>
#include <utility>

#include "jsbridge/jsc/jsc_runtime.h"
#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {
class JSCRuntime;
namespace detail {

class JSCHostFunctionProxy {
 public:
  JSCHostFunctionProxy(HostFunctionType hostFunction, JSCRuntime& rt)
      : hostFunction_(std::move(hostFunction)), rt_(rt) {}

  HostFunctionType& getHostFunction() { return hostFunction_; }

  static Function createFunctionFromHostFunction(JSCRuntime& rt,
                                                 JSGlobalContextRef ctx,
                                                 const PropNameID& name,
                                                 unsigned int paramCount,
                                                 HostFunctionType func);

  static JSClassRef getHostFunctionClass();

 protected:
  HostFunctionType hostFunction_;
  JSCRuntime& rt_;
};

class HostFunctionMetadata : public JSCHostFunctionProxy {
 public:
  HostFunctionMetadata(JSCRuntime& rt, HostFunctionType hf, unsigned ac,
                       JSStringRef n)
      : JSCHostFunctionProxy(std::move(hf), rt),
        runtime_(rt),
        argCount_(ac),
        name_(JSStringRetain(n)),
        is_runtime_destroyed_(rt.GetRuntimeDestroyedFlag()) {}

  static void initialize(JSContextRef ctx, JSObjectRef object);

  static JSValueRef makeError(JSGlobalContextRef ctx, JSCRuntime& rt,
                              const std::string& desc);

  static JSValueRef call(JSContextRef ctx, JSObjectRef function,
                         JSObjectRef thisObject, size_t argumentCount,
                         const JSValueRef arguments[], JSValueRef* exception);

  static void finalize(JSObjectRef object);

  JSCRuntime& runtime_;
  unsigned argCount_;
  JSStringRef name_;
  std::shared_ptr<bool> is_runtime_destroyed_;
};

}  // namespace detail
}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_JSC_JSC_HOST_FUNCTION_H_
