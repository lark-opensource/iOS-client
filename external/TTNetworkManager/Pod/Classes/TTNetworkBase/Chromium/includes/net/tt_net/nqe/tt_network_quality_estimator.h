// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_NETWORK_QUALITY_ESTIMATOR_H_
#define NET_TT_NET_NQE_TT_NETWORK_QUALITY_ESTIMATOR_H_

#include "base/memory/singleton.h"
#include "net/base/net_export.h"
#include "net/base/network_change_notifier.h"
#include "net/tt_net/config/tt_config_manager.h"
#include "net/tt_net/nqe/tt_network_quality_detector.h"
#include "net/tt_net/route_selection/tt_server_config.h"
#include "net/tt_net/url_request/tt_url_request_manager.h"

namespace base {
class TimeTicks;
class OneShotTimer;
class RepeatingTimer;
}  // namespace base

namespace net {

class TTThroughputAnalyzer;
class URLRequest;

// Network quality level(NQL).
enum TTNetworkQualityLevel {
  TTNQL_FAKE_NETWORK = -1,
  TTNQL_UNKNOWN = 0,  // Default value
  TTNQL_OFFLINE = 1,
  TTNQL_POOR_NETWORK = 2,
  TTNQL_MODERATE_NETWORK = 3,
  TTNQL_GOOD_NETWORK = 4
};

class NET_EXPORT_PRIVATE TTNetworkQualityEstimator
    : public TTServerConfigObserver,
      public TTURLRequestManager::PendingRequestObserver,
      public TTNetworkQualityDetector::FakeNetworkStateObserver,
      public NetworkChangeNotifier::ConnectionTypeObserver {
 public:
  enum TransportPotocol { TCP, QUIC };

  class NET_EXPORT_PRIVATE NQLObserver {
   public:
    virtual void OnNQLChanged(TTNetworkQualityLevel nql) = 0;

    virtual void OnNetworkQualityRttAndThroughputNotified(
        int effective_hrtt,
        int effective_trtt,
        int effective_rx_throughput) = 0;

   protected:
    virtual ~NQLObserver() {}
  };

  static TTNetworkQualityEstimator* GetInstance();

  bool Init();

  // If the |url_host| matches TNC config, record RTT or Downstream Throughput.
  // |SocketWatcher| will deal with Transport RTT, thus don't filter it again in
  // |NetworkQualityEstimator|.
  bool ShouldSampling(const std::string& url_host) const;

  // Request lifecycle callbacks
  void OnRequestTransactionStarted(const URLRequest& request);
  // For HTTP RTT computing.
  void OnRequestHeaderReceived(const URLRequest& request);
  // For rx throughput computing.
  void OnRequestBytesReceived(const URLRequest& request);
  void OnRequestCompleted(const URLRequest& request);
  void OnRequestDestroyed(const URLRequest& request);

  // Transport RTT notification.
  bool ShouldNotifyTransportRtt(const base::TimeTicks& now) const;
  void OnTransportRttUpdated(TransportPotocol proto,
                             const base::TimeTicks& now,
                             const base::TimeDelta& rtt);

  int effective_hrtt() const { return effective_hrtt_; }
  int effective_trtt() const { return effective_trtt_; }
  int effective_rx_throughput() const { return effective_rx_throughput_; }
  TTNetworkQualityLevel current_nql() const { return current_nql_; }

  void AddNQLObserver(NQLObserver* observer);
  void RemoveNQLObserver(NQLObserver* observer);

 private:
  friend struct base::DefaultSingletonTraits<TTNetworkQualityEstimator>;
  TTNetworkQualityEstimator();
  ~TTNetworkQualityEstimator() override;

  struct NqeLevelRule {
    TTNetworkQualityLevel level{TTNQL_UNKNOWN};
    int hrtt_level{-1};
    int trtt_level{-1};
    int rx_throughput_level{-1};
  };

  struct TNCConfig {
    bool enable;
    // For HTTP RTT effective value computing.
    double hrtt_coef;
    // If it hasn't sampled a HTTP RTT with a certain duraion, use the
    // |hrtt_comp| as a compensation sample.
    int hrtt_comp;
    // Limit effective HTTP RTT less or equal to |hrtt_clamped|
    int hrtt_clamped;
    // For Transport RTT effective value computing.
    double trtt_coef;
    // If it hasn't sampled a Transport RTT with a certain duraion, use the
    // |trtt_comp| as a compensation sample.
    int trtt_comp;
    // Limit effective HTTP RTT less or equal to |trtt_clamped|
    int trtt_clamped;
    // If it hasn't sampled a Downstream Throughput with a certain duraion, use
    // the |rx_throughput_comp| as a compensation sample.
    int rx_throughput_comp;
    // Limit Transport RTT updating frequency.
    int64_t trtt_update_min_interval;
    // If HTTP RTT or Transport RTT hasn't updated withing
    // |rtt_update_max_interval| use a compensaton value for computing.
    int64_t sampling_max_interval;
    // Compute the network quality level every |nql_compute_interval| ms.
    int64_t nql_compute_interval;
    // If there is pending request, effective HTTP RTT, Transport RTT and
    // Downstream Throughput will be notified every
    // |effective_value_notify_interval| ms.
    int64_t effective_value_notify_interval;
    // Standars to determine the current NQL.
    std::map<TTNetworkQualityLevel, NqeLevelRule> level_rules;
    // Hosts or host patterns that filter the URL requests whose RTT and
    // Downstream Throughput should be sampled.
    std::vector<std::string> sampling_filter_hosts;
    std::string dsa_detect_url;
    int64_t dsa_detect_interval_ms;

    TNCConfig();
    TNCConfig(const TNCConfig& other);
    ~TNCConfig();
  };

  // TTServerConfigObserver implementation:
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  void ReadTNCConfigFromCache();
  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);

