//
// Created by 李岩波 on 2019-09-12.
//

#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_RUNTIME_WRAPPER_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_RUNTIME_WRAPPER_H_

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs.h"
#ifdef __cplusplus
}
#endif
#include <base/no_destructor.h>

#include <unordered_map>

#include "base/log/logging.h"
#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {
using LepusIdContainer = std::unordered_map<LEPUSRuntime*, LEPUSClassID>;
class QuickjsRuntimeInstance : public VMInstance {
 public:
  QuickjsRuntimeInstance() = default;
  virtual ~QuickjsRuntimeInstance();

  void InitQuickjsRuntime();
  inline LEPUSRuntime* Runtime() { return rt_; }
  LEPUSClassID getFunctionId() { return mFunctionId; }
  LEPUSClassID getObjectId() { return mObjectID; }

  static LEPUSClassID getFunctionId(LEPUSContext* ctx) {
    LEPUSRuntime* rt = LEPUS_GetRuntime(ctx);
    return getFunctionId(rt);
  }

  static LEPUSClassID getFunctionId(LEPUSRuntime* rt) {
    auto it = GetFunctionIdContainer().find(rt);
    DCHECK(it != GetFunctionIdContainer().end());
    if (it != GetFunctionIdContainer().end()) {
      return it->second;
    }
    return 0;
  }

  static LEPUSClassID getObjectId(LEPUSContext* ctx) {
    LEPUSRuntime* rt = LEPUS_GetRuntime(ctx);
    return getObjectId(rt);
  }

  static LEPUSClassID getObjectId(LEPUSRuntime* rt) {
    auto it = GetObjectIdContainer().find(rt);
    if (it != GetObjectIdContainer().end()) {
      return it->second;
    }
    return 0;
  }

  static LepusIdContainer& GetObjectIdContainer();
  static LepusIdContainer& GetFunctionIdContainer();
  static LEPUSClassDef& GetFunctionClassDef();
  static LEPUSClassExoticMethods& GetExoticMethods();
  static LEPUSClassDef& GetObjectClassDef();

  JSRuntimeType GetRuntimeType() { return piper::quickjs; }

 private:
  void InitFunctionClassId();
  void InitObjectClassId();
  LEPUSRuntime* rt_;
  LEPUSClassID mFunctionId = 0;
  LEPUSClassID mObjectID = 0;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_RUNTIME_WRAPPER_H_
