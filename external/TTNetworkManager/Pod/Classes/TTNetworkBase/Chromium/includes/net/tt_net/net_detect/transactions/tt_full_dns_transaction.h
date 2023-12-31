// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_FULL_DNS_TRANSACTION_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_FULL_DNS_TRANSACTION_H_

#include "base/memory/weak_ptr.h"
#include "base/threading/thread_task_runner_handle.h"
#include "base/values.h"
#include "net/base/address_list.h"
#include "net/base/host_port_pair.h"
#include "net/log/net_log_with_source.h"
#include "net/tt_net/net_detect/transactions/reports/tt_full_dns_report.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"

#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
#include "net/dns/host_resolver_manager.h"
#else
#include "net/game_sdk/dns/game_sdk_dns_manager.h"
#endif

namespace net {
namespace tt_detect {

class TTFullDnsTransaction : public TTNetDetectTransaction {
 public:
  TTFullDnsTransaction(const DetectTarget& parsed_target,
                       base::WeakPtr<TTNetDetectTransactionCallback> callback);
  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

 private:
  ~TTFullDnsTransaction() override;
  void StartInternal() override;
  void CancelInternal(int error) override;
  void OnResolveComplete(int result);

#if !BUILDFLAG(TTNET_IMPLEMENT_ENABLE_GAME_SDK_INDEPENDENT)
  std::unique_ptr<HostResolver::ResolveHostRequest> host_resolve_request_;
#else
  std::unique_ptr<GameSdkDnsRequest> host_resolve_request_;
#endif

  std::unique_ptr<FullDnsReport> report_;

  base::WeakPtrFactory<TTFullDnsTransaction> factory_;
};

}  // namespace tt_detect
}  // namespace net

#endif
