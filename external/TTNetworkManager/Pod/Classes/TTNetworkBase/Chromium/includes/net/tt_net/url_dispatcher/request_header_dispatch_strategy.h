// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_REQUEST_HEADER_DISPTACH_STRATEGY_H_
#define NET_TTNET_URL_DISPATCHER_REQUEST_HEADER_DISPTACH_STRATEGY_H_

#include "net/tt_net/url_dispatcher/dispatch_strategy.h"

namespace net {

class RequestHeaderDispatchStrategy : public DispatchStrategy {
 public:
  RequestHeaderDispatchStrategy(const base::DictionaryValue* strategy_info);
  ~RequestHeaderDispatchStrategy() override;

  // DispatchStrategy implementations:
  void DispatchRequestHeaders(URLRequest* request) override;

  DispatchStrategyType GetStrategyType() const override;

 private:
  std::unordered_map<std::string, std::string> add_headers_map_;

  DISALLOW_COPY_AND_ASSIGN(RequestHeaderDispatchStrategy);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_REQUEST_HEADER_DISPATCH_STRATEGY_H_
