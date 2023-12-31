// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_PING_REPORT_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_PING_REPORT_H_

#include "net/tt_net/net_detect/transactions/reports/tt_base_detect_report.h"

namespace net {
namespace tt_detect {

struct PingReport : public BaseDetectReport {
  struct EchoReport {
    EchoReport();
    EchoReport(int64_t cost, int net_error);

    int64_t cost{0};
    int net_error{OK};
  };
  int max_cost{0};
  int min_cost{0};
  int avg_cost{0};
  int ping_times{0};
  int success_count{0};
  int lost_count{0};
  int error_count{0};
  double loss_rate{1.0};  // Use 1.0 as default value of loss rate.
  std::string host;
  std::string ip;
  std::vector<EchoReport> echo_reports;

  PingReport();
  ~PingReport() override;
  PingReport(const PingReport& other);
  void ParseEchoReports();
  std::unique_ptr<base::DictionaryValue> ToJson() const override;
};

struct IcmpPingReport : public PingReport {
  IcmpPingReport();
  std::string GetReportName() const override;
  std::unique_ptr<BaseDetectReport> Clone() override;
};

struct UdpPingReport : public PingReport {
  UdpPingReport();
  std::string GetReportName() const override;
  std::unique_ptr<BaseDetectReport> Clone() override;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_PING_REPORT_H_
