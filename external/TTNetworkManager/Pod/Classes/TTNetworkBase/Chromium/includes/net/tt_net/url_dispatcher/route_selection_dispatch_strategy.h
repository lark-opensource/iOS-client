// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_DISPATCH_STRATEGY_H_
#define NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_DISPATCH_STRATEGY_H_

#include <memory>
#include <set>

#include "net/tt_net/url_dispatcher/dispatch_strategy.h"

namespace net {

class RouteSelectionDispatchStrategy : public DispatchStrategy {
 public:
  RouteSelectionDispatchStrategy(const base::DictionaryValue* strategy_info,
                                 const std::string& sign,
                                 const int64_t epoch,
                                 unsigned int priority,
                                 const std::string& service_name);
  ~RouteSelectionDispatchStrategy() override;

  // DispatchStrategy implementations:
  bool NeedRequestResultFeedback() override;

  GURL GetTargetURL(const GURL& original_url) override;

  void NotifyRequestResult(const GURL& target_url,
                           int net_error,
                           int code) override;

  DispatchStrategyType GetStrategyType() const override;

 private:
  GURL MockForCommonRouteSelection(const GURL& original_url);
  GURL MockForTTRouteSelection(const GURL& original_url);

  int registered_id_;

  std::string service_name_;

  // Request ends with failure if response code in |error_code| list.
  std::set<int> error_code_;

  DISALLOW_COPY_AND_ASSIGN(RouteSelectionDispatchStrategy);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_DISPATCH_STRATEGY_H_
