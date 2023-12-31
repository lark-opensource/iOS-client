// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_PACKET_LOSS_ESTIMATOR_H_
#define NET_TT_NET_NQE_TT_PACKET_LOSS_ESTIMATOR_H_

#include <vector>
#include "base/memory/singleton.h"
#include "base/observer_list.h"
#include "net/net_buildflags.h"
#include "net/tt_net/nqe/tt_nqe_constants.h"
#include "net/tt_net/nqe/tt_packet_loss_observer.h"
#include "net/tt_net/route_selection/tt_server_config.h"

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_NQE_SUPPORT)

namespace net {

struct LossRateMetrics {
  double rate{0.0};
  double variance{0.0};
};

namespace nqe {
class TTPacketLossAnalyzer;
}

class TTNET_IMPLEMENT_EXPORT TTPacketLossEstimator
    : public TTServerConfigObserver {
 public:
  // All TNC configures about packet loss estimating are as following.
  struct TNCConfig {
    bool enable_loss_rate_sampling;
    // Sampling period
    base::TimeDelta quic_loss_rate_sampling_period;
    // Samples in this window are effective to compute send loss rate and
    // variance.
    base::TimeDelta quic_loss_rate_sample_window;
    // The upper limit of loss packets preserved for each connection.
    uint64_t most_loss_packets_preserved;
    // The upper limit of loss windows preserved for each connection.
    uint64_t most_loss_windows_preserved;
    TNCConfig();
    TNCConfig(const TNCConfig& other) = default;
    ~TNCConfig() = default;
  };

  // A provider should implement this interface, from which estimator can get
  // received packet count and loss packet count.
  class ReceivePacketLossInfoProvider {
   public:
    virtual uint64_t GetReceivedPacketCount() = 0;
    virtual uint64_t GetLossPacketCount() = 0;
    virtual void CleanStatsData() = 0;

   protected:
    virtual ~ReceivePacketLossInfoProvider() {}
  };

  static TTPacketLossEstimator* GetInstance();

  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  const TNCConfig& GetTNCConfig() const { return tnc_config_; }

  void Init();

  // When constructing provider, call this function to add it to estimator。
  void AddReceivePacketLossMetricsProvider(
      ReceivePacketLossInfoProvider* provider,
      PacketLossAnalyzerProtocol protocol);

  // When destructing provider, call this function to remove it from estimator。
  void RemoveReceivePacketLossMetricsProvider(
      ReceivePacketLossInfoProvider* provider,
      PacketLossAnalyzerProtocol protocol);

  // Call by QuicConnectionLogger::OnPacketSent, add 1 to send packet count for
  // each invocation.
  void OnPacketSent(PacketLossAnalyzerProtocol protocol);

  // Call by QuicConnectionLogger::OnPacketLoss, add 1 to send packet loss count
  // for each invocation.
  void OnSendPacketLoss(PacketLossAnalyzerProtocol protocol);

  void GetSendPacketLossMetrics(PacketLossAnalyzerProtocol protocol,
                                LossRateMetrics* metrics);

  void GetReceivePacketLossMetrics(PacketLossAnalyzerProtocol protocol,
                                   LossRateMetrics* metrics);

  // Add observer for packet loss metrics.
  void AddPacketLossObserver(TTPacketLossObserver* observer);

  // Remove observer for packet loss metrics.
  void RemovePacketLossObserver(TTPacketLossObserver* observer);

  void NotifyPacketLossResult();

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  void SetAnalyzerForTesting(
      std::unique_ptr<nqe::TTPacketLossAnalyzer> analyzer,
      PacketLossAnalyzerProtocol protocol);

  bool HasPacketLossObserverForTesting(TTPacketLossObserver* observer) {
    return packet_loss_observers_.HasObserver(observer);
  }
#endif

 private:
  friend struct base::DefaultSingletonTraits<TTPacketLossEstimator>;
  TTPacketLossEstimator();
  ~TTPacketLossEstimator() override;

  void CalculateAndNotifySamplesCapacity();

  void CleanStatsData();

  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);

  std::unique_ptr<nqe::TTPacketLossAnalyzer>
      packet_loss_analyers_[PROTOCOL_COUNT];

  // TNC configures.
  TNCConfig tnc_config_;

  base::ObserverList<TTPacketLossObserver>::Unchecked packet_loss_observers_;

  bool initialized_;

  DISALLOW_COPY_AND_ASSIGN(TTPacketLossEstimator);
};
}  // namespace net

#endif

#endif  // NET_TT_NET_NQE_TT_PACKET_LOSS_ESTIMATOR_H_
