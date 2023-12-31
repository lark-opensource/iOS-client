// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_FULL_DNS_REPORT_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_FULL_DNS_REPORT_H_

#include "net/tt_net/net_detect/transactions/reports/tt_base_detect_report.h"

namespace net {
namespace tt_detect {

struct FullDnsReport : public BaseDetectReport {
  int port{0};
  int source{AddressList::NOT_SET};
  std::string host;
  std::vector<std::string> resolved_ips;

  FullDnsReport();
  ~FullDnsReport() override;
  FullDnsReport(const FullDnsReport& other);
  void ParseAddressList(const AddressList& address_list);
  std::unique_ptr<base::DictionaryValue> ToJson() const override;
  std::string GetReportName() const override;
  std::unique_ptr<BaseDetectReport> Clone() override;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_FULL_DNS_REPORT_H_
