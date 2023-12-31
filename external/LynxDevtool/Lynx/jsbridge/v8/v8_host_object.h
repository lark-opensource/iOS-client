// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_V8_V8_HOST_OBJECT_H_
#define LYNX_JSBRIDGE_V8_V8_HOST_OBJECT_H_

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

// HostObject details
struct V8HostObjectProxyBase {
  V8HostObjectProxyBase(V8Runtime* rt,
                        const std::shared_ptr<piper::HostObject>& sho);
  ~V8HostObjectProxyBase() = default;

 public:
  V8Runtime* runtime;
  std::shared_ptr<piper::HostObject> hostObject;
  std::shared_ptr<bool> is_runtime_destroyed_;
  v8::Persistent<v8::Object> keeper_;
  friend class V8Runtime;
};

struct V8HostObjectProxy : public V8HostObjectProxyBase {
 public:
  V8HostObjectProxy(V8Runtime* rt,
                    const std::shared_ptr<piper::HostObject>& sho)
      : V8HostObjectProxyBase(rt, sho) {}

  static void getProperty(v8::Local<v8::Name> property,
                          const v8::PropertyCallbackInfo<v8::Value>& info);

  static void setProperty(v8::Local<v8::Name> property,
                          v8::Local<v8::Value> value,
                          const v8::PropertyCallbackInfo<v8::Value>& info);

  static void getPropertyNames(const v8::PropertyCallbackInfo<v8::Array>& info);

  static piper::Object createObject(V8Runtime* rt,
                                    v8::Local<v8::Context> context,
                                    std::shared_ptr<piper::HostObject> ho);

  static void onFinalize(const v8::WeakCallbackInfo<V8HostObjectProxy>& data);

  const static std::string HOST_OBJ_KEY;

  friend class V8Runtime;
};

};  // namespace detail

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_V8_V8_HOST_OBJECT_H_
