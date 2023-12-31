// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//
//  Created by gaohaidong on 6/4/19.
//  Copyright © 2019 ttnet. All rights reserved.
//

#ifndef NET_TT_NET_BASE_TCP_CLIENT_SOCKET_CONCURRENT_H_
#define NET_TT_NET_BASE_TCP_CLIENT_SOCKET_CONCURRENT_H_

#include <vector>

#include "base/timer/timer.h"
#include "net/base/address_list.h"
#include "net/base/completion_once_callback.h"
#include "net/log/net_log_with_source.h"
#include "net/socket/stream_socket.h"
#include "net/socket/tcp_client_socket.h"
#include "net/socket/tcp_socket.h"
#include "net/tt_net/base/socket_timeout_param.h"

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
#include "net/tt_net/unit_test/tt_transport_client_socket_test_util.h"
#endif

namespace net {

class NetLog;
struct NetLogSource;
class SocketPerformanceWatcher;

class TCPClientSocketConcurrent : public TransportClientSocket {
 public:
  // The IP address(es) and port number to connect to.  The TCP socket will try
  // each IP address in the list until it succeeds in establishing a
  // connection.
  TCPClientSocketConcurrent(
      const AddressList& addresses,
      std::unique_ptr<SocketPerformanceWatcher> socket_performance_watcher,
      net::NetLog* net_log,
      const net::NetLogSource& source);

  // Adopts the given, connected socket and then acts as if Connect() had been
  // called. This function is used by TCPServerSocket and for testing.
  TCPClientSocketConcurrent(std::unique_ptr<TCPSocket> connected_socket,
                            const IPEndPoint& peer_address);

  ~TCPClientSocketConcurrent() override;

  const SocketTimeoutParam& socket_timeout_param() const {
    return socket_timeout_param_;
  }

  // TransportClientSocket implementation.
  int Bind(const net::IPEndPoint& local_addr) override;

  // StreamSocket implementation.
  int Connect(CompletionOnceCallback callback) override;
  void Disconnect() override;
  bool IsConnected() const override;
  bool IsConnectedAndIdle() const override;
  int GetPeerAddress(IPEndPoint* address) const override;
  int GetLocalAddress(IPEndPoint* address) const override;
  const NetLogWithSource& NetLog() const override;
  bool WasEverUsed() const override;
  bool WasAlpnNegotiated() const override;
  NextProto GetNegotiatedProtocol() const override;
  bool GetSSLInfo(SSLInfo* ssl_info) override;
  void SetNewSocketTimeoutParam(
      const SocketTimeoutParam& socket_timeout_param) override;
  void ApplySocketTag(const SocketTag& tag) override;

  // Socket implementation.
  // Multiple outstanding requests are NOW supported!!!
  // Full duplex mode (reading and writing at the same time) is supported.
  int Read(IOBuffer* buf,
           int buf_len,
           CompletionOnceCallback callback) override;
  int Write(IOBuffer* buf,
            int buf_len,
            CompletionOnceCallback callback,
            const NetworkTrafficAnnotationTag& traffic_annotation) override;
  int SetReceiveBufferSize(int32_t size) override;
  int SetSendBufferSize(int32_t size) override;

  void GetConnectionAttempts(ConnectionAttempts* out) const override;
  void ClearConnectionAttempts() override;
  void AddConnectionAttempts(const ConnectionAttempts& attempts) override;
  int64_t GetTotalReceivedBytes() const override;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  void SetSocketCreatorForTesting(
      TCPClientSocketForTestCreatorCallback creator) {
    creator_ = creator;
  }
#endif

 private:
  //  bool concurrent_mode_{true};
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  TCPClientSocketForTestCreatorCallback creator_;
#endif
  std::unique_ptr<TransportClientSocket> winner_{nullptr};
  std::vector<std::unique_ptr<TransportClientSocket>> pending_sockets_;
  std::unique_ptr<base::OneShotTimer> timeout_timer_;
  // The list of addresses we should try in order to establish a connection.
  AddressList addresses_;

  std::unique_ptr<SocketPerformanceWatcher> socket_performance_watcher_;

  net::NetLog* net_log_{nullptr};
  const net::NetLogSource* source_{nullptr};

  int current_address_index_;
  // External callback; called when connect is complete.
  CompletionOnceCallback connect_callback_;

  int32_t socket_receive_buf_size_{0};
  int32_t socket_send_buf_size_{0};

  NetLogWithSource net_log_with_source_;

  SocketTimeoutParam socket_timeout_param_;

  int DoConnect();
  int TryConnectNextIP();
  void OnConnectTimeout();
  void CleanupPendingSocketsAndRecordAttempts();

  void DidCompleteConnect(int current_address_index, int result);

  void AssignWinnerSocket(std::unique_ptr<TransportClientSocket> socket);

  // Failed connection attempts made while trying to connect this socket.
  ConnectionAttempts connection_attempts_;

  DISALLOW_COPY_AND_ASSIGN(TCPClientSocketConcurrent);
};

}  // namespace net

#endif  // NET_TT_NET_BASE_TCP_CLIENT_SOCKET_CONCURRENT_H_
