// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_JSC_JSC_EXCEPTION_H_
#define LYNX_JSBRIDGE_JSC_JSC_EXCEPTION_H_

#include <JavaScriptCore/JavaScript.h>

#include <string>

#include "jsbridge/jsc/jsc_helper.h"
#include "jsbridge/jsc/jsc_runtime.h"

namespace lynx {
namespace piper {

class JSCException : public JSError {
 public:
  JSCException(JSCRuntime& rt, JSValueRef value)
      : JSError(rt, detail::JSCHelper::createValue(rt, value)) {}

  static bool ReportExceptionIfNeeded(JSGlobalContextRef, JSCRuntime&,
                                      JSValueRef);
  static bool ReportExceptionIfNeeded(JSGlobalContextRef, JSCRuntime&,
                                      JSValueRef, JSValueRef);
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_JSC_JSC_EXCEPTION_H_
