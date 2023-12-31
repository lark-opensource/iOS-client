// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef COMPONENTS_CRONET_IOS_CRONET_ENVIRONMENT_H_
#define COMPONENTS_CRONET_IOS_CRONET_ENVIRONMENT_H_

#include <list>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "base/files/file_path.h"
#include "base/files/scoped_file.h"
#include "base/macros.h"
#include "base/strings/sys_string_conversions.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/thread.h"
#include "components/cronet/url_request_context_config.h"
#include "components/cronet/version.h"
#include "net/cert/cert_verifier.h"
#include "net/url_request/url_request_context.h"
#include "net/url_request/url_request_context_getter.h"

#if BUILDFLAG(TTNET_IMPLEMENT)
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NQE_SUPPORT)
#include "net/nqe/effective_connection_type.h"
#include "net/nqe/network_quality_estimator.h"
#include "net/nqe/network_quality_observation_source.h"
#include "net/tt_net/nqe/tt_network_quality_estimator.h"
#include "net/tt_net/nqe/tt_packet_loss_estimator.h"
#endif  // !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NQE_SUPPORT)
#if BUILDFLAG(ENABLE_NQE_AND_WIFI_TO_CELL_ON_MOBILE)
#include "net/tt_net/multinetwork/wifi_to_cell/tt_multinetwork_manager.h"
#endif  // BUILDFLAG(ENABLE_NQE_AND_WIFI_TO_CELL_ON_MOBILE)
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_STREAM_ZSTD)
#include "net/tt_net/zstd/tt_zstd_manager.h"
#endif
#endif  // BUILDFLAG(TTNET_IMPLEMENT)

#if BUILDFLAG(TTNET_IMPLEMENT)
#include "net/tt_net/base/cronet_init_timing_info.h"
#include "net/tt_net/route_selection/tt_monitor_module.h"
#endif

namespace base {
class WaitableEvent;
}  // namespace base

namespace net {
class CookieStore;
class NetLog;
class FileNetLogObserver;
#if BUILDFLAG(TTNET_IMPLEMENT)
class CompressNativeWrapper;
class ProxyConfigService;
class TTNetDetectListener;
class TTNetworkDelegate;
class TTColdStartListener;
class TTDnsResolveListener;
class URLDispatchByAppControl;
#endif
}  // namespace net

namespace cronet {
class CronetPrefsManager;

// CronetEnvironment contains all the network stack configuration
// and initialization.
class TTNET_IMPLEMENT_EXPORT CronetEnvironment {
 public:
  using PkpVector = std::vector<std::unique_ptr<URLRequestContextConfig::Pkp>>;

  // A special thread priority value that indicates that the thread priority
  // should not be altered when a thread is created.
  static const double kKeepDefaultThreadPriority;

  // |user_agent| will be used to generate the user-agent if
  // |user_agent_partial| is true, or will be used as the complete user-agent
  // otherwise.
  CronetEnvironment(const std::string& user_agent, bool user_agent_partial);
  ~CronetEnvironment();

  // Starts this instance of Cronet environment.
  void Start();

  // The full user-agent.
  std::string user_agent();

  // Get global UMA histogram deltas.
  std::vector<uint8_t> GetHistogramDeltas();

  // Creates a new net log (overwrites existing file with this name). If
  // actively logging, this call is ignored.
  bool StartNetLog(base::FilePath::StringType file_name, bool log_bytes);
  // Stops logging and flushes file. If not currently logging this call is
  // ignored.
  void StopNetLog();

  void AddQuicHint(const std::string& host, int port, int alternate_port);

  // Setters and getters for |http2_enabled_|, |quic_enabled_|, and
  // |brotli_enabled| These only have any effect
  // before Start() is called.
  void set_http2_enabled(bool enabled) { http2_enabled_ = enabled; }
  void set_quic_enabled(bool enabled) { quic_enabled_ = enabled; }
  void set_brotli_enabled(bool enabled) { brotli_enabled_ = enabled; }

  bool http2_enabled() const { return http2_enabled_; }
  bool quic_enabled() const { return quic_enabled_; }
  bool brotli_enabled() const { return brotli_enabled_; }

  void set_accept_language(const std::string& accept_language) {
    accept_language_ = accept_language;
  }

  void set_mock_cert_verifier(
      std::unique_ptr<net::CertVerifier> mock_cert_verifier) {
    mock_cert_verifier_ = std::move(mock_cert_verifier);
  }

