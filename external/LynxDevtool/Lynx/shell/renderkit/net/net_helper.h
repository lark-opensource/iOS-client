// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_NET_NET_HELPER_H_
#define LYNX_SHELL_RENDERKIT_NET_NET_HELPER_H_

#include <ctime>
#include <functional>
#include <memory>
#include <string>

#include "shell/renderkit/net/ttnet_executor.h"
#include "shell/renderkit/net/url_request_callback.h"

struct CronetServerConfig;
namespace lynx {
class NetHelper {
 public:
  ~NetHelper();

  std::string SyncRequest(const std::string& url);
  void AsyncRequest(const std::string& url,
                    std::function<void(const std::string&)> callback);
  static NetHelper* GetInstance();

 private:
  NetHelper();
  NetHelper(const NetHelper&);
  NetHelper& operator=(const NetHelper&);
  Cronet_EnginePtr CreateCronetEngine();
  Cronet_EnginePtr GetEngine();
  TtnetExecutor* GetExecutor();
  static constexpr int kDefaultConnectionTimeout = 15;
  static constexpr int kDefaultIOTimeout = 5;

  void InitRequest(const std::string& url, Cronet_UrlRequestPtr request,
                   const UrlRequestCallback& url_request_callback);
  Cronet_EnginePtr g_cronet_engine = nullptr;
  CronetServerConfig* g_cronet_server_config = nullptr;
  std::unique_ptr<TtnetExecutor> g_p_executor;
  bool external_engine_{false};
};

}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_NET_NET_HELPER_H_
