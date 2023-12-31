#include "jsbridge/quickjs/quickjs_host_object.h"

#include <vector>

#include "base/compiler_specific.h"
#include "jsbridge/quickjs/quickjs_runtime.h"

#ifdef __cplusplus
extern "C" {
#include "quickjs.h"
#endif
#ifdef __cplusplus
}
#endif
namespace lynx {
namespace piper {
namespace detail {
QuickjsHostObjectProxyBase::QuickjsHostObjectProxyBase(
    QuickjsRuntime* rt, const std::shared_ptr<piper::HostObject>& sho)
    : runtime(rt),
      hostObject(sho),
      is_runtime_destroyed_(rt->GetRuntimeDestroyedFlag()) {
  runtime->AddObserver(this);
};

QuickjsHostObjectProxyBase::~QuickjsHostObjectProxyBase() {
  //  LOGI( "lynx ~QuickjsHostObjectProxyBase");
  if (runtime) {
    runtime->RemoveObserver(this);
    runtime = nullptr;
  }
}

void QuickjsHostObjectProxyBase::Update() {
  if (runtime) {
    runtime = nullptr;
  }
}

void QuickjsHostObjectProxy::hostFinalizer(LEPUSRuntime* rt, LEPUSValue val) {
  LEPUSClassID object_id = lynx::piper::QuickjsRuntimeInstance::getObjectId(rt);
  if (UNLIKELY(object_id == 0)) {
    LOGE("HostObject Finalizer Error! object_id is 0. LEPUSRuntime:" << rt);
    return;
  }
  QuickjsHostObjectProxy* th =
      static_cast<QuickjsHostObjectProxy*>(LEPUS_GetOpaque(val, object_id));
  if (th) {
    delete th;
  }
}

LEPUSValue QuickjsHostObjectProxy::getProperty(LEPUSContext* ctx,
                                               LEPUSValueConst obj,
                                               LEPUSAtom atom,
                                               LEPUSValueConst receiver) {
  LEPUSClassID objectId = lynx::piper::QuickjsRuntimeInstance::getObjectId(ctx);
  if (objectId == 0) {
    LOGE(
        "QuickjsHostObjectProxy::getProperty Error! object id is 0. "
        "LEPUSContext:"
        << ctx);
    return LEPUS_UNDEFINED;
  }
  QuickjsHostObjectProxy* proxy =
      static_cast<QuickjsHostObjectProxy*>(LEPUS_GetOpaque(obj, objectId));
  LEPUSValue atom_val = LEPUS_AtomToValue(ctx, atom);
  if (LEPUS_IsException(atom_val)) {
    LOGE("Error getProperty is exception");
    LEPUS_FreeValue(ctx, atom_val);
    return LEPUS_EXCEPTION;
  }
  if (UNLIKELY(proxy == nullptr || *proxy->is_runtime_destroyed_ ||
               proxy->runtime == nullptr)) {
    LOGE("QuickjsHostObjectProxy::getProperty Error! LEPUSContext:" << ctx);
    return LEPUS_UNDEFINED;
  }

  piper::Value va =
      proxy->hostObject->get(static_cast<Runtime*>(proxy->runtime),
                             QuickjsHelper::createPropNameID(ctx, atom_val));
  LEPUSValue ret = LEPUS_DupValue(ctx, proxy->runtime->valueRef(va));

  if (LEPUS_IsException(ret) || LEPUS_IsError(ctx, ret)) {
    LOGE(std::string("Exception in HostObject::getProperty(propName:") +
         QuickjsHelper::LEPUSStringToSTLString(ctx, atom_val));
  }
  return ret;
}

// return 1 is ok, 0 is false.
int QuickjsHostObjectProxy::getOwnProperty(LEPUSContext* ctx,
                                           LEPUSPropertyDescriptor* desc,
                                           LEPUSValueConst obj,
                                           LEPUSAtom prop) {
  LEPUSClassID objectId = lynx::piper::QuickjsRuntimeInstance::getObjectId(ctx);
  if (objectId == 0) {
    LOGE(
        "Error getProperty sObjectClassId is null. objectId is 0. LEPUSContext:"
        << ctx);
    return 0;
  }
  QuickjsHostObjectProxy* proxy =
      static_cast<QuickjsHostObjectProxy*>(LEPUS_GetOpaque(obj, objectId));
  LEPUSValue atom_val = LEPUS_AtomToValue(ctx, prop);
  if (LEPUS_IsException(atom_val)) {
    LOGE("Error getOwnProperty atom_val is exception");
    LEPUSValue exception_val = LEPUS_GetException(ctx);
    auto error_msg = QuickjsHelper::getErrorMessage(ctx, exception_val);
    LOGE(error_msg);
    LEPUS_FreeValue(ctx, exception_val);
    LEPUS_FreeValue(ctx, atom_val);
    return 0;
  }
  if (UNLIKELY(proxy == nullptr || *proxy->is_runtime_destroyed_ ||
               proxy->runtime == nullptr)) {
    LOGE("QuickjsHostObjectProxy::getOwnProperty Error! LEPUSContext:" << ctx);
    return 0;
  }
  piper::Value va =
      proxy->hostObject->get(static_cast<Runtime*>(proxy->runtime),
                             QuickjsHelper::createPropNameID(ctx, atom_val));
  LEPUSValue ret = LEPUS_DupValue(ctx, proxy->runtime->valueRef(va));
  //  LOGE( "LYNX host_object_getPropertyNames jsvalueptr=" <<
  //  LEPUS_VALUE_GET_PTR(ret));
  if (desc) {
    desc->flags = LEPUS_PROP_ENUMERABLE;
    desc->value = ret;
    desc->getter = LEPUS_UNDEFINED;
    desc->setter = LEPUS_UNDEFINED;
  } else {
    LEPUS_FreeValue(ctx, ret);
  }
  return 1;
}

int QuickjsHostObjectProxy::setProperty(LEPUSContext* ctx, LEPUSValueConst obj,
                                        LEPUSAtom atom, LEPUSValueConst value,
                                        LEPUSValueConst receiver, int flags) {
  LEPUSClassID objectId = lynx::piper::QuickjsRuntimeInstance::getObjectId(ctx);
  if (objectId == 0) {
    LOGE("Error setProperty! objectId is 0. LEPUSContext:" << ctx);
    return -1;
  }
  QuickjsHostObjectProxy* proxy =
      static_cast<QuickjsHostObjectProxy*>(LEPUS_GetOpaque(obj, objectId));
  if (UNLIKELY(proxy == nullptr || *proxy->is_runtime_destroyed_ ||
               proxy->runtime == nullptr)) {
    LOGE("QuickjsHostObjectProxy::setProperty Error! LEPUSContext:" << ctx);
    return -1;
  }
  LEPUSValue atom_val = LEPUS_AtomToValue(ctx, atom);
  proxy->hostObject->set(
      static_cast<Runtime*>(proxy->runtime),
      QuickjsHelper::createPropNameID(ctx, atom_val),
      QuickjsHelper::createValue(LEPUS_DupValue(ctx, value), proxy->runtime));
  return 1;
}

int QuickjsHostObjectProxy::getPropertyNames(LEPUSContext* ctx,
                                             LEPUSPropertyEnum** ptab,
                                             uint32_t* plen,
                                             LEPUSValueConst obj) {
  LEPUSClassID objectId = lynx::piper::QuickjsRuntimeInstance::getObjectId(ctx);
  if (objectId == 0) {
    LOGE("Error getProperty! objectId is 0. LEPUSContext:" << ctx);
    return -1;
  }
  QuickjsHostObjectProxy* proxy =
      static_cast<QuickjsHostObjectProxy*>(LEPUS_GetOpaque(obj, objectId));
  Runtime* rt = proxy->runtime;
  if (UNLIKELY(proxy == nullptr || *proxy->is_runtime_destroyed_ ||
               proxy->runtime == nullptr)) {
    LOGE(
        "QuickjsHostObjectProxy::getPropertyNames Error! LEPUSContext:" << ctx);
    return -1;
  }
  std::vector<PropNameID> names = proxy->hostObject->getPropertyNames(*rt);
  LEPUSPropertyEnum* tab = nullptr;
  uint32_t len = names.size();
  if (len > 0) {
    tab = static_cast<LEPUSPropertyEnum*>(
        lepus_malloc(ctx, sizeof(LEPUSPropertyEnum) * len));
    if (!tab) {
      LOGE("getPropertyNames alloc tab error");
      return -1;
    }
    for (uint32_t i = 0; i < len; i++) {
      tab[i].atom = LEPUS_NewAtom(ctx, names[i].utf8(*rt).c_str());
    }
  }
  *ptab = tab;
  *plen = len;
  return 0;
}

piper::Object QuickjsHostObjectProxy::createObject(
    QuickjsRuntime* rt, std::shared_ptr<piper::HostObject> ho) {
  LEPUSContext* ctx = rt->getJSContext();
  LEPUSClassID object_id = rt->getObjectClassID();
  if (UNLIKELY(object_id == 0)) {
    LOGE("createHostObject error! object_id is 0. LEPUSContext:" << ctx);
    return QuickjsHelper::createObject(ctx, LEPUS_UNDEFINED);
  }
  QuickjsHostObjectProxy* proxy = new QuickjsHostObjectProxy(rt, ho);
  LEPUSValue obj = LEPUS_NewObjectClass(ctx, object_id);

  LEPUS_SetOpaque(obj, proxy);
  //  LOGE( "LYNX" << "NewObjectClass ptr=" << LEPUS_VALUE_GET_PTR(obj));

  return QuickjsHelper::createObject(ctx, obj);
}

}  // namespace detail

}  // namespace piper

}  // namespace lynx