  void set_http_cache(URLRequestContextConfig::HttpCacheType http_cache) {
    http_cache_ = http_cache;
  }

  void set_experimental_options(const std::string& experimental_options) {
    experimental_options_ = experimental_options;
  }

  void SetHostResolverRules(const std::string& host_resolver_rules);

  void set_ssl_key_log_file_name(const std::string& ssl_key_log_file_name) {
    ssl_key_log_file_name_ = ssl_key_log_file_name;
  }

  void set_pkp_list(PkpVector pkp_list) { pkp_list_ = std::move(pkp_list); }

  void set_enable_public_key_pinning_bypass_for_local_trust_anchors(
      bool enable) {
    enable_pkp_bypass_for_local_trust_anchors_ = enable;
  }

  // Sets priority of the network thread. The |priority| should be a
  // floating point number between 0.0 to 1.0, where 1.0 is highest priority.
  void SetNetworkThreadPriority(double priority);

  // Returns the URLRequestContext associated with this object.
  net::URLRequestContext* GetURLRequestContext() const;

  // Return the URLRequestContextGetter associated with this object.
  net::URLRequestContextGetter* GetURLRequestContextGetter() const;

  // The methods below are used for testing.
  base::SingleThreadTaskRunner* GetFileThreadRunnerForTesting() const;
  base::SingleThreadTaskRunner* GetNetworkThreadRunnerForTesting() const;

 private:
  // Extends the base thread class to add the Cronet specific cleanup logic.
  class CronetNetworkThread : public base::Thread {
   public:
    CronetNetworkThread(const std::string& name,
                        cronet::CronetEnvironment* cronet_environment);

   protected:
    ~CronetNetworkThread() override;
    void CleanUp() override;

   private:
    cronet::CronetEnvironment* const cronet_environment_;

    DISALLOW_COPY_AND_ASSIGN(CronetNetworkThread);
  };

  // Performs initialization tasks that must happen on the network thread.
  void InitializeOnNetworkThread();

  // Returns the task runner for the network thread.
  base::SingleThreadTaskRunner* GetNetworkThreadTaskRunner() const;

  // Runs a closure on the network thread.
  void PostToNetworkThread(const base::Location& from_here,
                           base::OnceClosure task);

  // Helper methods that start/stop net logging on the network thread.
  void StartNetLogOnNetworkThread(const base::FilePath&, bool log_bytes);
  void StopNetLogOnNetworkThread(base::WaitableEvent* log_stopped_event);

  base::Value GetNetLogInfo() const;

  // Returns the HttpNetworkSession object from the passed in
  // URLRequestContext or NULL if none exists.
  net::HttpNetworkSession* GetHttpNetworkSession(
      net::URLRequestContext* context);

  // Sets host resolver rules on the network_io_thread_.
  void SetHostResolverRulesOnNetworkThread(const std::string& rules,
                                           base::WaitableEvent* event);

  // Sets priority of the network thread. This method should only be called
  // on the network thread.
  void SetNetworkThreadPriorityOnNetworkThread(double priority);

  std::string getDefaultQuicUserAgentId() const;

