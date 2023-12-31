// Copyright (c) 2019 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_ROUTE_SELECTION_MANAGER_H_
#define NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_ROUTE_SELECTION_MANAGER_H_

#include <memory>

#include "base/memory/singleton.h"
#include "base/time/time.h"
#include "net/tt_net/config/tt_config_manager.h"
#include "net/tt_net/url_dispatcher/route_selection/route_selection_group.h"

namespace net {

class RouteSelectionManager : public NetworkChangeNotifier::IPAddressObserver,
                              public base::PowerObserver {
 public:
  static RouteSelectionManager* GetInstance();
  ~RouteSelectionManager() override;

  enum RouteSelectionSource {
    // 0-100 reserved for TTServerConfigObserver::UpdateSource
    NETWORK_CHANGED = 100,
    FEEDBACK_ERROR,
    IES_TIMING_POLL,
    DSA_TIMING_POLL,
  };

  // Return a unique id for caller to retrieve route selection result of a
  // particular group.
  int RegisterRouteSelectionGroup(std::unique_ptr<RouteSelectionGroup> group);

  const url::SchemeHostPort GetBestTargetWithGroupId(int group_id);

  void SetBestHostWithRouteSelectionName(const std::string& host,
                                         const std::string& rs_name);
  void NotifyGroupRequestFailure(int group_id);

  void StartWorking(TTServerConfigObserver::UpdateSource source);
  void StopWorking();

  bool HasStartedBefore() const { return has_started_; }

  void ClearExpiredCacheFromFile(int64_t epoch);

  // NetworkChangeObserver overrides:
  void OnIPAddressChanged() override;

  // PowerObserver overrides:
  void OnSuspend() override;
  void OnResume() override;

#if defined(OS_ANDROID) && BUILDFLAG(ENABLE_WEBSOCKETS)
  // If the group failed to select route, this magic string will be filled
  // and update to other process. This magic string will occupy one slot
  // to represent corresponding group in other process.
  const std::string FailureMagic() const { return "FailToSelect"; }

  // |UpdateBestHostInOtherProcess| is only executed in main process, best host
  // in other process need to be updated by IPC channel from main process.
  void UpdateBestHostInOtherProcess(const std::string& best_host,
                                    int group_id,
                                    int64_t epoch);
#endif

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  void SetMainProcessForTesting();
  RouteTestResultTable* GetRouteTestResultTable();
  void SetHasStartedBefore(bool enabled) { has_started_ = enabled; }
#endif

  void SetHasDsaGroup(bool has_dsa_group) { has_dsa_group_ = has_dsa_group; }

 private:
  friend struct base::DefaultSingletonTraits<RouteSelectionManager>;

  RouteSelectionManager();

  void StartRouteSelectionInternal(base::TimeDelta delay,
                                   int source,
                                   bool clear = true);

  void DoRouteSelectJobForNextGroup(int rv);

  bool IsCacheExpiredOrInvalid(const std::string& key,
                               const std::string& value) const;

  const NetConfig* config_;

  int route_selection_group_index_;

  std::vector<std::unique_ptr<RouteSelectionGroup>> route_selection_groups_;

  base::RepeatingTimer ies_period_trigger_timer_;

  base::RepeatingTimer dsa_period_trigger_timer_;

  bool pending_network_change_signal_;

  bool pending_ies_poll_signal_{false};

  bool pending_dsa_poll_signal_{false};

  bool route_selection_in_progress_;

  base::TimeTicks last_ies_poll_route_selection_timeticks_;

  base::TimeTicks last_dsa_poll_route_selection_timeticks_;

  std::unique_ptr<RouteTestResultTable> route_test_result_;

  bool is_main_process_{true};

  bool has_started_{false};

  bool has_added_observer_;

  int64_t dispatch_epoch_{-1};

  int route_selection_source_{-1};

  bool has_dsa_group_{false};

  DISALLOW_COPY_AND_ASSIGN(RouteSelectionManager);
};

}  // namespace net

#endif  // NET_TTNET_URL_DISPATCHER_ROUTE_SELECTION_ROUTE_SELECTION_MANAGER_H_
