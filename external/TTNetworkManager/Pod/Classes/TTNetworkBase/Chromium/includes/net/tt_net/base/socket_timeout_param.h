// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_BASE_SOCKET_TIMEOUT_PARAM_H_
#define NET_TT_NET_BASE_SOCKET_TIMEOUT_PARAM_H_

#include "base/time/time.h"
#include "net/base/net_export.h"

namespace net {

// Structure containing timeout control parameters for a request.
struct NET_EXPORT SocketTimeoutParam {
  SocketTimeoutParam();
  SocketTimeoutParam(const SocketTimeoutParam& other);
  ~SocketTimeoutParam();

  bool IsZero() const;

  // Timeout for TCP three-way handshake.
  base::TimeDelta connect_timeout;

  // Timeout for socket read.
  base::TimeDelta read_timeout;

  // Timeout for socket write.
  base::TimeDelta write_timeout;
};

}  // namespace net

#endif  // NET_TT_NET_BASE_SOCKET_TIMEOUT_PARAM_H_
