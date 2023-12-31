// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_MULTINETWORK_WIFI_TO_CELL_TT_MULTINETWORK_MANAGER_H_
#define NET_TT_NET_MULTINETWORK_WIFI_TO_CELL_TT_MULTINETWORK_MANAGER_H_

#include <unordered_set>
#include "base/task/common/checked_lock.h"
#include "net/base/address_family.h"
#include "net/base/net_export.h"
#include "net/nqe/network_quality_estimator.h"
#include "net/tt_net/config/tt_config_manager.h"
#include "net/tt_net/config/tt_init_config.h"
#include "net/tt_net/multinetwork/utils/tt_multinetwork_utils.h"
#include "net/tt_net/multinetwork/wifi_to_cell/tt_multinetwork_manager_base.h"
#include "net/tt_net/route_selection/tt_server_config.h"

#if BUILDFLAG(ENABLE_WEBSOCKETS_ON_ANDROID)
#include "net/tt_net/ipc/ipc_message.h"
#endif

namespace net {
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
using MockChannelSendCallback = base::RepeatingCallback<void(Message* message)>;
#endif

class NET_EXPORT_PRIVATE TTMultiNetworkManager
    : public TTMultiNetworkManagerBase,
      public TTServerConfigObserver {
 public:
  class NET_EXPORT_PRIVATE StateChangeObserver {
   public:
    virtual void OnMultiNetworkStateChanged(State previous_state,
                                            State current_state) = 0;

   protected:
    StateChangeObserver() {}
    virtual ~StateChangeObserver() {}
  };

  static TTMultiNetworkManager* GetInstance();

  void AddStateChangeObserver(StateChangeObserver* observer);
  void RemoveStateChangeObserver(StateChangeObserver* observer);

  virtual bool Init(NetworkQualityEstimator* network_quality_estimator);

  // After receiving a callback of OnMultiNetworkStateChanged with
  // |current_state| of STATE_WAIT_USER_ENABLE, upper layer can call
  // this method with |enable| of true to confirm network state to
  // change to STATE_WIFI_WITH_CELLULAR_TRANS_DATA. If |enable| is false,
  // network state will fallback.
  virtual void NotifySwitchToMultiNetwork(bool enable);

#if BUILDFLAG(ENABLE_WEBSOCKETS_ON_ANDROID)
  virtual void OnIPCMessageReceived(const Message& message);
#endif

  // For request log.
  virtual std::unique_ptr<base::Value> GetRequestLogBlock() const = 0;

  // For NQE constructing network_id object.
  NetworkChangeNotifier::ConnectionType GetConnectionType() const;

  bool ConfigEnable() const {
    return tnc_config_.enable.load(std::memory_order_relaxed);
  }

  bool ShouldForceUseCellular() const;

  // By calling NetworkChangeNotifier::NotifyObserversOfIPAddressChange will
  // resulting ERR_NETWORK_CHANGED(21) for each ongoing request. By using this
  // net_error code and filtering the path, we can resend the specified
  // requests. Of course, only failed request with ERR_NETWORK_CHANGED that
  // caused by entering or leaving STATE_WIFI_WITH_CELLULAR_TRANS_DATA should be
  // resend.
  virtual bool ShouldResendRequest(const std::string& path,
                                   int net_error) const;

  // For proxy bypass.
  virtual bool CanUseProxy(bool is_ttnet_tunnel) const;

  virtual void TiggerWiFiToCellularByThirdParty();

  TTMultiNetworkManager();
  ~TTMultiNetworkManager() override;

 protected:
  // The manager FSM state.
  State current_state_;
  // Maybe upper layer needs previous state to know that state leaves from
  // WIFI_WITH_CELLULAR.
  State previous_state_;

  struct TNCConfig {
    std::atomic<bool> enable;

    bool auto_switch;

    std::unordered_set<std::string> retry_paths_filter;

    bool evaluate_cell_enable;
    struct {
      int poor_net_level;
      int64_t trigger_window_ms;
      // If the RTT of evalulating cellular is less than
      // |cellular_rtt_threshold_ms|, it means that the
      // cellular network is good enough and we can consider
      // using it.
      int64_t cellular_rtt_threshold_ms;
      int64_t cell_evaluate_delay_multiplier_ms;
      std::set<std::string> cellular_evaluate_hosts;
    } wifi_to_cellular_config;

    struct {
      // WARNING:
      // Currently DNS Cache is not seperate to Cellular and WiFi independently,
      // detect_target_hosts SHOULD NOT use hosts that APP is using.
      std::set<std::string> detect_target_hosts;
      int64_t detect_interval_ms;
      int64_t recover_rtt_threshold_ms;
      int64_t trigger_window_ms;
    } cellular_to_wifi_config;

    TNCConfig();
    TNCConfig(const TNCConfig& other);
    ~TNCConfig();
    TNCConfig& operator=(const TNCConfig& other);
  };

  TNCConfig tnc_config_;

  base::ObserverList<StateChangeObserver>::Unchecked
      state_change_observer_list_;

  TTMultiNetworkUtils* utils_;  // Singleton

  bool initialized_;

  URLRequestContextGetter* context_getter_;

  void ReadTNCConfigFromCache();

  void CleanUpAllConnectionResources() const;

  void NotifyObserversOfCurrentState() const;

  void UpdateState(State new_state);

  void DoLoop(Event ev) override;

  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);

 private:

  // Called by UpdateState().
  virtual void OnUpdateState() = 0;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  friend class TTMultiNetworkManagerMainTest;
  friend class TTMultiNetworkManagerSubTest;
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkManagerMainTest, ParseServerConfig);
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkManagerMainTest, EvaluateCellular);
  virtual void DeinitForTesting();

  void SetMockChannelSendCallbackForTesting(MockChannelSendCallback callback) {
    mock_channel_send_callback_ = callback;
  }

  State GetCurrentStateForTesting() const { return current_state_; }

  State GetPreviousStateForTesting() const { return previous_state_; }

  void SetMultiNetworkUtilsForTesting(TTMultiNetworkUtils* utils) {
    utils_ = utils;
  }

 protected:
  virtual void ResetMemberVariablesForTesting();

  MockChannelSendCallback mock_channel_send_callback_;
#endif
};

}  // namespace net

#endif
