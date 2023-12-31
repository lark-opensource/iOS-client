#include "jsbridge/v8/v8_host_object.h"

#include <mutex>
#include <vector>

#include "base/compiler_specific.h"
#include "base/log/logging.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/v8/v8_helper.h"
#include "jsbridge/v8/v8_runtime.h"
#include "libplatform/libplatform.h"
#include "v8.h"

namespace lynx {
namespace piper {
namespace detail {
const std::string V8HostObjectProxy::HOST_OBJ_KEY = "hostObjectFlag";
V8HostObjectProxyBase::V8HostObjectProxyBase(
    V8Runtime* rt, const std::shared_ptr<piper::HostObject>& sho)
    : runtime(rt),
      hostObject(sho),
      is_runtime_destroyed_(rt->GetRuntimeDestroyedFlag()) {}

void V8HostObjectProxy::getProperty(
    v8::Local<v8::Name> property,
    const v8::PropertyCallbackInfo<v8::Value>& info) {
  v8::Local<v8::Object> obj = info.Holder();
  V8HostObjectProxy* proxy = static_cast<V8HostObjectProxy*>(
      obj->GetAlignedPointerFromInternalField(0));

  if (UNLIKELY(proxy == nullptr || *proxy->is_runtime_destroyed_)) {
    LOGE("V8HostObjectProxy::getProperty Error!");
    return;
  }

#if OS_ANDROID
  piper::Value va = proxy->hostObject->get(
      proxy->runtime, V8Helper::createPropNameID(property, info.GetIsolate()));
#else
  piper::Value va = proxy->hostObject->get(
      (Runtime*)proxy->runtime,
      V8Helper::createPropNameID(property, proxy->runtime->getContext()));
#endif
  info.GetReturnValue().Set(proxy->runtime->valueRef(va));
}

void V8HostObjectProxy::setProperty(
    v8::Local<v8::Name> property, v8::Local<v8::Value> value,
    const v8::PropertyCallbackInfo<v8::Value>& info) {
  v8::Local<v8::Object> obj = info.Holder();
  V8HostObjectProxy* proxy = static_cast<V8HostObjectProxy*>(
      obj->GetAlignedPointerFromInternalField(0));

  if (UNLIKELY(proxy == nullptr || *proxy->is_runtime_destroyed_)) {
    LOGE("V8HostObjectProxy::setProperty Error!");
    return;
  }

#if OS_ANDROID
  proxy->hostObject->set(
      proxy->runtime, V8Helper::createPropNameID(property, info.GetIsolate()),
      V8Helper::createValue(value, proxy->runtime->getContext()));
#else
  proxy->hostObject->set(
      (Runtime*)proxy->runtime,
      V8Helper::createPropNameID(property, proxy->runtime->getContext()),
      V8Helper::createValue(value, proxy->runtime->getContext()));
#endif
}

void V8HostObjectProxy::getPropertyNames(
    const v8::PropertyCallbackInfo<v8::Array>& info) {
  v8::Local<v8::Object> obj = info.Holder();
  V8HostObjectProxy* proxy = static_cast<V8HostObjectProxy*>(
      obj->GetAlignedPointerFromInternalField(0));

  if (UNLIKELY(proxy == nullptr || *proxy->is_runtime_destroyed_)) {
    LOGE("V8HostObjectProxy::getPropertyNames Error!");
    return;
  }

  Runtime* rt = proxy->runtime;
  std::vector<PropNameID> names = proxy->hostObject->getPropertyNames(*rt);

  auto ary = piper::Array::createWithLength(*rt, names.size());
  if (!ary) {
    return;
  }
  for (size_t i = 0; i < names.size(); i++) {
    if (!(*ary).setValueAtIndex(
            *rt, i, piper::String::createFromUtf8(*rt, names[i].utf8(*rt)))) {
      return;
    }
  }
  v8::Local<v8::Object> ary_obj = V8Helper::objectRef(*ary);
  v8::Local<v8::Array> result;
  result = result.Cast(ary_obj);
  info.GetReturnValue().Set(result);
}

void V8HostObjectProxy::onFinalize(
    const v8::WeakCallbackInfo<V8HostObjectProxy>& data) {
  V8HostObjectProxy* proxy = data.GetParameter();
  proxy->keeper_.Reset();
  delete proxy;
}

piper::Object V8HostObjectProxy::createObject(
    V8Runtime* rt, v8::Local<v8::Context> context,
    std::shared_ptr<piper::HostObject> ho) {
  ENTER_SCOPE(context)

  v8::Local<v8::ObjectTemplate> object_template = rt->GetHostObjectTemplate();
  if (object_template.IsEmpty()) {
    object_template = v8::ObjectTemplate::New(context->GetIsolate());
    object_template->SetInternalFieldCount(1);

    v8::NamedPropertyHandlerConfiguration config;
    config.getter = getProperty;
    config.setter = setProperty;
    config.enumerator = getPropertyNames;

    object_template->SetHandler(config);
    rt->SetHostObjectTemplate(object_template);
  }

  v8::Local<v8::Object> obj =
      object_template->NewInstance(context).ToLocalChecked();
  V8HostObjectProxy* proxy = new V8HostObjectProxy(rt, ho);
  obj->SetAlignedPointerInInternalField(0, proxy);
  v8::Local<v8::Private> key = v8::Private::New(
      context->GetIsolate(),
      V8Helper::ConvertToV8String(context->GetIsolate(), HOST_OBJ_KEY));
  obj->SetPrivate(
      context, key,
      V8Helper::ConvertToV8String(context->GetIsolate(), "hostObject"));
  proxy->keeper_.Reset(context->GetIsolate(), obj);
  proxy->keeper_.SetWeak(proxy, onFinalize, v8::WeakCallbackType::kParameter);
  return V8Helper::createObject(obj, context->GetIsolate());
}

}  // namespace detail
}  // namespace piper
}  // namespace lynx
