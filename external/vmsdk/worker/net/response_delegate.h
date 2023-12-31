#ifndef VMSDK_RESPONSE_DELEGATE_H
#define VMSDK_RESPONSE_DELEGATE_H
#include "napi.h"
namespace vmsdk {
namespace worker {
class Worker;
}

namespace net {
class ResponseDelegate {
 public:
  ResponseDelegate(Napi::Promise::Deferred&& defered, const Napi::Env& env,
                   worker::Worker* worker)
      : defered_(std::move(defered)), env_(env), worker_(worker) {}
  ~ResponseDelegate() = default;
  void resolve(Napi::Value response);
  void reject(Napi::Value reject);
  const Napi::Env Env() { return env_; }
  static Napi::Value getBodyText(Napi::ArrayBuffer& body);  // text string
  static Napi::Value getBodyJson(Napi::ArrayBuffer& body);  // json object
  static Napi::Value json(const Napi::CallbackInfo& info);
  static Napi::Value text(const Napi::CallbackInfo& info);

 private:
  Napi::Promise::Deferred defered_;
  Napi::Env env_;
  worker::Worker* worker_;
};
}  // namespace net
}  // namespace vmsdk
#endif
