#pragma once

#include <Foundation/Foundation.h>
#include "jsb/runtime/js_runtime.h"
#include "jsb/runtime/runtime_delegate.h"
#include "worker/iOS/js_worker_ios.h"

namespace vmsdk {
namespace worker {

class WorkerDelegateIOS : public runtime::JSRuntimeDelegate {
 public:
  WorkerDelegateIOS(JsWorkerIOS *js_worker_ios, std::shared_ptr<runtime::JSRuntime> js_runtime)
      : js_worker_ios_(js_worker_ios), js_runtime_(js_runtime) {}
  virtual ~WorkerDelegateIOS() = default;

  void CallOnMessageCallback(std::string &msg) override {
    NSString *ns_msg = [NSString stringWithCString:msg.c_str() encoding:NSUTF8StringEncoding];
    if (js_worker_ios_) {
      [js_worker_ios_ onMessage:ns_msg];
    }
    NSLog(@"in worker delegate ios calling onMessage.");
  }

  void CallOnErrorCallback(std::string &msg) override {
    NSString *ns_msg = [NSString stringWithCString:msg.c_str() encoding:NSUTF8StringEncoding];
    if (js_worker_ios_) {
      [js_worker_ios_ onError:ns_msg];
    }
    NSLog(@"in worker delegate ios calling onError.");
  }
#ifndef LARK_MINIAPP
  std::string FetchJsWithUrlSync(std::string &url) override {
    NSString *ns_url = [NSString stringWithCString:url.c_str() encoding:NSUTF8StringEncoding];
    NSString *js = [js_worker_ios_ FetchJsWithUrlSync:ns_url];
    return (js == nullptr) ? "" : [js UTF8String];

    NSLog(@"in worker delegate ios FetchJsWithUrlSync.");
  }

  void Fetch(const std::string &url, const std::string &params, const void *bodyData,
             int bodyLength, vmsdk::net::ResponseDelegate *resDelPtr) override {
    NSString *ns_url = [NSString stringWithCString:url.c_str() encoding:NSUTF8StringEncoding];
    NSString *ns_param = [NSString stringWithCString:params.c_str() encoding:NSUTF8StringEncoding];
    [js_worker_ios_ Fetch:ns_url
                    param:ns_param
                 bodyData:bodyData
               bodyLength:bodyLength
                   delPtr:resDelPtr];
  }

  bool workerDelegateExists() override { return [js_worker_ios_ workerDelegate] != nil; }
#endif

  std::shared_ptr<runtime::JSRuntime> GetJSRuntime() override { return js_runtime_; }

  void Terminate() override {
    js_worker_ios_ = nullptr;
    js_runtime_->TurnOff();
    js_runtime_ = nullptr;
  }

 private:
  JsWorkerIOS *js_worker_ios_;
  std::shared_ptr<runtime::JSRuntime> js_runtime_;
};

}  // namespace worker
}  // namespace vmsdk
