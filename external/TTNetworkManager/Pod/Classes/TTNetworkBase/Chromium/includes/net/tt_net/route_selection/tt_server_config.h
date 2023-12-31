//
//  Created by songlu on 4/17/17.
//  Copyright © 2017 ttnet. All rights reserved.
//

#ifndef NET_TTNET_ROUTE_SELECTION_TT_SERVER_CONFIG_H_
#define NET_TTNET_ROUTE_SELECTION_TT_SERVER_CONFIG_H_

#include "net/tt_net/route_selection/tt_default_server_config.h"

#include <atomic>
#include <list>

#include "base/memory/singleton.h"
#include "base/optional.h"
#include "base/power_monitor/power_monitor.h"
#include "base/power_monitor/power_observer.h"
#include "base/single_thread_task_runner.h"
#include "base/timer/timer.h"
#include "base/values.h"
#include "net/http/http_response_headers.h"
#include "net/net_buildflags.h"

namespace net {
class URLRequest;
struct CronetInitTimingInfo;

extern const char kUseStoreRegionQuery[];

class TTColdStartListener {
 public:
  virtual void OnColdStartFinish(bool timeout) = 0;
  virtual void OnTNCUpdateFailed(const std::vector<std::string>& urls,
                                 const std::string& summary) = 0;

  virtual void OnCronetInitCompleted(const CronetInitTimingInfo& timing_info) {}
  virtual ~TTColdStartListener() {}
};

class TTServerConfigObserver {
 public:
  enum UpdateSource {
    TTCACHE = 0,  // Used by local config cache during cold start.
    TTSERVER,     // Used by TNC request during cold start.
    TTERROR,      // Used by disaster recovery.
    TTPOLL,       // Used by polling caused by timer.
    TTTNC,        // Used by TNC probe.
    TTFRONTIER,   // Used by Frontier websocket.
    TTWEBVIEW,    // Used by Android TTWebview request for TNC config. Not used
                  // currently.
    PORT_RETRY,   // Used by OC or Java adapter layer to get the TNC config
                  // through system default API, such as NSUrlSession or java
                  // UrlConnection. Not used currently.
    TTALARMFAIL,  // Not used currently.
    TTRETRY,      // Used by TNC request failure retry timer.
    TTREGION,     // Used by change of Store IDC information.
    TTPOLL_BY_REQUEST,   // Used by polling caused by normal request
                         // completes.
    TTRETRY_BY_REQUEST,  // Used by TNC retry when normal request
                         // completes.
    TTUSER,              // Used by users manually turn on and off NetLog.
#if BUILDFLAG(ENABLE_MPA_ON_MOBILE) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
    TTGAME_START,  // Used by starting game acceleration.
#endif
  };

  virtual void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) {}

  virtual void OnServerConfigChanged(const UpdateSource source,
                                     const std::string& tnc_config_string) {}

  virtual void OnServerConfigChanged(const UpdateSource source,
                                     const std::string& tnc_config_string,
                                     const std::string& tnc_etag,
                                     const std::string& tnc_abtest) {}

 protected:
  virtual ~TTServerConfigObserver() {}
};

class TTServerConfig {
 public:
  enum RequestState {
    NOT_START = 1,    // Config request has not been sent.
    REQ_PENDING = 2,  // Config request has been sent, and response has not been
                      // received.
    REQ_FAILED = 3,   // A failure response has been received.
    DATA_FAILED = 4,  // Response has been received successfully, but config
                      // content is invalid.
    SUCCESS = 5       // Valid config has been received.
  };

  TTNET_IMPLEMENT_EXPORT static TTServerConfig* GetInstance();

  virtual ~TTServerConfig();

  void InitServerConfig(
      const std::string& config_file_path,
      scoped_refptr<base::SingleThreadTaskRunner> file_task_runner);

  void UpdateServerConfigForProbe(TTServerConfigObserver::UpdateSource source,
                                  int64_t probe_version,
                                  int64_t probe_cmd,
                                  int delay = 0,
                                  bool use_injected_hosts_first = false,
                                  bool trigger_by_user = false);

  TTNET_IMPLEMENT_EXPORT void UpdateServerConfig(
      TTServerConfigObserver::UpdateSource source);

  TTNET_IMPLEMENT_EXPORT void AddServerConfigObserver(
      TTServerConfigObserver* observer);

