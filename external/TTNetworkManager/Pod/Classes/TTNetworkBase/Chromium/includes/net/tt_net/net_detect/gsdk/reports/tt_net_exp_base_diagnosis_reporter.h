
// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_BASE_DIAGNOSIS_REPORTER_H_
#define NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_BASE_DIAGNOSIS_REPORTER_H_

#include "base/strings/string_number_conversions.h"
#include "net/base/network_change_notifier.h"
#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_base_experience_reporter.h"

namespace net {
namespace tt_exp {

// The whole report of experience request.
struct BaseDiagnosisReport : BaseExperienceReport {
  // Show the device information about the start and end of the job
  struct DeviceNode {
    uint64_t total_tx_bytes{0};
    uint64_t total_rx_bytes{0};
    int32_t signal_strength{-1};
    std::string network_status;
    NetworkChangeNotifier::ConnectionType default_connection_type{
        NetworkChangeNotifier::CONNECTION_UNKNOWN};

    DeviceNode();
    ~DeviceNode();
  };

  // Show the access point info, including its channel.
  struct AccessPointNode {
    AccessPointNode();
    ~AccessPointNode();
    AccessPointNode(const AccessPointNode& other);

    int current_channel{-1};
    std::vector<int> total_channels;
  };

  // time axis
  struct TimelineNode {
    enum TimeNodeType {
      TYPE_NONE,
      TYPE_NETWORK_CHANGE,
      TYPE_ENVIRONMENT,
      TYPE_LAN_SCAN,
      TYPE_TRACEROUTE,
      TYPE_PING,
      TYPE_KEY_POINT,
      TYPE_SELF_POLL,
      TYPE_FULL_DIAG
    };
    int time_node_type{TYPE_NONE};
    int64_t started_time{0};
    int64_t end_time{0};

    TimelineNode();
    virtual ~TimelineNode();
    std::string const GetTypeName() const;
  };
  typedef TimelineNode::TimeNodeType TimeNodeType;

  // Show the LAN info, including the number of devices connected to this LAN.
  struct LanScanNode : TimelineNode {
    LanScanNode();
    ~LanScanNode() override;
    int device_count{0};
  };

  // Show traceroute info. Note that only key echo nodes are displayed
  struct TraceNode : TimelineNode {
    struct EchoNode {
      int detect_error{ND_ERR_OK};
      uint16_t send_hops{0};
      uint16_t reply_hops{0};
      int64_t cost{0};
      std::string ip;
    };

    struct FallbackNode {
      std::string target;
    };

    int detect_error{ND_ERR_OK};
    // Check whether the object has collect results from transaction called
    // |TTNetExpDiagnosisTracer::CollectTraceNodeFromTransaction|
    bool had_collected_trans{false};
    // Check whether the object has collect results from config called
    // |TTNetExpDiagnosisTracer::CollectFallbackNodeFromManualConfig|
    bool had_collected_config{false};
    // It is the default connection_type.
    NetworkChangeNotifier::ConnectionType default_connect_type{
        NetworkChangeNotifier::CONNECTION_NONE};
    // Not default connection_type! it is decided by MultiNet.
    NetworkChangeNotifier::ConnectionType path_type{
        NetworkChangeNotifier::CONNECTION_NONE};
    std::string origin_target;  // the diagnosis target passed by user
    std::string target_ip;      // the ip resolved from |origin_target|
    base::Optional<EchoNode> default_gateway_echo;
    base::Optional<EchoNode> public_access_point_echo;
    base::Optional<FallbackNode> system_gateway_point;
    base::Optional<FallbackNode> edge_point;

    TraceNode();
    ~TraceNode() override;
    TraceNode(const TraceNode& other);
    TraceNode& operator=(const TraceNode& other);
    std::vector<std::string> GetAllTargets() const;
  };
  typedef TraceNode::EchoNode EchoNode;

  // Show ping info.
  struct PingGroupNode : TimelineNode {
    struct PingNode {
      int error{ND_ERR_OK};
      int avg_rtt{-1};
      int max_rtt{-1};
      int min_rtt{-1};
      int ping_count{0};
      int lost_count{0};
      int error_count{0};
      std::string origin_target;
      std::string host;
      std::string ip;
      std::string type;

      PingNode();
      ~PingNode();
      PingNode(const PingNode& other);
    };

    // Check whether the object has collect diagnosis results
    bool is_collected{false};
    std::vector<PingNode> all_ping_nodes;
    int detect_error{ND_ERR_OK};

    PingGroupNode();
    ~PingGroupNode() override;
    PingGroupNode(const PingGroupNode& other);
    bool DeletePingNode(const std::string& ip);
  };
  typedef BaseDiagnosisReport::PingGroupNode::PingNode PingNode;

  int64_t job_start_time{0};
  int64_t job_end_time{0};
  DeviceNode start_device_node;
  DeviceNode end_device_node;

  BaseDiagnosisReport();
  ~BaseDiagnosisReport() override;
  BaseDiagnosisReport(const BaseDiagnosisReport& other);
};

class TTNetExpBaseDiagnosisReporter : public TTNetExpBaseExperienceReporter {
 public:
  TTNetExpBaseDiagnosisReporter();
  ~TTNetExpBaseDiagnosisReporter() override;

  std::unique_ptr<base::DictionaryValue> ToJson(
      const BaseDiagnosisReport::DeviceNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const BaseDiagnosisReport::TimelineNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const BaseDiagnosisReport::AccessPointNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const BaseDiagnosisReport& root) const;
};

}  // namespace tt_exp
}  // namespace net
#endif  // NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_BASE_DIAGNOSIS_REPORTER_H_