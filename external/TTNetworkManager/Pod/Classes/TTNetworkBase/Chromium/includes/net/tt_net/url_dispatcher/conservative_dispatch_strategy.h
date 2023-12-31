// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_CONSERVATIVE_DISPATCH_STRATEGY_H_
#define NET_TTNET_URL_DISPATCHER_CONSERVATIVE_DISPATCH_STRATEGY_H_

#include <string>

#include "base/time/time.h"
#include "net/third_party/quiche/src/common/simple_linked_hash_map.h"
#include "net/tt_net/url_dispatcher/history_based_dispatch_strategy.h"

namespace net {

class ConservativeDispatchStrategy
    : public HistoryBasedDispatchStrategy,
      public HistoryBasedDispatchStrategy::RequestResultHistoryObserver {
 public:
  ConservativeDispatchStrategy(const base::DictionaryValue* strategy_info);
  ~ConservativeDispatchStrategy() override;

  // DispatchStrategy implementations:
  GURL GetTargetURL(const GURL& original_url) override;

  // HistoryBasedLoadBalance::RequestResultHistoryObserver implementations:
  void OnSampleAddedToHistory(const std::string& host,
                              RequestResult result) override;
  DispatchStrategyType GetStrategyType() const override;

 private:
  struct HostStatus {
    bool is_forbidden;

    // Forbidden time duration for the host.
    int forbid_duration;

    // Forbidden start time of the host.
    base::TimeTicks forbid_start;

    // Current states for the host.
    int current_fail_request_count;

    HostStatus();
    ~HostStatus();
  };

  void EvaluateToForbidHost(const std::string& host, HostStatus& status);

  void RecoverHostStatusFromForbidden();

  // Get First replace host iterator in |host_statistics_|, refer to
  // |use_default_host_| in file history_based_dispatch_strategy.h.
  quiche::SimpleLinkedHashMap<std::string, HostStatus>::iterator
  GetFirstAttemptHost(const GURL& original_url);

  // The least number of samples to make the forbidden logic effective.
  int least_sample_to_decide_;

  // Select best host randomly from |host_statistics_|.
  bool random_select_{false};

  // The last select host by function |GetTargetURL|.
  std::string last_select_host_;

  quiche::SimpleLinkedHashMap<std::string, HostStatus> host_statistics_;

  DISALLOW_COPY_AND_ASSIGN(ConservativeDispatchStrategy);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_CONSERVATIVE_DISPATCH_STRATEGY_H_
