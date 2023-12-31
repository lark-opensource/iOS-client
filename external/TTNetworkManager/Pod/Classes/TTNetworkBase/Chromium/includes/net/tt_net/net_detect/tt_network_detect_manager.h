// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NETWORK_DETECT_MANAGER_H_
#define NET_TT_NETWORK_DETECT_MANAGER_H_

#include <deque>
#include <map>
#include <string>
#include <vector>

#include "base/memory/singleton.h"
#include "base/single_thread_task_runner.h"
#include "base/values.h"
#include "net/base/ip_endpoint.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"
#include "net/tt_net/route_selection/tt_server_config.h"
#include "url/url_constants.h"

namespace base {
class DictionaryValue;
class OneShotTimer;
}  // namespace base

namespace net {

class URLRequest;

class TTNetDetectListener {
 public:
  virtual void onTTNetDetectFinish(const std::string& info) = 0;
};

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
using MockTTNetDetectTransactionCreatorCallback =
    base::RepeatingCallback<tt_detect::TTNetDetectTransaction*(
        const std::string& target,
        base::WeakPtr<tt_detect::TTNetDetectTransactionCallback> callback)>;
#endif

class TTNetworkDetectManager : public tt_detect::TTNetDetectTransactionCallback,
                               public TTServerConfigObserver {
 public:
  // The reason triggering network detect which is used for statistics.
  enum NetDetectSource {
    FEEDBACK = 0,  // user feedback
    EXCEPTION,     // request exception
    POLLING,       // timed polling
  };

  // detect type
  enum NetDetectAction {
    ALL = 0,
    HTTP_GET = 1 << 0,
    PING = 1 << 1,
    TRACEROUTE = 1 << 2,
    DNS_LOCAL = 1 << 3,
    DNS_HTTP = 1 << 4,
    DNS_SERVER = 1 << 5,
    UDP_PING = 1 << 6,
    DNS_FULL = 1 << 7,
    TCP_CONNECT = 1 << 8,
    UDP_PERF = 1 << 9,
    TCP_PERF = 1 << 10,
    HTTP_ISP = 1 << 11,
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
    MOCK_DETECT = 1 << 32
#endif
  };

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_CDN_DETECT) || \
    BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  struct CdnDetectConfig {
    bool enabled = false;
    std::string scheme = url::kHttpsScheme;
    std::vector<std::string> hosts;
    size_t concurrency = 10;
    double hit_ratio = 0;
    bool clean_history = true;
    size_t history_limit = 30;

    CdnDetectConfig();
    CdnDetectConfig(const CdnDetectConfig& other);
    ~CdnDetectConfig();
  };
#endif

  // TNC configuration
  struct TTNetworkDetectConfig {
    // basic config
    int64_t version = 0;
    size_t enable_feedback = 0;
    size_t enable_except = 0;
    size_t enable_polling = 0;
    size_t interval = 1800;
    size_t timeout = 60;
    size_t save_local_delay = 60;

    // polling detect config
    std::vector<std::string> targets;
    size_t polling_max = 1;
    size_t polling_interval = 1800;
    size_t polling_start_delay = 5;
    size_t forbid_suspended_polling = 0;
    size_t force_continued_polling = 0;
    size_t actions = 1;
    size_t stress_test = 0;

    // http detect config
    size_t socket_reuse = 1;
    size_t report_request_log = 0;
    size_t report_resp_headers = 0;
    std::vector<std::string> extra_headers;
    size_t use_ttnet_common_params = 0;
    bool isolation_enabled{false};

    // ping detect config
    size_t ping_times = 3;
    size_t ping_timeout = 2;
    size_t udp_ping_port = 5678;

    // except detect config
    size_t req_err_cnt = 10;
    size_t req_err_api_cnt = 5;
    size_t req_err_host_cnt = 3;
    std::map<std::string, uint64_t> req_host_list;
    size_t match_error = 0;

    // httpdns detect config
    size_t use_google_dns = 0;
    size_t use_tt_http_dns = 0;
    std::string tt_http_dns_domain;

    // dnsserver detect config
    std::string get_dns_server_host;

    // traceroute config
    size_t parallel_num = 1;
    int64_t hop_timeout_ms = 5;
    std::string specified_hops;
    size_t trace_total_num{100};
    bool ipv6_enabled = false;

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

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_CDN_DETECT) || \
    BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
    CdnDetectConfig cdn_detect;
#endif

