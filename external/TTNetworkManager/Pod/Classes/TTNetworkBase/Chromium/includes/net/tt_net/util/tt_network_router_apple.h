// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_UTIL_TT_NETWORK_ROUTER_APPLE_H_
#define NET_TT_NET_UTIL_TT_NETWORK_ROUTER_APPLE_H_

#include "net/tt_net/util/tt_network_router.h"

#include <net/if.h>
#include <string>

namespace net {
namespace internal {

/**
 * Convert socket address to string.
 */
std::string GetSockAddrString(const sockaddr* sa);

}  // namespace internal
}  // namespace net

#endif  // NET_TT_NET_UTIL_TT_NETWORK_ROUTER_APPLE_H_
