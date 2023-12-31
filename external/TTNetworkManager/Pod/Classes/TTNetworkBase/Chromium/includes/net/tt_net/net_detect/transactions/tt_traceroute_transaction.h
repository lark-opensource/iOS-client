// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TT_TRACEROUTE_TRANSACTION_
#define NET_TT_NET_NET_DETECT_TT_TRACEROUTE_TRANSACTION_

#include <map>
#include <set>
#include <string>
#include <vector>

#include "base/memory/weak_ptr.h"
#include "base/single_thread_task_runner.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/timer/timer.h"
#include "net/base/address_family.h"
#include "net/base/ip_endpoint.h"
#include "net/log/net_log_source.h"
#include "net/socket/udp_client_socket.h"
#include "net/socket/udp_socket.h"
#include "net/tt_net/net_detect/base/tt_tcpip_protocol.h"
#include "net/tt_net/net_detect/transactions/reports/tt_traceroute_report.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
#include "net/dns/mock_host_resolver.h"
#include "net/tt_net/unit_test/tt_udp_client_socket_test_util.h"
#endif
#if defined(OS_WIN)
// iphlpapi.h must be in front of icmpapi.h
#include <iphlpapi.h>
#include <icmpapi.h>
#endif

#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
#include "net/dns/host_resolver_manager.h"
#include "net/tt_net/config/tt_init_config.h"
#else
#include "net/game_sdk/dns/game_sdk_dns_manager.h"
#endif

namespace net {
namespace tt_detect {

#if defined(OS_WIN)
using Callback = base::OnceCallback<void(const ICMP_ECHO_REPLY& echoreply)>;
struct WinIcmpInput {
  WinIcmpInput(const std::string& host,
               int ttl,
               int timeout,
               Callback callback);
  ~WinIcmpInput();
  HANDLE event_handle{nullptr};
  scoped_refptr<base::SingleThreadTaskRunner> net_thread_task_runner;
  std::string host;
  int ttl{1};
  int timeout{5000};
  Callback callback;
  const base::Location location = base::Location::Current();
  DISALLOW_COPY_AND_ASSIGN(WinIcmpInput);
};
#endif

class TTTracerouteTransaction : public TTNetDetectTransaction {
 public:
  struct TTProtoParams {
    int sock_proto{IPPROTO_ICMP};
    int sock_opt_lvl{IPPROTO_IP};
    int sock_opt_ttl{IP_TTL};
#if defined(OS_ANDROID) || defined(OS_APPLE)
    int sock_opt_recv_ttl{IP_RECVTTL};
#endif
#if defined(OS_ANDROID)
    int sock_opt_recv_error{IP_RECVERR};
#endif
    uint8_t icmp_timxceed{ICMP_TIMXCEED_V4};
    uint8_t icmp_echoreply{ICMP_ECHOREPLY_V4};
  };
  typedef struct TTProtoParams TTProtoParams;

  TTTracerouteTransaction(
      const DetectTarget& parsed_target,
      base::WeakPtr<TTNetDetectTransactionCallback> callback);
  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

  void SetParallelNumber(const size_t parallel_num);
  void SetEchoTimeout(const int64_t echo_timeout);
  // SetSpecifiedHops: set up to record specified hop.
  // specified_hops format: can use "~" to specify the range of hops and use ","
  // to separate the specified hop. Example: "1~5, 7, 10"
  void SetSpecifiedHops(const std::string& specified_hops);
  void SetIpv6Enabled(bool enabled) { ipv6_enabled_ = enabled; }
  void SetResolveHostFlag(
      HostResolver::ResolveHostParameters::TTFlag resolved_host_flag) {
    resolved_host_flag_ = resolved_host_flag;
  }

 private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class TTTracerouteDetectTest;
  FRIEND_TEST_ALL_PREFIXES(TTTracerouteDetectTest, TestTracerouteStart);
  FRIEND_TEST_ALL_PREFIXES(TTTracerouteDetectTest, TestTracerouteError);
  FRIEND_TEST_ALL_PREFIXES(TTTracerouteDetectTest, TestGetDetectResult);
  FRIEND_TEST_ALL_PREFIXES(TTTracerouteDetectTest, TestEchoMsg);
  FRIEND_TEST_ALL_PREFIXES(TTTracerouteDetectTest, TestTracerouteParallel);
  FRIEND_TEST_ALL_PREFIXES(TTTracerouteDetectTest, TestTracerouteStragety);
  void SetHostResolverForTesting(HostResolver* host_resolver) {
    host_resolver_ = host_resolver;
  }

  HostResolver* host_resolver_{nullptr};
  const NetLogWithSource net_log_;
#endif
  class EchoJob : public base::RefCountedThreadSafe<EchoJob> {
   public:
    EchoJob(TTTracerouteTransaction* transaction_);
    void SendEcho();
    bool OnEchoClose();
    void SetHop(const uint16_t hop) { hop_ = hop; }
    uint16_t GetHop() const { return hop_; }
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
    void set_multi_net_action(TTMultiNetworkUtils::MultiNetAction action) {
      multi_network_action_ = action;
    }
#endif

