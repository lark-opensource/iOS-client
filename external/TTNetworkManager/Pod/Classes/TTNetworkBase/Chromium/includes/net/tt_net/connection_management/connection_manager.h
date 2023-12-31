// Copyright (c) 2018 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_CONNECTION_MANAGEMENT_CONNECTION_MANAGER_H_
#define NET_TTNET_CONNECTION_MANAGEMENT_CONNECTION_MANAGER_H_

#include <map>
#include <string>

#include "base/memory/singleton.h"
#include "base/power_monitor/power_observer.h"
#include "net/base/network_change_notifier.h"
#include "net/tt_net/config/tt_config_manager.h"
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
#include "net/tt_net/multinetwork/utils/tt_multinetwork_state_watcher.h"
#endif

namespace net {

class URLRequestContext;
class HttpStreamFactory;

class ConnectionManager
    : public ConfigManager::Observer,
      public NetworkChangeNotifier::IPAddressObserver,
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
      public TTMultiNetworkStateWatcher::MultiNetStateObserver,
#endif
      public base::PowerObserver {
 public:
  static ConnectionManager* GetInstance();
  ~ConnectionManager() override;

  // Preconnect urls when cronet engine starts coldly.
  void DoPreconnect();

  // Preconnect urls at fixed streams number.
  void PreconnectUrls(const std::map<std::string, int>& preconnect_urls);

  void SetURLRequestContext(URLRequestContext* context);

  // ConfigManager::Observer methods:
  // We update the http2 config when net config changed.
  void OnNetConfigChanged(const NetConfig* config_ptr) override;

  // NetworkChangeNotifier::IPAddressObserver methods:
  // We preconnect the ssl client socket due to the IP address change.
  void OnIPAddressChanged() override;

  // base::PowerObserver methods:
  void OnPowerStateChange(bool on_battery_power) override {}
  void OnSuspend() override;
  void OnResume() override;

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class ConnectionManagerTest;
#endif

  friend struct base::DefaultSingletonTraits<ConnectionManager>;

  ConnectionManager();

#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  // TTMultiNetworkStateWatcher::MultiNetStateObserver implementation:
  void OnMultiNetStateChanged(
      TTMultiNetworkStateWatcher::State previous_state,
      TTMultiNetworkStateWatcher::State current_state) override;

  void PreconnectByAlternativeNetwork(HttpStreamFactory* stream_factory,
                                      int num_streams,
                                      const HttpRequestInfo& request) const;
  using PreconnectCallback = base::OnceCallback<void()>;
  std::vector<PreconnectCallback> alt_net_preconnect_delay_tasks_;
#endif

  // Preconnect urls in |preconnect_h2session_urls_| at fix
  // |h2_session_check_interval_|.
  void PreconnectSSLClientSocketForH2Session(int network_changes);

  URLRequestContext* context_;

  std::map<std::string, int> preconnect_h2session_urls_;

  // Initial the timer to check and rebuild ssl client socket
  // in |ping_keepalive_hosts|.
  base::RepeatingTimer preconnect_url_repeating_timer_;

  bool h2_session_check_enabled_;

  base::TimeDelta h2_session_check_interval_;

  int network_changes_{0};

  DISALLOW_COPY_AND_ASSIGN(ConnectionManager);
};

}  // namespace net

#endif  // NET_TTNET_CONNECTION_MANAGERMENT_CONNECTION_MANAGER_H_
