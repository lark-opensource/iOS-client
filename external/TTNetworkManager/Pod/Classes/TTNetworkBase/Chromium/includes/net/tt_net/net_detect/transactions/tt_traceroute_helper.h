// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TT_TRACEROUTE_HELPER_H_
#define NET_TT_NET_NET_DETECT_TT_TRACEROUTE_HELPER_H_

#include <string>
#include "base/memory/singleton.h"
#include "base/single_thread_task_runner.h"
#include "base/timer/timer.h"
#include "net/base/ip_endpoint.h"
#include "net/dns/host_resolver_manager.h"
#include "net/socket/udp_client_socket.h"
#include "net/socket/udp_socket.h"
#include "net/tt_net/net_detect/base/tt_tcpip_protocol.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"
#include "net/tt_net/net_detect/transactions/tt_traceroute_transaction.h"
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
#include "net/tt_net/multinetwork/utils/tt_multinetwork_utils.h"
#endif

namespace net {
namespace tt_detect {

class TTTracerouteTransaction;

using EchoJobCompleteCallback =
    base::Callback<void(const ttnet::TTUdpSocketErrorMsg&)>;

class TTTracerouteHelper {
 public:
  struct EchoJobKey {
    EchoJobKey();
    EchoJobKey(const EchoJobKey&);
    ~EchoJobKey();

    bool operator<(const EchoJobKey& other) const {
      return std::tie(is_ipv6, dest_ip, trace_id, trace_seq) <
             std::tie(other.is_ipv6, other.dest_ip, other.trace_id,
                      other.trace_seq);
    }

    bool is_ipv6{false};
    std::string dest_ip;
    uint16_t trace_id{0};
    uint16_t trace_seq{0};
    EchoJobCompleteCallback callback;
  };

  struct TTIPHeader {
    int length{0};
    uint8_t sub_proto{0};
    uint8_t ttl{0};
    std::string src_ip;
    std::string dest_ip;
  };

  static TTTracerouteHelper* GetInstance();

  void TryStartRecv(bool is_ipv6,
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
                    TTMultiNetworkUtils::MultiNetAction multi_net_action,
#endif
                    const std::string& dest_ip,
                    uint16_t trace_id,
                    uint16_t trace_seq,
                    EchoJobCompleteCallback callback);
  void StopRecv(bool is_ipv6,
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
                TTMultiNetworkUtils::MultiNetAction multi_net_action,
#endif
                const std::string& dest_ip,
                uint16_t trace_id,
                uint16_t trace_seq);
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  bool ParseIcmpPkgForTesting(char* icmp_pkg,
                              int icmp_pkg_len,
                              TTIPHeader* reply_ip_header,
                              ttnet::ICMPHeader** reply_icmp_header,
                              TTIPHeader* echo_ip_header,
                              ttnet::ICMPHeader** echo_icmp_header);
#endif
 private:
  struct ReceiverKey {
    ReceiverKey();
    ReceiverKey(const ReceiverKey& other);
    ~ReceiverKey();

    bool operator<(const ReceiverKey& other) const {
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
      return std::tie(is_ipv6, multi_net_action) <
             std::tie(other.is_ipv6, other.multi_net_action);
#else
      return std::tie(is_ipv6) < std::tie(other.is_ipv6);
#endif
    }

    bool is_ipv6;
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
    TTMultiNetworkUtils::MultiNetAction multi_net_action{
        TTMultiNetworkUtils::ACTION_NOT_SPECIFIC};
#endif
  };

  class TTTracerouteReceiver;

  friend struct base::DefaultSingletonTraits<TTTracerouteHelper>;
  TTTracerouteHelper();
  ~TTTracerouteHelper();

  std::map<ReceiverKey, std::unique_ptr<TTTracerouteReceiver>> receivers_;

  DISALLOW_COPY_AND_ASSIGN(TTTracerouteHelper);
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TT_TRACEROUTE_HELPER_H_
