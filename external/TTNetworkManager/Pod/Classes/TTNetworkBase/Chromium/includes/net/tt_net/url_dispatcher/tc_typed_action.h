// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_TC_TYPED_ACTION_H_
#define NET_TTNET_URL_DISPATCHER_TC_TYPED_ACTION_H_

#include <memory>
#include <regex>

#include "net/tt_net/url_dispatcher/url_dispatch_action.h"

namespace net {

class TCTypedAction : public URLDispatchAction {
 public:
  TCTypedAction(int priority, const std::string& sign);
  ~TCTypedAction() override;

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

  bool IsPossibilityHit();

  bool ShouldDropByColdStartLimit() const;

  DispatchResult DispatchAndDropRequest(const GURL& origin_url, GURL* new_url);

  void ParseRequestTagFromTNCConfig(const std::string& tnc_tag_string);

  std::string scheme_replace_;

  std::string host_replace_;

  std::string path_replace_;

  // Use std::regex_replace to replace original url.
  std::regex replace_regex_;
  std::string replace_value_;

  bool is_drop_;

  bool is_tag_drop_;

  int64_t cold_start_drop_time_;

  bool is_random_delay_;

  // Inclusive bound.
  int random_delay_lower_bound_;
  int random_delay_upper_bound_;

  int possibility_;

  bool is_invalid_;

  std::unordered_map<std::string, std::set<std::string>> tnc_tag_;

  DISALLOW_COPY_AND_ASSIGN(TCTypedAction);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_TC_TYPED_ACTION_H_
