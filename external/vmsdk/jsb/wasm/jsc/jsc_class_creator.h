// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_JSC_CLASS_CREATOR_H_
#define JSB_WASM_JSC_CLASS_CREATOR_H_

#include <JavaScriptCore/JavaScriptCore.h>

#include "jsc_class_creator.h"

namespace vmsdk {
namespace jsc {

class JSClassCreator {
 public:
  static JSClassRef Create(const JSClassDefinition& def);
  static JSClassRef Create(const char* name,
                           JSObjectFinalizeCallback finalizer);
  static JSClassDefinition GetClassDefinition(
      const char* name, JSObjectFinalizeCallback finalizer = NULL,
      JSObjectCallAsConstructorCallback callback = NULL);

  inline static JSPropertyAttributes DefaultAttr() {
    return kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum |
           kJSPropertyAttributeDontDelete;
  }
};

}  // namespace jsc
}  // namespace vmsdk
#endif  // JSB_WASM_JSC_CLASS_CREATOR_H_
