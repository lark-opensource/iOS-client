//
//  Created by songlu on 4/17/17.
//  Copyright © 2017 ttnet. All rights reserved.
//

#ifndef NET_TTNET_ROUTE_SELECTION_TT_APP_INFO_H_
#define NET_TTNET_ROUTE_SELECTION_TT_APP_INFO_H_

#include <atomic>
#include <vector>

#include "base/memory/singleton.h"
#include "base/time/time.h"
#include "net/base/ip_address.h"
#include "net/base/network_change_notifier.h"
#include "net/net_buildflags.h"
#include "net/tt_net/route_selection/tt_default_server_config.h"

namespace net {

struct TTAppInfoNode {
  // get_domains query
  std::string sdk_app_id;
  std::string sdk_version;
  std::string userId;
  std::string appId;
  std::string deviceId;
  std::string netAccessType;
  std::string versionCode;
  std::string deviceType;
  std::string appName;
  std::string channel;
  std::string osVersion;
  std::string devicePlatform;
  std::string update_version_code;
  std::string device_model;

#if defined(OS_ANDROID)
  std::string device_brand;
  std::string osApi;
  std::string version_name;
  std::string manifest_version_code;
  std::string abi;

  std::string process_name;
#endif

  std::string host_first;
  std::string host_second;
  std::string host_third;

  std::string domain_httpdns;
  std::string domain_netlog;
  std::string domain_boe;
  std::string domain_boe_https;

  std::string is_main_process;
  std::string is_drop_first_tnc;

  std::string store_idc;

  std::string region;
  std::string sys_region;
  std::string carrier_region;
  std::string init_region;

  std::map<std::string, std::string> headers;
  std::map<std::string, std::string> queries;

  int tnc_load_flags{0};
  int httpdns_load_flags{0};

  bool is_domestic{false};

  TTAppInfoNode();
  TTAppInfoNode(const TTAppInfoNode& other);
  ~TTAppInfoNode();
};

class TTAppInfoProvider {
 public:
  virtual bool GetAppInfo(TTAppInfoNode* app_info_node) = 0;
  virtual void OnClientIPChanged(const std::string& client_ip) = 0;
  virtual void OnPublicIPsChanged(
      const std::vector<std::string>& ipv4_list,
      const std::vector<std::string>& ipv6_list) = 0;
  virtual void OnStoreIdcChanged(const std::string& store_idc,
                                 const std::string& store_region,
                                 const std::string& store_region_src,
                                 const std::string& sec_uid,
                                 const std::string& logid) = 0;

 protected:
  virtual ~TTAppInfoProvider() {}
};

class PrioritizedIPAddress : public IPAddress {
 public:
  enum Priority {
    UNDEFINED = 0,
    CELL_CONNECTION_PRIORITY = 1,
    WIFI_CONNECTION_PRIORITY = 2,
    DEFAULT_CONNECTION_PRIORITY = 3,
    MAXIMUM_PRIORITY = 4
  };
  explicit PrioritizedIPAddress(const Priority priority);
  PrioritizedIPAddress(const IPAddress& other, const Priority priority);

  static Priority MapInterfaceNameToPriority(const NetworkInterface& interface);
  void SetPriority(const Priority priority) { priority_ = priority; }
  Priority GetPriority() const { return priority_; }

 private:
  Priority priority_{UNDEFINED};
};

class TTAppInfoManager : public NetworkChangeNotifier::NetworkChangeObserver {
 public:
  enum TTNetAppInfoUpdateReason {
    TTNET_GET_DOMAIN_UPDATE = 0,  // get-domain update
    TTNET_TIME_REFRESH,           // time update
    TTNET_INITIALIZATION          // ttnet boot up
  };

  TTNET_IMPLEMENT_EXPORT static TTAppInfoManager* GetInstance();

  ~TTAppInfoManager() override;

  bool Init();

  bool UpdateAppInfoValue(TTNetAppInfoUpdateReason reason);

  bool IsMainProcess() { return app_info_node_.is_main_process == "1"; }

#if defined(OS_ANDROID)
  const std::string GetProcessName() const {
    return app_info_node_.process_name;
  }
#endif

