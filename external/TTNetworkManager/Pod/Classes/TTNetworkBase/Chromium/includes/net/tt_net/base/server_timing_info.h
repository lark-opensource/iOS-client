// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_BASE_SERVER_TIMING_INFO_H
#define NET_TT_NET_BASE_SERVER_TIMING_INFO_H

#include <stdint.h>

#include "net/base/net_export.h"

namespace net {

struct NET_EXPORT_PRIVATE ServerTimingInfo {
  ServerTimingInfo();
  ~ServerTimingInfo();

  // Flag to indicate that whether the request has passed CDN.
  bool passed_cdn;
  // Flag to indicate that whether the request hit the cache.
  bool cdn_hit_cache;
  int64_t edge;  // Timing cost in cdn inner process.
  int64_t
      origin;  // Timing cost from access point to real server(include inner).
  int64_t inner;  // Timing cost in real server inner process.
  int64_t rtt;    // Timing cost between client and access point.
};

}  // namespace net

#endif  // NET_TT_NET_BASE_SERVER_TIMING_INFO_H
