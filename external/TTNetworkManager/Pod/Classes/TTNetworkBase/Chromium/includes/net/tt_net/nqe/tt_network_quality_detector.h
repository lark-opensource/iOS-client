// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_NETWORK_QUALITY_DETECTOR_H_
#define NET_TT_NET_NQE_TT_NETWORK_QUALITY_DETECTOR_H_

#include "base/memory/singleton.h"
#include "base/power_monitor/power_observer.h"
#include "base/timer/timer.h"
#include "net/net_buildflags.h"
#include "net/nqe/network_quality_estimator.h"
#include "net/tt_net/config/tt_config_manager.h"
#include "net/tt_net/net_detect/tt_network_detect_dispatched_manager.h"
#include "net/tt_net/route_selection/tt_server_config.h"

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NQE_SUPPORT)

namespace net {

// TTNetworkQualityDetector is used to detect fake network, as well as
// compute |NetworkQualityType| which is more precise than
// |EffectiveConnectionType| and can be controlled by TNC.
// TTNetworkQualityDetector is supplementary of |NetworkQualityEstimator| to
// meet extra NQE requirement.
class TTNetworkQualityDetector : public TTServerConfigObserver,
                                 public base::PowerObserver {
 public:
  ~TTNetworkQualityDetector() override;

  static TTNetworkQualityDetector* GetInstance();

  class FakeNetworkStateObserver {
   public:
    virtual void OnNetworkQualityTypeChanged(
        NqeConfig::NetworkQualityType nqt) = 0;

   protected:
    virtual ~FakeNetworkStateObserver() {}
  };

  // Initialize fake network detector and start detect timer if detect is
  // enabled.
  // Note: Should init after PowerMonitor::Initialize finished.
  bool Init(NetworkQualityEstimator* network_quality_estimator,
            bool is_main_process);

  void OnSocketConnectOrReadComplete();

  // When |NetworkQualityEstimator| finishes rtt or throughput computing,
  // it should call this method to compute |NetworkQualityType| which is more
  // precise than ECT and whose standard is controlled by TNC.
  // But if it is fake network right now, don't notify until fake network
  // is recoverd by net detecting or socket events;
  void MaybeComputeAndNotifyNetworkQualityType(
      const base::TimeDelta& http_rtt,
      const base::TimeDelta& transport_rtt,
      const int32_t downstream_throughput_kbps);

  NqeConfig::NetworkQualityType GetNetQualityType() const {
    return current_net_quality_type_;
  }

  bool HasInited() const;

  void AddFakeNetworkStateObserver(FakeNetworkStateObserver* observer);

  void RemoveFakeNetworkStateObserver(FakeNetworkStateObserver* observer);

 private:
  friend struct base::DefaultSingletonTraits<TTNetworkQualityDetector>;

  enum DetectType {
    INVALID = 0,
    PING = (1 << 0),
    TCP_CONNECT = (1 << 1),
    HTTP_GET = (1 << 2),
    ALL = PING | TCP_CONNECT | HTTP_GET,
  };

  struct TNCConfig {
    // Determine whether to detect fake network.
    bool detect_enable;
    // Within time windows of |detect_timeout_ms|, if there is no socket connect
    // or socket read event, detect network. Unit: Millisecond.
    int detect_timeout_ms;
    // What strategies will be used to detect network. These strategies will
    // be used concurrently.
    int detect_types;
    // Within |detect_result_timeout_ms|, if there is no detect reply, set ECT
    // to NETWORK_QUALITY_TYPE_FAKE. Unit: Millisecond.
    int detect_result_timeout_ms;
    // If true, subprocess will also detect fake network.
    bool sub_process_detect;
    // Network detect target hosts.
    std::vector<std::string> detect_targets;

    TNCConfig();
    TNCConfig(const TNCConfig& other);
    ~TNCConfig();
  };

  TTNetworkQualityDetector();

  // If there is any detect transaction getting reply, stop remaining
  // requests and change net quality type according rtt samples of
  // |NetworkQualityEstimator|.
  void OnDetectRequestFinish(
      base::WeakPtr<TTNetworkDetectDispatchedManager::Request> request_weak_ptr,
      int result);

  void ReadTNCConfigFromCache();

  // TTServerConfigObserver implementation:
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  // base::PowerObserver implementation:
  // When entering background, stop detector.
  void OnSuspend() override;
  // When back to foreground, restart detector.
  void OnResume() override;

  bool HasOngoingTransaction() const;

  bool HasPendingRequest() const;

  // Try to start detect when detect timer is timeout.
  void OnDetectTimeout();

  void OnDetectResultTimeout();

  void DoNetDetect();

  void StopAndClearTransactions();

  // Try starting |detect_timer_| according to |tnc_config_.detect_enable|.
  void TryStartDetectTimer();

  // Reset detect timer and stop ongoing requests if any.
  // (1) If there is socket connect or read event, reset detect timer.
  // (2) If a detect transaction gets result
  // (3) or all requests are timeout, reset detect timer.
  void ResetDetector(bool stop = false);

  bool CanDetermineFakeNetworkByRTTSample();

  // The detector is currently working. It means that the |detect_timer_| is
  // running or there are ongoing requests;
  bool IsWorking() const;

  void NotifyFakeNetworkQualityType();

  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);

