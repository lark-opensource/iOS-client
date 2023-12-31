// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_PACKET_RETRANS_STAT_ESTIMATOR_H_
#define NET_TT_NET_NQE_TT_PACKET_RETRANS_STAT_ESTIMATOR_H_

#include <deque>
#include <map>
#include "base/memory/singleton.h"
#include "base/time/tick_clock.h"
#include "base/timer/timer.h"
#include "net/tt_net/nqe/tt_tcp_info_helper.h"
#include "net/tt_net/route_selection/tt_server_config.h"

namespace net {

class TTPacketRetransStatEstimator : public TTServerConfigObserver {
 public:
  static TTPacketRetransStatEstimator* GetInstance();

  ~TTPacketRetransStatEstimator() override;

  bool Init();

  // Save total sent packets and total retrans packets info in
  // |sockets_retrans_info_| based on the fd that |tcp_info| carries.
  void OnTCPInfoUpdated(const TTTCPInfo& tcp_info);

  // When socket is destructed, call this to erase it from
  // |sockets_retrans_info_|.
  void OnSocketDestructed(SocketDescriptor fd);

  // Update |retrans_rate_result_| and |retrans_rate_variance_result_|.
  // Should be triggered by NQE computing.
  void UpdateStatResults();

  double GetRetransRate() const { return retrans_rate_result_; }

  double GetRetransRateVariance() const {
    return retrans_rate_variance_result_;
  }

  bool ShouldReportRetransStat() const {
    return tnc_config_.enable && initialized_;
  }

 private:
  friend struct base::DefaultSingletonTraits<TTPacketRetransStatEstimator>;

  struct Sample {
    uint64_t sent_packets;
    uint64_t retrans_packets;
    double retrans_rate;
    double retrans_rate_sq;
    // Time when this sample starts.
    base::TimeTicks sampling_start;
  };

  // Current total sent packets and total retrans packets info of each socket.
  struct SocketRetransInfo {
    uint64_t total_sent_packets;
    uint64_t total_retrans_packets;
  };

  struct TNCConfig {
    TNCConfig();
    ~TNCConfig();
    TNCConfig(const TNCConfig& other);
    bool enable;
    // Used by |sampling_timer_|, which helps us to save sample periodically.
    base::TimeDelta sample_interval;

    // Samples within |sample_time_range| will be saved in |samples_|.
    base::TimeDelta sample_time_range;

    std::set<std::string> filter_hosts;
  };

  TTPacketRetransStatEstimator();

  // TTServerConfigObserver implementation:
  void OnServerConfigChanged(
      const UpdateSource source,
      const base::Optional<base::Value>& tnc_config_value) override;

  void ReadTNCConfigFromCache();

  bool ParseJsonResult(const base::Optional<base::Value>& tnc_config_value);

  void ComputeSamplesCapacity();

  // It may be long ago if this manager stops and restarts after a long time.
  // In this case, when restarting if the time is longer than
  // |sample_time_range_ms|, reset all variables for recording.
  void StartRecording();

  void StopRecording();

  void RecordSample();

  TNCConfig tnc_config_;

  bool initialized_;

  // Help to generate sample and compute |retrans_rate_result_| and
  // |retrans_rate_variance_result_| periodically.
  base::RepeatingTimer sampling_timer_;

  // Sum of all |sockets_retrans_info_| sockets' |total_sent_packets|
  uint64_t total_sent_packets_last_time_;

  // Sum of all |sockets_retrans_info_| sockets' |total_retrans_packets|
  uint64_t total_retrans_packets_last_time_;

  // Time when a new sampling period starts.
  base::TimeTicks last_sampling_time_;

  // Sum of all samples' |sent_packets|
  uint64_t accumulate_sent_packets_;

  // Sum of all samples' |retrans_packets|
  uint64_t accumulate_retrans_packets_;

  // Convenient for computing retrans rate variance.
  double accumulate_retrans_rate_;

  // Convenient for computing retrans rate variance.
  double accumulate_retrans_rate_sq_;

  size_t sample_capacity_;

  std::deque<std::unique_ptr<Sample>> samples_;

  // From |sockets_retrans_info_| we can get current total sent packets and
  // total retrans packets of each sockets periodically
  std::map<SocketDescriptor, SocketRetransInfo> sockets_retrans_info_;

  double retrans_rate_result_;

  double retrans_rate_variance_result_;

  // Time when update stat result;
  base::TimeTicks last_update_result_time_;

  const base::TickClock* clock_;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  bool InitForTesting(const base::TickClock* clock);

  void DeinitForTesting();

  const TNCConfig& GetTncConfigForTesting() const { return tnc_config_; }

  bool IsWorkingForTesting() const { return sampling_timer_.IsRunning(); }

 private:
  friend class TTPacketRetransStatEstimatorTest;
  FRIEND_TEST_ALL_PREFIXES(TTPacketRetransStatEstimatorTest, ParseServerConfig);
  FRIEND_TEST_ALL_PREFIXES(TTPacketRetransStatEstimatorTest,
                           ShouldReportRetransStat);
  FRIEND_TEST_ALL_PREFIXES(TTPacketRetransStatEstimatorTest,
                           CalculateRetransStat);
  FRIEND_TEST_ALL_PREFIXES(TTPacketRetransStatEstimatorTest,
                           CalculateRetransStat_FilterHosts_TCPInfoEmptyHost);
  FRIEND_TEST_ALL_PREFIXES(TTPacketRetransStatEstimatorTest,
                           CalculateRetransStat_FilterHosts_TCPInfoHasHost);
#endif
};

}  // namespace net

#endif