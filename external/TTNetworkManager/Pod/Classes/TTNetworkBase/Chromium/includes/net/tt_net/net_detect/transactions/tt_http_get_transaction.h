// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_HTTP_GET_TRANSACTION_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_HTTP_GET_TRANSACTION_H_

#include "base/single_thread_task_runner.h"
#include "net/tt_net/net_detect/transactions/reports/tt_http_get_report.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"
#include "net/url_request/url_fetcher_delegate.h"

namespace net {
namespace tt_detect {

class TTHttpGetTransaction : public TTNetDetectTransaction,
                             public URLFetcherDelegate {
 public:
  TTHttpGetTransaction(const DetectTarget& parsed_target,
                       base::WeakPtr<TTNetDetectTransactionCallback> callback);
  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

  void SetReportResponseHeaders(bool report);
  void SetIsolationEnabled(bool isolation_enabled);
  void SetExtraHeaders(const std::vector<std::string>& headers);
  void SetSocketReuse(bool reuse);

 private:
  ~TTHttpGetTransaction() override;
  void StartInternal() override;
  void CancelInternal(int error) override;
  // net::URLFetcherDelegate implementation.
  void OnURLFetchComplete(const URLFetcher* source) override;
  void StartOnIOThread(const std::string& url_str);

  size_t report_response_headers_{0};
  std::vector<std::string> extra_headers_;
  bool socket_reuse_{true};
  bool isolation_enabled_{false};
  std::unique_ptr<HttpGetReport> report_;
  std::unique_ptr<URLFetcher> fetcher_;
  scoped_refptr<base::SingleThreadTaskRunner> net_thread_task_runner_;
  base::WeakPtrFactory<TTHttpGetTransaction> factory_;
};

}  // namespace tt_detect
}  // namespace net

#endif