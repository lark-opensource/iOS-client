//
//  Created by gaohaidong on 9/28/18.
//  Copyright © 2018 ttnet. All rights reserved.
//

#ifndef NET_TTNET_CONFIG_INIT_CONFIG_H_
#define NET_TTNET_CONFIG_INIT_CONFIG_H_

#include <string>

#include "base/memory/singleton.h"
#include "base/single_thread_task_runner.h"
#include "net/tt_net/dns/tt_dns_cross_sp_manager.h"
#include "net/url_request/url_request_context_getter.h"

namespace cronet {
struct URLRequestContextConfig;
}

namespace base {
class DictionaryValue;
}

namespace net {
class URLRequestContextBuilder;
class HostResolver;
class NetworkQualityEstimator;

class InitConfig final {
 public:
  TTNET_IMPLEMENT_EXPORT static InitConfig* GetInstance();
  ~InitConfig();

  void SetContextBuilderAndConfig(net::URLRequestContextBuilder* builder,
                                  cronet::URLRequestContextConfig* config) {
    context_builder_ = builder;
    config_ = config;
  }

  void SetHostResolver(net::HostResolver* resolver) {
    host_resolver_ = resolver;
  }

  void SetURLRequestContextGetter(net::URLRequestContextGetter* context_getter);

  void SetNetworkQualityEstimator(NetworkQualityEstimator* nqe) { nqe_ = nqe; }

  URLRequestContextGetter* GetURLRequestContextGetter() const {
    return context_getter_.get();
  }

  void SetConfigFilePath(const std::string& path) { config_file_path_ = path; }

  void SetFileTaskRunner(scoped_refptr<base::SingleThreadTaskRunner> runner) {
    file_task_runner_ = runner;
  }

  scoped_refptr<base::SingleThreadTaskRunner> GetFileTaskRunner() const {
    return file_task_runner_;
  }

  void DoInitConfig();

  net::HostResolver* host_resolver() const { return host_resolver_; }

  NetworkQualityEstimator* nqe() const { return nqe_; }

  TTDnsCrossSpManager* GetDnsCrossSpManager() const;

 private:
  friend struct base::DefaultSingletonTraits<InitConfig>;
  FRIEND_TEST_ALL_PREFIXES(ConfigManagerTest, HandlePersistentHostCacheConfig);

  net::URLRequestContextBuilder* context_builder_{nullptr};
  cronet::URLRequestContextConfig* config_{nullptr};
  net::HostResolver* host_resolver_{nullptr};

  scoped_refptr<URLRequestContextGetter> context_getter_{nullptr};
  std::string config_file_path_;
  scoped_refptr<base::SingleThreadTaskRunner> file_task_runner_;
  bool init_config_done_{false};
  NetworkQualityEstimator* nqe_{nullptr};

  InitConfig();
  void HandlePersistentHostCacheConfig(base::DictionaryValue* dict_data);
  DISALLOW_COPY_AND_ASSIGN(InitConfig);
};
}  // namespace net

#endif
