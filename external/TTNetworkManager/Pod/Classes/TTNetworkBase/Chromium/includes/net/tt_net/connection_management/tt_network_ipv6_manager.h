// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_CONNECTION_MANAGEMENT_NETWORK_IPV6_MANAGER_H_
#define NET_TTNET_CONNECTION_MANAGEMENT_NETWORK_IPV6_MANAGER_H_

#include "base/memory/singleton.h"
#include "base/power_monitor/power_observer.h"
#include "base/timer/timer.h"
#include "base/values.h"
#include "net/base/network_change_notifier.h"
#include "net/base/network_interfaces.h"
#include "net/net_buildflags.h"

#if BUILDFLAG(ENABLE_NQE_AND_WIFI_TO_CELL_ON_MOBILE)
#include "net/tt_net/multinetwork/wifi_to_cell/tt_multinetwork_manager.h"
#endif

namespace net {

class TTNET_IMPLEMENT_EXPORT IPv6Manager final
    : public NetworkChangeNotifier::NetworkChangeObserver,
#if BUILDFLAG(ENABLE_NQE_AND_WIFI_TO_CELL_ON_MOBILE)
      public TTMultiNetworkManager::StateChangeObserver,
#endif
      public base::PowerObserver {
 public:
  static IPv6Manager* GetInstance();
  ~IPv6Manager() override;

  std::unique_ptr<base::Value> GetDeviceNetworkInterfaceAsValue();

  void GetNetworkInterfacesOnIOThread();

  bool is_ipv6_globally_reachable() const {
    return is_ipv6_globally_reachable_;
  }
  bool is_ipv4_globally_reachable() const {
    return is_ipv4_globally_reachable_;
  }

  static bool IsIPv6LinkLocalAddress(const IPAddress& address);

#if defined(OS_IOS)
  bool enable_sc_ipv6_detect() const { return enable_sc_ipv6_detect_; }
  void set_enable_sc_ipv6_detect(bool enable) {
    enable_sc_ipv6_detect_ = enable;
  }
#endif

  std::vector<IPAddress> GetDeviceClientAddress() const;

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class IPv6ManagerTest;
  IPAddress ipv6_address_for_testing_;
  IPAddress ipv4_address_for_testing_;
#endif
  friend struct base::DefaultSingletonTraits<IPv6Manager>;
  IPv6Manager();

  void OnNetworkChanged(NetworkChangeNotifier::ConnectionType type) override;

#if BUILDFLAG(ENABLE_NQE_AND_WIFI_TO_CELL_ON_MOBILE)
  void OnMultiNetworkStateChanged(
      TTMultiNetworkManager::State previous_state,
      TTMultiNetworkManager::State current_state) override;
#endif
  // base::PowerObserver override.
  void OnSuspend() override;
  void OnResume() override;
  void OnPowerStateChange(bool on_battery_power) override;

  bool IsGloballyReachable(const IPAddress& dest, IPAddress* local);

  // net::NetworkInterfaceList interface_list_;
  std::atomic<bool> is_ipv6_globally_reachable_{false};
  std::atomic<bool> is_ipv4_globally_reachable_{false};
  base::RepeatingTimer ipv6_period_detect_timer_;

  NetworkInterfaceList interface_list_;
  base::Optional<IPAddress> ipv4_client_addr_;
  base::Optional<IPAddress> ipv6_client_addr_;

#if defined(OS_IOS)
  // use SCNetwork to detect ipv6
  bool enable_sc_ipv6_detect_{false};
#endif

  DISALLOW_COPY_AND_ASSIGN(IPv6Manager);
};

}  // namespace net

#endif  // NET_TTNET_CONNECTION_MANAGEMENT_NETWORK_IPV6_MANAGER_H_
