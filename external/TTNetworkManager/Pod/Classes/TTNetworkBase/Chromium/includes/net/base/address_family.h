// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_BASE_ADDRESS_FAMILY_H_
#define NET_BASE_ADDRESS_FAMILY_H_

#include "base/ttnet_implement_buildflags.h"
#include "net/base/net_export.h"
#if BUILDFLAG(TTNET_IMPLEMENT)
#include "net/net_buildflags.h"
#endif

namespace net {

class IPAddress;

// Enum wrapper around the address family types supported by host resolver
// procedures.
enum AddressFamily {
  ADDRESS_FAMILY_UNSPECIFIED,   // AF_UNSPEC
  ADDRESS_FAMILY_IPV4,          // AF_INET
  ADDRESS_FAMILY_IPV6,          // AF_INET6
  ADDRESS_FAMILY_LAST = ADDRESS_FAMILY_IPV6
};

// HostResolverFlags is a bitflag enum used by host resolver procedures to
// determine the value of addrinfo.ai_flags and work around getaddrinfo
// peculiarities.
enum {
  HOST_RESOLVER_CANONNAME = 1 << 0,  // AI_CANONNAME
  // Hint to the resolver proc that only loopback addresses are configured.
  HOST_RESOLVER_LOOPBACK_ONLY = 1 << 1,
  // Indicate the address family was set because no IPv6 support was detected.
  HOST_RESOLVER_DEFAULT_FAMILY_SET_DUE_TO_NO_IPV6 = 1 << 2,
// The resolver should only invoke getaddrinfo, not DnsClient.
#if BUILDFLAG(TTNET_IMPLEMENT)
  HOST_RESOLVER_SYSTEM_ONLY = 1 << 3,
  // The prefer address family is used when request has not specified.
  HOST_RESOLVER_PREFER_ADDRESS_FAMILY_USED = 1 << 4,
  // The resolve request will use local DNS only rather than HTTP DNS.
  HOST_RESOLVER_LOCAL_DNS_ONLY = 1 << 5,
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  // Make the local DNS resolving always go through default network, not bind
  // to WiFi nor Cellular's net id.
  // Priority: default > force Cellular > force WiFi.
  HOST_RESOLVER_FORCE_USING_DEFAULT_NETWORK = 1 << 6,

  // Always try to use Cellular even if its net id is unavailable.
  HOST_RESOLVER_FORCE_USING_CELLULAR = 1 << 7,

  // Always try to use WiFi even if its net id is unavailable.
  HOST_RESOLVER_FORCE_USING_WIFI = 1 << 8,
  HOST_RESOLVER_FORCE_USING_CELLULAR_WHILE_DEFAULT_NETWORK_IS_NOT_CELLULAR =
      1 << 9,
#endif
  HOST_RESOLVER_ENUM_END = 1 << 31
#else
  HOST_RESOLVER_SYSTEM_ONLY = 1 << 3
#endif
};
typedef int HostResolverFlags;

// Returns AddressFamily for |address|.
NET_EXPORT AddressFamily GetAddressFamily(const IPAddress& address);

// Maps the given AddressFamily to either AF_INET, AF_INET6 or AF_UNSPEC.
NET_EXPORT int ConvertAddressFamily(AddressFamily address_family);

}  // namespace net

#endif  // NET_BASE_ADDRESS_FAMILY_H_
