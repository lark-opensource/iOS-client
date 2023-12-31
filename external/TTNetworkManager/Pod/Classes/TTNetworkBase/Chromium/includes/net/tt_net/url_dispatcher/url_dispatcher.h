// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_URL_DISPATCHER_H_
#define NET_TTNET_URL_DISPATCHER_URL_DISPATCHER_H_

#include <list>
#include <memory>
#include <string>

#include "base/memory/singleton.h"
#include "base/values.h"
#include "net/tt_net/route_selection/tt_server_config.h"
#include "net/tt_net/url_dispatcher/url_dispatch_action.h"

namespace net {

class URLRequest;

class URLDispatcher : public TTServerConfigObserver {
 public:
  static URLDispatcher* GetInstance();
  ~URLDispatcher() override;

  // TTServerConfigObserver overrides:
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  int Dispatch(URLRequest* request, GURL* new_url);

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_REQUEST_DELAY)
  int DelayRequest(URLRequest* request);
#endif

  void NotifyRequestCompleted(URLRequest* request, int net_error);

  int64_t dispatch_actions_epoch() const { return dispatch_actions_epoch_; }

  int64_t action_update_time() const { return action_update_time_; }

  bool dispatch_actions_empty() const { return dispatch_actions_.empty(); }

  std::string md5_config() const { return md5_config_; }

  TTServerConfigObserver::UpdateSource update_source() const { return source_; }

 private:
  friend struct base::DefaultSingletonTraits<URLDispatcher>;

  URLDispatcher();

  void ParseActionInfo(const base::DictionaryValue* action_info,
                       bool is_delay = false);

  std::list<std::unique_ptr<URLDispatchAction>> dispatch_actions_;

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_REQUEST_DELAY)
  std::list<std::unique_ptr<URLDispatchAction>> delay_actions_;
#endif

  int64_t dispatch_actions_epoch_;

  int64_t action_update_time_;

  std::string md5_config_;

  TTServerConfigObserver::UpdateSource source_;

  DISALLOW_COPY_AND_ASSIGN(URLDispatcher);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_URL_DISPATCHER_H_