    TTNetworkDetectConfig();
    TTNetworkDetectConfig(const TTNetworkDetectConfig& other);
    ~TTNetworkDetectConfig();
  };

  static TTNetworkDetectManager* GetInstance();

  void Init();

  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  // Try to trigger network detect
  // Restricted by concurrency control and frequency control strategies,
  // it is possible to return false here and not perform detection.
  void TryStartFeedbackDetect(const std::vector<std::string>& targets,
                              size_t timeout,
                              size_t actions);
  // Process TNC config parse
  void HandleRemoteConfig(const base::DictionaryValue* dict);
  // Statistics the request result
  bool HandleResponseResult(URLRequest* url_request, int net_error);
  // Turn on the poll detect strategy
  bool StartPollingDetect(bool first_start);

  void setDetectListener(TTNetDetectListener* listener);

 private:
  friend struct base::DefaultSingletonTraits<TTNetworkDetectManager>;
  TTNetworkDetectManager();
  ~TTNetworkDetectManager() override;

  bool has_inited_;

  // Do not allow to trigger network detect on mutiple scenes at the same time.
  bool detect_running_flag_;
  // Time of last detect start, use for frequency control.
  base::Time last_detect_time_;

  bool is_last_detect_stress_test_{false};
  NetDetectSource last_detect_source_;
  // TNC configuration
  TTNetworkDetectConfig detect_config_;
  // Poll timer
  base::OneShotTimer polling_detect_timer_;

  bool first_polling_consumed_;
  scoped_refptr<base::SingleThreadTaskRunner> net_thread_task_runner_;

  // Parameters used for controling the logic of triggering detect when request
  // is timeout
  size_t req_err_count_{0};
  std::map<std::string, uint64_t> req_err_api_map_;
  std::map<std::string, uint64_t> req_err_host_map_;

  base::OneShotTimer timeout_timer_;
  std::vector<scoped_refptr<tt_detect::TTNetDetectTransaction>>
      transaction_list_;
  size_t transaction_finished_;

  std::string start_detect_nettype_{"unknown"};
  int detect_rank_{-1};
  size_t last_detect_actions_{0};
  int64_t last_detect_version_{0};
  size_t trace_current_num_{100};

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_CDN_DETECT) || \
    BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  std::deque<std::string> cdn_detect_requested_urls_;
  uint32_t cdn_detect_request_count_{0};
  uint32_t cdn_detect_request_hit_count_{0};
#endif

  TTNetDetectListener* detect_listener_{nullptr};

  void InitDefaultRemoteConfig();
  void DoStartNetDetect(const std::vector<std::string>& targets,
                        NetDetectSource source,
                        size_t timeout,
                        size_t use_google_dns,
                        size_t use_tt_dns,
                        const std::string& tt_dns_domain,
                        size_t actions);
  void ResetExceptControlStates();
  bool MatchRequestError(int net_error);
  void OnPollingDetectTimerTimeout(bool first);

  void OnDetectTransactionProgress() override;
  void OnDetectTransactionFinish() override;

  void OnTimeout();
  void OnDetectFinish();
  void DoReport();

  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);
  bool IsMainProcess();
  bool TryStartNetDetect(const std::vector<std::string>& targets,
                         const bool useRemoteTargets,
                         NetDetectSource source,
                         size_t timeout,
                         size_t actions);
  void DoStartFeedbackDetect(const std::vector<std::string>& targets,
                             size_t timeout,
                             size_t actions);
  size_t HaveTraceEcho(size_t parallel_num);

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_CDN_DETECT) || \
    BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  bool CheckCdnDetectEnabled(NetDetectSource source) const;
  void GenerateCdnDetectTargets(std::vector<std::string>& targets_list);
  std::string RandomCdnDetectPath() const;
  std::vector<std::string> PickUrlsFromCdnDetectRequestedQueue(
      size_t count) const;
  std::vector<std::string> GenerateNewUrlsForCdnDetect(size_t count);
#endif

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class TTNetworkDetectTest;
  FRIEND_TEST_ALL_PREFIXES(TTNetworkDetectTest, TryStartNetDetect);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkDetectTest, DoNetDetect);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkDetectTest, PollingDetectControl);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkDetectTest, CheckCdnDetect);

  MockTTNetDetectTransactionCreatorCallback mock_trans_creator_func_;
  std::unique_ptr<base::DictionaryValue> last_detect_result_;
#endif

  base::WeakPtrFactory<TTNetworkDetectManager> factory_;
  DISALLOW_COPY_AND_ASSIGN(TTNetworkDetectManager);
};
}  // namespace net

#endif  // NET_TT_NETWORK_DETECT_MANAGER_H_
