// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_PACKET_LOSS_ANALYZER_H_
#define NET_TT_NET_NQE_TT_PACKET_LOSS_ANALYZER_H_

#include <queue>
#include "base/macros.h"
#include "base/memory/singleton.h"
#include "base/time/tick_clock.h"
#include "net/base/net_export.h"
#include "net/tt_net/nqe/tt_packet_loss_estimator.h"
#include "net/tt_net/route_selection/tt_server_config.h"

namespace net {
namespace nqe {

class NET_EXPORT TTPacketLossAnalyzer {
 public:
  using Provider = TTPacketLossEstimator::ReceivePacketLossInfoProvider;

  TTPacketLossAnalyzer();

  TTPacketLossAnalyzer(const base::TickClock* clock);

  virtual ~TTPacketLossAnalyzer() {}

  virtual void AddReceivePacketLossMetricsProvider(Provider* provider);

  virtual void RemoveReceivePacketLossMetricsProvider(Provider* provider);

  virtual void OnPacketSent();

  virtual void OnSendPacketLoss();

  virtual void GetSendPacketLossMetrics(LossRateMetrics* metrics);

  virtual void GetReceivePacketLossMetrics(LossRateMetrics* metrics);

  void SetSamplesCapacity(size_t capacity);

  virtual void CleanStatsData() = 0;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  void SetSendSamplingPeriodForTesting(const base::TimeDelta& sampling_period) {
    send_sampling_period_ = sampling_period;
  }

  void SetSendSampleWindowForTesting(const base::TimeDelta& sample_window) {
    send_sample_window_ = sample_window;
  }
#endif

 protected:
  // Sample set capacity.
  size_t sample_capacity_{0};

  const base::TickClock* clock_;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  base::TimeDelta send_sampling_period_;
  base::TimeDelta send_sample_window_;
#endif

 private:
  DISALLOW_COPY_AND_ASSIGN(TTPacketLossAnalyzer);
};
}  // namespace nqe
}  // namespace net

#endif
