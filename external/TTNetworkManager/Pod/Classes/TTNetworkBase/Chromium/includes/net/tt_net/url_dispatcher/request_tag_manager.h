// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_REQUEST_TAG_MANAGER_H_
#define NET_TTNET_URL_DISPATCHER_REQUEST_TAG_MANAGER_H_

#include "base/power_monitor/power_observer.h"
#include "net/tt_net/route_selection/tt_server_config.h"

namespace net {

class URLRequest;

class RequestTagManager : public TTServerConfigObserver,
                          public base::PowerObserver {
 public:
  static RequestTagManager* GetInstance();
  ~RequestTagManager() override;

  enum AppInitialState {
    NormalStart = -1,
    ColdStart = 0,
    HotStart = 1,
    WarmStart = 2,
    LastState = WarmStart,
  };

  void AddRequestTag(URLRequest* request);

  // Match tnc and request tag to drop request, refer to feishu
  // /docs/doccndZolMLPNkoT8zOMANbXyhd.
  // exp1: "req tag":"n=0;s=0;t=0;p=0","tnc tag":"s=0,s=1;t=0;n=0",drop:1
  // exp2: "req tag":"s=1;n=0;f=0","tnc tag":"s=0,s=1,s=2;n=0;f=0",drop:1
  // exp3: "req tag":"n=0;s=0;t=0","tnc tag":"s=0;t=0;n=1",drop:0
  using TNCTagMap = std::unordered_map<std::string, std::set<std::string>>;
  using RequestTagMap = std::unordered_map<std::string, std::string>;
  bool MatchTagAndDropRequest(const RequestTagMap& request_tag,
                              const TNCTagMap& tnc_tag) const;

  void SetAppStartUpState(int state);

  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  // base::PowerObserver methods:
  void OnPowerStateChange(bool on_battery_power) override {}
  void OnSuspend() override {}
  void OnResume() override;
  std::string GetAppStateTagString();

 private:
  friend struct base::DefaultSingletonTraits<RequestTagManager>;
  RequestTagManager();

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  FRIEND_TEST_ALL_PREFIXES(RequestTagManagerTest, GetCurrentAppStateTest);
  FRIEND_TEST_ALL_PREFIXES(RequestTagManagerTest, MatchTagAndDropRequestTest);
  FRIEND_TEST_ALL_PREFIXES(RequestTagManagerTest, DispachRequestTagDropTest);
  FRIEND_TEST_ALL_PREFIXES(RequestTagManagerTest, AddRequestTagTest);

  void SetAppStateDeltaTimeForTesting(base::TimeDelta delta) {
    app_state_change_time_ -= delta;
  }
#endif

  AppInitialState GetCurrentAppState();

  int64_t cold_start_duration_seconds_{60};
  int64_t hot_start_duration_seconds_{60};
  int64_t warm_start_duration_seconds_{60};

  bool request_tag_enabled_{false};

  base::TimeTicks app_state_change_time_;
  AppInitialState app_state_{NormalStart};

  DISALLOW_COPY_AND_ASSIGN(RequestTagManager);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_REQUEST_TAG_MANAGER_H_
