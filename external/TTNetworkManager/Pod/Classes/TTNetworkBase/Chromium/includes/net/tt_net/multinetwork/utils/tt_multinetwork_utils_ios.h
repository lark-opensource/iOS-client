// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_MULTINETWORK_UTILS_TT_MULTINETWORK_UTILS_IOS_H_
#define NET_TT_NET_MULTINETWORK_UTILS_TT_MULTINETWORK_UTILS_IOS_H_

#include "base/memory/singleton.h"
#include "base/memory/weak_ptr.h"
#include "base/timer/timer.h"
#include "ios/net/tt_net/multinetwork/tt_network_monitor_observer.h"
#include "net/base/network_change_notifier.h"
#include "net/base/network_interfaces.h"
#include "net/tt_net/multinetwork/utils/tt_multinetwork_utils.h"

namespace net {

class TTMultiNetworkUtilsIOS
    : public TTMultiNetworkUtils,
      public NetworkChangeNotifier::NetworkChangeObserver,
      public TTNetworkMonitorObserver {
 public:
  static TTMultiNetworkUtilsIOS* GetInstance();

  bool PrepareEnvironment() override;

  bool TryAlwaysUpCellular(ActivatingCellCallback callback) override;

  void OnCellularAlwaysUp(bool success) override;

  bool IsWiFiAvailable() const override;

  bool IsCellularAvailable() const override;

  bool IsVpnOn() const override;

  NetworkChangeNotifier::ConnectionType GetConnectionTypeOfCellular()
      const override;

 private:
  friend struct base::DefaultSingletonTraits<TTMultiNetworkUtilsIOS>;
  TTMultiNetworkUtilsIOS();
  ~TTMultiNetworkUtilsIOS() override;

  // TTMultiNetworkUtils implementation:
  bool GetAddrInfoInternal(const char* node,
                           const char* service,
                           const struct addrinfo* hints,
                           struct addrinfo** res,
                           int* net_error,
                           int* os_error,
                           HostResolverFlags flags) const override;
  void FreeAddrInfoInternal(struct addrinfo* res) override;
  bool TryBindToMultiNetworkInternal(int socket_fd,
                                     int* net_error,
                                     MultiNetAction action) const override;

  // TTNetworkMonitorObserver implementation:
  void OnNetworkUpdated(
      uint32_t wifi_if_index,
      uint32_t cell_if_index,
      NetworkChangeNotifier::ConnectionType defaultConnectionType) override;

  void OnNetworkChanged(NetworkChangeNotifier::ConnectionType type) override;
  bool TryUpdateNetworkList() override;

  // Keep notification behaviour identical to Android's.
  void NotifyMultiNetworkManagerOfCellularUp();
  void TryUpdateNetworkListAndNotifyCellularUpIfNeeded();

  // Check Cellular availability if WiFi is on, because there is no notification
  // from NetworkChangeNotifier for iOS when turn on and off Cellular within
  // WiFi on.
  // TODO(zhangzeming)
  // Use nw_monitor_t for iOS 12.0 and later.
  void TryStartCellAvailableChecking();
  void OnCellAvailableCheckTimeout();

  // Cellular interface index.
  uint32_t cellular_if_index_;
  // WiFi interface index.
  uint32_t wifi_if_index_;
  bool is_vpn_on_;

  // Available on iOS 12.0 and later.
  uint32_t notified_cellular_if_index_;
  uint32_t notified_wifi_if_index_;

  base::OneShotTimer cell_available_check_timer_;

  base::WeakPtrFactory<TTMultiNetworkUtilsIOS> weak_factory_;
};

}  // namespace net
#endif