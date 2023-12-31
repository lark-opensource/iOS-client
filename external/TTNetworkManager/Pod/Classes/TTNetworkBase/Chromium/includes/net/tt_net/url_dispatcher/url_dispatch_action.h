// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_URL_DISPATCH_ACTION_H_
#define NET_TTNET_URL_DISPATCHER_URL_DISPATCH_ACTION_H_

#include <memory>
#include <regex>

#include "base/time/time.h"
#include "base/values.h"
#include "net/url_request/url_request.h"
#include "url/gurl.h"

namespace net {

enum DispatchResult {
  DISPATCH_NONE = 0,
  DISPATCH_HIT,
  DISPATCH_DROP,
  DISPATCH_DELAY
};

class URLDispatchAction {
 public:
  static std::unique_ptr<URLDispatchAction> Factory(
      const std::string& action_name,
      int priority,
      const base::DictionaryValue* param,
      const int rule_id,
      base::Time lifetime_begin,
      base::Time lifetime_end,
      const std::set<std::string>& supported_methods,
      int set_req_priority,
      const std::string& sign,
      const int64_t epoch);

  URLDispatchAction(int priority, const std::string& sign);
  virtual ~URLDispatchAction();

  DispatchResult TakeAction(const GURL& origin_url,
                            GURL* new_url,
                            URLRequest* request);

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_REQUEST_DELAY)
  static std::unique_ptr<URLDispatchAction> Factory(
      int priority,
      const base::DictionaryValue* param,
      base::Time lifetime_begin,
      base::Time lifetime_end);

  int TakeDelayAction(const GURL& origin_url, URLRequest* request);
#endif

  void NotifyRequestComplete(const GURL& replace_url, int net_error, int code);

  void InitWithActionParam(const base::DictionaryValue* param,
                           const std::string& sign,
                           const int64_t epoch);

  // Optional settings:
  void SetRuleId(int rule_id);
  void SetLifeCycle(base::Time begin, base::Time end);
  void SetSupportedRequestMethods(
      const std::set<std::string>& supported_methods);
  void ToSetRequestPriority(int set_req_priority);

  unsigned int priority() const { return priority_; }

  std::string sign() const { return sign_; }

  int RuleId() const { return rule_id_; }

  bool NeedRequestResultFeedback() const {
    return need_request_result_feedback_;
  }

  std::string GetServiceName() const { return service_name_; }

 protected:
  virtual void LoadActionParam(const base::DictionaryValue* param,
                               const std::string& sign,
                               const int64_t epoch,
                               bool& need_request_result_feedback) = 0;

  virtual DispatchResult Dispatch(const GURL& origin_url,
                                  GURL* new_url,
                                  URLRequest* request) = 0;

  virtual int GetDispatchStrategyType() const = 0;

  virtual void OnRequestCompleted(const GURL& replace_url, int net_error, int code) = 0;

  virtual void LoadMatchRules(const base::DictionaryValue* param);

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_REQUEST_DELAY)
  virtual int DispatchDelay(const GURL& origin_url, URLRequest* request);
#endif

  // Define five URL match rules of request:
  // ----------------------------------------------------
  // 1. First check if the domain of url is in |host_group_|,
  // if hit execute 2, otherwise return false.
  // ----------------------------------------------------
  // 2. Next check if the the path of URL is in |equal_group_|,
  // or match |prefix_group_|, |contain_group_|, or |pattern_group_|.
  // if hit return true, otherwise execute 3.
  // ----------------------------------------------------
  // 3. Finally check if the whole URL match the |full_url_group_|.
  // if hit return true, otherwise return false.
  // ----------------------------------------------------
  // Efficiency ranking: equal > prefix > contain > pattern > full url match.
  virtual bool IsMatchedRules(const GURL& url);

  std::vector<std::string> host_group_;
  std::set<std::string> equal_group_;
  std::vector<std::string> prefix_group_;
  std::vector<std::string> contain_group_;
  std::vector<std::regex> pattern_group_;
  std::vector<std::regex> full_url_group_;

  // To improve the efficiency of regular matching,
  // |path_contain_| is cooperated with |full_url_group_|.
  // It will not get into regular matching with |full_url_group_|,
  // if path of URL doesn't contain |path_contain_| string,
  std::set<std::string> path_contain_;

  std::string service_name_;

  // Add "X-SS-TC" request header if url match the dispatch action
  // and |add_tc_header_| set to true.
  bool add_tc_header_{false};

 private:
  bool IsActionEffective(const URLRequest* request);

  DispatchResult DoDispatch(const GURL& origin_url,
                            GURL* new_url,
                            URLRequest* request);

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_REQUEST_DELAY)
  int DoDispatchDelay(const GURL& origin_url, URLRequest* request);
#endif

  unsigned int priority_;

  std::string sign_;

  int rule_id_;

  base::Time lifetime_begin_;
  base::Time lifetime_end_;

  std::set<std::string> supported_methods_;

  unsigned int set_req_priority_;

  bool need_request_result_feedback_;

  DISALLOW_COPY_AND_ASSIGN(URLDispatchAction);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_URL_DISPATCH_ACTION_H_
