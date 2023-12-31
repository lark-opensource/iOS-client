#include "jsbridge/bindings/api_call_back.h"

#include <utility>

#include "base/log/logging.h"
#include "base/trace_event/trace_event.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/runtime/lynx_runtime.h"

namespace lynx {
namespace piper {

ApiCallBack ApiCallBackManager::createCallbackImpl(piper::Function func) {
  int id = next_timer_index_++;
  const auto &callback = ApiCallBack(id);

  // Now ApiCallBack supports tracing with flow.
  // TRACE_EVENT_FLOW_BEGIN0 and TRACE_EVENT_FLOW_END0 is already
  // implemented in ApiCallBackManager.
  // If you want to trace ApiCallBack, you can use
  // `ctx.event()->add_flow_ids(callback.trace_flow_id());` to
  // add you trace in the lifecycle of ApiCallBack.
  TRACE_EVENT_FLOW_BEGIN0(LYNX_TRACE_CATEGORY,
                          "ApiCallBackManager::createCallbackImpl",
                          callback.trace_flow_id());

  std::shared_ptr<CallBackHolder> holder =
      std::make_shared<CallBackHolder>(std::move(func));
  callback_map_.insert(std::make_pair(id, holder));
  return callback;
}

void ApiCallBackManager::Invoke(piper::Runtime *rt, ApiCallBack callBack) {
  TRACE_EVENT_FLOW_END0(LYNX_TRACE_CATEGORY, "ApiCallBackManager::Invoke",
                        callBack.trace_flow_id());

  DCHECK(rt != nullptr &&
         callback_map_.find(callBack.id()) != callback_map_.end());
  auto itr = callback_map_.find(callBack.id());
  if (!rt || itr == callback_map_.end()) {
    return;
  }
  std::shared_ptr<CallBackHolder> holder = itr->second;
  if (holder) {
    holder->Invoke(rt);
  }
  callback_map_.erase(itr);
}

void ApiCallBackManager::InvokeWithValue(piper::Runtime *rt,
                                         ApiCallBack callBack,
                                         const lepus::Value &value) {
  TRACE_EVENT_FLOW_END0(LYNX_TRACE_CATEGORY,
                        "ApiCallBackManager::InvokeWithValue",
                        callBack.trace_flow_id());

  DCHECK(rt != nullptr &&
         callback_map_.find(callBack.id()) != callback_map_.end());
  auto itr = callback_map_.find(callBack.id());
  if (!rt || itr == callback_map_.end()) {
    return;
  }
  std::shared_ptr<CallBackHolder> holder = itr->second;
  if (holder) {
    holder->InvokeWithValue(rt, value);
  }
  callback_map_.erase(itr);
}

void ApiCallBackManager::InvokeWithValue(piper::Runtime *rt,
                                         ApiCallBack callback,
                                         piper::Value value) {
  TRACE_EVENT_FLOW_END0(LYNX_TRACE_CATEGORY,
                        "ApiCallBackManager::InvokeWithValue",
                        callback.trace_flow_id());

  DCHECK(rt);
  auto iter = callback_map_.find(callback.id());
  if (iter == callback_map_.end()) {
    LOGE("ApiCallBackManager::InvokeWithValue with illegal id:"
         << callback.id());
    return;
  }

  auto &holder = iter->second;
  DCHECK(holder);
  holder->InvokeWithValue(rt, std::move(value));
  callback_map_.erase(iter);
}

void ApiCallBackManager::Destroy() { callback_map_.clear(); }

CallBackHolder::CallBackHolder(piper::Function func)
    : function_(std::move(func)) {}

void CallBackHolder::Invoke(piper::Runtime *rt) {
  DCHECK(rt != nullptr);
  if (rt) {
    Scope scope(*rt);
    function_.call(*rt, nullptr, 0);
  }
}

void CallBackHolder::InvokeWithValue(piper::Runtime *rt,
                                     const lepus::Value &value) {
  DCHECK(rt != nullptr);
  if (rt) {
    piper::Scope scope(*rt);
    if (value.IsNil()) {
      function_.call(*rt, nullptr, 0);
    } else {
      auto jsArgs = piper::valueFromLepus(*rt, value);
      if (jsArgs) {
        function_.call(*rt, *jsArgs);
      }
    }
  }
}

void CallBackHolder::InvokeWithValue(piper::Runtime *rt, piper::Value value) {
  DCHECK(rt);
  piper::Scope scope(*rt);
  function_.call(*rt, std::move(value));
}

}  // namespace piper
}  // namespace lynx
