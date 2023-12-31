//
//  Created by songlu on 4/17/17.
//  Copyright © 2017 ttnet. All rights reserved.
//

#ifndef NET_TTNET_ROUTE_SELECTION_TT_MONITOR_MODULE_H_
#define NET_TTNET_ROUTE_SELECTION_TT_MONITOR_MODULE_H_

#include <map>

#include "base/memory/singleton.h"
#include "net/tt_net/base/ttnet_basic_request_info.h"
#include "net/url_request/url_fetcher.h"

namespace net {

class TTRequestInfoProvider {
 public:
  virtual void HandleRequestInfoNotify(const TTNetBasicRequestInfo& info) = 0;
};

class TTMonitorProvider {
 public:
  virtual void SendMonitor(const std::string& json,
                           const std::string& log_type) = 0;

  virtual void HandleApiStart(const std::string& uuid,
                              const std::string& url,
                              const std::string& method) = 0;
  virtual void HandleApiResult(const std::string& uuid,
                               bool succ,
                               const std::string& url,
                               const std::string& method,
                               const std::string& traceCode,
                               int64_t app_start,
                               int64_t request_start,
                               int64_t response_back,
                               int64_t response_complete,
                               int64_t request_end,
                               const net::URLFetcher* request) = 0;

 protected:
  virtual ~TTMonitorProvider() {}
};

class TTMonitorManager {
 public:
  TTNET_IMPLEMENT_EXPORT static TTMonitorManager* GetInstance();

  TTNET_IMPLEMENT_EXPORT void AddMonitor(TTMonitorProvider* monitor);

  void RemoveMonitor();

  void AddNativeMonitor(TTMonitorProvider* monitor);
  void RemoveNativeMonitor();

  void SendMonitor(const std::string& json, const std::string& log_type);

  void HandleApiStart(const std::string& uuid,
                      const std::string& url,
                      const std::string& method);

  void HandleApiResult(const std::string& uuid,
                       bool succ,
                       const std::string& url,
                       const std::string& method,
                       const std::string& traceCode,
                       int64_t app_start,
                       int64_t request_start,
                       int64_t response_back,
                       int64_t response_complete,
                       int64_t request_end,
                       const net::URLFetcher* request);

  void SetRequestInfoProvider(TTRequestInfoProvider* provider);

  void HandleRequestInfoNotify(const TTNetBasicRequestInfo& info) const;

  ~TTMonitorManager();

 private:
  friend struct base::DefaultSingletonTraits<TTMonitorManager>;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  FRIEND_TEST_ALL_PREFIXES(TTMonitorManager, SendMonitor);
  FRIEND_TEST_ALL_PREFIXES(TTMonitorManager, HandleApiStart);
  FRIEND_TEST_ALL_PREFIXES(TTMonitorManager, HandleApiResult);
  friend class TTNetworkDelegateTest;
  bool handle_for_testing_{false};
#endif

  TTMonitorManager();

  TTMonitorProvider* ttnet_monitor_{nullptr};
  TTRequestInfoProvider* request_info_provider_{nullptr};
  TTMonitorProvider* ttnet_monitor_native_{nullptr};

  DISALLOW_COPY_AND_ASSIGN(TTMonitorManager);
};

}  // namespace net

#endif
