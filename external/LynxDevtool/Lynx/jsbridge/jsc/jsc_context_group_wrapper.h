#ifndef LYNX_JSBRIDGE_JSC_JSC_CONTEXT_GROUP_WRAPPER_H_
#define LYNX_JSBRIDGE_JSC_JSC_CONTEXT_GROUP_WRAPPER_H_

#include <JavaScriptCore/JavaScript.h>

#include <unordered_map>

#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace piper {

class JSCContextGroupWrapper : public VMInstance {
 public:
  JSCContextGroupWrapper() = default;
  virtual ~JSCContextGroupWrapper() = default;

  virtual void InitContextGroup() = 0;
  JSRuntimeType GetRuntimeType() { return piper::jsc; }

 private:
  friend class JSCRuntime;
  friend class JSCContextWrapper;
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_JSC_JSC_CONTEXT_GROUP_WRAPPER_H_
