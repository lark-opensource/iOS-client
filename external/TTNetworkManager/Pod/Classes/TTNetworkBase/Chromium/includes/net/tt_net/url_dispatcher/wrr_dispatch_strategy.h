// Copyright (c) 20189 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_WRR_DISPATCH_STRATEGY_H_
#define NET_TTNET_URL_DISPATCHER_WRR_DISPATCH_STRATEGY_H_

#include <string>

#include "net/tt_net/url_dispatcher/dispatch_strategy.h"

namespace net {

class WRRDispatchStrategy : public DispatchStrategy {
 public:
  WRRDispatchStrategy(const base::DictionaryValue* strategy_info);
  ~WRRDispatchStrategy() override;

  // LoadBalanceMethod implementations:
  bool NeedRequestResultFeedback() override;

  GURL GetTargetURL(const GURL& original_url) override;

  void NotifyRequestResult(const GURL& target_url,
                           int net_error,
                           int code) override;

  DispatchStrategyType GetStrategyType() const override;

 private:
  using HostWeightInfo = std::pair<std::string, int>;

  std::vector<HostWeightInfo> initial_host_weight_;

  std::vector<HostWeightInfo>::iterator current_index_;

  int current_index_remaining_weight_;

  DISALLOW_COPY_AND_ASSIGN(WRRDispatchStrategy);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_WRR_DISPATCH_STRATEGY_H_
