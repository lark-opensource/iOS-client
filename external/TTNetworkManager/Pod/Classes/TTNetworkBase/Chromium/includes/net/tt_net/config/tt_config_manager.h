// Copyright (c) 2018 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_CONFIG_TT_CONFIG_MANAGER_H_
#define NET_TTNET_CONFIG_TT_CONFIG_MANAGER_H_

#include <regex>
#include <set>
#include <string>

#include "base/memory/singleton.h"
#include "base/values.h"
#include "net/base/address_family.h"
#include "net/base/ip_endpoint.h"
#include "net/base/net_errors.h"
#include "net/net_buildflags.h"
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_PROXY_SUPPORT)
#include "net/proxy_resolution/proxy_config.h"
#endif
#include "net/socket/client_socket_pool.h"
#include "net/tt_net/base/address_list_resorter.h"
#include "net/tt_net/dns/tt_wise_host_resolver_impl.h"
#include "net/tt_net/route_selection/tt_server_config.h"
#if BUILDFLAG(TTNET_IMPLEMENT)
#include "net/third_party/quiche/src/quic/core/quic_config.h"
#endif

namespace net {

class AddressList;
class HttpServerProperties;

void ParseQuicHostConfigUnit(
    const base::DictionaryValue* dict_quic_config_param,
    quic::QuicHostConfig* host_config,
    const quic::QuicHostConfig& global_config);

struct RequestRetryCustomizeConfig {
  RequestRetryCustomizeConfig();
  RequestRetryCustomizeConfig(const RequestRetryCustomizeConfig&);
  ~RequestRetryCustomizeConfig();

  std::vector<std::string> wildchar_hosts;
  std::set<int> errors;
  int delay_ms{0};
  int attempts{0};

  bool Valid() const {
    if (wildchar_hosts.size() > 0 && errors.size() > 0 && delay_ms > 0 &&
        attempts > 0) {
      return true;
    }
    return false;
  }
};

struct RouteSelectionConfig {
  RouteSelectionConfig();
  RouteSelectionConfig(const RouteSelectionConfig&);
  ~RouteSelectionConfig();

  int group_failure_tolerant_limit{0};
  int ies_route_selection_trigger_interval{1800};
  int dsa_route_selection_trigger_interval{1800};
  int route_selection_init_delay{3};
  bool cache_enabled{false};
  int cache_expire_seconds{3600 * 24};
};

struct HostResolverConfig {
  enum AsyncHttpDnsModeForQuic {
    BOTH_ENABLED = 0,
    QUIC_STALE_RACE,
    ASYNC_HTTPDNS,
    MAX_VALUE
  };

  HostResolverConfig();
  HostResolverConfig(const HostResolverConfig&);
  ~HostResolverConfig();

  // The OAA switch for our new host resolver.
  bool tt_wise_host_resolver_enabled;

  // Basic.
  DnsServiceTrustLevel
      dns_service_trust_level_setting[DNS_SERVICE_TYPE_LAST + 1];
  HostResolverWorkingMode host_resolver_working_mode;

  std::map<std::string, AddressList> hardcode_ip_mapping;
  std::map<std::string, AddressList> direct_ip_mapping;

  std::map<std::string, int> min_dns_ttl_control_map;

  AddressFamily prefer_address_family;

  // Customized dns.
  IPEndPoint customized_nameserver;

  // Persistent host cache.
  bool persistent_host_cache_enabled;
  int persistent_host_cache_first_saving_interval;
  int persistent_host_cache_repeat_saving_interval;

  // HttpDns related.
  bool http_dns_enabled{false};
  bool google_http_dns_enabled;
  bool tt_http_dns_enabled;
  bool http_dns_prefered{true};
  bool http_dns_bypass_from_header_enabled{true};

  bool dns_race_enabled{false};
  std::vector<std::string> dns_race_host_list;
  bool dns_race_strict_enabled{false};

  std::string tt_httpdns_host;
  std::set<std::string> httpdns_backup_domain_set;
  std::set<std::string> httpdns_domain_set;

  std::vector<std::regex> httpdns_bypass_regex_list;
  std::vector<std::string> httpdns_bypass_str_list;

  std::vector<std::string> httpdns_host_white_list;
  std::vector<std::regex> httpdns_host_white_list_regex;

