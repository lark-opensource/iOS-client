// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_EXP_RAW_DETECT_JOB_H_
#define NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_EXP_RAW_DETECT_JOB_H_

#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_raw_detect_reporter.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager_job.h"

namespace net {
namespace tt_exp {

class TTNetExperienceManager::TTNetExpRawDetectJob
    : public TTNetExperienceManager::Job {
 public:
  TTNetExpRawDetectJob(const TNCConfig& tnc_config,
                       TTNetExperienceManager::Request* request);
  ~TTNetExpRawDetectJob() override;

 private:
  friend class TTNetExpRawDetectJobTest;
  enum State {
    STATE_INIT,
    STATE_DETECT,
    STATE_ENTRY_DETECT_COMPLETE,
    STATE_BATCH_DETECT_COMPLETE,
    STATE_ALL_DETECT_COMPLETE,
    STATE_NONE,
  };

  // TTNetExperienceManager::Job implementation:
  int StartInternal() override;
  void CollectReport(int result) override;

  int DoLoop(int result);
  int DoInit();
  int DoDetect();
  int DoEntryDetectComplete(int result);
  int DoBatchDetectComplete(int result);
  int DoAllDetectComplete(int result);
  void OnIOComplete(int result);
  void CollectBasicNode(BaseExperienceReport::BasicNode& basic_node);
  void CollectDeviceNode(RawDetectReport::DeviceNode& device_node);
  // Calculate the number of sockets required for all detection transactions of
  // each target address.
  int CalculateDetectSocketNumber(
      const TTNetworkDetectDispatchedManager::NetDetectAction action);

  State next_state_{STATE_NONE};
  std::unique_ptr<RawDetectReport> report_;
  std::vector<TTNetworkDetectDispatchedManager::RequestConfig>
      waiting_detect_configs_;
  std::vector<std::unique_ptr<TTNetworkDetectDispatchedManager::Request>>
      batch_requests_;

  base::WeakPtrFactory<TTNetExpRawDetectJob> factory_;
  DISALLOW_COPY_AND_ASSIGN(TTNetExpRawDetectJob);
};

}  // namespace tt_exp
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_EXP_RAW_DETECT_JOB_H_
