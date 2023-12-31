// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_IOS_JS_PROXY_DARWIN_H_
#define LYNX_SHELL_IOS_JS_PROXY_DARWIN_H_

#import <Foundation/Foundation.h>

#include <memory>
#include <string>
#import <Lynx/LynxView.h>
#include "shell/lynx_shell.h"

namespace lynx {
namespace shell {

class JSProxyDarwin {
 public:
  ~JSProxyDarwin();

  static std::shared_ptr<JSProxyDarwin> Create(
      const std::shared_ptr<LynxActor<runtime::LynxRuntime>>& actor, LynxView* lynx_view,
      int64_t id, bool use_proxy_map);

  // ensure call on js thread
  static std::shared_ptr<JSProxyDarwin> GetJSProxyById(int64_t id);

  void CallJSFunction(NSString* module, NSString* method, NSArray* args);

  void CallJSIntersectionObserver(NSInteger observer_id, NSInteger callback_id, NSDictionary* args);

  void CallJSApiCallbackWithValue(NSInteger callback_id, NSDictionary* args);

  void EvaluateScript(const std::string& url, std::string script, int32_t callback_id);

  void RejectDynamicComponentLoad(const std::string& url, int32_t callback_id, int32_t err_code,
                                  const std::string& err_msg);

  int64_t GetId() const { return id_; }

  LynxView* GetLynxView() const { return lynx_view_; }

 private:
  JSProxyDarwin(const std::shared_ptr<LynxActor<runtime::LynxRuntime>>& actor, LynxView* lynx_view,
                int64_t id, bool use_proxy_map);

  std::shared_ptr<LynxActor<runtime::LynxRuntime>> actor_;

  __weak LynxView* const lynx_view_;

  const int64_t id_;
  const bool use_proxy_map_;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_IOS_JS_PROXY_DARWIN_H_
