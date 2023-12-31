// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_DISPATCH_TYPED_ACTION_H_
#define NET_TTNET_URL_DISPATCHER_DISPATCH_TYPED_ACTION_H_

#include <memory>
#include <regex>

#include "net/tt_net/url_dispatcher/url_dispatch_action.h"

namespace net {

class DispatchStrategy;

class DispatchTypedAction : public URLDispatchAction {
 public:
  DispatchTypedAction(int priority, const std::string& sign);
  ~DispatchTypedAction() override;

 private:
  void LoadActionParam(const base::DictionaryValue* param,
                       const std::string& sign,
                       const int64_t epoch,
                       bool& need_request_result_feedback) override;

  DispatchResult Dispatch(const GURL& origin_url,
                          GURL* new_url,
                          URLRequest* request) override;

  int GetDispatchStrategyType() const override;

  void OnRequestCompleted(const GURL& replace_url, int net_error, int code) override;

  std::unique_ptr<DispatchStrategy> dispatch_strategy_;

  DISALLOW_COPY_AND_ASSIGN(DispatchTypedAction);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_DISPATCH_TYPED_ACTION_H_
