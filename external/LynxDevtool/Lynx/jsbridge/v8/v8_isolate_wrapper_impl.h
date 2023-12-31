#ifndef LYNX_JSBRIDGE_V8_V8_ISOLATE_WRAPPER_IMPL_H_
#define LYNX_JSBRIDGE_V8_V8_ISOLATE_WRAPPER_IMPL_H_

#include "jsbridge/v8/v8_isolate_wrapper.h"

namespace lynx {
namespace piper {

class V8IsolateInstanceImpl : public V8IsolateInstance {
 public:
  V8IsolateInstanceImpl();
  ~V8IsolateInstanceImpl() override;

  void InitIsolate(const char* arg, bool useSnapshot) override;

  // void AddObserver(base::Observer* obs) { observers_.AddObserver(obs); }
  // void RemoveObserver(base::Observer* obs) {
  // observers_.RemoveObserver(obs);
  // }
  v8::Isolate* Isolate() const override;

 private:
  v8::Isolate* isolate_;
  friend class V8Runtime;
  friend class V8ContextWrapper;
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_V8_V8_ISOLATE_WRAPPER_IMPL_H_