  void ComputeAndNotifyNetworkQualityType(
      const base::TimeDelta& http_rtt,
      const base::TimeDelta& transport_rtt,
      const int32_t downstream_throughput_kbps,
      bool recover_state);

  // Only network detecting or socket events can recover NQT from fake network
  // state to normal state.
  void RecoverNetworkQualityType();

  int CaculateNetworkQualityType(const int64_t http_rtt,
                                 const int64_t tcp_rtt,
                                 const int32_t throughput);

  void NotifyNQTIfObserverPresent(FakeNetworkStateObserver* observer);
  void NotifyObserversOfNQT();

  // Detector has been inited or not. It can only be inited once.
  bool initialized_;

  bool is_main_process_;

  // Configures controlled by TNC.
  TNCConfig tnc_config_;

  // List of requests detecting fake network concurrently.
  std::vector<std::unique_ptr<TTNetworkDetectDispatchedManager::Request>>
      detect_requests_;

  // If |detect_timer_| times out, it means that there is no socket connect or
  // read event in the time window of |detect_timeout_ms|. Network detect should
  // start.
  base::OneShotTimer detect_timer_;

  // If |result_timer_| timesout, it means that all detect requests get no
  // reply within the period of |detect_result_timeout_ms|.
  base::OneShotTimer result_timer_;

  base::TimeTicks last_socket_update_;

  NqeConfig::NetworkQualityType current_net_quality_type_;

  // Network state before it changes to offline state. If it was fake network
  // state, we should try a detect after the state changes from offline state.
  NqeConfig::NetworkQualityType type_before_offline_type_;

  // If this is true, it means that the current network type is offline state
  // and the previous one is fake, and we should detect firstly to determine
  // whether it is still fake state network while network state changes from
  // offline state.
  bool offline_recover_detecting_;

  NetworkQualityEstimator* network_quality_estimator_;

  URLRequestContextGetter* context_getter_;

  base::ObserverList<FakeNetworkStateObserver>::Unchecked observer_list_;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  bool CanDoNetDetect() const;

  void SetNetworkQualityTypeForTesting(NqeConfig::NetworkQualityType type) {
    current_net_quality_type_ = type;
  }

  void SetHasInitedForTesting(bool initialized) { initialized_ = initialized; }

  void DeinitForTesting();

  struct TNCConfig& GetTncConfigForTesting() {
    return tnc_config_;
  }

  void SetIsMainProcessForTesting(bool is_main_process) {
    is_main_process_ = is_main_process;
  }

 private:
  friend class TTNetworkQualityDetectorTest;
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityDetectorTest, ParseServerConfig);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityDetectorTest, TNCEnableAndDisable);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityDetectorTest, 100Transactions);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityDetectorTest, PingDetect);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityDetectorTest, TCPConnectDetect);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityDetectorTest, Suspend);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityDetectorTest, SubProcess_NotWork);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityDetectorTest, SubProcess_Work);

#endif

  DISALLOW_COPY_AND_ASSIGN(TTNetworkQualityDetector);
};

}  // namespace net

#endif

#endif  // NET_TT_NET_NET_DETECT_TT_NETWORK_QUALITY_DETECTOR_H_
