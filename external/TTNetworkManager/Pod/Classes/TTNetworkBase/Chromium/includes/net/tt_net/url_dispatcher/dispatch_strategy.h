// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_DISPATCH_STRATEGY_H_
#define NET_TTNET_URL_DISPATCHER_DISPATCH_STRATEGY_H_

#include <memory>

#include "base/values.h"
#include "net/url_request/url_request.h"
#include "url/gurl.h"

namespace net {

enum DispatchStrategyType {
  UNKNOWN_DISPATCH_STRATEGY = 0,
  STATIC_DISPATCH_STRATEGY,
  WRR_DISPATCH_STRATEGY,
  CONSERVATIVE_DISPATCH_STRATEGY,
  OPTIMIZED_DISPATCH_STRATEGY,
  ROUTE_SELECTION_DISPATCH_STRATEGY,
  REQUEST_HEADER_DISPATCH_STRATEGY,
  MAIN_ALTERNATIVE_DISPATCH_STRATEGY,
  DISPATCH_STRATEGY_SUPPORTED_LAST = MAIN_ALTERNATIVE_DISPATCH_STRATEGY
};

class DispatchStrategy {
 public:
  DispatchStrategy();
  virtual ~DispatchStrategy();

  static std::unique_ptr<DispatchStrategy> Factory(
      DispatchStrategyType type,
      const base::DictionaryValue* strategy_info,
      const std::string& sign,
      const int64_t epoch,
      unsigned int priority,
      const std::string& service_name);

  virtual bool NeedRequestResultFeedback();

  virtual GURL GetTargetURL(const GURL& original_url);

  virtual void DispatchRequestHeaders(URLRequest* request);

  virtual void NotifyRequestResult(const GURL& target_url,
                                   int net_error,
                                   int code);

  virtual DispatchStrategyType GetStrategyType() const;

 private:
  DispatchStrategyType type_;

  DISALLOW_COPY_AND_ASSIGN(DispatchStrategy);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_DISPATCH_STRATEGY_H_
