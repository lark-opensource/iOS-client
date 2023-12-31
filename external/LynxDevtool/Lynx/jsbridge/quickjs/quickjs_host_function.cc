#include "jsbridge/quickjs/quickjs_host_function.h"

#include <utility>

#include "base/compiler_specific.h"
#include "jsbridge/quickjs/quickjs_helper.h"
#include "jsbridge/quickjs/quickjs_runtime.h"
#include "jsbridge/utils/args_converter.h"
extern "C" {
#include "quickjs.h"
};
namespace lynx {
namespace piper {
namespace detail {

QuickjsHostFunctionProxy::QuickjsHostFunctionProxy(
    piper::HostFunctionType hostFunction, QuickjsRuntime* rt)
    : rt_(rt),
      hostFunction_(std::move(hostFunction)),
      is_runtime_destroyed_(rt->GetRuntimeDestroyedFlag()) {
  rt_->AddObserver(this);
}

QuickjsHostFunctionProxy::~QuickjsHostFunctionProxy() {
  if (rt_) {
    rt_->RemoveObserver(this);
    rt_ = nullptr;
  }
}

void QuickjsHostFunctionProxy::Update() {
  if (rt_) {
    rt_ = nullptr;
  }
}

void QuickjsHostFunctionProxy::hostFinalizer(LEPUSRuntime* rt, LEPUSValue val) {
  LEPUSClassID function_id =
      lynx::piper::QuickjsRuntimeInstance::getFunctionId(rt);
  if (UNLIKELY(function_id == 0)) {
    LOGE("hostFinalizer Error! functionId is 0. LEPUSRuntime:" << rt);
    return;
  }
  QuickjsHostFunctionProxy* th =
      static_cast<QuickjsHostFunctionProxy*>(LEPUS_GetOpaque(val, function_id));
  if (th) {
    delete th;
  }
}

LEPUSValue QuickjsHostFunctionProxy::FunctionCallback(
    LEPUSContext* ctx, LEPUSValueConst func_obj, LEPUSValueConst this_obj,
    int argc, LEPUSValueConst* argv, int flags) {
  LEPUSClassID functionId =
      lynx::piper::QuickjsRuntimeInstance::getFunctionId(ctx);
  if (UNLIKELY(functionId == 0)) {
    LOGE(
        "QuickjsHostFunctionProxy::FunctionCallback Error! functionId is 0. "
        "LEPUSContext:"
        << ctx);
    // TODO(wangqingyu): HostFunction supports throw exception
    return LEPUS_UNDEFINED;
  }
  QuickjsHostFunctionProxy* proxy = static_cast<QuickjsHostFunctionProxy*>(
      LEPUS_GetOpaque(func_obj, functionId));
  if (UNLIKELY(proxy == nullptr || *proxy->is_runtime_destroyed_ ||
               proxy->rt_ == nullptr)) {
    LOGE("QuickjsHostFunctionProxy::FunctionCallback Error! LEPUSContext:"
         << ctx);
    // TODO(wangqingyu): HostFunction supports throw exception
    return LEPUS_UNDEFINED;
  }
  auto converter = ArgsConverter<Value>(
      argc, argv, [&ctx, proxy](const LEPUSValueConst& value) {
        return QuickjsHelper::createValue(LEPUS_DupValue(ctx, value),
                                          proxy->rt_);
      });
  std::optional<piper::Value> ret_opt = proxy->hostFunction_(
      *(static_cast<Runtime*>(proxy->rt_)),
      QuickjsHelper::createValue(LEPUS_DupValue(ctx, this_obj), proxy->rt_),
      converter, argc);
  if (ret_opt) {
    return LEPUS_DupValue(ctx, proxy->rt_->valueRef(*ret_opt));
  }
  // TODO(wangqingyu): HostFunction supports throw exception
  return LEPUS_UNDEFINED;
}

// QuickjsHostFunctionProxy

piper::HostFunctionType& getHostFunction(QuickjsRuntime* rt,
                                         const piper::Function& obj) {
  DCHECK(rt->getFunctionClassID() != 0);
  LEPUSValue quick_obj = QuickjsHelper::objectRef(obj);

  QuickjsHostFunctionProxy* proxy = static_cast<QuickjsHostFunctionProxy*>(
      LEPUS_GetOpaque(quick_obj, rt->getFunctionClassID()));
  return proxy->getHostFunction();
}

LEPUSValue QuickjsHostFunctionProxy::createFunctionFromHostFunction(
    QuickjsRuntime* rt, LEPUSContext* ctx, const piper::PropNameID& name,
    unsigned int paramCount, piper::HostFunctionType func) {
  LEPUSClassID function_id = rt->getFunctionClassID();
  if (UNLIKELY(function_id == 0)) {
    LOGE("createFunctionFromHostFunction Error! function_id is 0. LEPUSContext:"
         << ctx);
    return LEPUS_UNDEFINED;
  }
  auto proxy = new QuickjsHostFunctionProxy(std::move(func), rt);
  LEPUSValue obj = LEPUS_NewObjectClass(ctx, function_id);

  //  LOGE( "LYNX" << " createFunctionFromHostFunction name=" <<
  //  name.utf8(*rt)); LOGE( "LYNX" << " createFunctionFromHostFunction
  //  ptr=" << LEPUS_VALUE_GET_PTR(obj));
  LEPUS_SetOpaque(obj, proxy);

  // Add prototype to HostFunction
  LEPUSValue global_obj = LEPUS_GetGlobalObject(ctx);
  LEPUSValue func_ctor = LEPUS_GetPropertyStr(ctx, global_obj, "Function");
  if (LIKELY(!LEPUS_IsException(func_ctor))) {
    LEPUS_SetPrototype(ctx, obj, LEPUS_GetPrototype(ctx, func_ctor));

    // Setup `name` and `length` properties for HostFunction.
    // `name` property indicates the typical number of arguments expected by the
    // function. This property has the attributes
    // {
    //   [[Writable]]: false,
    //   [[Enumerable]]: false,
    //   [[Configurable]]: true
    // }.
    // See: // https://tc39.es/ecma262/#sec-function-instances-name
    LEPUS_DefinePropertyValueStr(
        ctx, obj, "name",
        // Here we have to call `LEPUS_DupValue` to avoid crashing
        LEPUS_DupValue(ctx, QuickjsHelper::valueRef(name)),
        LEPUS_PROP_CONFIGURABLE);
    // `length` is descriptive of the function
    // This property has the attributes
    // {
    //   [[Writable]]: false,
    //   [[Enumerable]]: false,
    //   [[Configurable]]: true
    // }.
    // See: https://tc39.es/ecma262/#sec-function-instances-length
    LEPUS_DefinePropertyValueStr(
        ctx, obj, "length",
        LEPUS_NewInt32(ctx, static_cast<int32_t>(paramCount)),
        LEPUS_PROP_CONFIGURABLE);
  }
  LEPUS_FreeValue(ctx, func_ctor);
  LEPUS_FreeValue(ctx, global_obj);
  return obj;
}

}  // namespace detail

}  // namespace piper

}  // namespace lynx
