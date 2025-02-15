// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_SOCKET_CLIENT_SOCKET_FACTORY_H_
#define NET_SOCKET_CLIENT_SOCKET_FACTORY_H_

#include <memory>
#include <string>

#include "net/base/net_export.h"
#include "net/http/proxy_client_socket.h"
#include "net/socket/datagram_socket.h"
#include "net/socket/socket_performance_watcher.h"
#include "net/socket/transport_client_socket.h"
#include "net/traffic_annotation/network_traffic_annotation.h"

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_PROXY_SUPPORT)
#include "net/tt_net/proxy/tt_proxy_info.h"
#endif

namespace net {

class AddressList;
class DatagramClientSocket;
class HostPortPair;
class NetLog;
struct NetLogSource;
class SSLClientContext;
class SSLClientSocket;
struct SSLConfig;
class ProxyClientSocket;
class ProxyDelegate;
class ProxyServer;
class HttpAuthController;
class NetworkQualityEstimator;

// An interface used to instantiate StreamSocket objects.  Used to facilitate
// testing code with mock socket implementations.
class NET_EXPORT ClientSocketFactory {
 public:
  virtual ~ClientSocketFactory() {}

  // |source| is the NetLogSource for the entity trying to create the socket,
  // if it has one.
  virtual std::unique_ptr<DatagramClientSocket> CreateDatagramClientSocket(
      DatagramSocket::BindType bind_type,
      NetLog* net_log,
      const NetLogSource& source) = 0;

  // |network_quality_estimator| is optional. If not specified, the network
  // quality will not be considered when determining TCP connect handshake
  // timeouts, or when histogramming the handshake duration.
  virtual std::unique_ptr<TransportClientSocket> CreateTransportClientSocket(
      const AddressList& addresses,
      std::unique_ptr<SocketPerformanceWatcher> socket_performance_watcher,
      NetworkQualityEstimator* network_quality_estimator,
      NetLog* net_log,
      const NetLogSource& source) = 0;

#if BUILDFLAG(TTNET_IMPLEMENT)
  virtual std::unique_ptr<DatagramClientSocket> CreateDatagramClientSocket(
      DatagramSocket::BindType bind_type,
      const NetworkIsolationKey& network_isolation_key,
      NetLog* net_log,
      const NetLogSource& source);

  virtual std::unique_ptr<TransportClientSocket> CreateTransportClientSocket(
      const AddressList& addresses,
      std::unique_ptr<SocketPerformanceWatcher> socket_performance_watcher,
      NetworkQualityEstimator* network_quality_estimator,
      const NetworkIsolationKey& network_isolation_key,
      NetLog* net_log,
      const NetLogSource& source);
#endif

  // It is allowed to pass in a StreamSocket that is not obtained from a
  // socket pool. The caller could create a StreamSocket directly.
  virtual std::unique_ptr<SSLClientSocket> CreateSSLClientSocket(
      SSLClientContext* context,
      std::unique_ptr<StreamSocket> stream_socket,
      const HostPortPair& host_and_port,
      const SSLConfig& ssl_config) = 0;

  virtual std::unique_ptr<ProxyClientSocket> CreateProxyClientSocket(
      std::unique_ptr<StreamSocket> stream_socket,
      const std::string& user_agent,
      const HostPortPair& endpoint,
      const ProxyServer& proxy_server,
      HttpAuthController* http_auth_controller,
      bool tunnel,
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_PROXY_SUPPORT)
      bool is_ttnet_tunnel,
      const std::map<std::string, std::string>& ttnet_proxy_auth,
      OnTTNetProxyInfoCallback ttnet_proxy_info_callback,
#endif
      bool using_spdy,
      NextProto negotiated_protocol,
      ProxyDelegate* proxy_delegate,
      const NetworkTrafficAnnotationTag& traffic_annotation) = 0;

  // Returns the default ClientSocketFactory.
  static ClientSocketFactory* GetDefaultFactory();
};

}  // namespace net

#endif  // NET_SOCKET_CLIENT_SOCKET_FACTORY_H_
