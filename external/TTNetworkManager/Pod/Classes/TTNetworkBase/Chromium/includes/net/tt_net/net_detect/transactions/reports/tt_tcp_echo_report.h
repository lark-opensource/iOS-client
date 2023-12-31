// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_TCP_ECHO_REPORT_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_TCP_ECHO_REPORT_H_

#include "net/tt_net/net_detect/transactions/reports/tt_tcp_connect_report.h"

namespace net {
namespace tt_detect {

struct TcpEchoReport : public TcpConnectReport {
  int write_cost{0};
  int read_cost{0};

  TcpEchoReport();
  ~TcpEchoReport() override;
  TcpEchoReport(const TcpEchoReport& other);
  std::unique_ptr<base::DictionaryValue> ToJson() const override;
  std::string GetReportName() const override;
  std::unique_ptr<BaseDetectReport> Clone() override;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_TCP_ECHO_REPORT_H_