   private:
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
    friend class TTTracerouteDetectTest;
    FRIEND_TEST_ALL_PREFIXES(TTTracerouteDetectTest, TestTracerouteStart);
    FRIEND_TEST_ALL_PREFIXES(TTTracerouteDetectTest, TestTracerouteError);
    FRIEND_TEST_ALL_PREFIXES(TTTracerouteDetectTest, TestGetDetectResult);
    FRIEND_TEST_ALL_PREFIXES(TTTracerouteDetectTest, TestEchoMsg);
    FRIEND_TEST_ALL_PREFIXES(TTTracerouteDetectTest, TestTracerouteParallel);
    FRIEND_TEST_ALL_PREFIXES(TTTracerouteDetectTest, TestTracerouteStragety);
    std::unique_ptr<MockUDPClientSocketTest> mock_client_socket_;
    std::string target_ip_;
#endif
    void SendEchoCompletionCallback(int rv);
    void ReadReplyIfReady();
    void OnEchoTimeout();
    bool OnEchoFinish(int error,
                      size_t reply_hops,
                      const std::string& ipstr,
                      bool reached);
    void NotifyFinish(int error);
    bool SetClientSocketOption(size_t send_hops);
    scoped_refptr<IOBuffer> MakeEchoMsg(int* buffer_size);
#if defined(OS_ANDROID) || BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
    void ReadReplyCompletionCallback(int rv);
    bool ParseReplyPkg(int rv, ttnet::TTUdpSocketErrorMsg* error_msg);
    bool ParseIcmpPkg(char* icmp_pkg,
                      int icmp_pkg_len,
                      ttnet::ICMPHeader** reply_icmp_header);
#elif defined(OS_APPLE)
    void OnEchoJobCompleteCallback(const ttnet::TTUdpSocketErrorMsg& error_msg);
#elif defined(OS_WIN)
    void OnComplete(const ICMP_ECHO_REPLY& echo_reply);
    static void IcmpTaskCompletedOnNetworkThread(
        base::WeakPtr<EchoJob> echo_job,
        const ICMP_ECHO_REPLY& echo_reply);
    static void CALLBACK IcmpTaskOnWinThread(void* param, BOOLEAN timed_out);
#endif

    uint16_t hop_{1};
    scoped_refptr<IOBufferWithSize> read_buffer_;
    std::unique_ptr<UDPClientSocket> client_socket_{nullptr};
    uint16_t retry_per_hop_{0};
    int64_t trace_echo_time_{0};
    size_t icmp_pkg_len_{ttnet::ICMP_PKG_SIZE};
    char icmp_pkg_[ttnet::ICMP_PKG_SIZE];
    base::OneShotTimer echo_timeout_timer_;
    TTTracerouteTransaction* transaction_{nullptr};
    uint16_t trace_seq_{0};
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
    TTMultiNetworkUtils::MultiNetAction multi_network_action_{
        TTMultiNetworkUtils::ACTION_NOT_SPECIFIC};
#endif
    friend class base::RefCountedThreadSafe<EchoJob>;
    ~EchoJob();
    base::WeakPtrFactory<EchoJob> weak_ptr_factory_{this};
    DISALLOW_COPY_AND_ASSIGN(EchoJob);
  };

  std::vector<scoped_refptr<EchoJob>> echo_jobs_;
  bool ipv6_enabled_{false};
  uint16_t trace_id_{0};
  uint16_t trace_seq_{0};
  uint16_t hops_limit_{30};
  uint16_t retry_limit_{2};
  uint16_t try_hops_{1};
  uint16_t parallel_num_{1};
  int64_t echo_timeout_{5000};
  uint16_t closed_parallel_num_{0};
  uint16_t reached_hop_{0};
  bool is_specified_hops_{false};
  HostResolver::ResolveHostParameters::TTFlag resolved_host_flag_{
      HostResolver::ResolveHostParameters::NONE};

  std::unique_ptr<IcmpTracerouteReport> report_;
  NetworkChangeNotifier::NetworkHandle network_handle_{
      NetworkChangeNotifier::kInvalidNetworkHandle};
  std::set<int> specified_hops_;
  scoped_refptr<base::SingleThreadTaskRunner> net_thread_task_runner_;
  NetLogWithSource netlog_source_;
#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
  std::unique_ptr<HostResolver::ResolveHostRequest> host_resolve_request_;
#else
  std::unique_ptr<GameSdkDnsRequest> host_resolve_request_;
#endif
  IPEndPoint resolved_address_;
  std::string resolved_host_;
  bool is_ipv6_{false};
  TTProtoParams proto_params_;
  std::map<int, IPAddress> diagnosis_hops_map_;

  void StartInternal() override;
  void CancelInternal(int error) override;
  void DoHostResolve();
  void OnHostResolveComplete(int result);

  void BuildEchoJob();
  void NotifyEchoFinish(int error);
  void NotifyFinish(int error);
  void Send(base::WeakPtr<EchoJob> echo_job);
  void InternalSend(base::WeakPtr<EchoJob> echo_job);
  // CloseBackSocket: when the hop reaches the specified ip, use this function
  // to close the socket of the following hop.
  void CloseBackSocket(uint16_t reached_hop);
  void SortRecords();
  void CloseAllSocket();
  bool IsEnoughHops(uint16_t hop);
  ~TTTracerouteTransaction() override;
  base::WeakPtrFactory<TTTracerouteTransaction> weak_ptr_factory_{this};
  DISALLOW_COPY_AND_ASSIGN(TTTracerouteTransaction);
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TT_TRACEROUTE_TRANSACTION_
