// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXPERIENCE_MANAGER_H_
#define NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXPERIENCE_MANAGER_H_

#include "net/net_buildflags.h"

#include "base/memory/singleton.h"
#include "base/timer/timer.h"
#include "net/base/completion_once_callback.h"
#include "net/base/prioritized_dispatcher.h"
#include "net/base/request_priority.h"
#include "net/tt_net/net_detect/base/tt_network_detect_errors.h"
#include "net/tt_net/net_detect/tt_network_detect_dispatched_manager.h"

#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
#include "net/tt_net/route_selection/tt_server_config.h"
#else
#include "net/game_sdk/route_selection/game_sdk_server_config.h"
#endif
#include "url/gurl.h"
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
#include "net/tt_net/multinetwork/utils/tt_multinetwork_utils.h"
#endif

namespace net {
namespace tt_exp {

class TTNetExpBadRequestDiagnoser;

class TTNET_IMPLEMENT_EXPORT TTNetExperienceManager
#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
    : public TTServerConfigObserver {
#else
    : public GameSdkServerConfigObserver {
#endif
 public:
  class Request;
  class MockRequest;

  enum RequestType {
    REQ_TYPE_INVALID = -1,
    REQ_TYPE_DNS_ONLY = 0,   // DNS resolve the given target.
    REQ_TYPE_RACE_ONLY = 1,  // Race the given targets and rank them.
    REQ_TYPE_DNS_AND_RACE,   // DNS resolve and race the result if needed.
    REQ_TYPE_DIAGNOSIS_V1,   // Lan scan, trace route and ping key points.
    REQ_TYPE_DIAGNOSIS_V2,   // Lan scan, trace route, poll target ip and ping
                             // key points.
    REQ_TYPE_RAW_DETECT,     // Raw detect transaction group.
    REQ_TYPE_BAD_REQUEST_DIAGNOSIS,  // Diagnosis when Http requests failed
                                     // consecutively.
    REQ_TYPE_COUNT
  };

  enum HostResolverType {
    RESOLVER_TYPE_UNSPECIFIED = 0,
    RESOLVER_TYPE_LOCAL_DNS_ONLY = 1
  };

  // Configure for transactions' behaviours.
  // These configurations are provided by users.
  struct RequestConfig {
    RequestConfig();
    ~RequestConfig();
    RequestConfig(const RequestConfig& other);

    struct Dns {
      std::string target;
    } dns;

    struct DiagnosisV1 {
      std::string target;
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
      TTMultiNetworkUtils::MultiNetAction multi_net_action;
#endif
      HostResolverType resolver_type;
    } diagnosis_v1;

    struct DiagnosisV2 {
      std::string target;
    } diagnosis_v2;

    struct Race {
      Race();
      ~Race();
      Race(const Race& other);
      std::vector<std::string> targets;
      TTNetworkDetectDispatchedManager::NetDetectAction actions;
    } race;

    struct Acceleration {
      Acceleration();
      std::string target;
      // Only one action
      TTNetworkDetectDispatchedManager::NetDetectAction action;
    } acceleration;

    struct RawDetect {
      RawDetect();
      ~RawDetect();
      RawDetect(const RawDetect& other);
      struct Entry {
        std::string target;
        TTNetworkDetectDispatchedManager::NetDetectAction actions{
            TTNetworkDetectDispatchedManager::ACTION_INVALID};
      };
      std::vector<Entry> entries;
    } raw_detect;

    int64_t timeout_ms;
    RequestType request_type;
    RequestPriority priority;
    std::string tnc_str;
  };

  struct TNCConfig {
    size_t max_concurrent_jobs;
    // Limits of jobs that are waiting for running in |job_dispatcher_|.
    size_t max_queued_jobs;

    struct {
      bool enable;
    } user_log;

    struct {
      bool enable;
    } dns;

    struct {
      bool enable;
      uint32_t ping_count;
      int64_t ping_timeout_ms;
      uint16_t race_parallel_num;
    } race;

    struct {
      bool enable;
      // For race step.
      bool use_tnc_action;
      TTNetworkDetectDispatchedManager::NetDetectAction action;
      std::set<std::string> hosts;
      uint32_t ping_count;
      int64_t ping_timeout_ms;
    } acceleration;

    struct {
      bool enable;
      bool enable_channel_scan;
      uint32_t ping_count;
      int64_t ping_timeout_ms;
      int64_t ping_route_timeout_ms;
      uint16_t ping_route_parallel_num;
      uint16_t local_dev_detect_count;
      int64_t full_diag_interval_ms;
      TTNetworkDetectDispatchedManager::NetDetectAction fallback_protocol;
      std::vector<std::string> edge_points;
      std::vector<std::string> fallback_points;
      struct {
        uint16_t parallel_num;
        int64_t hop_timeout_ms;
      } tracert;
      struct {
        bool enable;
        int64_t timeout_ms;
      } tcp_connect;
    } diagnosis;

    struct {
      bool enable;
      bool enable_channel_scan;
      std::string target;
      int64_t interval_ms;
      int64_t ping_route_timeout_ms;
      uint16_t ping_route_parallel_num;
      uint16_t local_dev_detect_count;
      int ping_timeout_interval_ms;
      int protocol;
      int record_count_limit;
      TTNetworkDetectDispatchedManager::NetDetectAction fallback_protocol;
      std::vector<std::string> edge_points;
      std::vector<std::string> fallback_points;
      struct {
        uint16_t parallel_num;
        int64_t hop_timeout_ms;
        std::string specified_hops;
      } tracert;
      struct {
        bool enable;
        int rtt_diff_threshold_ms;
        int last_rtt_threshold_ms;
        int64_t interval_time_ms;
        uint32_t ping_count;
        int64_t ping_timeout_ms;
        int limit_count;
        int extra_message_length_limit;
      } diag;
    } poll;

    struct {
      // basic config
      bool enable;
      uint16_t detect_parallel_num;
      // cloud detect config
      struct {
        int64_t version;
        uint32_t poll_count;
        int64_t poll_interval_s;
        int64_t save_delay_s;
        int64_t start_delay_s;
        int64_t timeout_ms;
        std::vector<RequestConfig::RawDetect::Entry> entries;
      } cloud;
      struct {
        int64_t timeout_ms;
      } tcp_connect;
      struct {
        int64_t timeout_ms;
      } tcp_echo;
      struct {
        int64_t timeout_ms;
      } full_dns;
      struct {
        int64_t timeout_ms;
      } local_dns;
      struct {
        int64_t timeout_ms;
      } http_dns;
      struct {
        int64_t timeout_ms;
      } dns_server;
      struct {
        int64_t timeout_ms;
        bool report_response_headers;
        std::vector<std::string> extra_headers;
      } http_get;
      struct {
        uint32_t ping_count;
        int64_t echo_timeout_ms;
        int64_t timeout_ms;
      } icmp_ping;
      struct {
        uint32_t ping_count;
        int64_t echo_timeout_ms;
        int64_t timeout_ms;
      } udp_ping;
      struct {
        uint16_t parallel_num;
        int64_t echo_timeout_ms;
        std::string specified_hops;
        int64_t timeout_ms;
      } icmp_traceroute;
      struct {
        uint32_t byte_rate{0};
        uint16_t frame_bytes{0};
        uint16_t duration_s{0};
      } udp_perf;
      struct {
        uint32_t byte_rate{0};
        uint16_t frame_bytes{0};
        uint16_t duration_s{0};
      } tcp_perf;
      struct {
        uint32_t post_count{0};
        uint16_t duration_s{0};
      } http_isp;
    } raw_detect;

    struct BadRequestDiagnosis {
      struct MatchRule {
        std::vector<std::string> host_group;
        std::vector<std::string> path_group;
        std::vector<int> net_error_group;

        MatchRule();
        MatchRule(const MatchRule& other);
        ~MatchRule();
      };
      struct {
        std::vector<std::string> targets;
        int64_t trans_timeout_ms{0};
      } http_get;
      struct {
        uint16_t parallel_num{0};
        int64_t hop_timeout_ms{0};
      } traceroute;
      struct {
        uint32_t ping_count{0};
        int64_t ping_timeout_ms{0};
      } ping;

      bool enabled{false};
      bool report_enabled{false};
      bool route_enabled{false};
      int bad_request_max_count{0};
      int diagnosis_max_count{0};
      int64_t job_timeout_ms{0};
      int64_t diagnosis_interval_ms{0};
      std::vector<MatchRule> match_rules;

      BadRequestDiagnosis();
      BadRequestDiagnosis(const BadRequestDiagnosis& other);
      ~BadRequestDiagnosis();
    } bad_request_diagnosis;

    explicit TNCConfig(bool is_trans_default_enabled);
    TNCConfig(const TNCConfig& other);
    ~TNCConfig();
  };

  static TTNetExperienceManager* GetInstance();

  // TTServerConfigObserver implementation:
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_json) override;

  // Should init after TTNetworkDetectDispatchedManager::Init.
  virtual bool Init();
  virtual std::unique_ptr<Request> CreateRequest(
      std::unique_ptr<RequestConfig> config);
  void ReportNetworkEnvironment(const std::string& user_log);
  void UpdateTransactionDefaultEnabled(bool enable);
  bool ParseJsonResult(TNCConfig& tnc_config, const base::Value& tnc_json);
  void NotifyRequestCompleted(const URLRequest* url_request, int net_error);
  PrioritizedDispatcher* job_dispatcher() { return job_dispatcher_.get(); }

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  static void set_mock_manager(TTNetExperienceManager* mock_manager);
#endif

 protected:
  friend struct base::DefaultSingletonTraits<TTNetExperienceManager>;
  friend class TTNetExperienceManagerTest;
  FRIEND_TEST_ALL_PREFIXES(TTNetExperienceManagerTest,
                           ReportNetworkEnvironment);
  friend class TTNetExpDnsRaceJobTest;
  friend class TTNetExpDiagnosisV1JobTest;
  friend class TTNetExpDiagnosisV2JobTest;
  friend class TTNetExpRawDetectJobTest;
  friend class TTNetExpBadRequestDiagnosisJobTest;
  friend class TTNetExpDiagnosisPingerTest;
  friend class TTNetExpDiagnosisTracerTest;
  friend class TTNetExpCloudDetectorTest;
  friend class TTNetExpBadRequestDiagnoserTest;
  friend class MockTTNetExperienceManager;

  class Job;
  class MockJob;
  class TTNetExpBaseDiagnosisJob;
  class TTNetExpDnsRaceJob;
  class TTNetExpDiagnosisV1Job;
  class TTNetExpDiagnosisV2Job;
  class TTNetExpRawDetectJob;
  class TTNetExpBadRequestDiagnosisJob;
  using JobList = std::list<std::unique_ptr<Job>>;

  TTNetExperienceManager();
  ~TTNetExperienceManager() override;
  virtual std::unique_ptr<Job> CreateJob(Request* request);

 private:
  void ReadTNCConfigFromCache();
  int StartJob(std::unique_ptr<Job> new_job);
  std::unique_ptr<Job> RemoveJob(JobList::iterator job_it);
  base::DictionaryValue CollectNetworkEnvironmentReport(
      const std::string& user_log);

  bool initialized_;
  // Experience transaction default switch value, used in TNCConfig.
  bool is_trans_default_enabled_;
  TNCConfig tnc_config_;
  // Dispatcher that manages jobs.
  std::unique_ptr<PrioritizedDispatcher> job_dispatcher_;
  // All jobs owned by this manager.
  JobList jobs_;
  std::unique_ptr<TTNetExpBadRequestDiagnoser> bad_request_diagnoser_;

  DISALLOW_COPY_AND_ASSIGN(TTNetExperienceManager);
};

}  // namespace tt_exp
}  // namespace net

#endif