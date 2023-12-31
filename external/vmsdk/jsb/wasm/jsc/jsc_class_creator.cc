// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "jsc_class_creator.h"

#include <JavaScriptCore/JavaScriptCore.h>

#include "jsc_ext_api.h"

namespace vmsdk {
namespace jsc {

JSClassRef JSClassCreator::Create(const JSClassDefinition& def) {
  return JSClassCreate(&def);
}

JSClassRef JSClassCreator::Create(const char* name,
                                  JSObjectFinalizeCallback finalizer) {
  JSClassDefinition def = GetClassDefinition(name, finalizer);
  return JSClassCreate(&def);
}

JSClassDefinition JSClassCreator::GetClassDefinition(
    const char* name, JSObjectFinalizeCallback finalizer,
    JSObjectCallAsConstructorCallback ctorCallback) {
  JSClassDefinition def = kJSClassDefinitionEmpty;
  def.attributes = kJSClassAttributeNoAutomaticPrototype;
  if (ctorCallback) {
    def.callAsConstructor = ctorCallback;
    // callAsFunction must be set so as to make typeof(constructor) ==
    // "function" for [[Constructor]], NOTE(): def.callAsFunction can be
    // overwritten by GetClassDefinition caller to allow the constructor can be
    // [[Call]] rather than the default behavior to throw exception.
    def.hasInstance = JSCExtAPI::HasInstance;
    def.callAsFunction = JSCExtAPI::ThrowCallException;
  }
  def.className = name;
  def.finalize = finalizer;
  return def;
}

}  // namespace jsc
}  // namespace vmsdk
