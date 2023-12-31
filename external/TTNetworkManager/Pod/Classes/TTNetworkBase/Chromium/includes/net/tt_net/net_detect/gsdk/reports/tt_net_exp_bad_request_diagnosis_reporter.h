// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_BAD_REQUEST_DIAGNOSIS_REPORTER_H_
#define NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_BAD_REQUEST_DIAGNOSIS_REPORTER_H_

#include "base/memory/singleton.h"
#include "net/base/network_change_notifier.h"
#include "net/base/network_interfaces.h"
#include "net/http/http_status_code.h"
#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_base_diagnosis_reporter.h"
#include "net/tt_net/net_detect/transactions/reports/tt_http_get_report.h"
#include "net/tt_net/util/tt_network_router.h"

namespace net {
namespace tt_exp {

struct BadRequestDiagnosisReport : BaseDiagnosisReport {
  struct HttpGetGroupNode {
    HttpGetGroupNode();
    ~HttpGetGroupNode();

    int detect_error{ND_ERR_OK};
    std::vector<std::unique_ptr<tt_detect::HttpGetReport>> entities;
  };

  BadRequestDiagnosisReport();
  ~BadRequestDiagnosisReport() override;

  NetworkInterfaceList interfaces;
  RouteEntryList routes;
  HttpGetGroupNode http_get_group_node;
  TraceNode trace_node;
  PingGroupNode key_point_ping_group;
};

class TTNetExpBadRequestDiagnosisReporter
    : public TTNetExpBaseDiagnosisReporter {
 public:
  TTNetExpBadRequestDiagnosisReporter();
  ~TTNetExpBadRequestDiagnosisReporter() override;

  std::unique_ptr<base::DictionaryValue> ToJson(
      const BadRequestDiagnosisReport& root) const;

 private:
  std::unique_ptr<base::DictionaryValue> ToJson(
      const BadRequestDiagnosisReport::HttpGetGroupNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const BadRequestDiagnosisReport::TraceNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const BadRequestDiagnosisReport::PingGroupNode& root) const;
};

}  // namespace tt_exp
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_BAD_REQUEST_DIAGNOSIS_REPORTER_H_