  // TTURLRequestManager::PendingRequestObserver implementation:
  void OnPendingRequestCountChanged(CountChange change) override;

  // TTNetworkQualityDetector::FakeNetworkStateObserver implementation:
  void OnNetworkQualityTypeChanged(NqeConfig::NetworkQualityType nqt) override;

  // NetworkChangeNotifier::ConnectionTypeObserver implementation:
  void OnConnectionTypeChanged(
      NetworkChangeNotifier::ConnectionType type) override;

  void OnSamplingWatcherTimeout();
  void OnNotifyRttAndThroughputTimeout();

  void ComputeEffectiveHttpRtt(int new_hrtt);
  void ComputeEffectiveTransportRtt(int new_trtt);
  void ComputeNQLAndNotifyObservers(bool force_compute = false);
  void ComputeNQL();
  void NotifyObserversOfNQL();
  void NotifyObserversOfRttAndThroughput(bool force_notify = false);
  void NotifyNQLAndRttIfObserverPresent(NQLObserver* observer);

  bool ShouldRequestSampled(const URLRequest& request) const;

  void CalculateWeightedAverageRtt(int new_rtt,
                                   double coef,
                                   int clamped,
                                   int& result);

  void TryStartTimers();
  void StopTimers();

  void StartDsaDetection();
  void OnDsaDetectionTimeout();
  void OnDsaDetectionComplete(int response_code,
                              const std::string& content,
                              HttpResponseHeaders* response_headers);

  TNCConfig tnc_config_;

  bool initialized_;

  // Effective HTTP RTT, which is used to compute NQL;
  int effective_hrtt_;

  // Effective Transport RTT, which is used to compute NQL;
  int effective_trtt_;

  // Effective Downstream Throughput, which is used to compute NQL;
  int effective_rx_throughput_;

  // Network quality level computed latest.
  TTNetworkQualityLevel current_nql_;

  // If HTTP RTT hasn't been updated for a certain time,
  // use compensation values.
  base::OneShotTimer hrtt_sampling_watcher_;

  base::RepeatingTimer nql_computing_timer_;

  base::RepeatingTimer effective_value_notify_timer_;

  base::TimeTicks last_update_trtt_;

  base::TimeTicks last_sampling_hrtt_;

  std::unique_ptr<TTThroughputAnalyzer> throughput_analyzer_;

  base::ObserverList<NQLObserver>::Unchecked nql_observer_list_;

  base::TimeTicks last_connection_change_;

  base::TimeTicks last_nql_compute_;

  base::TimeTicks last_rtt_notified_;

  CountChange pending_count_changed_{CHANGE_CLEAN_UP};

  bool is_dsa_detection_inflight_{false};

  base::TimeTicks last_dsa_detection_;

  // uint32_t continuous_quick_canceled_req_count_{0};

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  void SetNqlForTesting(TTNetworkQualityLevel nql) {
    current_nql_ = nql;
  }
  void SetEffectiveHrttForTesting(int effective_hrtt) {
    effective_hrtt_ = effective_hrtt;
  }
  void SetEffectiveTrttForTesting(int effective_trtt) {
    effective_trtt_ = effective_trtt;
  }
  void SetEffectiveRxThroughputForTesting(int effective_rx_throughput) {
    effective_rx_throughput_ = effective_rx_throughput;
  }

  const TNCConfig& GetTncConfigForTesting() const {
    return tnc_config_;
  }

  bool CheckSamplingWatcherIsRunning() const {
    return hrtt_sampling_watcher_.IsRunning();
  }

  bool CheckNQLComputingTimerIsRunning() const {
    return nql_computing_timer_.IsRunning();
  }

  bool CheckEffectiveValueNotifyTimerIsRunning() const {
    return effective_value_notify_timer_.IsRunning();
  }

  void DeinitForTesting();

  void SetMockDsaDetectorCallbackForTesting(
      base::RepeatingCallback<void(int)> callback) {
    mock_dsa_detector_callback_ = callback;
  }

  bool is_dsa_detection_inflight_for_testing() const {
    return is_dsa_detection_inflight_;
  }

  void SetDsaDetectionReceiveTimeForTesting(int64_t dsa_detection_receive_interval) {
    dsa_detection_receive_interval_ = dsa_detection_receive_interval;
  }

 private:
  friend class TTNetworkQualityEstimatorTest;
  friend class MockDsaDetector;
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest, ParseTncConfig);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest, AddObserver);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest, ConnectionTypeChanged);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest, NQTChanged);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest, PendingRequestsChanged);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest, CalculateEffectiveHrtt);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest, CalculateEffectiveTrtt);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest, CalculateNQL);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest, HostFilter);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest,
                           EffectiveHttpRttSamplingWatching);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest, DsaDetection_Failed);
  FRIEND_TEST_ALL_PREFIXES(TTNetworkQualityEstimatorTest, DsaDetection_Success);

  base::RepeatingCallback<void(int)> mock_dsa_detector_callback_;
  // A time interval between send and receive the dsa detection request.
  int64_t dsa_detection_receive_interval_; // ms
#endif

  DISALLOW_COPY_AND_ASSIGN(TTNetworkQualityEstimator);
};

}  // namespace net

#endif