  TTNET_IMPLEMENT_EXPORT void RemoveServerConfigObserver(
      TTServerConfigObserver* observer);

  const std::string& GetTncConfigString() const { return tnc_config_string_; }
  const base::Optional<base::Value>& GetTncConfigValue() const {
    return tnc_config_value_;
  }

  bool ReadConfigFile(std::string& content);

  void WriteConfigFile(const std::string& content);

  // Return true if tnc config parse successfully.
  bool ParseJsonResult(int response_code,
                       const std::string& content,
                       const std::string& tnc_version,
                       const std::string& tnc_canary,
                       const std::string& tnc_config_id,
                       const std::string& tnc_abtest,
                       const std::string& tnc_control,
                       const std::string& tnc_attr,
                       bool remote,
                       bool fromPort,
                       bool from_region = false);

  void ParseRemoteJsonResult(int response_code,
                             const std::string& content,
                             HttpResponseHeaders* responseHeaders);

  std::string GetConfigRootPath() const { return config_root_path_; }

  scoped_refptr<base::SingleThreadTaskRunner> GetFileTaskRunner() const {
    return file_task_runner_;
  }

  void StartFirstUpdate();
  void SetColdStartListener(TTColdStartListener* listener);

  bool IsColdStart() const;
  bool IsConfigUpdateSucc() const;

  void SetLastestProbeInfo(int64_t version, int64_t cmd, int64_t time);
  std::string GetConfigVersion() const;
  std::string GetTNCABTest() const;
  std::string GetTNCCanary() const;
  std::string GetTNCProbeVersion() const;
  void HandleRequestResult(URLRequest* url_request, int net_error);
  TTServerConfigObserver::UpdateSource GetConfigSource() const {
    return source_;
  }
  std::unique_ptr<base::Value> GetTNCBaseInfo() const;
  std::unique_ptr<base::Value> GetRecentProbeInfo() const;
  std::unique_ptr<base::Value> GetRecentTNCRequestInfo() const;

  void TryUpdateTncPolling(const bool first, const bool from_alarm);

  std::string GetTTNetVersionParams() const { return ttnet_version_; }
#if defined(OS_ANDROID) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  void UpdateFirstTncConfig();
#endif

#if BUILDFLAG(ENABLE_WEBSOCKETS)
  // |UpdateServerConfig| is only executed in main process, server config
  // in other process need to be updated by IPC channel from main process.
  void UpdateServerConfigInOtherProcess(
      TTServerConfigObserver::UpdateSource source,
      const std::string& content);
#endif

 private:
  friend struct base::DefaultSingletonTraits<TTServerConfig>;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, BuildGetDomainsUrlArray);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest,
                           BuildGetDomainsUrlArrayWithRemoteOnlyHosts);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, ParseJsonResultError);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, ParseJsonResultNotValidData);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, StartFirstUpdateEmptyDeviceId);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, StartFirstUpdateValidDeviceId);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, HandleRequestResult);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, ParseRemoteJsonResultError);
  FRIEND_TEST_ALL_PREFIXES(TTFileSslSessionCacheManagerTest, SetSslSession);
  FRIEND_TEST_ALL_PREFIXES(TTFileSslSessionCacheManagerTest, LoadFileCache);
  FRIEND_TEST_ALL_PREFIXES(TTFileSslSessionCacheManagerTest, ReadFileCacheData);
  FRIEND_TEST_ALL_PREFIXES(TTFileSslSessionCacheManagerTest,
                           HandleRemoteSessionConfig);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, TryAcceptTncConfigByAttr);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, UpdateFirstTncConfigTest);
  FRIEND_TEST_ALL_PREFIXES(TTFileSslSessionCacheManagerTest, ClearEarlyData);
  FRIEND_TEST_ALL_PREFIXES(StoreIdcManagerTest, UpdateTncConfigTest);

  friend class TTNetworkDelegateTest;

  struct RemoteResponseForTesting {
    RemoteResponseForTesting() : response_code(0), response_header(nullptr) {}
    RemoteResponseForTesting(int response_code,
                             const std::string& content,
                             HttpResponseHeaders* response_header)
        : response_code(response_code),
          content(content),
          response_header(response_header) {}
    int response_code;
    std::string content;
    HttpResponseHeaders* response_header;
  };

  void SetRemoteResponseForTesting(const RemoteResponseForTesting& response) {
    remote_response_for_testing_ = response;
  }

  void SetServerConfigContentForTesting(const std::string& content) {
    tnc_config_string_ = content;
    ParseTncConfigJsonString(content);
  }

  base::Optional<RemoteResponseForTesting> remote_response_for_testing_;
