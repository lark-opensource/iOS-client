#pragma once
#include <string>

#ifndef LARK_MINIAPP
namespace vmsdk {
namespace net {
class ResponseDelegate;
}
}  // namespace vmsdk
#endif
namespace vmsdk {
namespace runtime {
class JSRuntime;
class JSRuntimeDelegate {
 public:
  JSRuntimeDelegate() = default;
  virtual ~JSRuntimeDelegate() = default;

  virtual void CallOnMessageCallback(std::string &msg) = 0;
  virtual void CallOnErrorCallback(std::string &msg) = 0;
  virtual std::shared_ptr<JSRuntime> GetJSRuntime() = 0;
  virtual void Terminate() = 0;
#ifndef LARK_MINIAPP
  virtual std::string FetchJsWithUrlSync(std::string &url) = 0;
  virtual void Fetch(const std::string &url, const std::string &params,
                     const void *bodyData, int bodyLength,
                     vmsdk::net::ResponseDelegate *resDelPtr) = 0;
  virtual bool workerDelegateExists() = 0;
#endif
};

}  // namespace runtime
}  // namespace vmsdk
