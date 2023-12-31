#ifndef LYNX_JSBRIDGE_V8_V8_ISOLATE_WRAPPER_H_
#define LYNX_JSBRIDGE_V8_V8_ISOLATE_WRAPPER_H_

#include <unordered_map>

#include "base/observer/observer_list.h"
#include "jsbridge/jsi/jsi.h"
#include "v8.h"

namespace lynx {
namespace piper {

class V8IsolateInstance : public VMInstance {
 public:
  V8IsolateInstance() = default;
  virtual ~V8IsolateInstance() = default;

  virtual void InitIsolate(const char* arg, bool useSnapshot) = 0;

  // void AddObserver(base::Observer* obs) { observers_.AddObserver(obs); }
  // void RemoveObserver(base::Observer* obs) {
  // observers_.RemoveObserver(obs);
  // }
  virtual v8::Isolate* Isolate() const = 0;
  JSRuntimeType GetRuntimeType() { return piper::v8; }
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_V8_V8_ISOLATE_WRAPPER_H_
