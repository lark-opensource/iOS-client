#ifndef LYNX_JSBRIDGE_V8_V8_EXCEPTION_H_
#define LYNX_JSBRIDGE_V8_V8_EXCEPTION_H_

#include <stdexcept>
#include <string>

#include "jsbridge/jsi/jsi.h"
#include "v8.h"
#include "v8_runtime.h"

namespace lynx {
namespace piper {

class V8Exception : public JSError {
 public:
  explicit V8Exception(V8Runtime &rt, v8::Local<v8::Value> value)
      : JSError(rt, detail::V8Helper::createValue(value, rt.getContext())) {}

  static bool ReportExceptionIfNeeded(V8Runtime &rt, v8::TryCatch &try_catch);
};
}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_V8_V8_EXCEPTION_H_
