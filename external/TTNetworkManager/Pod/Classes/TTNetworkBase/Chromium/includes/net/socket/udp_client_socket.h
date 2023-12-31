// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_SOCKET_UDP_CLIENT_SOCKET_H_
#define NET_SOCKET_UDP_CLIENT_SOCKET_H_

#include <stdint.h>

#include "base/macros.h"
#include "net/base/net_export.h"
#include "net/socket/datagram_client_socket.h"
#include "net/socket/udp_socket.h"
#include "net/traffic_annotation/network_traffic_annotation.h"
#if BUILDFLAG(TTNET_IMPLEMENT)
#include "net/tt_net/net_detect/base/tt_tcpip_protocol.h"
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
#include "net/tt_net/multinetwork/utils/tt_multinetwork_utils.h"
#endif  // BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
#endif

namespace net {

class NetLog;
struct NetLogSource;

// A client socket that uses UDP as the transport layer.
class NET_EXPORT_PRIVATE UDPClientSocket : public DatagramClientSocket {
 public:
  UDPClientSocket(DatagramSocket::BindType bind_type,
                  net::NetLog* net_log,
                  const net::NetLogSource& source);
  ~UDPClientSocket() override;

  // DatagramClientSocket implementation.
  int Connect(const IPEndPoint& address) override;
  int ConnectUsingNetwork(NetworkChangeNotifier::NetworkHandle network,
                          const IPEndPoint& address) override;
  int ConnectUsingDefaultNetwork(const IPEndPoint& address) override;
  NetworkChangeNotifier::NetworkHandle GetBoundNetwork() const override;
  void ApplySocketTag(const SocketTag& tag) override;
  int Read(IOBuffer* buf,
           int buf_len,
           CompletionOnceCallback callback) override;
  int Write(IOBuffer* buf,
            int buf_len,
            CompletionOnceCallback callback,
            const NetworkTrafficAnnotationTag& traffic_annotation) override;

  int WriteAsync(
      const char* buffer,
      size_t buf_len,
      CompletionOnceCallback callback,
      const NetworkTrafficAnnotationTag& traffic_annotation) override;
  int WriteAsync(
      DatagramBuffers buffers,
      CompletionOnceCallback callback,
      const NetworkTrafficAnnotationTag& traffic_annotation) override;

  DatagramBuffers GetUnwrittenBuffers() override;

  void Close() override;
  int GetPeerAddress(IPEndPoint* address) const override;
  int GetLocalAddress(IPEndPoint* address) const override;
  // Switch to use non-blocking IO. Must be called right after construction and
  // before other calls.
  void UseNonBlockingIO() override;
  int SetReceiveBufferSize(int32_t size) override;
  int SetSendBufferSize(int32_t size) override;
  int SetDoNotFragment() override;
  void SetMsgConfirm(bool confirm) override;
  const NetLogWithSource& NetLog() const override;
  void EnableRecvOptimization() override;

  void SetWriteAsyncEnabled(bool enabled) override;
  bool WriteAsyncEnabled() override;
  void SetMaxPacketSize(size_t max_packet_size) override;
  void SetWriteMultiCoreEnabled(bool enabled) override;
  void SetSendmmsgEnabled(bool enabled) override;
  void SetWriteBatchingActive(bool active) override;
  int SetMulticastInterface(uint32_t interface_index) override;
#if BUILDFLAG(TTNET_IMPLEMENT)
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_QUIC_RECVMMSG)
  void SetRecvmmsgEnabled(bool enabled) override;
  int MultipleRead(DatagramReadBuffers* read_buffers,
                   int buf_len,
                   CompletionOnceCallback callback) override;
#endif
  const quic::QuicWallTime& GetQuicWallTimestamp() override;
  void SetBeforeConnect(bool enable_wall_timestamp,
                        bool enable_multi_network) override;
  void SetSocketProtocol(int protocol);
  int SetSockOpt(int lvl, int optname, const void* optval, socklen_t optlen);
  int RecvFrom(IOBuffer* buf,
               int buf_len,
               IPEndPoint* address,
               CompletionOnceCallback callback);
  int SendTo(IOBuffer* buf,
             int buf_len,
             const IPEndPoint& address,
             CompletionOnceCallback callback);
  int Open(AddressFamily address_family);
#if defined(OS_ANDROID) || defined(OS_APPLE)
  void SetRecvErrMsg(bool recv);
  ttnet::TTUdpSocketErrorMsg GetUdpSocketErrorMsg() const;
#endif
#if defined(OS_APPLE)
  bool IsReadCallbackEmpty() const;
#endif
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  void set_multi_net_action(TTMultiNetworkUtils::MultiNetAction action);
#endif
#endif

 private:
  UDPSocket socket_;
  NetworkChangeNotifier::NetworkHandle network_;

  DISALLOW_COPY_AND_ASSIGN(UDPClientSocket);
};

}  // namespace net

#endif  // NET_SOCKET_UDP_CLIENT_SOCKET_H_