  // Timeout control.
  int http_dns_timeout_seconds;
  int batch_http_dns_timeout_seconds;
  int local_dns_timeout_seconds;
  std::map<std::string, int> http_dns_timeout_seconds_map;
  std::map<std::string, int> local_dns_timeout_seconds_map;

  std::vector<std::string> httpdns_forbidden_hosts;
  std::vector<std::string> httpdns_forbidden_wildchar_hosts;
  int ipv6_fallback_timer_ms{300};

  // Misc
  int stale_entry_preserve_limit_times_of_ttl;
  std::set<std::string> keep_fresh_hostname_list;

  std::vector<std::string> tt_httpdns_google_host_pattern;
  std::vector<std::string> tt_httpdns_tt_host_pattern;
  std::map<std::string, std::vector<std::string>> tt_httpdns_host_pattern_map;

  bool parallel_localdns_enable{false};
  bool optimize_ip_rank_enable{false};
  std::vector<std::string> ipv4_prefered_wildchar_hosts;

  std::vector<std::string> async_httpdns_wildcard_hosts;
  std::vector<std::string> async_httpdns_forbid_wildcard_hosts;
  size_t async_httpdns_batch_size_threshold{10};
  int async_httpdns_batch_timeout_threshold{600};
  int httpdns_stale_interval{60};
  AsyncHttpDnsModeForQuic async_httpdns_mode_for_quic{BOTH_ENABLED};

  // Display more detailed information about DNS when use TTDnsResolve function
  bool dns_detailed_info_display_enable{false};

  std::vector<std::string> localdns_append_dns_addr_wildchar_hosts;
  std::vector<std::string> httpdns_append_dns_addr_wildchar_hosts;

  std::vector<std::string> dns_check_hosts;
  int dns_check_interval_limit{60};
  bool skip_mssdk{false};
};

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NQE_SUPPORT)
struct NqeConfig {
  enum NetworkQualityType {
    // When the network is fake network.
    NETWORK_QUALITY_TYPE_FAKE = -1,

    NETWORK_QUALITY_TYPE_UNKNOWN = 0,

    NETWORK_QUALITY_TYPE_OFFLINE = 1,

    // When the network has the quality of a poor 2G connection.
    NETWORK_QUALITY_TYPE_SLOW_2G = 2,

    // When the network has the quality of a faster 2G connection.
    NETWORK_QUALITY_TYPE_2G,

    // When the network has the quality of a 3G connection.
    NETWORK_QUALITY_TYPE_3G,

    // When the network has the quality of a SLOW_4G connection.
    NETWORK_QUALITY_TYPE_SLOW_4G,

    // When the network has the quality of a MODERATE_4G connection.
    NETWORK_QUALITY_TYPE_MODERATE_4G,

    // When the network has the quality of a GOOD_4G connection.
    NETWORK_QUALITY_TYPE_GOOD_4G,

    // when the network has the quality of a EXCELLENT_4G connection.
    NETWORK_QUALITY_TYPE_EXCELLENT_4G,

    // Last value of the network quality type. This value is unused.
    NETWORK_QUALITY_TYPE_LAST,
  };

  struct NetworkQuality {
    NetworkQuality() : http_rtt(0), tcp_rtt(0), throughput(0) {}
    NetworkQuality(int http_rtt, int tcp_rtt, int throughput)
        : http_rtt(http_rtt), tcp_rtt(tcp_rtt), throughput(throughput) {}
    int http_rtt;
    int tcp_rtt;
    int throughput;
  };

  NqeConfig();
  ~NqeConfig();

  std::map<NetworkQualityType, NetworkQuality> ect_thresholds;
  int nqe_tcp_rtt_observer_buff_size{0};
  bool nqe_use_small_responses{false};
  int nqe_min_socket_watcher_notification_interval{0};
  int nqe_ect_recomputation_interval_seconds{0};
  int nqe_observation_valid_window_seconds{0};
  int nqe_observation_calculate_percentile{0};
  bool use_raw_rtt{false};
#if defined(OS_ANDROID) && BUILDFLAG(ENABLE_WEBSOCKETS)
  bool enable_interproc{false};
#endif

#if defined(OS_ANDROID) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  bool force_update_network_type_enabled{true};
  int force_update_network_type_interval{3 * 60};
#endif
};
#endif

