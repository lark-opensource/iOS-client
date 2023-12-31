// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_TCP_CONNECT_TRANSACTION_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_TCP_CONNECT_TRANSACTION_H_

#include "base/threading/thread_task_runner_handle.h"
#include "base/values.h"
#include "net/base/address_list.h"
#include "net/base/host_port_pair.h"
#include "net/log/net_log_with_source.h"
#include "net/tt_net/net_detect/transactions/reports/tt_tcp_connect_report.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
#include "net/tt_net/unit_test/tt_transport_client_socket_test_util.h"
#endif

#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
#include "net/dns/host_resolver_manager.h"
#include "net/tt_net/config/tt_init_config.h"
#else
#include "net/game_sdk/dns/game_sdk_dns_manager.h"
#endif
#include "net/socket/tcp_client_socket.h"
#include "net/socket/transport_client_socket.h"

namespace net {
namespace tt_detect {

class TTTCPConnectTransaction : public TTNetDetectTransaction {
 public:
  TTTCPConnectTransaction(
      const DetectTarget& parsed_target,
      base::WeakPtr<TTNetDetectTransactionCallback> callback,
      std::unique_ptr<TcpConnectReport> report =
          std::make_unique<TcpConnectReport>());
  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

  void set_bypass_http_dns(bool bypass_http_dns) {
    bypass_http_dns_ = bypass_http_dns;
  }

  void set_force_http_dns(bool force_http_dns) {
    force_http_dns_ = force_http_dns;
  }

  void set_port(uint16_t port) { port_ = port; }

 protected:
  enum State {
    STATE_RESOLVE_HOST,
    STATE_RESOLVE_HOST_COMPLETE,
    STATE_TCP_CONNECT,
    STATE_TCP_CONNECT_COMPLETE,
    STATE_NONE,
  };

  ~TTTCPConnectTransaction() override;
  void StartInternal() override;
  void CancelInternal(int error) override;
  virtual int DoLoop(int result);
  virtual int DoResolveHost();
  virtual int DoResolveHostComplete(int result);
  virtual int DoTCPConnect();
  virtual int DoTCPConnectComplete(int result);
  void OnIOComplete(int result);
  void DoTransactionCompletion(int result);

  std::unique_ptr<TransportClientSocket> client_socket_;

  // Timing stats
  base::TimeTicks start_time_;
  base::TimeTicks dns_start_;
  base::TimeTicks tcp_connect_start_;

  bool bypass_http_dns_{false};
  bool force_http_dns_{false};
  uint16_t port_{80};
  std::unique_ptr<TcpConnectReport> report_;

 private:
  friend class TTTCPConnectTransactionTest;
  State next_state_{STATE_NONE};
  HostPortPair host_and_port_;
  AddressList address_list_;
  NetLogWithSource net_log_with_source_;
#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
  HostResolver* host_resolver_;
  std::unique_ptr<HostResolver::ResolveHostRequest> host_resolve_request_;
#else
  std::unique_ptr<GameSdkDnsRequest> host_resolve_request_;
#endif

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  void SetSocketCreatorForTesting(
      TCPClientSocketForTestCreatorCallback creator) {
    creator_ = creator;
  }

#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
  void SetHostResolverForTesting(HostResolver* host_resolver) {
    host_resolver_ = host_resolver;
  }
#endif

  HostPortPair host_and_port() const { return host_and_port_; }

 private:
  TCPClientSocketForTestCreatorCallback creator_;
#endif
  base::WeakPtrFactory<TTTCPConnectTransaction> factory_;
};

}  // namespace tt_detect
}  // namespace net

#endif
