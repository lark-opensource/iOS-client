#ifndef LYNX_JSBRIDGE_V8_V8_CONTEXT_WRAPPER_H_
#define LYNX_JSBRIDGE_V8_V8_CONTEXT_WRAPPER_H_

#include <memory>
#include <unordered_map>

#include "base/observer/observer_list.h"
#include "jsbridge/jsi/jsi.h"
#include "v8.h"

namespace lynx {
namespace piper {

class V8ContextWrapper : public JSIContext {
 public:
  V8ContextWrapper(std::shared_ptr<VMInstance> vm) : JSIContext(vm) {}
  virtual ~V8ContextWrapper() = default;
  virtual void Init() = 0;
  virtual v8::Local<v8::Context> getContext() const = 0;
  virtual v8::Isolate* getIsolate() const = 0;
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_V8_V8_CONTEXT_WRAPPER_H_
