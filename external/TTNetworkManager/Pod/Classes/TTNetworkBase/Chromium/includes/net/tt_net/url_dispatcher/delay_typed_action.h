// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_DELAY_TYPED_ACTION_H_
#define NET_TTNET_URL_DISPATCHER_DELAY_TYPED_ACTION_H_

#include <vector>

#include "net/tt_net/url_dispatcher/url_dispatch_action.h"

namespace net {

class DelayTypedAction : public URLDispatchAction {
 public:
  DelayTypedAction(int priority, const std::string& sign);
  ~DelayTypedAction() override;

 private:
  void LoadActionParam(const base::DictionaryValue* param,
                       const std::string& sign,
                       const int64_t epoch,
                       bool& need_request_result_feedback) override;

  DispatchResult Dispatch(const GURL& origin_url,
                          GURL* new_url,
                          URLRequest* request) override;
  int GetDispatchStrategyType() const override;
  void OnRequestCompleted(const GURL& replace_url,
                          int net_error,
                          int code) override;

  int DispatchDelay(const GURL& origin_url, URLRequest* request) override;

  int delay_time_;
  bool is_random_delay_;
  // Inclusive bound.
  int random_delay_lower_bound_;
  int random_delay_upper_bound_;
  bool is_invalid_;
  std::unordered_map<std::string, std::set<std::string>> tnc_tag_;

  DISALLOW_COPY_AND_ASSIGN(DelayTypedAction);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_DELAY_TYPED_ACTION_H_
