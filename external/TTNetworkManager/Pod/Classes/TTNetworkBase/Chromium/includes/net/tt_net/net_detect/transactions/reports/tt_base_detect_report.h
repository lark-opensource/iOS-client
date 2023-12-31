// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_BASE_DETECT_REPORT_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_BASE_DETECT_REPORT_H_

#include "net/tt_net/net_detect/tt_network_detect_dispatched_manager.h"

namespace net {
namespace tt_detect {

struct BaseDetectReport {
  int detect_type{TTNetworkDetectDispatchedManager::ACTION_INVALID};
  int detect_error{ND_ERR_OK};
  int net_error{OK};
  std::string origin_target;

  BaseDetectReport();
  virtual ~BaseDetectReport();
  virtual std::unique_ptr<base::DictionaryValue> ToJson() const;
  virtual std::string GetReportName() const;
  virtual std::unique_ptr<BaseDetectReport> Clone();

  bool is_http_get() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_HTTP_GET;
  }
  bool is_icmp_ping() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_ICMP_PING;
  }
  bool is_icmp_traceroute() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_TRACEROUTE;
  }
  bool is_local_dns() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_DNS_LOCAL;
  }
  bool is_http_dns() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_DNS_HTTP;
  }
  bool is_dns_server() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_DNS_SERVER;
  }
  bool is_udp_ping() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_UDP_PING;
  }
  bool is_full_dns() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_DNS_FULL;
  }
  bool is_tcp_connect() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_TCP_CONNECT;
  }
  bool is_tcp_echo() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_TCP_ECHO;
  }
  bool is_tcp_perf() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_TCP_PERF;
  }
  bool is_udp_perf() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_UDP_PERF;
  }
  bool is_http_isp() const {
    return detect_type == TTNetworkDetectDispatchedManager::ACTION_HTTP_ISP;
  }
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_BASE_DETECT_REPORT_H_
