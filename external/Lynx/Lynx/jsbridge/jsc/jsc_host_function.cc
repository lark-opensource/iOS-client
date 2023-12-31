// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/jsc/jsc_host_function.h"

#include <utility>

#include "base/compiler_specific.h"
#include "base/log/logging.h"
#include "jsbridge/jsc/jsc_helper.h"
#include "jsbridge/jsc/jsc_host_object.h"
#include "jsbridge/jsc/jsc_runtime.h"
#include "jsbridge/utils/args_converter.h"

namespace lynx {
namespace piper {
std::once_flag hostFunctionClassOnceFlag;
JSClassRef hostFunctionClass{};
namespace detail {

Function JSCHostFunctionProxy::createFunctionFromHostFunction(
    JSCRuntime& rt, JSGlobalContextRef ctx, const PropNameID& name,
    unsigned int paramCount, HostFunctionType func) {
  std::call_once(hostFunctionClassOnceFlag, []() {
    JSClassDefinition functionClass = kJSClassDefinitionEmpty;
    functionClass.version = 0;
    functionClass.attributes = kJSClassAttributeNoAutomaticPrototype;
    functionClass.initialize = HostFunctionMetadata::initialize;
    functionClass.finalize = HostFunctionMetadata::finalize;
    functionClass.callAsFunction = HostFunctionMetadata::call;

    hostFunctionClass = JSClassCreate(&functionClass);
  });

  JSObjectRef funcRef =
      JSObjectMake(ctx, hostFunctionClass,
                   new HostFunctionMetadata(rt, std::move(func), paramCount,
                                            JSCHelper::stringRef(name)));
  return JSCHelper::createObject(ctx, rt.getCtxInvalid(), rt.objectCounter(),
                                 funcRef)
      .getFunction(rt);
}

JSClassRef JSCHostFunctionProxy::getHostFunctionClass() {
  return hostFunctionClass;
}

void HostFunctionMetadata::initialize(JSContextRef ctx, JSObjectRef object) {
  HostFunctionMetadata* metadata =
      static_cast<HostFunctionMetadata*>(JSObjectGetPrivate(object));
  if (UNLIKELY(metadata == nullptr || *metadata->is_runtime_destroyed_)) {
    LOGE("HostFunctionMetadata::initialize Error!");
    return;
  }

  JSValueRef exc = nullptr;
  JSObjectSetProperty(ctx, object, JSCHelper::getJSStringFromPool("length"),
                      JSValueMakeNumber(ctx, metadata->argCount_),
                      kJSPropertyAttributeReadOnly |
                          kJSPropertyAttributeDontEnum |
                          kJSPropertyAttributeDontDelete,
                      &exc);
  if (exc) {
    exc = nullptr;
  }

  JSStringRef name = nullptr;
  std::swap(metadata->name_, name);
  JSObjectSetProperty(ctx, object, JSCHelper::getJSStringFromPool("name"),
                      JSValueMakeString(ctx, name),
                      kJSPropertyAttributeReadOnly |
                          kJSPropertyAttributeDontEnum |
                          kJSPropertyAttributeDontDelete,
                      &exc);
  JSStringRelease(name);
  if (exc) {
    exc = nullptr;
  }

  JSObjectRef global = JSContextGetGlobalObject(ctx);
  JSValueRef value = JSObjectGetProperty(
      ctx, global, JSCHelper::getJSStringFromPool("Function"), &exc);
  // if (JSC_UNLIKELY(exc)) {
  //   abort();
  // }
  JSObjectRef funcCtor = JSValueToObject(ctx, value, &exc);
  if (!funcCtor) {
    return;
  }
  JSValueRef funcProto = JSObjectGetPrototype(ctx, funcCtor);
  JSObjectSetPrototype(ctx, object, funcProto);
}

JSValueRef HostFunctionMetadata::call(JSContextRef ctx, JSObjectRef function,
                                      JSObjectRef thisObject,
                                      size_t argumentCount,
                                      const JSValueRef arguments[],
                                      JSValueRef* exception) {
  HostFunctionMetadata* metadata =
      static_cast<HostFunctionMetadata*>(JSObjectGetPrivate(function));
  if (UNLIKELY(metadata == nullptr || *metadata->is_runtime_destroyed_)) {
    LOGE("HostFunctionMetadata::call Error!");
    // TODO(wangqingyu): HostFunction supports throw exception
    return JSValueMakeUndefined(ctx);
  }
  JSCRuntime& rt = metadata->runtime_;
  JSGlobalContextRef global_ctx = JSContextGetGlobalContext(ctx);
  auto converter = ArgsConverter<Value>(
      argumentCount, arguments,
      [&rt](const auto& value) { return JSCHelper::createValue(rt, value); });
  JSValueRef res;
  Value thisVal(JSCHelper::createObject(global_ctx, rt.getCtxInvalid(),
                                        rt.objectCounter(), thisObject));
  std::optional<piper::Value> ret_opt =
      metadata->hostFunction_(rt, thisVal, converter, argumentCount);
  if (ret_opt) {
    res = JSCHelper::valueRef(global_ctx, rt, *ret_opt);
  } else {
    // TODO(wangqingyu): HostFunction supports throw exception
    res = JSValueMakeUndefined(ctx);
  }
  return res;
}

void HostFunctionMetadata::finalize(JSObjectRef object) {
  HostFunctionMetadata* metadata =
      static_cast<HostFunctionMetadata*>(JSObjectGetPrivate(object));
  JSObjectSetPrivate(object, nullptr);
  delete metadata;
}

}  // namespace detail
}  // namespace piper
}  // namespace lynx
