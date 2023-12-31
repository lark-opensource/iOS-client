#include "jsbridge/v8/v8_host_function.h"

#include <mutex>
#include <utility>

#include "base/compiler_specific.h"
#include "base/log/logging.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/utils/args_converter.h"
#include "jsbridge/v8/v8_helper.h"
#include "jsbridge/v8/v8_host_object.h"
#include "jsbridge/v8/v8_runtime.h"
#include "libplatform/libplatform.h"
#include "v8.h"

namespace lynx {
namespace piper {
namespace detail {
const std::string V8HostFunctionProxy::HOST_FUN_KEY = "hostFunctionFlag";

V8HostFunctionProxy::V8HostFunctionProxy(piper::HostFunctionType hostFunction,
                                         V8Runtime* rt)
    : hostFunction_(std::move(hostFunction)),
      rt_(rt),
      is_runtime_destroyed_(rt->GetRuntimeDestroyedFlag()) {}

v8::Local<v8::Object> V8HostFunctionProxy::createFunctionFromHostFunction(
    V8Runtime* rt, v8::Local<v8::Context> ctx, const piper::PropNameID& name,
    unsigned int paramCount, piper::HostFunctionType func) {
  v8::Local<v8::ObjectTemplate> function_template =
      rt->GetHostFunctionTemplate();
  if (function_template.IsEmpty()) {
    function_template = v8::ObjectTemplate::New(ctx->GetIsolate());
    function_template->SetInternalFieldCount(1);
    function_template->SetCallAsFunctionHandler(FunctionCallback);
    rt->SetHostFunctionTemplate(function_template);
  }

  v8::Local<v8::Object> obj =
      function_template->NewInstance(ctx).ToLocalChecked();
  V8HostFunctionProxy* proxy = new V8HostFunctionProxy(std::move(func), rt);
  obj->SetAlignedPointerInInternalField(0, proxy);
  v8::Local<v8::Private> key = v8::Private::New(
      ctx->GetIsolate(),
      V8Helper::ConvertToV8String(ctx->GetIsolate(), HOST_FUN_KEY));
  obj->SetPrivate(
      ctx, key, V8Helper::ConvertToV8String(ctx->GetIsolate(), "hostFunction"));

  // Add prototype to HostFunction
  v8::MaybeLocal<v8::Value> func_ctor = ctx->Global()->Get(
      ctx, V8Helper::ConvertToV8String(ctx->GetIsolate(), "Function"));
  if (LIKELY(!func_ctor.IsEmpty())) {
#if OS_ANDROID
    v8::Maybe<bool> result =
        obj->SetPrototype(ctx, func_ctor.ToLocalChecked()
                                   ->ToObject(ctx->GetIsolate())
                                   ->GetPrototype());
#else
    v8::Maybe<bool> result = obj->SetPrototype(ctx, func_ctor.ToLocalChecked()
                                                        ->ToObject(ctx)
                                                        .ToLocalChecked()
                                                        ->GetPrototype());
#endif
    ALLOW_UNUSED_LOCAL(result);
  }
  proxy->keeper_.Reset(ctx->GetIsolate(), obj);
  proxy->keeper_.SetWeak(proxy, onFinalize, v8::WeakCallbackType::kParameter);
  return obj;
}

piper::HostFunctionType& getHostFunction(V8Runtime* rt,
                                         const piper::Function& obj) {
  v8::Local<v8::Object> v8_obj = V8Helper::objectRef(obj);
  void* data = v8_obj->GetAlignedPointerFromInternalField(0);
  auto proxy = static_cast<V8HostFunctionProxy*>(data);
  return proxy->getHostFunction();
}

void V8HostFunctionProxy::FunctionCallback(
    const v8::FunctionCallbackInfo<v8::Value>& info) {
  v8::Local<v8::Object> obj = info.Holder();
  V8HostFunctionProxy* proxy = static_cast<V8HostFunctionProxy*>(
      obj->GetAlignedPointerFromInternalField(0));

  if (UNLIKELY(proxy == nullptr || *proxy->is_runtime_destroyed_)) {
    LOGE("V8HostFunctionProxy::FunctionCallback Error!");
    // TODO(wangqingyu): HostFunction supports throw exception
    return;
  }

  int count = info.Length();
  auto context = info.GetIsolate()->GetCurrentContext();
  auto converter = ArgsConverter<Value>(
      count, info, [&context](const v8::Local<v8::Value>& value) {
        return V8Helper::createValue(value, context);
      });
  std::optional<piper::Value> ret_opt = proxy->hostFunction_(
      *proxy->rt_,
      V8Helper::createValue(info.Holder(),
                            info.GetIsolate()->GetCurrentContext()),
      converter, count);
  if (ret_opt) {
    info.GetReturnValue().Set(proxy->rt_->valueRef(*ret_opt));
    return;
  }
  // TODO(wangqingyu): HostFunction supports throw exception
  info.GetReturnValue().Set(v8::Local<v8::Value>());
}

void V8HostFunctionProxy::onFinalize(
    const v8::WeakCallbackInfo<V8HostFunctionProxy>& data) {
  V8HostFunctionProxy* proxy = data.GetParameter();
  proxy->keeper_.Reset();
  delete proxy;
}

}  // namespace detail

}  // namespace piper
}  // namespace lynx
