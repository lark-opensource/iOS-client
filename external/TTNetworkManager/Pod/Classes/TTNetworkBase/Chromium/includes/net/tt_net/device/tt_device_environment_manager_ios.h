// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_DEVICE_TT_DEVICE_ENVIRONMENT_MANAGER_IOS_H_
#define NET_TT_NET_DEVICE_TT_DEVICE_ENVIRONMENT_MANAGER_IOS_H_

#include "base/memory/singleton.h"
#include "ios/net/tt_net/multinetwork/tt_network_monitor_observer.h"
#include "net/base/network_change_notifier.h"
#include "net/tt_net/device/tt_device_environment_manager.h"

namespace net {

class TTDeviceEnvironmentManagerIOS
    : public TTDeviceEnvironmentManager,
      public TTNetworkMonitorObserver,
      public NetworkChangeNotifier::ConnectionTypeObserver {
 public:
  static TTDeviceEnvironmentManager* GetInstance();

  bool Init() override;

 private:
  friend struct base::DefaultSingletonTraits<TTDeviceEnvironmentManagerIOS>;
  TTDeviceEnvironmentManagerIOS();
  ~TTDeviceEnvironmentManagerIOS() override;

  // NetworkChangeNotifier::ConnectionTypeObserver implementation:
  void OnConnectionTypeChanged(
      NetworkChangeNotifier::ConnectionType type) override;

  // TTNetworkMonitorObserver implementation:
  void OnGatewayUpdated(const std::string& gateway) override;

  void ObtainGatewayIP() override;
  void ObtainNameServersInfo() override;

  DISALLOW_COPY_AND_ASSIGN(TTDeviceEnvironmentManagerIOS);
};

}  // namespace net

#endif  // NET_TT_NET_DEVICE_TT_DEVICE_ENVIRONMENT_MANAGER_IOS_H_
