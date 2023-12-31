// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_DIAGNOSIS_V2_REPORTER_H_
#define NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_DIAGNOSIS_V2_REPORTER_H_

#include "net/base/network_change_notifier.h"
#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_base_diagnosis_reporter.h"

namespace net {
namespace tt_exp {

struct DiagnosisV2Report : BaseDiagnosisReport {
  struct NetworkChangeNode : TimelineNode {
    NetworkChangeNotifier::ConnectionType default_connection_type{
        NetworkChangeNotifier::CONNECTION_NONE};
    NetworkChangeNode();
    ~NetworkChangeNode() override;
  };

  // Obtain the environment information of the network or device, which changes
  // with the network change.
  struct EnvironmentNode : TimelineNode {
    std::vector<std::string> dns_nameservers;
    base::Optional<AccessPointNode> access_point;

    EnvironmentNode();
    ~EnvironmentNode() override;
    EnvironmentNode(const EnvironmentNode& other);
  };

  struct KeyPointNode : TimelineNode {
    TraceNode trace_node;

    KeyPointNode();
    ~KeyPointNode() override;
    std::vector<std::string> GetAllKeyPointIP() const;
  };

  struct PingGroupV2Node : TimelineNode {
    int32_t signal_strength{-1};
    NetworkChangeNotifier::ConnectionType connection_type{
        NetworkChangeNotifier::CONNECTION_NONE};
    PingGroupNode ping_group;

    PingGroupV2Node();
    ~PingGroupV2Node() override;
  };

  struct SelfPollNode : PingGroupV2Node {
    SelfPollNode();
    ~SelfPollNode() override;
  };

  struct FullDiagNode : PingGroupV2Node {
    std::string target_ip;
    std::string extra_message;
    PingGroupNode fallback_ping_group;

    FullDiagNode();
    ~FullDiagNode() override;
  };

  std::string diagnosis_target;
  std::vector<NetworkChangeNode> network_change_nodes;
  std::vector<EnvironmentNode> environment_nodes;
  std::vector<LanScanNode> lan_scan_nodes;
  std::vector<KeyPointNode> key_point_nodes;
  std::vector<SelfPollNode> self_poll_nodes;
  std::vector<FullDiagNode> full_diag_nodes;

  DiagnosisV2Report();
  DiagnosisV2Report(const DiagnosisV2Report& other);
  ~DiagnosisV2Report() override;
};

class TTNetExpDiagnosisV2Reporter : public TTNetExpBaseDiagnosisReporter {
 public:
  TTNetExpDiagnosisV2Reporter();
  TTNetExpDiagnosisV2Reporter(const TTNetExpDiagnosisV2Reporter& other);
  ~TTNetExpDiagnosisV2Reporter() override;

  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV2Report::EchoNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV2Report::TraceNode::FallbackNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV2Report::LanScanNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV2Report::NetworkChangeNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV2Report::EnvironmentNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV2Report::KeyPointNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV2Report::PingGroupV2Node& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV2Report::SelfPollNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV2Report::FullDiagNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DiagnosisV2Report& root) const;

 private:
  DiagnosisV2Report report_;
};

}  // namespace tt_exp
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_DIAGNOSIS_V2_REPORTER_H_