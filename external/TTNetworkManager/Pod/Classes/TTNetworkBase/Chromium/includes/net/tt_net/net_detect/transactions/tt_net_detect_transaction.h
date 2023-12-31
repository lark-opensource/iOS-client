// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_NET_DETECT_TRANSACTION_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_NET_DETECT_TRANSACTION_H_

#include <string>

#include "base/memory/ref_counted.h"
#include "base/memory/weak_ptr.h"
#include "base/time/time.h"
#include "base/values.h"
#include "net/base/address_list.h"
#include "net/base/host_port_pair.h"
#include "net/base/net_errors.h"
#include "net/net_buildflags.h"
#include "net/tt_net/net_detect/base/tt_network_detect_errors.h"
#include "net/tt_net/net_detect/transactions/reports/tt_base_detect_report.h"
#include "url/gurl.h"

#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
#include "net/tt_net/multinetwork/utils/tt_multinetwork_utils.h"
#endif

namespace net {
namespace tt_detect {

class TTNetDetectTransactionCallback {
 public:
  virtual void OnDetectTransactionProgress() = 0;
  virtual void OnDetectTransactionFinish() = 0;
};

struct DetectTarget {
  GURL url;
  std::string origin_target;

  DetectTarget();
  DetectTarget(const char* target);
  DetectTarget(const std::string& target);
  ~DetectTarget();
  bool is_valid() const;
};

class TTNetDetectTransaction
    : public base::RefCountedThreadSafe<TTNetDetectTransaction> {
 public:
  TTNetDetectTransaction(
      const DetectTarget& target,
      base::WeakPtr<TTNetDetectTransactionCallback> callback);

  void Start();
  void Cancel(int error);
  virtual std::unique_ptr<BaseDetectReport> GetDetectReport() const;
  bool IsFinished() const { return is_finished_; }
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  void SetMultiNetAction(TTMultiNetworkUtils::MultiNetAction action) {
    multi_network_action_ = action;
  }
#endif

 protected:
  friend class base::RefCountedThreadSafe<TTNetDetectTransaction>;
  virtual ~TTNetDetectTransaction();
  virtual void StartInternal();
  virtual void CancelInternal(int error);

  void NotifyTransactionProgress();
  void NotifyTransactionFinish();

  bool is_finished_{false};
  DetectTarget detect_target_;
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  TTMultiNetworkUtils::MultiNetAction multi_network_action_{
      TTMultiNetworkUtils::ACTION_NOT_SPECIFIC};
#endif
  base::WeakPtr<TTNetDetectTransactionCallback> callback_{nullptr};

 private:
  void OnProgressCallback();
  void OnFinishCallback();

  base::WeakPtrFactory<TTNetDetectTransaction> factory_;
  DISALLOW_COPY_AND_ASSIGN(TTNetDetectTransaction);
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_NET_DETECT_TRANSACTION_H_