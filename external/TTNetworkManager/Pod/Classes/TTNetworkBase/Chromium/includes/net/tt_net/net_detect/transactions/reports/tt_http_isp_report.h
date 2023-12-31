// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_HTTP_ISP_REPORT_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_HTTP_ISP_REPORT_H_

#include "net/tt_net/net_detect/transactions/reports/tt_base_detect_report.h"
#include "net/url_request/url_fetcher.h"

namespace net {
namespace tt_detect {

struct HttpIspReport : public BaseDetectReport {
  struct TransactionParam {
    uint32_t post_count{0};
    uint16_t duration_s{0};

    std::unique_ptr<base::DictionaryValue> ToJson() const;
  };

  struct RequestEntity {
    bool is_collected{false};
    int64_t start_time{0};
    int64_t end_time{0};
    int net_error{OK};
    int http_code{URLFetcher::RESPONSE_CODE_INVALID};

    std::unique_ptr<base::DictionaryValue> ToJson() const;
  };

  int64_t start_trans_time{0};
  int64_t end_trans_time{0};
  uint64_t task_id{0};  // The identity of the detection.
  std::string request_url;
  TransactionParam param;
  std::vector<RequestEntity> entities;

  HttpIspReport();
  ~HttpIspReport() override;
  HttpIspReport(const HttpIspReport& other);
  std::unique_ptr<base::DictionaryValue> ToJson() const override;
  std::string GetReportName() const override;
  std::unique_ptr<BaseDetectReport> Clone() override;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_REPORTS_TT_HTTP_ISP_REPORT_H_