struct RequestLogConfig {
  RequestLogConfig();
  ~RequestLogConfig();

  int report_timestamp_info{0};
  bool report_reset_error_list{false};
};

struct DnsCrossSpConfig {
  DnsCrossSpConfig();
  ~DnsCrossSpConfig();

  std::vector<std::string> wildchar_hosts;
  int64_t interval{5 * 60};
  int64_t action_stat_interval{5 * 60};
  bool test_mode{false};
};

struct ForceHttp11Config {
  ForceHttp11Config();
  ~ForceHttp11Config();

  bool enable{false};
  std::set<std::string> wildchar_hosts;
};

#if defined(OS_ANDROID) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
struct BaseStationConfig {
  BaseStationConfig();
  ~BaseStationConfig();

  bool enabled{false};
  std::vector<std::string> ping_hosts;
  int64_t ping_timeout_ms{1500};
  std::vector<std::string> http_urls;
  int64_t http_timeout_ms{10000};
  int64_t active_succ_interval_seconds{10 * 60};
  int64_t active_fail_interval_seconds{5 * 60};
  int64_t stat_available_interval_ms{2 * 60 * 1000};
  int64_t recovery_timeout_ms{10 * 1000};
  bool test_mode_enabled{false};
};
#endif

class QuicHostConfigManager {
public:
  QuicHostConfigManager();
  ~QuicHostConfigManager();

  const quic::QuicHostConfig& global_config() const { return global_config_; }

  const std::map<std::string, quic::QuicHostConfig>& host_configs() const {
    return host_configs_;
  }

  const quic::QuicHostConfig& GetConfigByHost(const std::string& host) const {
    const auto& iter = host_configs_.find(host);

    return iter == host_configs_.end() ? global_config_ : iter->second;
  }

private:
  friend class ConfigManager;

  quic::QuicHostConfig global_config_;
  std::map<std::string, quic::QuicHostConfig> host_configs_;
};

struct TTNetQuicConfig {
  TTNetQuicConfig();
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_QUIC_RECVMMSG)
  TTNetQuicConfig(const TTNetQuicConfig&);
#endif
  ~TTNetQuicConfig();

  // Set by "quic_versions" : {"host1":"Q043", "host2":"draft29"}
  std::map<std::string, quic::ParsedQuicVersion> quic_host_version_map;

  bool allow_post_request_before_shlo;
  int broken_delay;
  int broken_delay_max_shift;
  bool reuse_session_with_same_quic_version = false;

  std::string quic_version;
  int delay_tcp_race;
  bool disable_confirmation;
  bool enable_packet_wall_timestamp;

  // Mark broken disable
  bool disable_report_broken;
  bool disable_ietf_session_stored;
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_QUIC_RECVMMSG)
  // Support recvmmsg
  bool enable_quic_recvmmsg;
  int max_packets_per_read;
#endif
  std::set<std::string> ping_keepalive_hosts;
  std::set<url::SchemeHostPort> quic_hint_hosts;
};

struct SocketConfig {
  SocketConfig();
  ~SocketConfig();

  bool enable_ws_fast_connect{false};
  int ws_reconnect_timeout_interval_ms{1000};
  int reconnect_timeout_interval_ms{320};
  int triplicate_ip_numbers_less_than{0};
  bool enable_quick_test_when_socket_timeout_set{false};
  AddressListResorterType addresses_resort_type{ADDRESS_LIST_RESORTER_NONE};
  bool enable_concurrent_connect{false};
  std::set<std::string> concurrent_connect_hosts;
  int ip_forbid_duration{0};
  std::set<int> socket_close_error_list;
#if !defined(OS_ANDROID) && !defined(OS_IOS)
  bool enable_keepalive_config{false};
  bool tcp_keep_alive{true};
  int tcp_keep_delay{45};
#endif
};

