#include "jsbridge/v8/v8_exception.h"

#include "base/compiler_specific.h"
#include "jsbridge/v8/v8_helper.h"
#include "v8.h"

namespace lynx {
namespace piper {

bool V8Exception::ReportExceptionIfNeeded(V8Runtime &rt,
                                          v8::TryCatch &try_catch) {
  if (UNLIKELY(try_catch.HasCaught())) {
    V8Exception exception(rt, try_catch.Exception());
    rt.reportJSIException(exception);
    return false;
  }
  return true;
}

}  // namespace piper
}  // namespace lynx
