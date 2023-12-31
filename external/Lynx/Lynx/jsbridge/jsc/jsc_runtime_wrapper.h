#ifndef LYNX_JSBRIDGE_JSC_JSC_RUNTIME_WRAPPER_H_
#define LYNX_JSBRIDGE_JSC_JSC_RUNTIME_WRAPPER_H_

#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {
class JSCRuntimeWrapper : public VMInstance {
 public:
  JSRuntimeType GetRuntimeType() { return piper::jsc; }
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_JSC_JSC_RUNTIME_WRAPPER_H_
