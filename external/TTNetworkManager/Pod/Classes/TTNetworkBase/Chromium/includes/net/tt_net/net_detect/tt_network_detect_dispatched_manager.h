// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TT_NETWORK_DETECT_DISPATCHED_MANAGER_H_
#define NET_TT_NET_NET_DETECT_TT_NETWORK_DETECT_DISPATCHED_MANAGER_H_

#include "base/memory/scoped_refptr.h"
#include "base/memory/singleton.h"
#include "base/timer/timer.h"
#include "net/base/completion_once_callback.h"
#include "net/base/host_port_pair.h"
#include "net/base/network_change_notifier.h"
#include "net/base/prioritized_dispatcher.h"
#include "net/base/request_priority.h"
#include "net/dns/host_resolver.h"
#include "net/tt_net/net_detect/base/tt_network_detect_errors.h"
#include "url/gurl.h"

#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
#include "net/tt_net/route_selection/tt_server_config.h"
#else
#include "net/game_sdk/route_selection/game_sdk_server_config.h"
#endif
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
#include "net/tt_net/multinetwork/utils/tt_multinetwork_utils.h"
#endif

namespace net {

class TTNetworkDetectDispatchedManager
#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
    : public TTServerConfigObserver,
#else
    : public GameSdkServerConfigObserver,
#endif
      public NetworkChangeNotifier::IPAddressObserver {
 public:
  class Request;
  class MockRequest;

  // detect types.
  enum NetDetectAction {
    ACTION_INVALID = 0,
    ACTION_HTTP_GET = 1 << 0,
    ACTION_ICMP_PING = 1 << 1,
    ACTION_TRACEROUTE = 1 << 2,
    ACTION_DNS_LOCAL = 1 << 3,
    ACTION_DNS_HTTP = 1 << 4,
    ACTION_DNS_SERVER = 1 << 5,
    ACTION_UDP_PING = 1 << 6,
    ACTION_DNS_FULL = 1 << 7,
    ACTION_TCP_CONNECT = 1 << 8,
    ACTION_TCP_ECHO = 1 << 9,
    ACTION_UDP_PERF = 1 << 10,
    ACTION_TCP_PERF = 1 << 11,
    ACTION_HTTP_ISP = 1 << 12,
  };

  // Configure for transactions' beviours.
  struct RequestConfig {
    RequestConfig();
    ~RequestConfig();
    RequestConfig(const RequestConfig& other);
    // TCP connect type transaction's configures.
    struct TcpConnect {
      bool bypass_http_dns;
      bool force_http_dns;
    } tcp_connect;
    // TCP echo type transaction's configures.
    struct TcpEcho : TcpConnect {
    } tcp_echo;
    // HTTP GET type transaction's configures.
    struct HttpGet {
      HttpGet();
      ~HttpGet();
      HttpGet(const HttpGet& other);
      bool reuse_socket;
      bool isolation_enabled;
      bool report_response_headers;
      std::vector<std::string> extra_headers;
    } http_get;

    // ICMP Ping and UDP Ping type transaction's basic configures.
    struct Ping {
      uint32_t max_ping_count;
      uint32_t ping_timeout_ms;
    };

    // ICMP Ping type transaction's configures.
    struct ICMPPing : public Ping {
    } icmp_ping;

    // UDP Ping type transaction's configures.
    struct UDPPing : public Ping {
      uint16_t port;
    } udp_ping;

    struct DNSServer {
      std::string server_host;
    } dns_server;

    struct Traceroute {
      uint32_t parallel_num;
      int64_t hop_timeout_ms;
      std::string specified_hops;
    } trace_route;

    // udp perf config
    struct UdpPerf {
      uint32_t byte_rate{0};
      uint16_t frame_bytes{0};
      uint16_t duration_s{0};
    } udp_perf;

    // tcp perf config
    struct TcpPerf {
      uint32_t byte_rate{0};
      uint16_t frame_bytes{0};
      uint16_t duration_s{0};
    } tcp_perf;

    // http isp config
    struct HttpIsp {
      uint32_t post_count{0};
      uint16_t duration_s{0};
    } http_isp;

    NetDetectAction actions;

    int64_t timeout_ms;

    RequestPriority priority;

    std::vector<std::string> targets;

    bool skip_dispatch;

#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
    TTMultiNetworkUtils::MultiNetAction multi_net_action;
#endif

    HostResolver::ResolveHostParameters::TTFlag resolve_host_flag;
  };

  static TTNetworkDetectDispatchedManager* GetInstance();

  virtual bool Init();

  virtual std::unique_ptr<Request> CreateRequest(
      std::unique_ptr<RequestConfig> config);

  PrioritizedDispatcher* job_dispatcher() { return job_dispatcher_.get(); }

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  static void set_mock_manager(TTNetworkDetectDispatchedManager* mock_manager);
#endif

 protected:
  class Job;
  class MockJob;
  TTNetworkDetectDispatchedManager();
  ~TTNetworkDetectDispatchedManager() override;

  virtual std::unique_ptr<Job> CreateJob(Request* request);

 private:
  friend struct base::DefaultSingletonTraits<TTNetworkDetectDispatchedManager>;
  friend class TTNetworkDetectDispatchedManagerTest;
  friend class TTNetworkQualityDetectorTest;
  friend class MockTTNetworkDetectDispatchedManager;

  using JobList = std::list<std::unique_ptr<Job>>;

  struct TNCConfig {
    size_t max_concurrent_jobs;
    // Limits of jobs that are waiting for running in |job_dispatcher_|.
    size_t max_queued_jobs;
    TNCConfig();
    TNCConfig(const TNCConfig& other);
    ~TNCConfig();
  };

  TNCConfig tnc_config_;

  // TTServerConfigObserver implementation:
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  void ReadTNCConfigFromCache();

  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);

  // NetworkChangeNotifier::IPAddressObserver:
  void OnIPAddressChanged() override;

  int StartJob(std::unique_ptr<Job> new_job);

  std::unique_ptr<Job> RemoveJob(JobList::iterator job_it);

  bool initialized_;

  // Dispatcher that manages jobs.
  std::unique_ptr<PrioritizedDispatcher> job_dispatcher_;

  // All jobs owned by this manager.
  JobList jobs_;

  DISALLOW_COPY_AND_ASSIGN(TTNetworkDetectDispatchedManager);
};

}  // namespace net

#endif