  bool IsDropFirstTnc() const {
    return app_info_node_.is_drop_first_tnc == "1";
  }

  const TTAppInfoNode& GetAppInfoNode() const;

  TTNET_IMPLEMENT_EXPORT void RegisterAppInfoProvider(
      TTAppInfoProvider* app_info_provider);

  void UnRegisterAppInfoProvider();

  const std::string GetCommonParameters() const;

  void SetClientIP(const std::string& client_ip);
  const std::string GetClientIP() const { return client_ip_string_; }

  void SetPublicIP(const PrioritizedIPAddress& ip_address);

  void NotifyPublicIPsChanged();

  void StoreIdcChanged(const std::string& store_idc,
                       const std::string& store_region,
                       const std::string& store_region_src,
                       const std::string& sec_uid,
                       const std::string& logid) const;

  void SetAppWillTerminate(bool enabled) { app_will_terminate_ = enabled; }
  bool AppWillTerminate() const { return app_will_terminate_; }
  std::string GetLocalRegion() const;
#if defined(OS_ANDROID) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  void SetCookieInitCompleted();
  bool IsCookieInitDone() const { return cookie_init_done_; }
#endif

 private:
  friend struct base::DefaultSingletonTraits<TTAppInfoManager>;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  FRIEND_TEST_ALL_PREFIXES(TTAppInfoManager, GetAppInfoFailAndRetry);
  FRIEND_TEST_ALL_PREFIXES(TTAppInfoManager, EmptyDeviceId);
  FRIEND_TEST_ALL_PREFIXES(TTAppInfoManager, SetClientIP);
  FRIEND_TEST_ALL_PREFIXES(TTAppInfoManager, SetPublicIPs);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, StartFirstUpdateNotMainProcess);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, DoNotStartFirstUpdate);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, StartFirstUpdateEmptyDeviceId);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, StartFirstUpdateValidDeviceId);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, ParseRemoteJsonResultError);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, HandleRequestResult);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest,
                           BuildGetDomainsUrlArrayWithRemoteOnlyHosts);
  FRIEND_TEST_ALL_PREFIXES(HttpDnsHostResolverTest, MockAsyncTaskProblem);
  FRIEND_TEST_ALL_PREFIXES(HttpDnsHostResolverTest, TTHttpDNSResolve);
  FRIEND_TEST_ALL_PREFIXES(HttpDnsHostResolverTest, PreloadBatchHttpdns);
  FRIEND_TEST_ALL_PREFIXES(HttpDnsHostResolverTest,
                           PreloadBatchHttpdnsInvalidateCache);
  FRIEND_TEST_ALL_PREFIXES(HttpDnsHostResolverTest, WaitPreloadBatchHttpdnsOk);
  FRIEND_TEST_ALL_PREFIXES(HttpDnsHostResolverTest, ShouldSkipDnsDispatchQueue);
  FRIEND_TEST_ALL_PREFIXES(HttpDnsHostResolverTest,
                           PreloadBatchHttpdnsErrResponse);
  FRIEND_TEST_ALL_PREFIXES(HttpDnsHostResolverTest, SpecifyNetwork);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityDetectorTest, NotOnMainProcess);
  FRIEND_TEST_ALL_PREFIXES(TTWebsocketInnerMessageHandlerTest,
                           HandleMessageRefreshTnc);
  FRIEND_TEST_ALL_PREFIXES(TTWebsocketInnerMessageHandlerTest,
                           HandleMessageUploadNetlog);
  FRIEND_TEST_ALL_PREFIXES(TTWebsocketInnerMessageHandlerTest,
                           HandleMessageCloudDetect);
  FRIEND_TEST_ALL_PREFIXES(TTWebsocketInnerMessageHandlerTest,
                           HandleMessageCloudDetectErrDataFormat);
  FRIEND_TEST_ALL_PREFIXES(ConfigManagerTest, OnServerConfigChanged);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest, DoPreconnect);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest, DoPreconnectEmptyURL);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest, DoPreconnectNotMainProcess);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest, DoPreconnectContextNull);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest,
                           DoPreconnectTransactionFacNull);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest, OnSuspend);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest, OnSuspendSessionCheckUnabled);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest, OnResume);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest, OnResumeSessionCheckUnabled);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest, OnIPAddressChanged);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest,
                           OnIPAddressChangedSessionCheckUnabled);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest, AlternativeNetworkPreconnect);
  FRIEND_TEST_ALL_PREFIXES(TTFileSslSessionCacheManagerTest,
                           OnServerConfigChanged);
  FRIEND_TEST_ALL_PREFIXES(RequestTagManagerTest, AddRequestTagTest);
  FRIEND_TEST_ALL_PREFIXES(RequestTagManagerTest, DispachRequestTagDropTest);
  FRIEND_TEST_ALL_PREFIXES(StoreIdcManagerTest, UpdateAndAddStoreRegionTest);
  FRIEND_TEST_ALL_PREFIXES(StoreIdcManagerTest, UpdateStoreRegionFromTNCTest);
  FRIEND_TEST_ALL_PREFIXES(TTProxySettingTest, SetBoeProxyEnabled);
  FRIEND_TEST_ALL_PREFIXES(TTProxySettingTest,
                           ReplaceHostAndURLWithBoeSuffixTest);
  FRIEND_TEST_ALL_PREFIXES(TTProxySettingTest,
                           ReplaceHostAndURLWithoutBoeHttpSuffixTest);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkDelegateTest,
                           OnBeforeURLRequestNewDispatch);
  FRIEND_TEST_ALL_PREFIXES(TTZstdManagerTest, Init);
  FRIEND_TEST_ALL_PREFIXES(TTServerConfigTest, UpdateFirstTncConfigTest);
  FRIEND_TEST_ALL_PREFIXES(TTHttpDNSTransactionTest, TestTransactionStart);
  FRIEND_TEST_ALL_PREFIXES(StoreIdcManagerTest, UpdateStoreRegionFromBizTest);
  FRIEND_TEST_ALL_PREFIXES(StoreIdcManagerTest,
                           ExtractStoreRegionFromCookieHeadersTest);

  friend class ConnectionManagerTest;
  friend class HostResolverManagerTest;
  friend class NetLogManagerTest;
  friend class NetLogManagerTestByMockTime;
  friend class NetLogManagerTestFunction;
  friend class TTNetworkQualityDetectorTest;
  friend class TTNetworkDelegateTest;
  friend class TTWebsocketInnerMessageHandlerTest;
  friend class TTServerConfigTest;
  friend class TTMultiNetworkManagerMainTest;
  friend class TTMultiNetworkManagerSubTest;
  friend class TTPluginManagerTest;
  friend class TTZstdManagerTest;
  friend class IPv6ManagerTest;

 public:
  void SetAppInfoNodeForTesting(const TTAppInfoNode& node) {
    app_info_node_ = node;
  }

 private:
#endif

  TTAppInfoManager();

  // NetworkChangeNotifier::NetworkChangeObserver
  void OnNetworkChanged(NetworkChangeNotifier::ConnectionType type) override;

  void CheckDeviceId();

  TTAppInfoNode app_info_node_;

  bool initialized_{false};

  bool data_valid_{false};

  bool is_public_ips_changed_{false};

  TTAppInfoProvider* app_info_provider_{nullptr};

  size_t first_app_info_retry_times_{0};

  // Save the client ip of real public address.
  std::string client_ip_string_;

  std::vector<PrioritizedIPAddress> public_ips_;

  std::atomic_bool app_will_terminate_{false};

#if defined(OS_ANDROID) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  // Flag indicates that whether cookie manager has been inited complete.
  bool cookie_init_done_{false};
#endif

  THREAD_CHECKER(init_thread_checker_);
  THREAD_CHECKER(network_thread_checker_);
  DISALLOW_COPY_AND_ASSIGN(TTAppInfoManager);
};

}  // namespace net

#endif  // NET_TTNET_ROUTE_SELECTION_TT_APP_INFO_H_