  // Prepares the Cronet environment to be destroyed. The method must be
  // executed on the network thread. No other tasks should be posted to the
  // network thread after calling this method.
  void CleanUpOnNetworkThread();

#if BUILDFLAG(TTNET_IMPLEMENT)
 public:
  void HandleRequestInfoNotifyNativeCallback(
      const net::TTNetBasicRequestInfo& info);
  void EnableTTBizHttpDns(bool enable,
                          const std::string& domain,
                          const std::string& auth_id,
                          const std::string& auth_key,
                          bool temp_key,
                          const std::string& temp_key_timestamp);
  void TTDnsResolve(const std::string& host,
                    int sdk_id,
                    const std::string& uuid);
  void SetTTDnsResolveListener(net::TTDnsResolveListener* listener);
  void SetRequestInfoDelegate(net::TTRequestInfoProvider* delegate);
  void TTDnsResolveNativeCallback(const std::string& uuid,
                                  const std::string& host,
                                  int ret,
                                  int source,
                                  int cache_source,
                                  const std::vector<std::string>& ips,
                                  const std::string& detailed_info,
                                  bool is_native);
  void OnPublicIPsChangedNativeCallback(
      const std::vector<std::string>& ipv4_list,
      const std::vector<std::string>& ipv6_list);
  void OnServerConfigChangedNativeCallback(
      const net::TTServerConfigObserver::UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value);
  void TryStartNetDetect(const std::vector<std::string>& urllist,
                         int timeout,
                         int actions);
  void SetNetDetectListener(net::TTNetDetectListener* listener);
  void SetProxyConfig(const std::string& proxy_config);
  void SetBoeEnabled(bool enabled, const std::string& json);
  void SetAppWillTerminateEnabled(bool enabled);
  void SetAppInitRegionInfo(const std::string& init_region);
  void NotifyTNCConfigUpdated(const std::string& tnc_version,
                              const std::string& tnc_canary,
                              const std::string& tnc_config_id,
                              const std::string& tnc_abtest,
                              const std::string& tnc_control,
                              const std::string& tnc_config);
  void SetInitNetworkThreadPriority(double priority) {
    init_network_thread_priority_ = priority;
  }
  void SetStoreIdcRuleJSON(const std::string& json) {
    store_idc_rule_json_ = json;
  }
  void set_get_domain_default_json(const std::string& json) {
    get_domain_default_json_ = json;
  }
  void SetHttpDnsEnabled(bool enabled) { http_dns_enabled_ = enabled; }
  bool HttpDnsEnabled() { return http_dns_enabled_; }

  void SetMaxHttpDiskCacheSize(int size);
  int64_t GetHttpDiskCacheSize();
  void ClearHttpCache();
  void ClearHttpDiskCache();
  void ClearHttpDiskCacheForcelly();
  void SetZstdFuncAddr(void* create_dctx_addr,
                       void* decompress_stream_addr,
                       void* free_dctx_addr,
                       void* is_error_addr,
                       void* create_ddict_addr,
                       void* dctx_ref_ddict_addr,
                       void* free_ddict,
                       void* dctx_reset);

  void set_sc_ipv6_detect_enabled(bool enabled) {
    sc_ipv6_detect_enabled_ = enabled;
  }
  bool sc_ipv6_detect_enabled() const { return sc_ipv6_detect_enabled_; }

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_STREAM_ZSTD)
  void SetZstdFuncAddrOnNetworkThread(
      net::TTZstdManager::ZSTDCreateDCtx create_dctx_func,
      net::TTZstdManager::ZSTDDecompressStream decompress_stream_func,
      net::TTZstdManager::ZSTDFreeDCtx free_dctx_func,
      net::TTZstdManager::ZSTDIsError zstd_is_error_func,
      net::TTZstdManager::ZSTDCreateDDict zstd_create_ddict_func,
      net::TTZstdManager::ZSTDDCtxRefDDict zstd_dctx_ref_ddict_func,
      net::TTZstdManager::ZSTDFreeDDict zstd_free_ddict_func,
      net::TTZstdManager::ZSTDDCtxReset zstd_dctx_reset_func);
#endif
  void SetRouteSelectionBestHost(const std::string& host,
                                 const std::string& rs_name);
  void SetRouteSelectionBestHostOnNetworkThread(const std::string& host,
                                                const std::string& rs_name);
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NQE_SUPPORT)
  net::EffectiveConnectionType GetEffectiveConnectionType() const;
  int32_t GetHttpRttMs() const;
  int32_t GetTransportRttMs() const;
  int32_t GetDownstreamThroughputKbps() const;
  double GetUpstreamPacketLossRate(
      net::PacketLossAnalyzerProtocol protocol) const;
  double GetUpstreamPacketLossRateVariance(
      net::PacketLossAnalyzerProtocol protocol) const;
  double GetDownstreamPacketLossRate(
      net::PacketLossAnalyzerProtocol protocol) const;
  double GetDownstreamPacketLossRateVariance(
      net::PacketLossAnalyzerProtocol protocol) const;
  net::NetworkQualityEstimator* GetNQE();
  void AddNetworkQualityLevelObserver(
      net::TTNetworkQualityEstimator::NQLObserver* observer);
  int GetNetworkQualityLevel() const;
  int GetEffectiveHttpRtt() const;
  int GetEffectiveTransportRtt() const;
  int GetEffectiveDownstreamThroughput() const;
