// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_MULTINETWORK_UTILS_TT_MULTINETWORK_STATE_WATCHER_H_
#define NET_TT_NET_MULTINETWORK_UTILS_TT_MULTINETWORK_STATE_WATCHER_H_

#include "base/memory/singleton.h"
#include "base/observer_list.h"
#include "base/task/common/checked_lock.h"
#include "base/timer/timer.h"
#include "net/base/address_family.h"
#include "net/tt_net/multinetwork/utils/tt_multinetwork_state_watcher_base.h"
#include "net/tt_net/multinetwork/utils/tt_multinetwork_utils.h"
#include "net/tt_net/route_selection/tt_server_config.h"

namespace net {

class NET_EXPORT_PRIVATE TTMultiNetworkStateWatcher
    : public TTMultiNetworkStateWatcherBase,
      public TTMultiNetworkUtils::MultiNetChangeObserver,
      public TTServerConfigObserver {
 public:
  struct TNCConfig {
    TNCConfig();
    ~TNCConfig();
    TNCConfig(const TNCConfig& other);
    bool enable_user_ctl{false};
    std::set<std::string> preconnect_urls;
    std::set<int> fallback_resend_errors;
  };

  const TNCConfig& tnc_config() const { return tnc_config_; }

  static TTMultiNetworkStateWatcher* GetInstance();

  State GetCurrentState() const;

  void AddMultiNetStateObserver(MultiNetStateObserver* observer) override;

  void RemoveMultiNetStateObserver(MultiNetStateObserver* observer) override;

  void StartWatcher() override;

  // If we have definitely known that the device doesn't support multi-network,
  // return false, and return true otherwise. This means that if cellular has
  // been activated, or cellular is down, it also returns true.
  // Caller should wait for |OnStateChaned| callback to know whether cellular
  // is activated successfully. If so, |prev_state| will be
  // |STATE_WAIT_CELLULAR_ALWAYS_UP| and |curr_state| will be
  // |STATE_DEFAULT_WIFI_WITH_CELLULAR_UP|.
  bool TryActivatingCellular() override;

  int GetUnsupportedReason() const override;

  void ResetUnsupportedReason() override;

  bool AreBothWiFiAndCellOn() const;

  // If the request is sent by alternative network and encounters specified net
  // errors, such as -190, resend it by default network.
  bool ShouldFallbackResendForMultiNetworkError(int net_error) const;

  bool ShouldPreconnect(const std::string& url) const;

  std::unique_ptr<base::Value> GetRequestLogBlock() const;

 private:
  friend struct base::DefaultSingletonTraits<TTMultiNetworkStateWatcher>;

  enum Event {
    EVENT_ON_TRIGGER_START = 0,
    EVENT_ON_TRIGGER_STOP = 1,
    EVENT_ON_NETWORK_CHANGED = 2,
    EVENT_ON_ACTIVATE_CELLULAR = 3,
    EVENT_ON_CELLULAR_ALWAYS_UP_RESULT = 4,
    EVENT_ON_WAIT_CELLULAR_ALWAYS_UP_TIMEOUT = 5,
    EVENT_COUNT,
  };

  class StateRecorder {
   public:
    StateRecorder();
    ~StateRecorder();
    void UpdateCurrentState(State state);

    State current() const;

    State previous() const;

    State pre_previous() const;

    void Reset();

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
    void SetPrePreviousStateForTesting(State state);

    void SetPreviousStateForTesting(State state);

    void SetCurrentStateForTesting(State state);
#endif

   private:
    std::deque<State> states_;
  };

  TTMultiNetworkStateWatcher();
  ~TTMultiNetworkStateWatcher() override;

  void DoLoop(Event ev);
  void DoStopped(Event ev);
  void DoNoNetwork(Event ev);
  void DoDefaultCellularWithWiFiDown(Event ev);
  void DoDefaultWiFiWithCellularDown(Event ev);
  void DoDefaultWiFiWithCellularUp(Event ev);
  void DoWaitCellularAlwaysUp(Event ev);
  void DoDefaultVpnOn(Event ev);

  void DoStartManager();
  void ReadTNCConfigFromCache();
  void DoStopManager();
  void UpdateStateByMultiNetworkDelegate();
  void UpdateState(State new_state);
  void OnUpdateState();
  bool ActivateCellular();

  void OnCellularAlwaysUp(bool success);

  void NotifyObserversOfCurrentState();
  void NotifyObserversOfCurrentStateIfPresent(
      MultiNetStateObserver* observer) const;
  void NotifyObserversOfUserSpecifyingNetworkEnabled(bool enable) const;

  // STATE_WAIT_CELLULAR_ALWAYS_UP related.
  void OnWaitCellularAlwaysUpTimeout();

  // TTMultiNetworkUtils::NetworkChangeObserver implementation:
  void OnMultiNetChanged() override;

  // TTServerConfigObserver implementation:
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);

  TNCConfig tnc_config_;

  State prev_state_to_notify_;
  State curr_state_to_notify_;
  // Record continuous three states to current state.
  StateRecorder state_recorder_;

  bool always_up_cellular_result_;
  bool activating_cell_req_pending_;
  // There is perhaps no underlying alternative network when attempting to
  // activate Cellular. Cache activating request and send the request when
  // alternative network is ready.
  bool has_activating_cell_request_{false};
  base::TimeDelta wait_cellular_always_up_timeout_;
  base::OneShotTimer wait_cellular_always_up_timer_;
  base::TimeTicks cell_activate_start_;
  base::TimeDelta cell_activate_duration_;

  TTMultiNetworkUtils* utils_;  // Singleton

  base::ObserverList<MultiNetStateObserver>::Unchecked state_observer_list_;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  void SetMultiNetworkUtilsForTesting(TTMultiNetworkUtils* utils) {
    utils_ = utils;
  }

  void DeinitForTesting();

  void ResetMemberVariablesForTesting();

  void SetPrePreviousStateForTesting(State state);

  void SetPreviousStateForTesting(State state);

  void SetCurrentStateForTesting(State state);

  void StopWatcherForTesting() override;

 private:
  friend class TTMultiNetworkStateWatcherTest;
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkStateWatcherTest, ParseServerConfig);
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkStateWatcherTest,
                           ActivateCell_OnTNCConfigChanged);
  FRIEND_TEST_ALL_PREFIXES(ConnectionManagerTest, AlternativeNetworkPreconnect);

  bool cellular_always_upped_for_testing_{false};
#endif

  DISALLOW_COPY_AND_ASSIGN(TTMultiNetworkStateWatcher);
};

}  // namespace net

#endif