struct SocketPoolConfig {
  SocketPoolConfig();
  SocketPoolConfig(const SocketPoolConfig&);
  ~SocketPoolConfig();
  std::map<ClientSocketPool::GroupId, int> max_sockets_per_groupid_config;
  std::map<ClientSocketPool::GroupId, int>
      unused_idle_socket_timeout_per_groupid_config;
  std::map<ClientSocketPool::GroupId, int>
      used_idle_socket_timeout_per_groupid_config;
};

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_PROXY_SUPPORT)
struct TTProxyConfig {
  TTProxyConfig();

  ~TTProxyConfig();

  bool proxy_enable{false};
  std::vector<std::regex> black_list_regex;
  ProxyConfig http_proxy_config;
  ProxyConfig https_proxy_config;
};
#endif

struct BufferConfig {
  BufferConfig();
  BufferConfig(const BufferConfig&);
  ~BufferConfig();

  std::map<std::string, int> so_recv_buf_size_wildchar_map;
  std::map<std::string, int> so_send_buf_size_wildchar_map;

  std::map<std::string, int> so_recv_buf_size_map;
  std::map<std::string, int> so_send_buf_size_map;
  int request_body_buffer_size{0};
  int filter_stream_buffer_size{0};
};

struct HpackMatchRule {
  HpackMatchRule();
  ~HpackMatchRule();
  HpackMatchRule(const HpackMatchRule&);

  std::string domain;
  std::vector<std::string> path_prefix;
};

struct SslConfig {
  SslConfig();
  ~SslConfig();
  SslConfig(const SslConfig&);

  bool enable_tls13_all{true};
  std::set<std::string> disable_tls13_host_list;
  std::vector<std::string> enable_0rtt_hosts_wildchar;
  bool network_isolation_enabled{true};
  bool disable_cbc_suites{false};
};

struct Http2Config {
  Http2Config();
  ~Http2Config();

  std::vector<std::string> ping_keepalive_hosts;
  int ping_keepalive_interval{60};
  bool ping_keepalive_enabled{true};
  int ping_probe_timeout{10};

  int h2_session_check_interval{90};
  bool h2_session_check_enabled{false};
  std::vector<std::string> session_check_hosts;
  bool h2_session_timeout_enabled{false};
  int h2_session_idle_timeout_seconds{120};

  bool hpack_optimization_enabled{false};
  std::vector<std::string> hpack_optimization_path_list;
  std::vector<HpackMatchRule> hpack_optimization_match_rule_list;
  std::set<std::string> hpack_optimization_common_params_set;
  std::vector<std::string> hpack_optimization_common_params_list;
  std::set<std::string> hpack_optimization_header_without_index_set;
  bool hpack_optimization_header_index_permitted_enabled{false};
  std::set<std::string> hpack_optimization_header_index_set;

  int h2_throttle_ms{300};
  std::map<std::string, int> h2_throttle_ms_map;
  std::vector<std::string> force_throttle_hosts;

  std::set<std::string> disable_h2_priority_host_set;
};

struct MiscConfig {
  MiscConfig();
  MiscConfig(const MiscConfig&);
  ~MiscConfig();

  std::vector<RequestRetryCustomizeConfig> request_retry_customize_list;
  int request_retry_delay_interval_ms{0};
  std::set<int> request_retry_error_list;
  // If a net error in |retry_req_tag_errors| occurs, request log of the
  // HTTP DNS request started by the retrying will mark |is_internal_retry|
  // true. |retry_req_tag_errors| should be subset of
  // |request_retry_error_list|.
  std::set<int> retry_req_tag_errors;
  std::vector<std::string> request_retry_forbide_host_list;
  std::vector<std::string> request_retry_forbide_path_list;
  int request_retry_max_attempts{0};
  std::vector<std::string> share_cookie_host_list;

  bool request_retry_force_httpdns{false};
  std::vector<std::string> request_retry_force_httpdns_white_list;
  std::vector<std::string> request_retry_force_httpdns_wildchar_hosts;
  std::set<int> request_retry_force_httpdns_error_list;

  bool request_retry_skip_prefer_ip{false};
  std::vector<std::string> request_retry_skip_prefer_ip_wildchar_hosts;
  std::set<int> request_retry_skip_prefer_ip_error_list;

