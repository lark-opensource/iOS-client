// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_PING_TRANSACTION_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_PING_TRANSACTION_

#include <string>
#include <vector>

#include "base/callback.h"
#include "base/timer/timer.h"
#include "net/base/ip_endpoint.h"
#include "net/log/net_log_source.h"
#include "net/socket/udp_client_socket.h"
#include "net/tt_net/net_detect/transactions/reports/tt_ping_report.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"

#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
#include "net/dns/host_resolver_manager.h"
#include "net/tt_net/config/tt_init_config.h"
#else
#include "net/game_sdk/dns/game_sdk_dns_manager.h"
#endif

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
#include "net/dns/mock_host_resolver.h"
#include "net/tt_net/unit_test/tt_udp_client_socket_test_util.h"
#endif

namespace net {
namespace tt_detect {

class TTPingTransaction : public TTNetDetectTransaction {
 public:
  TTPingTransaction(
      const DetectTarget& parsed_target,
      base::WeakPtr<TTNetDetectTransactionCallback> callback,
      std::unique_ptr<PingReport> report = std::make_unique<PingReport>());

  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;
  void SetPingTimesLimit(size_t limit);
  void SetPingTimeoutMs(size_t timeout);
  void SetPingPort(uint16_t port);

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  void SetHostResolverForTesting(HostResolver* host_resolver) {
    host_resolver_ = host_resolver;
  }

  size_t GetPingTimesLimit() const { return ping_repeat_time_; }
  uint16_t GetPingSeq() const { return ping_seq_; }
  uint16_t GetPingId() const { return ping_id_; }
  std::unique_ptr<MockUDPClientSocketTest> mock_client_socket_;
  HostResolver* host_resolver_{nullptr};
  const NetLogWithSource net_log_;
  std::string target_ip_;
#endif

  void SetIpv6Enabled(bool enabled) { ipv6_enabled_ = enabled; }

  void SetResolveHostFlag(
      HostResolver::ResolveHostParameters::TTFlag resolved_host_flag) {
    resolved_host_flag_ = resolved_host_flag;
  }

 protected:
  uint16_t ping_id_{0};
  uint16_t ping_seq_{0};
  size_t ping_times_limit_{3};
  size_t ping_timeout_ms_{2000};
  size_t ping_repeat_time_{0};
  std::map<uint16_t, int64_t> sent_echoes_;
  IPEndPoint resolved_address_;
  scoped_refptr<IOBufferWithSize> read_buffer_;
  std::unique_ptr<UDPClientSocket> client_socket_{nullptr};
  bool is_ipv6_{false};
  bool ipv6_enabled_{false};
  std::unique_ptr<PingReport> report_;

  ~TTPingTransaction() override;
  void NotifyFinish(int error);
  virtual void SendEcho();
  bool OnEchoFinish(uint16_t seq, int error, int64_t cost);

 private:
  NetLogWithSource netlog_source_;
#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
  std::unique_ptr<HostResolver::ResolveHostRequest> host_resolve_request_;
#else
  std::unique_ptr<GameSdkDnsRequest> host_resolve_request_;
#endif
  uint16_t echo_port_{80};
  HostResolver::ResolveHostParameters::TTFlag resolved_host_flag_{
      HostResolver::ResolveHostParameters::NONE};
  base::OneShotTimer echo_timeout_timer_;

  void StartInternal() override;
  void CancelInternal(int error) override;
  void DoHostResolve();
  void OnHostResolveComplete(int result);
  void EchoTimeout(uint16_t ping_seq, int64_t echo_time);
  void SendEchoCompletionCallback(uint16_t seq, int64_t echo_time, int rv);
  void ReadReplyIfReady(uint16_t seq, int64_t echo_time);
  void ReadReplyCompletionCallback(uint16_t seq, int64_t echo_time, int rv);
  virtual scoped_refptr<IOBuffer> MakeEchoMsg(int* buffer_size,
                                              int64_t echo_time) = 0;
  virtual bool ParseAndCheckReplyMsg(int size, uint16_t seq) = 0;
  virtual bool SetClientSocketOption() = 0;
  base::WeakPtrFactory<TTPingTransaction> weak_factory_{this};
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TT_PING_TRANSACTION_
