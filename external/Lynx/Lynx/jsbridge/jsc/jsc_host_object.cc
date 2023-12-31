// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/jsc/jsc_host_object.h"

#include "base/compiler_specific.h"
#include "jsbridge/jsc/jsc_runtime.h"

namespace lynx {
namespace piper {
std::once_flag hostObjectClassOnceFlag;
JSClassRef hostObjectClass{};
namespace detail {

JSValueRef JSCHostObjectProxy::getProperty(JSContextRef ctx, JSObjectRef object,
                                           JSStringRef propertyName,
                                           JSValueRef* exception) {
  auto proxy = static_cast<JSCHostObjectProxy*>(JSObjectGetPrivate(object));
  if (UNLIKELY(proxy == nullptr || *proxy->is_runtime_destroyed_)) {
    LOGE("JSCHostObjectProxy::getProperty Error!");
    return JSValueMakeUndefined(ctx);
  }
  auto& rt = proxy->runtime;
  PropNameID sym =
      JSCHelper::createPropNameID(rt.objectCounter(), propertyName);
  Value ret;
  JSGlobalContextRef global_ctx = JSContextGetGlobalContext(ctx);
  ret = proxy->hostObject->get(&rt, sym);
  return JSCHelper::valueRef(global_ctx, rt, ret);
}

bool JSCHostObjectProxy::setProperty(JSContextRef ctx, JSObjectRef object,
                                     JSStringRef propertyName, JSValueRef value,
                                     JSValueRef* exception) {
  auto proxy = static_cast<JSCHostObjectProxy*>(JSObjectGetPrivate(object));
  if (UNLIKELY(proxy == nullptr || *proxy->is_runtime_destroyed_)) {
    LOGE("JSCHostObjectProxy::setProperty Error!");
    return JSValueMakeUndefined(ctx);
  }
  auto& rt = proxy->runtime;
  PropNameID sym =
      JSCHelper::createPropNameID(rt.objectCounter(), propertyName);
  proxy->hostObject->set(&rt, sym, JSCHelper::createValue(rt, value));
  return true;
}

void JSCHostObjectProxy::getPropertyNames(
    JSContextRef ctx, JSObjectRef object,
    JSPropertyNameAccumulatorRef propertyNames) noexcept {
  auto proxy = static_cast<JSCHostObjectProxy*>(JSObjectGetPrivate(object));
  if (UNLIKELY(proxy == nullptr || *proxy->is_runtime_destroyed_)) {
    LOGE("JSCHostObjectProxy::getPropertyNames Error!");
    return;
  }
  auto& rt = proxy->runtime;
  auto names = proxy->hostObject->getPropertyNames(rt);
  for (auto& name : names) {
    JSPropertyNameAccumulatorAddName(propertyNames, JSCHelper::stringRef(name));
  }
}

void JSCHostObjectProxy::finalize(JSObjectRef obj) {
  auto hostObject = static_cast<JSCHostObjectProxy*>(JSObjectGetPrivate(obj));
  JSObjectSetPrivate(obj, nullptr);
  delete hostObject;
}

Object JSCHostObjectProxy::createObject(JSCRuntime& rt, JSGlobalContextRef ctx,
                                        std::shared_ptr<HostObject> ho) {
  std::call_once(hostObjectClassOnceFlag, []() {
    JSClassDefinition hostObjectClassDef = kJSClassDefinitionEmpty;
    hostObjectClassDef.version = 0;
    hostObjectClassDef.attributes = kJSClassAttributeNoAutomaticPrototype;
    hostObjectClassDef.finalize = JSCHostObjectProxy::finalize;
    hostObjectClassDef.getProperty = JSCHostObjectProxy::getProperty;
    hostObjectClassDef.setProperty = JSCHostObjectProxy::setProperty;
    hostObjectClassDef.getPropertyNames = JSCHostObjectProxy::getPropertyNames;
    hostObjectClass = JSClassCreate(&hostObjectClassDef);
  });

  JSObjectRef obj =
      JSObjectMake(ctx, hostObjectClass, new JSCHostObjectProxy(rt, ho));
  return JSCHelper::createObject(ctx, rt.getCtxInvalid(), rt.objectCounter(),
                                 obj);
}

JSClassRef JSCHostObjectProxy::getHostObjectClass() { return hostObjectClass; }

}  // namespace detail
}  // namespace piper
}  // namespace lynx
