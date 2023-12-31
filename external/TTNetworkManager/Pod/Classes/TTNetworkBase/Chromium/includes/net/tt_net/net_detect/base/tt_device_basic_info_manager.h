// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_TT_DEVICE_BASIC_INFO_MANAGER_H_
#define NET_TT_NET_NET_DETECT_GSDK_TT_DEVICE_BASIC_INFO_MANAGER_H_

#include "base/memory/singleton.h"
#include "base/optional.h"
#include "base/values.h"
#include "net/base/network_change_notifier.h"
#include "net/base/network_interfaces.h"
#include "net/dns/system_dns_config_change_notifier.h"
#include "net/net_buildflags.h"
#include "net/tt_net/util/tt_network_router.h"

#if defined(OS_WIN)
#include <winsock2.h>
#else
#include <arpa/inet.h>
#endif

namespace net {

namespace {
const uint32_t kNetmask = inet_addr("255.255.255.0");
}

// Provide basic device information when network experience uploads report.
class TTDeviceBasicInfoManager {
 public:
  struct Stats {
    // uint64_t presents at most 17179869184 GB.
    uint64_t total_rx_bytes{0};
    uint64_t total_tx_bytes{0};
  };

  TTDeviceBasicInfoManager();

  virtual ~TTDeviceBasicInfoManager();

  static TTDeviceBasicInfoManager* GetInstance();

  virtual void InitCommon();

  virtual void InitDeviceScorer();

  virtual bool CheckIsVpnOn() const;

  virtual std::string GetNetworkOperator() const;

  virtual bool CheckIsProxyConfigured() const;

  /* Returns the signal strength of WiFi or cellular, The default value is -1.*/
  virtual int32_t GetSignalLevel(
      NetworkChangeNotifier::ConnectionType type) const;

  /* Returns the channel of the current access point. The default value is -1 */
  virtual int GetCurrentAccessPointChannel() const;

  /* Returns the channel list of all access points. */
  virtual std::vector<int> GetAllAccessPointChannels() const;

  virtual const char* GetNetworkStatus() const;

  virtual std::string GetDeviceModel() const;

  virtual std::string GetCPUModel() const;

  virtual std::string GetCPUCores() const;

  virtual std::string GetGPUModel() const;

  virtual std::string GetTotalMemory() const;

  virtual std::string GetTemperature() const;

  virtual std::string GetPlatform() const;

  virtual std::string GetGateway() const;

  virtual void GetDnsNameServers(std::vector<IPEndPoint>& dns_servers);

  virtual void GetAllSubnetIp(std::vector<std::string>& ips);

  virtual base::Optional<Stats> GetStats() const;

  virtual NetworkInterfaceList GetNetworkInterfaces() const;

  virtual RouteEntryList GetRoutes() const;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  static void set_mock_manager(TTDeviceBasicInfoManager* mock_manager);
#endif

 protected:
  friend struct base::DefaultSingletonTraits<TTDeviceBasicInfoManager>;
  bool is_common_initialized_{false};
  bool is_device_scorer_initialized_{false};

  DISALLOW_COPY_AND_ASSIGN(TTDeviceBasicInfoManager);
};

}  // namespace net

#endif