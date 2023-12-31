// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_CLOUD_DETECTOR_H_
#define NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_CLOUD_DETECTOR_H_

#include "base/memory/singleton.h"
#include "base/timer/timer.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager_request.h"

namespace net {
namespace tt_exp {

class TTNetExpCloudDetector {
 public:
  struct CloudConfig {
    int64_t version{0};
    uint32_t poll_count{0};
    int64_t poll_interval_s{std::numeric_limits<int64_t>::max()};
    int64_t save_delay_s{std::numeric_limits<int64_t>::max()};
    int64_t start_delay_s{std::numeric_limits<int64_t>::max()};

    CloudConfig();
    ~CloudConfig();
  };

  enum CheckResult {
    CHECK_RESULT_CANNOT_DETECT,
    CHECK_RESULT_CAN_START_NEW,
    CHECK_RESULT_CAN_POLL_PRE,
  };

  static TTNetExpCloudDetector* GetInstance();
  bool IsStarted() const { return is_started_; }
  CheckResult CheckCloudConfig(const CloudConfig& cloud_config) const;
  void StartCloudDetect(
      const CloudConfig& cloud_config,
      const TTNetExperienceManager::RequestConfig& exp_config);
  void StopCloudDetect();

 private:
  friend struct base::DefaultSingletonTraits<TTNetExpCloudDetector>;
  friend class TTNetExpCloudDetectorTest;
  TTNetExpCloudDetector();
  ~TTNetExpCloudDetector();

  void PollDetectRequest();

  bool is_started_{false};
  base::OneShotTimer poll_timer_;
  CloudConfig cloud_config_;
  TTNetExperienceManager::RequestConfig exp_config_;
  std::unique_ptr<TTNetExperienceManager::Request> request_{nullptr};

  DISALLOW_COPY_AND_ASSIGN(TTNetExpCloudDetector);
};

}  // namespace tt_exp
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_CLOUD_DETECTOR_H_