  bool update_hpack_table_size_enabled{false};
  bool remove_bad_dns_result_in_cache{false};
  bool request_headers_enabled{false};
  bool request_log_to_alog{false};
  bool cip_header_enabled{false};
  int tnc_update_interval{10800};
  int tnc_update_fail_interval{600};
  bool route_selection_ttfb_enabled{false};
  bool tnc_use_v5{true};
  bool builtin_cert_store_enabled{false};
  int ipv6_detect_interval{600};
  bool tnc_enable_update_timer{true};
  int tnc_request_timeout_seconds{15};
  bool clear_pool_enabled{false};
  bool verify_ssl_with_header_host{false};

  bool wpad_enabled{true};
  bool pac_enabled{true};

  bool report_fetcher_detail_info{false};
  bool report_native_requestlog{false};
  bool report_socket_buffer_size{false};
  bool report_native_detail_time{false};
  bool report_socket_pool_detail{false};
  int wait_cookie_timeout_mills{0};

  bool redirect_intercept_enabled{false};

#if defined(OS_ANDROID)
  bool dispatch_update_cookie_enable{false};
#endif
#if defined(OS_IOS)
  bool download_write_not_2xx_response_to_memory_enabled{true};
#endif
};

struct WebSocketConfig {
  WebSocketConfig();
  ~WebSocketConfig();

  std::vector<std::string> host_blacklist;
  std::vector<std::string> path_blacklist;
  bool ws_blacklist_reconnect_enabled{false};
  bool tcp_keep_alive{false};
  int tcp_keep_idle{8};
  int tcp_keep_interval{2};
  int tcp_keep_count{2};
  bool enable_connection_attempts{false};
};

struct TTMonitorConfig {
  TTMonitorConfig();
  ~TTMonitorConfig();

  int enable_cronet_request_report{0};
  std::vector<std::string> path_white_list;
};

struct PthreadConfig {
  PthreadConfig();
  ~PthreadConfig();
  bool is_pthread_net_priority_enable{false};
  int pthread_net_priority{0};
};

struct TTBizHttpDnsConfig {
  TTBizHttpDnsConfig();
  TTBizHttpDnsConfig(const TTBizHttpDnsConfig&);
  ~TTBizHttpDnsConfig();
  bool enabled{false};
  std::string auth_id;
  std::string auth_key;
  bool temp_key{false};
  std::string temp_key_timestamp;
};

struct RaceDnsStaleCacheConfig {
  //control the net_types that race dns stale enabled
  enum RaceDnsStaleCacheNetType {
    NET_ALL = 0,
    NET_WIFI = 1 << 0,
    NET_2G = 1 << 1,
    NET_3G = 1 << 2,
    NET_4G = 1 << 3,
    NET_5G = 1 << 4,
    NET_ETHERNET = 1 << 5,
    NET_BLUETOOTH = 1 << 6,
    NET_UNKNOWN = 1 << 7,
    NET_NONE = 1 << 8
  };

  RaceDnsStaleCacheConfig();
  RaceDnsStaleCacheConfig(const RaceDnsStaleCacheConfig&);
  ~RaceDnsStaleCacheConfig();

  std::vector<std::string> wildchar_hosts;
  int stale_interval{60 * 10};
  int backup_delay_ms{0}; //control the race backcup job delay start
  std::vector<std::string> forbid_wildchar_hosts;
  int net_types{0};      //control the net_types that race dns stale enabled
  bool wifi_tag_enabled{false};
  bool wifi_backup_enabled{false};
  std::vector<std::string> quic_radical_wildchar_hosts;
  std::vector<std::string> quic_radical_forbid_wildchar_hosts;
};

struct BackupDnsStaleCacheConfig {
  BackupDnsStaleCacheConfig();
  BackupDnsStaleCacheConfig(const BackupDnsStaleCacheConfig&);
  ~BackupDnsStaleCacheConfig();

  std::vector<std::string> wildchar_hosts;

  int stale_interval{60 * 10};
};

struct PreconnectUrlsConfig {
  PreconnectUrlsConfig();
  ~PreconnectUrlsConfig();
  std::map<std::string, int> preconnect_urls;
};

struct CDNCustomHeaderConfig {
  CDNCustomHeaderConfig();
  ~CDNCustomHeaderConfig();

  std::set<std::string> domain_list;
  std::string value;
};

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_PLUGIN_UPDATE) && \
    (defined(OS_WIN) || defined(OS_MAC))
