// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_TT_DEVICE_BASIC_INFO_MANAGER_IOS_H_
#define NET_TT_NET_NET_DETECT_GSDK_TT_DEVICE_BASIC_INFO_MANAGER_IOS_H_

#include "base/memory/singleton.h"
#include "base/sequence_checker.h"
#include "ios/net/tt_net/multinetwork/tt_network_monitor_observer.h"
#include "net/tt_net/net_detect/base/tt_device_basic_info_manager.h"

namespace net {
namespace ios {
class TTDeviceBasicInfoManagerIOS : public TTDeviceBasicInfoManager,
                                    public TTNetworkMonitorObserver {
 public:
  static TTDeviceBasicInfoManager* GetInstance();

  void InitCommon() override;

  bool CheckIsVpnOn() const override;

  std::string GetNetworkOperator() const override;

  bool CheckIsProxyConfigured() const override;

  std::string GetDeviceModel() const override;

  std::string GetPlatform() const override;

  std::string GetGateway() const override;

  void GetDnsNameServers(std::vector<IPEndPoint>& dns_servers) override;

  void GetAllSubnetIp(std::vector<std::string>& ips) override;

  base::Optional<Stats> GetStats() const override;

 private:
  friend struct base::DefaultSingletonTraits<TTDeviceBasicInfoManagerIOS>;

  TTDeviceBasicInfoManagerIOS();

  ~TTDeviceBasicInfoManagerIOS() override;

  // TTNetworkMonitorObserver implementation:
  void OnGatewayUpdated(const std::string& gateway) override;

  mutable std::string device_model_;

  std::string gateway_address_;

  SEQUENCE_CHECKER(network_sequence_checker_);

  DISALLOW_COPY_AND_ASSIGN(TTDeviceBasicInfoManagerIOS);
};
}  // namespace ios
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_TT_DEVICE_BASIC_INFO_MANAGER_IOS_H_