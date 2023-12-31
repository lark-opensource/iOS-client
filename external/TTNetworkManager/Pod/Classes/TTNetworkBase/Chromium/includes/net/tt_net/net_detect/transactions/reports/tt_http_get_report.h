// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_HTTP_GET_REPORT_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_HTTP_GET_REPORT_H_

#include "net/http/http_status_code.h"
#include "net/tt_net/net_detect/transactions/reports/tt_base_detect_report.h"
#include "net/url_request/url_fetcher.h"

namespace net {
namespace tt_detect {

struct HttpGetReport : public BaseDetectReport {
  int http_code{URLFetcher::RESPONSE_CODE_INVALID};
  int ttfb{-1};
  std::string target_url;
  std::string response_headers;
  std::string request_log;

  // Returns |value| if it is the http get report, nullptr otherwise.
  static std::unique_ptr<HttpGetReport> From(
      std::unique_ptr<BaseDetectReport> value);

  HttpGetReport();
  ~HttpGetReport() override;
  HttpGetReport(const HttpGetReport& other);
  std::unique_ptr<base::DictionaryValue> ToJson() const override;
  std::string GetReportName() const override;
  std::unique_ptr<BaseDetectReport> Clone() override;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_HTTP_GET_REPORT_H_