struct PluginUpdateConfig {
  PluginUpdateConfig();
  ~PluginUpdateConfig();

  bool enabled{true};
  int first_interval{300};
  int interval{3600};
  std::string url;
};
#endif

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_THROTTLE_MONITOR)
struct ThrottleConfig {
  ThrottleConfig();
  ~ThrottleConfig();

  bool force_delay_upload_enabled{false};

  // send/recv bytes will be reset every 200ms.
  bool use_higher_accuracy{true};

  uint32_t minimum_throttle_speed{20 * 1000};

  std::set<std::string> throttle_deny_list;
};
#endif

struct NetConfig {
  NetConfig();
  ~NetConfig();

  std::string tnc_rules;
  int http_properties_persistent_delay{60};

  RouteSelectionConfig rs;
  HostResolverConfig dns;
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NQE_SUPPORT)
  NqeConfig nqe;
#endif
  WebSocketConfig webSocket;
  TTNetQuicConfig quic;
  QuicHostConfigManager quic_host_config_mgr;
  SocketConfig socket;
  SocketPoolConfig socket_pool;
  MiscConfig misc;
  BufferConfig buffer;
  Http2Config http2;
  TTMonitorConfig montior;
  PthreadConfig pthread;

  BackupDnsStaleCacheConfig backup_dns_stale_cache_config;
  RaceDnsStaleCacheConfig race_dns_stale_cache_config;

  RequestLogConfig request_log;
  DnsCrossSpConfig dns_cross_sp;
  PreconnectUrlsConfig preconnect_config;
  SslConfig ssl_config;
  ForceHttp11Config force_http11;
#if defined(OS_ANDROID) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  BaseStationConfig base_station_config;
#endif
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_PROXY_SUPPORT)
  TTProxyConfig proxy;
#endif
  TTBizHttpDnsConfig tt_biz_http_dns_config;
  CDNCustomHeaderConfig cdn_custom_header;
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_PLUGIN_UPDATE) && \
    (defined(OS_WIN) || defined(OS_MAC))
  PluginUpdateConfig plugin_update_config;
#endif
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_THROTTLE_MONITOR)
  ThrottleConfig throttle_config;
#endif
  bool md5_check{true};
};

class ConfigManager : public TTServerConfigObserver {
 public:
  class Observer {
   public:
    virtual void OnNetConfigChanged(const NetConfig* config_ptr) = 0;

   protected:
    virtual ~Observer() {}
  };

  TTNET_IMPLEMENT_EXPORT static ConfigManager* GetInstance();
  ~ConfigManager() override;

  const NetConfig* GetNetConfigPtr() const { return &config_value_; }

  // TTServerConfigObserver overrides:
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_HTTPDNS_TOB)
  void EnableTTBizHttpDns(bool enable,
                          const std::string& httpdns_domain,
                          const std::string& auth_id,
                          const std::string& auth_key,
                          bool temp_key,
                          const std::string& temp_key_timestamp);
#endif
  bool CheckTTBizHttpDnsEnabled() const;

  void AddObserver(Observer* observer);

  void RemoveObserver(Observer* observer);

  void SetHttpServerProperties(HttpServerProperties* http_server_properties,
                               bool force_replace);

  void UnsetHttpServerProperties(HttpServerProperties* http_server_properties);
  bool MatchForceHttp11(const HttpRequestInfo& request) const;

  bool MatchIpv4PreferedHosts(const std::string& host) const;

  int GetConfigSoBufferSize(const std::string& host, bool send) const;

  bool MatchBackupDnsStaleCacheHost(const std::string& host) const;
  bool MatchRaceDnsStaleCacheHost(const std::string& host) const;
  bool MatchRaceDnsStaleCacheNetType(
      const NetworkChangeNotifier::ConnectionType& net_type) const;
  bool MatchRadicalForRaceDnsStaleCacheHost(const std::string& host) const;

  bool CheckEnableAsyncHttpDnsModeForQuicStale() const;
  bool CheckEnableRaceModeForQuicStale() const;

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_THROTTLE_MONITOR)
  bool ForceDelayUploadEnabled() const;
