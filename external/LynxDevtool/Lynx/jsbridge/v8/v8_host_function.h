// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_V8_V8_HOST_FUNCTION_H_
#define LYNX_JSBRIDGE_V8_V8_HOST_FUNCTION_H_

#include <atomic>
#include <memory>
#include <mutex>
#include <string>

#include "base/observer/observer.h"
#include "jsbridge/jsi/jsi.h"
#include "v8.h"

namespace lynx {
namespace piper {
class V8Runtime;

namespace detail {

piper::HostFunctionType& getHostFunction(V8Runtime* rt,
                                         const piper::Function& obj);

class V8HostFunctionProxy {
 public:
  V8HostFunctionProxy(piper::HostFunctionType hostFunction, V8Runtime* rt);

  ~V8HostFunctionProxy() = default;

  piper::HostFunctionType& getHostFunction() { return hostFunction_; }

  static v8::Local<v8::Object> createFunctionFromHostFunction(
      V8Runtime* rt, v8::Local<v8::Context> ctx, const piper::PropNameID& name,
      unsigned int paramCount, piper::HostFunctionType func);
  const static std::string HOST_FUN_KEY;

 protected:
  static void FunctionCallback(const v8::FunctionCallbackInfo<v8::Value>& info);

  static void onFinalize(const v8::WeakCallbackInfo<V8HostFunctionProxy>& data);

  piper::HostFunctionType hostFunction_;
  V8Runtime* rt_;
  std::shared_ptr<bool> is_runtime_destroyed_;
  v8::Persistent<v8::Object> keeper_;
};

}  // namespace detail
}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_V8_V8_HOST_FUNCTION_H_
