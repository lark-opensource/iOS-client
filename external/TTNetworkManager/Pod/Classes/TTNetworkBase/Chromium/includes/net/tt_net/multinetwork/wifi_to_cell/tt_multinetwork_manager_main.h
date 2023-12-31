// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_MULTINETWORK_WIFI_TO_CELL_TT_MULTINETWORK_MANAGER_MAIN_H_
#define NET_TT_NET_MULTINETWORK_WIFI_TO_CELL_TT_MULTINETWORK_MANAGER_MAIN_H_

#include "base/memory/singleton.h"
#include "base/timer/timer.h"
#include "net/tt_net/config/tt_config_manager.h"
#include "net/tt_net/multinetwork/wifi_to_cell/tt_multinetwork_manager.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"
#include "net/tt_net/net_detect/tt_network_detect_dispatched_manager.h"
#include "net/tt_net/url_request/tt_url_request_manager.h"

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
#include "base/gtest_prod_util.h"
#endif

namespace net {

// Currnetly, the multinetwork manager can be built and work only on Android
// platform.
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
using TCPConnectTransactionCreatorCallback =
    base::RepeatingCallback<tt_detect::TTNetDetectTransaction*(
        const std::string& target,
        base::WeakPtr<tt_detect::TTNetDetectTransactionCallback> callback)>;
#endif

class TTMultiNetworkManagerMain
    : public TTMultiNetworkManager,
      public EffectiveConnectionTypeObserver,
      public TTURLRequestManager::PendingRequestObserver {
 public:
  static TTMultiNetworkManagerMain* GetInstance();

  bool Init(NetworkQualityEstimator* network_quality_estimator) override;

  // After receiving a callback of OnMultiNetworkStateChanged with
  // |current_state| of STATE_WAIT_USER_ENABLE, upper layer can call
  // this method with |enable| of true to confirm network state to
  // change to STATE_WIFI_WITH_CELLULAR_TRANS_DATA. If |enable| is false,
  // network state will fallback.
  void NotifySwitchToMultiNetwork(bool enable) override;

  void OnCellularAlwaysUp(bool success);

  std::unique_ptr<base::Value> GetRequestLogBlock() const override;

  void TiggerWiFiToCellularByThirdParty() override;

#if BUILDFLAG(ENABLE_WEBSOCKETS_ON_ANDROID)
  void OnIPCMessageReceived(const Message& message) override;
#endif

 private:
  friend struct base::DefaultSingletonTraits<TTMultiNetworkManagerMain>;
  TTMultiNetworkManagerMain();
  ~TTMultiNetworkManagerMain() override;

  struct NQEResult {
    int ect;
    int64_t transport_rtt_ms;
    int64_t http_rtt_ms;
    int32_t downstream_throughput_kbps;
    NQEResult();
    ~NQEResult();
  };

  NQEResult previous_nqe_result_;

  // EffectiveConnectionTypeObserver implementation:
  void OnEffectiveConnectionTypeChanged(EffectiveConnectionType type) override;

  // TTMultiNetworkUtils::MultiNetChangeObserver implementation:
  void OnMultiNetChanged() override;

  // TTServerConfigObserver implementation:
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  // TTURLRequestManager::PendingRequestObserver implementation:
  void OnPendingRequestCountChanged(
      PendingRequestObserver::CountChange change) override;

  // If |current_state_| is WIFI_WITH_CELLULAR, start detecting network quality
  // periodly.
  void StartNetworkQualityDetect();

  void DoStopped(Event ev) override;
  void DoNoNetwork(Event ev) override;
  void DoDefaultCellularWithWiFiDown(Event ev) override;
  void DoDefaultWiFiWithCellularDown(Event ev) override;
  void DoDefaultWiFiWithCellularUp(Event ev) override;
  void DoWaitUserEnable(Event ev) override;
  void DoWaitCellularAlwaysUp(Event ev) override;
  void DoWiFiWithCellularTransData(Event ev) override;
  void DoEvaluateCellular(Event ev) override;

  void OnUpdateState() override;

  void DoStartManager();
  void DoStopManager();
  bool DoTrySwitchToWiFiWithCellularTransData();
  bool DoTrySwitchToWiFiWithCellularTransDataOnECTChanged();

  void UpdateStateByMultiNetworkUtils();

  // STATE_DEFAULT_WIFI_WITH_CELLULAR_DOWN and
  // STATE_DEFAULT_WIFI_WITH_CELLULAR_UP related.
  void OnDetectLongTermPoorNetworkTimeout();
  // STATE_WAIT_USER_ENABLE related.
  void OnWaitUserEnableTimeout();
  // STATE_WAIT_CELLULAR_ALWAYS_UP related.
  void OnWaitCellularAlwaysUpTimeout();

  // STATE_EVALUATE_CELLULAR related.
  void StartCellularEvaluateDetecting();
  void OnCellularEvaluateDetectRequestFinished(int result);
  void OnCellularEvaluateTimeout();
  void HandleCellularEvaluateResult(bool success);

  // STATE_WIFI_WITH_CELLULAR_TRANS_DATA related.
  void OnWaitWiFiDetectResultTimeout();
  // When this method is invoked, it means that the WiFi has recovered.
  void OnWiFiRecoverDetectFinished();
  // Callback for detect request.
  void OnWiFiRecoverDetectRequestFinish(int result);
  void StartWiFiRecoverDetecting();

  void SaveNQEResultBeforeStateChange();
  void CleanUpNQEResult() const;
  void CleanUpNQEResultLater() const;

  // Calling this is meaningful only when |current_state_| is
  // STATE_DEFAULT_WIFI_WITH_CELLULAR_DOWN or
  // STATE_DEFAULT_WIFI_WITH_CELLULAR_UP.
  void ActivateWithECTChangedEvent();

#if BUILDFLAG(ENABLE_WEBSOCKETS_ON_ANDROID)
  void NotifySubProcessesOfCurrentState();
#endif

  // Number of times that state swiches to STATE_NETWORK_WITH_CELLULAR.
  int wifi_with_cellular_cnt_;
  bool cell_eval_failed_report_;

  NetworkQualityEstimator* network_quality_estimator_;
  // ECT of current notification.
  NqeConfig::NetworkQualityType current_ect_;

  base::TimeDelta wait_cellular_always_up_timeout_;
  base::TimeDelta wait_user_enable_timeout_;

  // STATE_DEFAULT_WIFI_WITH_CELLULAR_UP related timer
  base::OneShotTimer long_term_poor_net_detect_timer_;
  // STATE_WAIT_CELLULAR_ALWAYS_UP related timer
  base::OneShotTimer wait_cellular_always_up_timer_;
  // STATE_EVALUATE_CELLULAR related timer
  base::OneShotTimer cellular_evaluate_timer_;
  // STATE_WAIT_USER_ENABLE related timer
  base::OneShotTimer wait_user_enable_timer_;
  // STATE_WIFI_WITH_CELLULAR_TRANS_DATA related timer
  base::OneShotTimer wifi_recover_trigger_timer_;

  // WiFi Network Quality detect reply timer.
  base::OneShotTimer wifi_detect_reply_timer_;
  base::OneShotTimer wifi_detect_interval_timer_;

  bool always_up_cellular_result_success_;
  // Whether the mobile Cellular is always upped.
  // If not, we need call OS API to make Cellular always upped.
  // Otherwise, the Cellular will shutdown when mobile accesses into WiFi.
  // We need do this only once in APP life cycle.
  bool cellular_always_upped_;
  // If WiFi to Cellular is triggerd by outer, don't check if there is pending
  // request after cellular is activated.
  bool wait_cell_up_state_triggered_by_outer_;
  // Upper layer requests for WiFi to Cellular, such as Media Player SDK
  // indirectly triggers within APP's calling TTNet's API.
  bool outer_requests_wifi_to_cell_;

  // True if cellular has a good network quality.
  bool cellular_evaluate_result_;
  // How many times we have evaluated cell before succeed.
  uint32_t cell_evaluate_times_;

  bool user_enabled_result_;

  std::vector<std::unique_ptr<TTNetworkDetectDispatchedManager::Request>>
      cellular_evaluate_detect_requests_;

  std::vector<std::unique_ptr<TTNetworkDetectDispatchedManager::Request>>
      wifi_recover_detect_requests_;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  void DeinitForTesting() override;

  void SetCellularAlwaysUpResultForTesting(bool result) {
    cellular_always_upped_ = result;
  }

  void SetRecoverTransCreatorForTesting(
      TCPConnectTransactionCreatorCallback func) {
    recover_trans_creator_func_ = func;
  }

 private:
  friend class TTMultiNetworkManagerMainTest;
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkManagerMainTest, ParseServerConfig);
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkManagerMainTest, ServerConfigChange);
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkManagerMainTest, ECTChangePoorNetwork);
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkManagerMainTest,
                           CellularAlwaysUpFailed);
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkManagerMainTest,
                           UserNotifySwitchToMultinetwork);
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkManagerMainTest, WiFiRecover);
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkManagerMainTest,
                           ResolveSocketViaCellular);
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkManagerMainTest, ResendRequest);
  FRIEND_TEST_ALL_PREFIXES(TTMultiNetworkManagerMainTest, CollectNQEResult);

  void ResetMemberVariablesForTesting() override;

  struct TNCConfig& GetTncConfigForTesting() {
    return tnc_config_;
  }

  struct NQEResult& GetNEQResultForTesting() {
    return previous_nqe_result_;
  }

  TCPConnectTransactionCreatorCallback recover_trans_creator_func_;
#endif

  DISALLOW_COPY_AND_ASSIGN(TTMultiNetworkManagerMain);
};

}  // namespace net

#endif