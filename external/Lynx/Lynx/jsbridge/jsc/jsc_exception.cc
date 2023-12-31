// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/jsc/jsc_exception.h"

#include <cstring>

#include "base/compiler_specific.h"
#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {
using detail::JSCHelper;
bool JSCException::ReportExceptionIfNeeded(JSGlobalContextRef ctx,
                                           JSCRuntime& rt, JSValueRef exc) {
  if (UNLIKELY((bool)exc)) {
    JSCException error(rt, exc);
    rt.reportJSIException(error);
    return false;
  }
  return true;
}

bool JSCException::ReportExceptionIfNeeded(JSGlobalContextRef ctx,
                                           JSCRuntime& rt, JSValueRef res,
                                           JSValueRef exc) {
  if (UNLIKELY((bool)!res)) {
    ReportExceptionIfNeeded(ctx, rt, exc);
    return false;
  }
  return true;
}

}  // namespace piper
}  // namespace lynx
