// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_UTIL_TT_NETWORK_UTIL_IOS_H_
#define NET_TT_NET_UTIL_TT_NETWORK_UTIL_IOS_H_

#include <stdint.h>
#include <string>

#include "net/base/ip_address.h"
#include "net/base/network_change_notifier.h"

namespace net {
namespace ios {

bool IsCellularNetworkInterface(const NetworkInterface& interface);

bool IsWifiNetworkInterface(const NetworkInterface& interface);

bool GetInterfaceIndex(uint32_t& cellular_if_index, uint32_t& wifi_if_index);

bool CheckIsVpnOn();

int IsScIpv6Reachable(const IPAddress& dest, int port);

// Returns MCC as the numeric name of the current mobile data operator,
// if |mainCardCarrierIfUnclear| is true, return main card carrier mcc
// while dual card in iOS12.x, else return empty string
std::string GetMobileCountryCode(bool mainCardCarrierIfUnclear = false);

// Returns MNC as the numeric name of the current mobile data operator,
// if |mainCardCarrierIfUnclear| is true, return main card carrier mnc
// while dual card in iOS12.x, else return empty string
std::string GetMobileNetworkCode(bool mainCardCarrierIfUnclear = false);

}  // namespace ios
}  // namespace net

#endif  // NET_TT_NET_UTIL_TT_NETWORK_UTIL_IOS_H_
