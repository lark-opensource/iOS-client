// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_OPTIMIZED_DISPATCH_STRATEGY_H_
#define NET_TTNET_URL_DISPATCHER_OPTIMIZED_DISPATCH_STRATEGY_H_

#include <string>

#include "net/third_party/quiche/src/common/simple_linked_hash_map.h"
#include "net/tt_net/url_dispatcher/history_based_dispatch_strategy.h"

namespace net {

class OptimizationDispatchStrategy : public HistoryBasedDispatchStrategy {
 public:
  OptimizationDispatchStrategy(const base::DictionaryValue* strategy_info);
  ~OptimizationDispatchStrategy() override;

  // DispatchStrategy implementations:
  GURL GetTargetURL(const GURL& original_url) override;

  void NotifyRequestResult(const GURL& target_url,
                           int net_error,
                           int code) override;

  DispatchStrategyType GetStrategyType() const override;

 private:
  void InitHistoryPositionWeight(double coefficient);

  void ComputeHostQualityIndicator();

  void ComputePolynomialDecayWeight(int start_pos, int end_pos);

  // Get First replace host iterator in |host_quality_indicator_|, refer to
  // |use_default_host_| in file history_based_dispatch_strategy.h.
  quiche::SimpleLinkedHashMap<std::string, double>::iterator
  GetFirstAttemptHost(const GURL& original_url);

  // Used to compute the quality indicator based on the history position weight
  // and the history request result.
  std::vector<double> history_position_weight_;

  // To keep order.
  quiche::SimpleLinkedHashMap<std::string, double> host_quality_indicator_;

  DISALLOW_COPY_AND_ASSIGN(OptimizationDispatchStrategy);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_OPTIMIZED_DISPATCH_STRATEGY_H_