#endif
#if BUILDFLAG(ENABLE_NQE_AND_WIFI_TO_CELL_ON_MOBILE)
  void AddMultiNetworkStateObserver(
      net::TTMultiNetworkManager::StateChangeObserver* observer);
  void NotifySwitchToMultiNetwork(bool enable);
  void TriggerSwitchingToCellular();
  void CheckMultiNetworkNativeCallback(int previous_state, int current_state);
#endif
  void AddPkp(const std::string& host,
              const std::vector<std::string>& hashes,
              bool includeSubDomain,
              long time);
  void SetColdStartListener(net::TTColdStartListener* listener);
  void InstallServerCertificate(const std::vector<std::string>& certificate) {
    certificate_ = certificate;
  }
  void AddClientCertificate(const std::vector<std::string>& host_list,
                            const std::string& certificate,
                            const std::string& private_key);
  void AddClientOpaqueDataAfterInit(const std::vector<std::string>& host_list,
                                    const std::string& certificate,
                                    const std::string& private_key);
  void ClearClientOpaqueData();
  void RemoveClientOpaqueData(const std::string& host);
  void TTURLDispatch(scoped_refptr<net::URLDispatchByAppControl> url_dispatch);
  void TTURLDelay(scoped_refptr<net::URLDispatchByAppControl> url_dispatch);
  void PreconnectUrl(const std::string& url);
  void TriggerGetDomain(bool use_latest_param = false);

 private:
  void InitTTNetModuleOnNetworkThread();
  void ParseServerConfig(const std::string& version,
                         const std::string& canary,
                         const std::string& tnc_config_id,
                         const std::string& tnc_abtest,
                         const std::string& tnc_control,
                         const std::string& config);
  base::ThreadPriority getNetworkThreadPriority(double priority) const;
  void PreconnectUrlOnNetworkThread(const std::string& url) const;
#if BUILDFLAG(ENABLE_NQE_AND_WIFI_TO_CELL_ON_MOBILE)
  void AddMultiNetworkStateObserverOnNetworkThread(
      net::TTMultiNetworkManager::StateChangeObserver* observer);
  void NotifySwitchToMultiNetworkOnNetworkThread(bool enable);
  void TriggerSwitchingToCellularOnNetworkThread();
#endif
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NQE_SUPPORT)
  void AddNetworkQualityLevelObserverOnNetworkThread(
      net::TTNetworkQualityEstimator::NQLObserver* observer);
  class NQEHandler : public net::EffectiveConnectionTypeObserver,
                     public net::RTTAndThroughputEstimatesObserver,
                     public net::NetworkQualityEstimator::RTTObserver,
                     public net::NetworkQualityEstimator::ThroughputObserver,
                     public net::TTNetworkQualityEstimator::NQLObserver,
                     public net::TTPacketLossObserver {
   public:
    NQEHandler(CronetEnvironment* env);
    ~NQEHandler() override;

    // net::EffectiveConnectionTypeObserver implementation.
    void OnEffectiveConnectionTypeChanged(
        net::EffectiveConnectionType effective_connection_type) override;

    // net::RTTAndThroughputEstimatesObserver implementation.
    void OnRTTOrThroughputEstimatesComputed(
        base::TimeDelta http_rtt,
        base::TimeDelta transport_rtt,
        int32_t downstream_throughput_kbps) override;

    // net::NetworkQualityEstimator::RTTObserver implementation.
    void OnRTTObservation(int32_t rtt_ms,
                          const base::TimeTicks& timestamp,
                          net::NetworkQualityObservationSource source) override;

    // net::NetworkQualityEstimator::ThroughputObserver implementation.
    void OnThroughputObservation(
        int32_t throughput_kbps,
        const base::TimeTicks& timestamp,
        net::NetworkQualityObservationSource source) override;

    void OnNQLChanged(net::TTNetworkQualityLevel nql) override;

    void OnNetworkQualityRttAndThroughputNotified(
        int effective_hrtt,
        int effective_trtt,
        int effective_rx_throughput) override;

    void OnPacketLossComputed(net::PacketLossAnalyzerProtocol protocol,
                              double send_loss_rate,
                              double send_loss_variance,
                              double receive_loss_rate,
                              double receive_loss_variance) override;

    net::EffectiveConnectionType GetEffectiveConnectionType() const;

    int32_t GetHttpRttMs() const;

    int32_t GetTransportRttMs() const;

    int32_t GetDownstreamThroughputKbps() const;

    double GetUpstreamPacketLossRate(
        net::PacketLossAnalyzerProtocol protocol) const;
    double GetUpstreamPacketLossRateVariance(
        net::PacketLossAnalyzerProtocol protocol) const;
    double GetDownstreamPacketLossRate(
        net::PacketLossAnalyzerProtocol protocol) const;
    double GetDownstreamPacketLossRateVariance(
        net::PacketLossAnalyzerProtocol protocol) const;

    int GetNetworkQualityLevel() const;
    int GetEffectiveHttpRtt() const;
    int GetEffectiveTransportRtt() const;
    int GetEffectiveDownstreamThroughput() const;

   private:
    CronetEnvironment* env_;
    std::atomic<net::EffectiveConnectionType> effective_connection_type_;
    std::atomic<int32_t> http_rtt_ms_;
    std::atomic<int32_t> transport_rtt_ms_;
    // Store upstream
    std::atomic<int32_t> downstream_throughput_kbps_;
    std::array<std::atomic<double>, net::PROTOCOL_COUNT>
        upstream_packet_loss_rate_;
    std::array<std::atomic<double>, net::PROTOCOL_COUNT>
        upstream_packet_loss_rate_variance_;
    std::array<std::atomic<double>, net::PROTOCOL_COUNT>
        downstream_packet_loss_rate_;
    std::array<std::atomic<double>, net::PROTOCOL_COUNT>
        downstream_packet_loss_rate_variance_;

    std::atomic<net::TTNetworkQualityLevel> nql_;
    std::atomic<int> effective_hrtt_;
    std::atomic<int> effective_trtt_;
    std::atomic<int> effective_rx_throughput_;
  };
