// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_UTIL_TT_NETWORK_ROUTER_H_
#define NET_TT_NET_UTIL_TT_NETWORK_ROUTER_H_

#include <string>
#include <vector>

#include "base/optional.h"

namespace net {

// Represents a route entry.
struct RouteEntry {
  RouteEntry();
  ~RouteEntry();
  RouteEntry(const RouteEntry& other);
  std::string GetDestinationWithPrefix() const;

  int prefix_length{-1};    // The length of netmask prefix
  std::string destination;  // The IP address of destination
  std::string gateway;      // The IP address or link address of gateway
  std::string if_name;      // The name of network interface
  // the interface global unique identifier, null on non-Windows.
  base::Optional<std::string> if_guid;
};

typedef std::vector<std::unique_ptr<RouteEntry>> RouteEntryList;

// Returns list of routing entries.
// Can be called only on a thread that allows IO.
bool GetRouteEntryList(RouteEntryList* entry_list);

}  // namespace net

#endif  // NET_TT_NET_UTIL_TT_NETWORK_ROUTER_H_
