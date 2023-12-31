// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_DIAGNOSIS_V1_REPORTER_H_
#define NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_DIAGNOSIS_V1_REPORTER_H_

#include "base/memory/singleton.h"
#include "net/base/network_change_notifier.h"
#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_base_diagnosis_reporter.h"
#include "net/tt_net/net_detect/transactions/reports/tt_tcp_connect_report.h"

namespace net {
namespace tt_exp {

struct DiagnosisV1Report : BaseDiagnosisReport {
  // Show the dual path diagnosis info.
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  struct MultiNetNode {
    int unsupported_reason{-1};
    int32_t start_signal_strength{-1};
    int32_t end_signal_strength{-1};
    NetworkChangeNotifier::ConnectionType connection_type{
        NetworkChangeNotifier::CONNECTION_UNKNOWN};
    TTMultiNetworkUtils::MultiNetAction multi_net_action{
        TTMultiNetworkUtils::ACTION_NOT_SPECIFIC};

    static const std::string MultiNetActionToString(
        TTMultiNetworkUtils::MultiNetAction action);
  } multi_net_node;
#endif

  std::string diagnosis_target;
  std::vector<std::string> dns_nameservers;
  base::Optional<AccessPointNode> access_point_node;
  LanScanNode lan_scan_node;
  base::Optional<tt_detect::TcpConnectReport> tcp_connect_node;
  TraceNode trace_node;
  PingGroupNode key_point_ping_group;
  PingGroupNode fallback_ping_group;

  DiagnosisV1Report();
  DiagnosisV1Report(const DiagnosisV1Report& other);
  ~DiagnosisV1Report() override;
};

class TTNetExpDiagnosisV1Reporter : public TTNetExpBaseDiagnosisReporter {
 public:
  TTNetExpDiagnosisV1Reporter();
  ~TTNetExpDiagnosisV1Reporter() override;

  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV1Report::LanScanNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const tt_detect::TcpConnectReport& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV1Report::EchoNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV1Report::TraceNode::FallbackNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV1Report::TraceNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV1Report::PingNode& root) const;
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV1Report::MultiNetNode& root) const;
#endif
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV1Report& root) const;

 private:
  std::unique_ptr<base::DictionaryValue> TraceKeyResultToJson(
      const DiagnosisV1Report::PingGroupNode& key_point_ping_group,
      const DiagnosisV1Report::EchoNode& echo_node) const;
  std::unique_ptr<base::DictionaryValue> FallbackKeyResultToJson(
      const DiagnosisV1Report::PingGroupNode& key_point_ping_group,
      const DiagnosisV1Report::TraceNode::FallbackNode& fallback_node) const;
  std::unique_ptr<base::DictionaryValue> TargetKeyResultToJson(
      const std::string& diagnosis_target,
      const std::string& diagnosis_ip,
      const DiagnosisV1Report::PingGroupNode& ping_group_node) const;
  std::unique_ptr<base::DictionaryValue> FallbackKeyResultToJson(
      const DiagnosisV1Report::PingGroupNode& ping_group_node) const;
};

}  // namespace tt_exp
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_DIAGNOSIS_V1_REPORTER_H_