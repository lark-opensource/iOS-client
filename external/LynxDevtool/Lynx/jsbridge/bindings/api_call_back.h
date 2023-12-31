#ifndef LYNX_JSBRIDGE_BINDINGS_API_CALL_BACK_H_
#define LYNX_JSBRIDGE_BINDINGS_API_CALL_BACK_H_

#include <base/log/logging.h>

#include <memory>
#include <unordered_map>

#include "base/trace_event/trace_event.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/utils/utils.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace runtime {
class LynxRuntime;
}
namespace piper {
class Runtime;

class ApiCallBack {
 public:
  ApiCallBack(int id = -1) {
    id_ = id;
    trace_flow_id_ = base::tracing::GetFlowId();
  }
  int id() const { return id_; }
  bool IsValid() const { return id_ != -1; }
  uint64_t trace_flow_id() const { return trace_flow_id_; }

 private:
  int id_;
  uint64_t trace_flow_id_;
};

class CallBackHolder;

class ApiCallBackManager {
 public:
  ApiCallBackManager() : next_timer_index_(0) {}
  ApiCallBack createCallbackImpl(piper::Function func);

  void Invoke(piper::Runtime* rt, ApiCallBack);
  void InvokeWithValue(piper::Runtime* rt, ApiCallBack,
                       const lepus::Value& value);
  void InvokeWithValue(piper::Runtime* rt, ApiCallBack callback,
                       piper::Value value);
  void Destroy();

 private:
  std::unordered_map<int, std::shared_ptr<CallBackHolder>> callback_map_;
  int next_timer_index_;
};

class CallBackHolder : public std::enable_shared_from_this<CallBackHolder> {
 public:
  CallBackHolder(piper::Function func);

  ~CallBackHolder() = default;

  void Invoke(piper::Runtime* rt);
  void InvokeWithValue(piper::Runtime* rt, const lepus::Value& value);
  void InvokeWithValue(piper::Runtime* rt, piper::Value value);

 public:
  piper::Function function_;
};

}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_BINDINGS_API_CALL_BACK_H_
