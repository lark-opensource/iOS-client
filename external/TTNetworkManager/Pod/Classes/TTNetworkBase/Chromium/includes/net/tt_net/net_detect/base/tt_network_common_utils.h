// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_BASE_TT_NETWORK_COMMON_UTILS_H_
#define NET_TT_NET_NET_DETECT_BASE_TT_NETWORK_COMMON_UTILS_H_

#include "net/base/network_change_notifier.h"

namespace net {

// Check weather the network has internet.
bool HasInternetCapability(NetworkChangeNotifier::ConnectionType type);

// Check weather the network has changed in the more permissive strategy.
bool IsPermissiveNetworkChanged(
    NetworkChangeNotifier::ConnectionType first_type,
    NetworkChangeNotifier::ConnectionType second_type);

}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_BASE_TT_NETWORK_COMMON_UTILS_H_
