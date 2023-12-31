// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_LOCAL_DNS_TRANSACTION_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_LOCAL_DNS_TRANSACTION_

#include <string>
#include <vector>

#include "base/single_thread_task_runner.h"
#include "net/tt_net/net_detect/transactions/reports/tt_local_dns_report.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#endif

namespace net {
namespace tt_detect {

class TTLocalDnsTransaction : public TTNetDetectTransaction {
 public:
  TTLocalDnsTransaction(const DetectTarget& parsed_target,
                        base::WeakPtr<TTNetDetectTransactionCallback> callback);
  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  std::map<std::string, addrinfo*> mock_host_ip_;
  int MockGetAddrInfo(const std::string& target_ip, addrinfo** addrinfo);
#endif

 private:
  ~TTLocalDnsTransaction() override;
  void StartInternal() override;
  void CancelInternal(int error) override;
  void StartOnIOThread();
  void TaskFinished();

  base::TimeTicks start_time_;
  std::unique_ptr<LocalDnsReport> report_;
  base::WeakPtrFactory<TTLocalDnsTransaction> factory_;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TT_LOCAL_DNS_TRANSACTION_
