// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_STATIC_DISPATCH_STRATEGY_H_
#define NET_TTNET_URL_DISPATCHER_STATIC_DISPATCH_STRATEGY_H_

#include <string>
#include <unordered_map>

#include "net/tt_net/url_dispatcher/dispatch_strategy.h"

namespace net {

class StaticDispatchStrategy : public DispatchStrategy {
 public:
  StaticDispatchStrategy(const base::DictionaryValue* strategy_info);
  ~StaticDispatchStrategy() override;

  // DispatchStrategy implementations:
  bool NeedRequestResultFeedback() override;

  GURL GetTargetURL(const GURL& original_url) override;

  void NotifyRequestResult(const GURL& target_url,
                           int net_error,
                           int code) override;

  DispatchStrategyType GetStrategyType() const override;

 private:
  std::unordered_map<std::string, std::string> host_mapping_;

  DISALLOW_COPY_AND_ASSIGN(StaticDispatchStrategy);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_STATIC_DISPATCH_STRATEGY_H_
