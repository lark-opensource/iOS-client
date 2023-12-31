// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_TCP_INFO_MANAGER_H_
#define NET_TT_NET_NQE_TT_TCP_INFO_MANAGER_H_

#include "base/memory/singleton.h"
#include "base/time/time.h"
#include "net/tt_net/nqe/tt_tcp_info_helper.h"
#include "net/tt_net/route_selection/tt_server_config.h"

namespace net {

class TTTCPInfoManager : public TTServerConfigObserver {
 public:
  struct TCPInfoStats {
    // Send MSS
    uint32_t send_mss_min{0};
    uint32_t send_mss_max{0};
    uint32_t send_mss_quantile{0};
    float send_mss_avg{0.0};
  };

  static TTTCPInfoManager* GetInstance();

  bool Init();

  void Deinit();

  // TTServerConfigObserver implementation:
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  bool ShouldReportTCPInfo() const {
    return tnc_config_.enable && initialized_;
  }

  bool ShouldUpdateTCPInfo(const base::TimeTicks& now) const;

  void OnTCPInfoUpdated(const TTTCPInfo& tcp_info, const base::TimeTicks& now);

  const TCPInfoStats& GetTCPInfoStats() const { return tcp_info_stats_; }

 private:
  friend struct base::DefaultSingletonTraits<TTTCPInfoManager>;
  friend class TTTCPInfoPosix;
  TTTCPInfoManager();
  ~TTTCPInfoManager() override;

  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);

  void UpdateTCPInfoSample(const TTTCPInfo& tcp_info);

  struct TNCConfig {
    bool enable;
    int64_t tcp_info_update_min_interval_ms;
    int64_t stats_compute_min_interval_ms;
    uint32_t mss_sample_size;
    float mss_percentile;
    TNCConfig();
    TNCConfig(const TNCConfig& other);
    ~TNCConfig();
  };

  TNCConfig tnc_config_;

  bool initialized_;

  // Last time when updating TCP info.
  base::TimeTicks last_update_;

  // Last time when computing TCP info stats.
  base::TimeTicks last_compute_;

  // MSS related statistic.
  // MSS samples.
  std::deque<uint32_t> mss_sample_buffer_;

  // MSS sum.
  int accumulative_mss_;

  TCPInfoStats tcp_info_stats_;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  void SetLastUpdateForTesting(const base::TimeTicks& now) {
    last_update_ = now;
  }

  void SetLastComputeForTesting(const base::TimeTicks& now) {
    last_compute_ = now;
  }

  const TNCConfig& GetTncConfigForTesting() const { return tnc_config_; }

  uint64_t compute_count_for_testing() const {
    return compute_count_for_testing_;
  }

  void SetTimeClockForTesting(base::TickClock* clock) {
    time_clock_for_testing_ = clock;
  }

 private:
  friend class TTTCPInfoManagerTest;
  FRIEND_TEST_ALL_PREFIXES(TTTCPInfoManagerTest, ParseServerConfig);
  FRIEND_TEST_ALL_PREFIXES(TTTCPInfoManagerTest, ComputeTCPInfoStats);

  uint64_t compute_count_for_testing_;

  base::TickClock* time_clock_for_testing_;
#endif

  DISALLOW_COPY_AND_ASSIGN(TTTCPInfoManager);
};
}  // namespace net

#endif