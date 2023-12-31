// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_HTTP_DNS_TRANSACTION_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_HTTP_DNS_TRANSACTION_

#include <string>
#include <vector>

#include "base/single_thread_task_runner.h"
#include "net/tt_net/dns/httpdns_host_resolver.h"
#include "net/tt_net/net_detect/transactions/reports/tt_http_dns_report.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"

namespace net {
namespace tt_detect {

class TTDetectHttpDnsTransaction : public TTNetDetectTransaction {
 public:
  TTDetectHttpDnsTransaction(
      const DetectTarget& parsed_target,
      base::WeakPtr<TTNetDetectTransactionCallback> callback);
  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

  void UseGoogleDns(bool use_google_dns);
  void UseTTHttpDns(bool use_tt_http_dns);
  void SetTimeoutSeconds(int seconds);
  void SetTTHttpDnsDomain(const std::string& domain);

 private:
  ~TTDetectHttpDnsTransaction() override;
  void StartInternal() override;
  void CancelInternal(int error) override;
  void StartOnIOThread(const std::string& host);
  void OnTransactionComplete(
      int net_error,
      const HttpDnsHostResolver::HttpDnsResponse& response);

  bool use_google_dns_{false};
  bool use_tt_http_dns_{false};
  int timeout_{60};
  base::TimeTicks start_time_;
  std::string tt_http_dns_domain_;
  std::unique_ptr<HttpDnsReport> report_;
  std::unique_ptr<HttpDnsHostResolver> http_dns_client_;
  std::unique_ptr<HttpDnsHostResolver::Handle> http_dns_handle_;

  base::WeakPtrFactory<TTDetectHttpDnsTransaction> factory_;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TT_HTTP_DNS_TRANSACTION_
