// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_TCP_CONNECT_REPORT_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_TCP_CONNECT_REPORT_H_

#include "net/tt_net/net_detect/transactions/reports/tt_base_detect_report.h"

namespace net {
namespace tt_detect {

struct TcpConnectReport : public BaseDetectReport {
  int dns_cost{0};
  int connect_cost{0};
  int total_cost{0};
  std::string target_url;
  std::vector<std::string> resolved_ips;

  TcpConnectReport();
  ~TcpConnectReport() override;
  TcpConnectReport(const TcpConnectReport& other);
  std::unique_ptr<base::DictionaryValue> ToJson() const override;
  std::string GetReportName() const override;
  std::unique_ptr<BaseDetectReport> Clone() override;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_TCP_CONNECT_REPORT_H_
