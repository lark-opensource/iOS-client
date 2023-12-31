// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_RAW_DETECT_REPORTER_H_
#define NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_RAW_DETECT_REPORTER_H_

#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_base_experience_reporter.h"
#include "net/tt_net/net_detect/transactions/reports/tt_dnsserver_report.h"
#include "net/tt_net/net_detect/transactions/reports/tt_full_dns_report.h"
#include "net/tt_net/net_detect/transactions/reports/tt_http_dns_report.h"
#include "net/tt_net/net_detect/transactions/reports/tt_http_get_report.h"
#include "net/tt_net/net_detect/transactions/reports/tt_http_isp_report.h"
#include "net/tt_net/net_detect/transactions/reports/tt_local_dns_report.h"
#include "net/tt_net/net_detect/transactions/reports/tt_perf_report.h"
#include "net/tt_net/net_detect/transactions/reports/tt_ping_report.h"
#include "net/tt_net/net_detect/transactions/reports/tt_tcp_connect_report.h"
#include "net/tt_net/net_detect/transactions/reports/tt_tcp_echo_report.h"
#include "net/tt_net/net_detect/transactions/reports/tt_traceroute_report.h"

namespace net {
namespace tt_exp {

struct RawDetectReport : BaseExperienceReport {
  struct DeviceNode {
    int32_t signal_strength{-1};
    std::string network_status;
    NetworkChangeNotifier::ConnectionType default_connection_type{
        NetworkChangeNotifier::CONNECTION_UNKNOWN};

    DeviceNode();
    ~DeviceNode();
    DeviceNode(const DeviceNode& other);
  };

  int64_t job_start_time{0};
  int64_t job_end_time{0};
  int64_t cloud_version{0};
  bool is_device_suspended{false};
  DeviceNode start_device_node;
  DeviceNode end_device_node;
  std::vector<std::unique_ptr<tt_detect::BaseDetectReport>> trans_nodes;

  RawDetectReport();
  ~RawDetectReport() override;
};

class TTNetExpRawDetectReporter : public TTNetExpBaseExperienceReporter {
 public:
  TTNetExpRawDetectReporter();
  ~TTNetExpRawDetectReporter() override;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const RawDetectReport::DeviceNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const RawDetectReport& root) const;

 private:
  RawDetectReport report_;
};

}  // namespace tt_exp
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_RAW_DETECT_REPORTER_H_