#endif

 private:
  net::TTNetworkDelegate* delegate_{nullptr};
  std::string get_domain_default_json_;
  std::string store_idc_rule_json_;
  std::string ttnet_proxy_config_;
  std::string bypass_boe_json_;
  bool boe_enabled_{false};
  bool http_dns_enabled_{false};
  bool sc_ipv6_detect_enabled_{false};
  std::unique_ptr<net::ProxyConfigService> proxy_config_service_;
  std::vector<std::string> certificate_;
  std::vector<net::ClientCertInfo> client_cert_info_;

  net::TTColdStartListener* cold_start_listener_{nullptr};
  std::unique_ptr<net::CompressNativeWrapper> compress_native_wrapper_;

  int max_http_disk_cache_size_{0};
  double init_network_thread_priority_{0.5};
  net::CronetInitTimingInfo init_timing_info_;
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NQE_SUPPORT)
  std::unique_ptr<net::NetworkQualityEstimator> network_quality_estimator_;
  std::unique_ptr<NQEHandler> nqe_handler_;
#endif
#endif  // TTNET_IMPLEMENT
  bool http2_enabled_;
  bool quic_enabled_;
  bool brotli_enabled_;
  std::string accept_language_;
  std::string experimental_options_;
  // Effective experimental options. Kept for NetLog.
  std::unique_ptr<base::DictionaryValue> effective_experimental_options_;
  std::string ssl_key_log_file_name_;
  URLRequestContextConfig::HttpCacheType http_cache_;
  PkpVector pkp_list_;

  std::list<net::HostPortPair> quic_hints_;

  std::unique_ptr<base::Thread> network_io_thread_;
  std::unique_ptr<base::Thread> file_thread_;
  scoped_refptr<base::SequencedTaskRunner> pref_store_worker_pool_;
  std::unique_ptr<net::CertVerifier> mock_cert_verifier_;
  std::unique_ptr<net::CookieStore> cookie_store_;
  std::unique_ptr<net::URLRequestContext> main_context_;
  scoped_refptr<net::URLRequestContextGetter> main_context_getter_;
  std::string user_agent_;
  bool user_agent_partial_;
  net::NetLog* net_log_;
  std::unique_ptr<net::FileNetLogObserver> file_net_log_observer_;
  bool enable_pkp_bypass_for_local_trust_anchors_;
  double network_thread_priority_;
  std::unique_ptr<CronetPrefsManager> cronet_prefs_manager_;

  DISALLOW_COPY_AND_ASSIGN(CronetEnvironment);
};

}  // namespace cronet

#endif  // COMPONENTS_CRONET_IOS_CRONET_ENVIRONMENT_H_
