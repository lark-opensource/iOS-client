//
// Created by 李岩波 on 2019-09-12.
//

#include "quickjs_runtime_wrapper.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "cutils.h"
#ifdef __cplusplus
}
#endif

#include "base/threading/thread_local.h"
#include "quickjs_host_function.h"
#include "quickjs_host_object.h"

namespace lynx {
namespace piper {

using detail::QuickjsHostFunctionProxy;
using detail::QuickjsHostObjectProxy;

QuickjsRuntimeInstance::~QuickjsRuntimeInstance() {
  LOGE("LYNX free quickjs runtime start");
  if (rt_) {
    LEPUS_FreeRuntime(rt_);
  }
  GetFunctionIdContainer().erase(rt_);
  GetObjectIdContainer().erase(rt_);

  LOGI("LYNX free quickjs runtime end. " << this << " LEPUSRuntime: " << rt_);
}

LepusIdContainer& QuickjsRuntimeInstance::GetObjectIdContainer() {
  static lynx_thread_local(LepusIdContainer) sObjectIdContainer;
  return sObjectIdContainer;
}

LepusIdContainer& QuickjsRuntimeInstance::GetFunctionIdContainer() {
  static lynx_thread_local(LepusIdContainer) sFunctionIdContainer;
  return sFunctionIdContainer;
}

LEPUSClassDef& QuickjsRuntimeInstance::GetFunctionClassDef() {
  static base::NoDestructor<LEPUSClassDef> sFunctionClassDef(LEPUSClassDef{
      .class_name = "LynxFunctionDef",
      .finalizer = QuickjsHostFunctionProxy::hostFinalizer,
      .call = QuickjsHostFunctionProxy::FunctionCallback,
  });
  return *sFunctionClassDef;
}

LEPUSClassDef& QuickjsRuntimeInstance::GetObjectClassDef() {
  static base::NoDestructor<LEPUSClassExoticMethods> sExoticMethod(
      LEPUSClassExoticMethods{
          .get_own_property = QuickjsHostObjectProxy::getOwnProperty,
          .get_own_property_names = QuickjsHostObjectProxy::getPropertyNames,
          .get_property = QuickjsHostObjectProxy::getProperty,
          .set_property = QuickjsHostObjectProxy::setProperty,
      });
  static base::NoDestructor<LEPUSClassDef> sObjectClassDef(LEPUSClassDef{
      .class_name = "LynxObjectClassDef",
      .finalizer = QuickjsHostObjectProxy::hostFinalizer,
      .exotic = sExoticMethod.get(),
  });
  return *sObjectClassDef;
}

void QuickjsRuntimeInstance::InitQuickjsRuntime() {
  LEPUSRuntime* rt;
  rt = LEPUS_NewRuntime();
  LEPUS_SetRuntimeInfo(rt, "Lynx_JS");
  if (!rt) {
    LOGE("init quickjs runtime failed!");
    return;
  }
  rt_ = rt;
  InitFunctionClassId();
  InitObjectClassId();
  LOGI("lynx InitQuickjsRuntime success");
}

void QuickjsRuntimeInstance::InitFunctionClassId() {
  LEPUS_NewClassID(&mFunctionId);
  LEPUS_NewClass(rt_, mFunctionId, &GetFunctionClassDef());
  GetFunctionIdContainer().insert({rt_, mFunctionId});
}

void QuickjsRuntimeInstance::InitObjectClassId() {
  LEPUS_NewClassID(&mObjectID);
  LEPUS_NewClass(rt_, mObjectID, &GetObjectClassDef());
  GetObjectIdContainer().insert({rt_, mObjectID});
}

}  // namespace piper
}  // namespace lynx