#endif

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_REQUEST_DELAY)
  void SetRequestDelayEnabled(bool enabled) {
    request_delay_enabled.store(enabled);
  }
  bool IsRequestDelayEnabled() const { return request_delay_enabled.load(); }
#endif

 private:
  friend struct base::DefaultSingletonTraits<ConfigManager>;
  friend class ALogWriteAdapter;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class ConfigManagerTest;
#endif

  ConfigManager();

  void NotifyObserversOfConfigChanged();

  void ParseRouteSelectionConfig(const base::DictionaryValue* data,
                                 RouteSelectionConfig* rs_config);
  void ParseBizHttpDnsConfig(const base::DictionaryValue* data,
                             TTBizHttpDnsConfig* dns_config);
  void ParseDnsConfig(const base::DictionaryValue* data,
                      HostResolverConfig* dns_config);
  void ParseAsyncHttpDnsConfig(const base::DictionaryValue* data,
                               HostResolverConfig* dns_config);
  void ParseBackupDnsStaleCacheConfig(const base::DictionaryValue* data,
                                      BackupDnsStaleCacheConfig* dns_config);
  void ParseRaceDnsStaleCacheConfig(const base::DictionaryValue* data,
                                    RaceDnsStaleCacheConfig* dns_config);
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NQE_SUPPORT)
  void ParseNqeConfig(const base::DictionaryValue* data,
                      NqeConfig* cookie_config);
#endif
  void ParseQuicConfig(const base::DictionaryValue* data,
                       TTNetQuicConfig* cookie_config,
                       quic::QuicHostConfig* global_config);
  // ParseQuicHostConfig() should be called after ParseQuicConfig().
  void ParseQuicHostConfig(const base::DictionaryValue* data,
                           QuicHostConfigManager* mgr);
  void ParseSocketConfig(const base::DictionaryValue* data,
                         SocketConfig* config);
  void ParseSocketPoolConfig(const base::DictionaryValue* data,
                             SocketPoolConfig* config);
  void ParseMiscConfig(const base::DictionaryValue* data, MiscConfig* config);
  void ParseBufferConfig(const base::DictionaryValue* data,
                         BufferConfig* config);
  void ParseHttp2Config(const base::DictionaryValue* data, Http2Config* config);
  void ParseMonitorConfig(const base::DictionaryValue* data,
                          TTMonitorConfig* cookie_config);
  void ParsePthreadConfig(const base::DictionaryValue* data,
                          PthreadConfig* config);
  void ParseRequestLogConfig(const base::DictionaryValue* data,
                             RequestLogConfig* config);
  void ParseDnsCrossSpConfig(const base::DictionaryValue* data,
                             DnsCrossSpConfig* config);
  void ParsePreconnectUrls(const base::DictionaryValue* data,
                           PreconnectUrlsConfig* config);
  void ParseWebSocketConfig(const base::DictionaryValue* data,
                            WebSocketConfig* websocket_config);
  void ParseSslConfig(const base::DictionaryValue* data, SslConfig* config);
  void ParseForceHttp11(const base::DictionaryValue* data,
                        ForceHttp11Config* config);
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_PROXY_SUPPORT)
  void ParseTTProxyConfig(const base::DictionaryValue* data,
                          TTProxyConfig* config);
#endif
  void ParseCDNCustomHeaderConfig(const base::DictionaryValue* data,
                                  CDNCustomHeaderConfig* config);
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_PLUGIN_UPDATE) && \
    (defined(OS_WIN) || defined(OS_MAC))
  void ParsePluginUpdateConfig(const base::DictionaryValue* data,
                               PluginUpdateConfig* config);
#endif

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_THROTTLE_MONITOR)
  void ParseThrottleConfig(const base::DictionaryValue* data,
                           ThrottleConfig* config);
#endif

  NetConfig config_value_;

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_REQUEST_DELAY)
  std::atomic<bool> request_delay_enabled{false};
#endif

  const scoped_refptr<base::ObserverListThreadSafe<Observer>>
      net_config_observer_list_;

  HttpServerProperties* http_server_properties_;

  static std::atomic<bool> alog_write_enabled_;

  DISALLOW_COPY_AND_ASSIGN(ConfigManager);
};

}  // namespace net

#endif  // NET_TTNET_CONFIG_TT_CONFIG_MANAGER_H_
