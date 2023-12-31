// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_HTTP_ISP_TRANSACTION_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_HTTP_ISP_TRANSACTION_H_

#include "base/single_thread_task_runner.h"
#include "net/tt_net/net_detect/transactions/reports/tt_http_isp_report.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"
#include "net/url_request/url_fetcher.h"
#include "net/url_request/url_fetcher_delegate.h"

namespace net {
namespace tt_detect {

class TTHttpIspTransaction : public TTNetDetectTransaction,
                             public URLFetcherDelegate {
 public:
  enum SourceType { APP = 1 };

  struct HttpIspPacket {
    uint32_t post_count{0};
    uint32_t duration_s{0};
    uint64_t task_id{0};
    int64_t send_time{0};
    SourceType source{APP};
    std::string origin_target;
    std::vector<IPAddress> local_ips;
    std::string gateway_ip;

    HttpIspPacket();
    virtual ~HttpIspPacket();
    std::unique_ptr<base::DictionaryValue> ToJson() const;
  };

  TTHttpIspTransaction(const DetectTarget& parsed_target,
                       base::WeakPtr<TTNetDetectTransactionCallback> callback);
  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

  void set_post_count(uint32_t post_count) { post_count_ = post_count; }
  void set_duration_s(uint16_t duration_s) { duration_s_ = duration_s; }

 private:
  friend class TTHttpIspTransactionTest;
  ~TTHttpIspTransaction() override;
  void StartInternal() override;
  void CancelInternal(int error) override;
  // net::URLFetcherDelegate implementation.
  void OnURLFetchComplete(const URLFetcher* source) override;

  void StartUrlRequest();
  void OnRequestIntervalTimeout();
  void DoTransactionCompletion(int result);
  void StopInternal();
  void CollectRequestEntity(const URLFetcher* source);

  // Total count of http post sending.
  uint32_t post_count_{0};
  // The duration second of HTTP sending.
  uint32_t duration_s_{0};
  // The interval between each request.
  uint32_t request_interval_ms_{0};

  GURL detect_url_;
  HttpIspPacket packet_;
  HttpIspReport report_;
  std::vector<HttpIspReport::RequestEntity>::iterator entity_;
  std::unique_ptr<URLFetcher> fetcher_{nullptr};
  base::OneShotTimer duration_timer_;
  base::RepeatingTimer request_interval_timer_;

  base::WeakPtrFactory<TTHttpIspTransaction> weak_factory_{this};
  DISALLOW_COPY_AND_ASSIGN(TTHttpIspTransaction);
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_HTTP_ISP_TRANSACTION_H_
