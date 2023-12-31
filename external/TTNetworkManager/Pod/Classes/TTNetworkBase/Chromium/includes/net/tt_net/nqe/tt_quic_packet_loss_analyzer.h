// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_QUIC_PACKET_LOSS_ANALYZER_H_
#define NET_TT_NET_NQE_TT_QUIC_PACKET_LOSS_ANALYZER_H_

#include "net/tt_net/nqe/tt_packet_loss_analyzer.h"

#include <deque>
#include "base/time/time.h"
#include "base/timer/timer.h"

namespace net {
namespace nqe {
class TTQuicPacketLossAnalyzer : public TTPacketLossAnalyzer {
 public:
  TTQuicPacketLossAnalyzer();

  TTQuicPacketLossAnalyzer(const base::TickClock* clock);

  ~TTQuicPacketLossAnalyzer() override;

  void AddReceivePacketLossMetricsProvider(Provider* provider) override;

  void RemoveReceivePacketLossMetricsProvider(Provider* provider) override;

  void OnPacketSent() override;

  void OnSendPacketLoss() override;

  void GetSendPacketLossMetrics(LossRateMetrics* metrics) override;

  void GetReceivePacketLossMetrics(LossRateMetrics* metrics) override;

  void CleanStatsData() override;

 private:
  void OnSendSamplingTimeout();

  struct SendPacketLossSample {
    base::TimeTicks sampling_start;
    std::atomic<uint64_t> send_count;
    std::atomic<uint64_t> loss_count;
    double loss_rate;
    double loss_rate_sq;
    SendPacketLossSample(const base::TickClock* clock);
  };

  // Sample that is currently collecting send and loss packet info.
  std::unique_ptr<SendPacketLossSample> current_sample_;

  std::deque<std::unique_ptr<SendPacketLossSample>> send_samples_;

  base::OneShotTimer sampling_timer_;

  uint64_t total_send_count_;

  uint64_t total_loss_count_;

  double accumulate_loss_rate_;

  double accumulate_loss_rate_sq_;

  // Providers from which we collect downstream packet loss metrics.
  std::unordered_set<Provider*> quic_receive_pkt_loss_info_providers_;

  DISALLOW_COPY_AND_ASSIGN(TTQuicPacketLossAnalyzer);
};
}  // namespace nqe
}  // namespace net

#endif