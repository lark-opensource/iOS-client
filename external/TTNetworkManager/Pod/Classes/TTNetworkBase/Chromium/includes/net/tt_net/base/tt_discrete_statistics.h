// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_BASE_TT_DISCRETE_STATISTICS_H_
#define NET_TT_NET_NQE_BASE_TT_DISCRETE_STATISTICS_H_

#include <deque>

#include "base/time/tick_clock.h"
#include "base/timer/timer.h"
#include "net/net_buildflags.h"

namespace net {

class TTDiscreteStatistics {
 public:
  TTDiscreteStatistics();
  ~TTDiscreteStatistics();

  // Must be called before StartRecording().
  bool UpdateConfig(int64_t sample_interval_ms, int64_t sample_time_range_ms);

  void StartRecording();

  void StopRecording();

  void AddToNumerator(uint64_t val);

  void AddToDenominator(uint64_t val);

  // Update statistics results based on newest samples.
  void UpdateStatResults();

  double GetRate() const { return rate_result_; }

  double GetRateVariance() const { return rate_variance_result_; }

 private:
  struct Sample {
    uint64_t numerator_value;
    uint64_t denominator_value;
    double rate;
    double rate_sq;
    // Time when this sample starts.
    base::TimeTicks sampling_start;
  };

  void RecordSample();

  base::RepeatingTimer sampling_timer_;

  // Sum of all samples' |numerator_value|
  uint64_t accumulate_numerator_value_;

  // Sum of all samples' |denominator_value|
  uint64_t accumulate_denominator_value_;

  // Convenient for computing rate variance.
  double accumulate_rate_;

  // Convenient for computing rate variance.
  double accumulate_rate_sq_;

  // Monotonic increases by calling |AddToNumerator|, and it's
  // not less than |accumulate_numerator_value_|.
  uint64_t total_numerator_value_so_far_;

  // Monotonic increases by calling |AddToDenominator|, and it's
  // not less than |accumulate_denominator_value_|.
  uint64_t total_denominator_value_so_far_;

  // This is equal to |total_numerator_value_so_far_| when the
  // current sample begins. It's used to calculate the |numerator|
  // of Sample.
  uint64_t total_numerator_value_last_sample_time_;

  // This is equal to |total_numerator_value_so_far_| when the
  // current sample begins. It's used to calculate the |denominator|
  // of Sample
  uint64_t total_denominator_value_last_sample_time_;

  // Used by |sampling_timer_|, which helps us to save sample periodically.
  base::TimeDelta sample_interval_;

  // Samples within |sample_time_range| will be saved in |samples_|.
  base::TimeDelta sample_time_range_;

  // Max count of sample in |samples_|.
  size_t sample_capacity_;

  std::deque<std::unique_ptr<Sample>> samples_;

  double rate_result_;

  double rate_variance_result_;

  // Time when update stat result;
  base::TimeTicks last_update_result_time_;

  const base::TickClock* clock_;

#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
 public:
  void SetClockForTesting(const base::TickClock* clock);

 private:
  friend class TTDiscreteStatisticsTest;
  FRIEND_TEST_ALL_PREFIXES(TTDiscreteStatisticsTest, UpdateConfig);
#endif

  DISALLOW_COPY_AND_ASSIGN(TTDiscreteStatistics);
};

}  // namespace net

#endif