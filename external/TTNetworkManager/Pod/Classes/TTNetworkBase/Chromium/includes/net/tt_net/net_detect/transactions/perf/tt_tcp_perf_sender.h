// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_TCP_PERF_SENDER_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_TCP_PERF_SENDER_H_

#include "net/base/io_buffer.h"
#include "net/log/net_log_with_source.h"
#include "net/socket/tcp_client_socket.h"
#include "net/tt_net/net_detect/transactions/perf/tt_base_perf_sender.h"

namespace net {

namespace tt_detect {

class TTTcpPerfSender : public TTBasePerfSender {
 public:
  TTTcpPerfSender();
  ~TTTcpPerfSender() override;

 private:
  int SocketConnectImpl() override;
  int SocketWriteImpl(const scoped_refptr<DrainableIOBuffer>& buffer) override;
  void Stop() override;

  std::unique_ptr<TransportClientSocket> client_socket_{nullptr};
  base::WeakPtrFactory<TTTcpPerfSender> weak_factory_{this};
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_TCP_PERF_SENDER_H_