#endif

  TTServerConfig();

  void NotifyObserver(TTServerConfigObserver::UpdateSource source);

  // Construct TNC config request urls.
  bool BuildGetDomainsUrlArray(bool use_injected_hosts_first);

  void RequestForTncConfig();

  bool ReadConfigFileInternal(std::string& content);

  void WriteConfigOnFileThread(const std::string& content);

  void SetDefaultRouteSelectionMatcHostArray();

  void ColdStartFinish(bool timeout);

  void ReportTNCUpdateResult(bool succ,
                             TTServerConfigObserver::UpdateSource source,
                             int64_t last_update_time);

  void SaveTNCResponseHeadersInfo(const std::string& tnc_version,
                                  const std::string& tnc_canary,
                                  const std::string& tnc_config_id,
                                  const std::string& tnc_abtest,
                                  bool from_region) const;

  bool ParseTncConfigJsonString(const std::string& data);

  // TNC may configure new TNC hosts. Merge configured hosts and injected hosts
  // and reorder them if needed.
  void MergeTncHostsWithConfig(std::vector<std::string>& current_tnc_hosts,
                               bool use_current_hosts_first);

#if !BUILDFLAG(DISABLE_STORE_IDC)
  bool TryAcceptTncConfigByAttr(const std::string& tnc_attr,
                                const std::string& logid,
                                const std::string& epoch) const;
#endif

  void ClearFlagAndTryPendingTriggerGetDomain();

  std::list<TTServerConfigObserver*> observer_list_;

  TTServerConfigObserver::UpdateSource source_;

  size_t get_domains_already_try_times_;

  std::vector<std::string> get_domains_url_array_;
  std::vector<std::string> route_selection_match_host_array_;

  std::string tnc_config_string_;
  base::Optional<base::Value> tnc_config_value_;

  std::string config_file_path_;
  std::string config_root_path_;

  std::string tnc_config_version_;

  scoped_refptr<base::SingleThreadTaskRunner> file_task_runner_;

  // There may exist multiple requests for TNC config concurrently. This flag
  // ensures only one request can request for config at one time.
  std::atomic_flag updating_svr_config_flag_ = ATOMIC_FLAG_INIT;
  std::atomic_flag pending_trigger_tnc_flag_ = ATOMIC_FLAG_INIT;
  bool trigger_tnc_force_update_{false};

  base::OneShotTimer update_server_config_timer_;
  base::OneShotTimer update_server_config_retry_timer_;

  // TNC request info.
  TTServerConfigObserver::UpdateSource tnc_source_{
      TTServerConfigObserver::TTCACHE};
  std::string tnc_source_str_;
  RequestState request_state_{NOT_START};
  int64_t request_start_time_{-1};

  std::string ttnet_version_;
  // TNC probe info.
  int64_t probe_version_{0};
  int64_t probe_cmd_{0};
  int64_t lastest_probe_version_{0};
  int64_t lastest_probe_cmd_{0};
  int64_t lastest_probe_get_time_{-1};
  int64_t lastest_probe_send_time_{-1};
  RequestState lastest_probe_state_{NOT_START};

  base::OneShotTimer cold_start_timeout_timer_;
  bool cold_start_finished_{false};
  TTColdStartListener* cold_start_listener_{nullptr};
  bool config_update_succ_{false};
  int64_t config_update_time_{-1};
  int64_t next_config_update_time_{-1};
  int64_t next_config_retry_update_time_{-1};
  int64_t last_config_retry_check_time_{-1};
  int config_retry_times_{0};
#if defined(OS_ANDROID) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  // Delay tnc request when cookie has not been inited completed.
  bool first_tnc_update_completed_{false};
  base::OneShotTimer delay_tnc_request_timer_;
#endif

  DISALLOW_COPY_AND_ASSIGN(TTServerConfig);
};

}  // namespace net

#endif  // NET_TTNET_ROUTE_SELECTION_TT_SERVER_CONFIG_H_
