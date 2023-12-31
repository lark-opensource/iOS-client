// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_UDP_PERF_SENDER_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_UDP_PERF_SENDER_H_

#include "net/base/io_buffer.h"
#include "net/socket/udp_client_socket.h"
#include "net/tt_net/net_detect/transactions/perf/tt_base_perf_sender.h"

namespace net {

namespace tt_detect {

class TTUdpPerfSender : public TTBasePerfSender {
 public:
  TTUdpPerfSender();
  ~TTUdpPerfSender() override;

 private:
  int SocketConnectImpl() override;
  int SocketWriteImpl(const scoped_refptr<DrainableIOBuffer>& buffer) override;
  void Stop() override;

  std::unique_ptr<DatagramClientSocket> client_socket_{nullptr};
  base::WeakPtrFactory<TTUdpPerfSender> weak_factory_{this};
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_UDP_PERF_SENDER_H_
