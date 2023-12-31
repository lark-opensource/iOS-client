// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_TRACEROUTE_REPORT_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_TRACEROUTE_REPORT_H_

#include "net/tt_net/net_detect/transactions/reports/tt_base_detect_report.h"

namespace net {
namespace tt_detect {

struct TracerouteReport : public BaseDetectReport {
  struct EchoRecord {
    int detect_error{ND_ERR_OK};
    uint16_t send_hops{0};
    uint16_t reply_hops{0};
    int64_t echo_time{0};
    int64_t cost{0};
    std::string ip;
    bool operator<(const EchoRecord& other) const {
      return send_hops < other.send_hops;
    }
  };

  uint16_t reached_hop{0};
  uint16_t try_hops{1};
  uint16_t parallel_num{1};  // Use 1 as default value of parallel_num.
  std::string host;
  std::string ip;
  NetworkChangeNotifier::ConnectionType connection_type{
      NetworkChangeNotifier::CONNECTION_UNKNOWN};
  std::vector<EchoRecord> echo_records;

  TracerouteReport();
  ~TracerouteReport() override;
  TracerouteReport(const TracerouteReport& other);
  std::unique_ptr<base::DictionaryValue> ToJson() const override;
};

struct IcmpTracerouteReport : public TracerouteReport {
  IcmpTracerouteReport();
  std::string GetReportName() const override;
  std::unique_ptr<BaseDetectReport> Clone() override;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_TRACEROUTE_REPORT_H_
