// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_HISTORY_BASED_DISPATCH_STRATEGY_H_
#define NET_TTNET_URL_DISPATCHER_HISTORY_BASED_DISPATCH_STRATEGY_H_

#include <deque>
#include <set>
#include <string>

#include "net/tt_net/url_dispatcher/dispatch_strategy.h"

namespace net {

class HistoryBasedDispatchStrategy : public DispatchStrategy {
 public:
  enum RequestResult {
    REQUEST_END_WITH_SUCCESS = 1,
    REQUEST_NOT_USE = 0,
    REQUEST_END_WITH_FAILURE = -1,
  };

  using HistoryLog = std::deque<RequestResult>;

  class RequestResultHistoryObserver {
   public:
    RequestResultHistoryObserver();
    virtual ~RequestResultHistoryObserver();

    virtual void OnSampleAddedToHistory(const std::string& host,
                                        RequestResult result) = 0;
  };

  HistoryBasedDispatchStrategy(const base::DictionaryValue* strategy_info);
  ~HistoryBasedDispatchStrategy() override;

  void RegisterRequestResultHistoryObserver(
      RequestResultHistoryObserver* observer);

  const HistoryLog* GetHistoryLogForHost(const std::string& host);

  // DispatchStrategy implementations:
  bool NeedRequestResultFeedback() override;

  void NotifyRequestResult(const GURL& target_url,
                           int net_error,
                           int code) override;

  int preserved_history_length() const { return preserved_history_length_; }

 protected:
  // Request ends with failure if response code in |error_code| list.
  std::set<int> error_code_;

  // If |use_default_host_| is true and original host in "target_hosts" config,
  // use original host as first attempt host to replace.
  // Otherwise use first one host in "target_hosts" config to replace.
  bool use_default_host_{true};

 private:
  void AddSampleToHistoryLog(HistoryLog* log,
                             const std::string& host,
                             RequestResult result);

  // Recent usage result of this service will be stored in the history log per
  // host.
  std::map<std::string, HistoryLog*> host_log_;

  int preserved_history_length_;

  RequestResultHistoryObserver* history_observer_;

  DISALLOW_COPY_AND_ASSIGN(HistoryBasedDispatchStrategy);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_HISTORY_BASED_DISPATCH_STRATEGY_H_
