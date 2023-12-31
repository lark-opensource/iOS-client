// Copyright (c) 2018 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_DNS_TT_DNS_SERVICE_PROVIDER_OBSERVER_H_
#define NET_TT_NET_DNS_TT_DNS_SERVICE_PROVIDER_OBSERVER_H_

#include "base/macros.h"
#include "base/time/time.h"
#include "net/dns/host_cache.h"

namespace net {

class DnsServiceProviderObserver {
 public:
  virtual void OnNewEntryAdded(const HostCache::Key& key,
                               const HostCache::Entry& entry) = 0;
};

}  // namespace net

#endif  // NET_TT_NET_DNS_TT_DNS_SERVICE_PROVIDER_OBSERVER_H_
