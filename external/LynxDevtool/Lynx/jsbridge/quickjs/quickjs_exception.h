//
// Created by 李岩波 on 2019-09-24.
//

#ifndef LYNX_JSBRIDGE_QUICKJS_QUICKJS_EXCEPTION_H_
#define LYNX_JSBRIDGE_QUICKJS_QUICKJS_EXCEPTION_H_

#include <string>

#include "jsbridge/jsi/jsi.h"
#include "jsbridge/quickjs/quickjs_runtime.h"

namespace lynx {
namespace piper {
class QuickjsException : public JSError {
 public:
  QuickjsException(QuickjsRuntime& rt, LEPUSValue value)
      : JSError(rt, detail::QuickjsHelper::createValue(value, &rt)) {}

  static bool ReportExceptionIfNeeded(QuickjsRuntime& rt, LEPUSValue value);
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_QUICKJS_QUICKJS_EXCEPTION_H_
