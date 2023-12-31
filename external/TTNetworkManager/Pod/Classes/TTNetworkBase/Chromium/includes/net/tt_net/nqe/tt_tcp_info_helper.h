// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_TCP_INFO_HELPER_H_
#define NET_TT_NET_NQE_TT_TCP_INFO_HELPER_H_

#include "base/time/time.h"
#include "net/base/ip_endpoint.h"
#include "net/net_buildflags.h"
#include "net/socket/socket_descriptor.h"

namespace net {

struct TTTCPInfo {
  TTTCPInfo();
  TTTCPInfo(const TTTCPInfo& other);
  ~TTTCPInfo();

  // On Android and Linux, it's from |tcpi_snd_mss|.
  // On iOS, it's from |tcpi_maxseg|.
  // Not implement on Windows currently.
  base::Optional<uint32_t> send_mss;

  // Smoothed RTT.
  // On Android and Linux, it's from |tcpi_rtt| and its unit is us.
  // On iOS, it's from |tcpi_srtt| and its unit is ms.
  // On Windows, it's unit is ms.
  base::TimeDelta srtt;

  uint64_t total_sent_packets{0};

  uint64_t total_retrans_packets{0};

  SocketDescriptor fd{kInvalidSocket};

  std::string host;
};

class TTTCPInfoHelper {
 public:
  TTTCPInfoHelper();
  virtual ~TTTCPInfoHelper() {}

  virtual void OnConnectSuccess(SocketDescriptor fd,
                                const std::string& host,
                                const IPEndPoint& local_addr,
                                const IPEndPoint& remote_addr);

  virtual bool UpdateTCPInfo() = 0;

  TTTCPInfo tt_tcp_info() const { return tt_tcp_info_; }

 protected:
  void Reset();

  base::TimeDelta SrttToTimeDelta(uint32_t srtt) const;

  SocketDescriptor fd_{kInvalidSocket};

  std::string host_;

  TTTCPInfo tt_tcp_info_;
};

}  // namespace net

#endif