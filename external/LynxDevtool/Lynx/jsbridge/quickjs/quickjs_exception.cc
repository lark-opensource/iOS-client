//
// Created by 李岩波 on 2019-09-24.
//

#include "jsbridge/quickjs/quickjs_exception.h"

#include "base/compiler_specific.h"
#include "base/log/logging.h"
#include "base/string/string_utils.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/quickjs/quickjs_helper.h"

namespace lynx {
namespace piper {
bool QuickjsException::ReportExceptionIfNeeded(QuickjsRuntime &rt,
                                               LEPUSValue value) {
  if (UNLIKELY(LEPUS_IsException(value))) {
    auto ctx = rt.getJSContext();
    LEPUSValue exception_val = LEPUS_GetException(ctx);
    rt.reportJSIException(QuickjsException(rt, exception_val));
    return false;
  }
  return true;
}

}  // namespace piper
}  // namespace lynx
