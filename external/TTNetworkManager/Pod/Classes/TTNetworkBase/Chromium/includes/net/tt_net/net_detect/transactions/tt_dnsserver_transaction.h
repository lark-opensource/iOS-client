// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_DNS_SERVER_TRANSACTION_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_DNS_SERVER_TRANSACTION_

#include <string>

#include "base/single_thread_task_runner.h"
#include "net/tt_net/dns/httpdns_host_resolver.h"
#include "net/tt_net/net_detect/transactions/reports/tt_dnsserver_report.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"
#include "net/url_request/url_fetcher_delegate.h"

namespace net {
namespace tt_detect {

class TTDnsServerTransaction : public TTNetDetectTransaction,
                               public URLFetcherDelegate {
 public:
  TTDnsServerTransaction(
      const DetectTarget& parsed_target,
      base::WeakPtr<TTNetDetectTransactionCallback> callback);

  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

 private:
  enum PerformStatus {
    Init = -1,
    GetRandomHost = 0,
    RequestRandomUrl = 1,
    GetDnsServer = 2,
  };
  ~TTDnsServerTransaction() override;
  void StartInternal() override;
  void CancelInternal(int error) override;
  void StartOnIOThread();
  void NextAction();

  void GetRandomUrlAction();
  bool HandleGetRandomUrlResult(const URLFetcher* source);
  void RequestRandomUrlAction();
  void GetDnsServerAction();
  bool HandleDnsServerResult(const URLFetcher* source);

  // net::URLFetcherDelegate implementation.
  void OnURLFetchComplete(const URLFetcher* source) override;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class TTNetworkDetectTest;
  FRIEND_TEST_ALL_PREFIXES(TTDnsServerTransactionTest,
                           TestHandleGetRandomUrlResultSucc);
  FRIEND_TEST_ALL_PREFIXES(TTDnsServerTransactionTest,
                           TestHandleGetRandomUrlResultFail);
  FRIEND_TEST_ALL_PREFIXES(TTDnsServerTransactionTest,
                           TestHandleDnsServerResultSucc);
  FRIEND_TEST_ALL_PREFIXES(TTDnsServerTransactionTest,
                           TestHandleDnsServerResultFail);
#endif

  int perform_tag_ = 0;
  std::string random_host_;
  base::TimeTicks start_time_;

  std::unique_ptr<DnsServerReport> report_;
  scoped_refptr<base::SingleThreadTaskRunner> net_thread_task_runner_;
  std::unique_ptr<URLFetcher> fetcher_;
  base::WeakPtrFactory<TTDnsServerTransaction> factory_;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TT_DNS_SERVER_TRANSACTION_
