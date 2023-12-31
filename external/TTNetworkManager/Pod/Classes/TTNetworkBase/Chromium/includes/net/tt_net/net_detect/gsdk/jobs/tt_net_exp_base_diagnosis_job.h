// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_EXP_BASE_DIAGNOSIS_JOB_H_
#define NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_EXP_BASE_DIAGNOSIS_JOB_H_

#include "net/base/network_change_notifier.h"
#include "net/tt_net/net_detect/base/tt_device_basic_info_manager.h"
#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_diagnosis_v1_reporter.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager_job.h"

namespace net {
namespace tt_exp {

class TTNetExperienceManager::TTNetExpBaseDiagnosisJob
    : public TTNetExperienceManager::Job,
      public NetworkChangeNotifier::IPAddressObserver {
 public:
  TTNetExpBaseDiagnosisJob(const TNCConfig& tnc_config,
                           TTNetExperienceManager::Request* request);
  ~TTNetExpBaseDiagnosisJob() override;

 protected:
  void CollectBasicNode(BaseDiagnosisReport::BasicNode& basic_node);

  void CollectDeviceNode(BaseDiagnosisReport::DeviceNode& device_node);

  void CollectAccessPointNode(BaseDiagnosisReport::AccessPointNode& ap_node);

 private:
  DISALLOW_COPY_AND_ASSIGN(TTNetExpBaseDiagnosisJob);
};

}  // namespace tt_exp
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_EXP_BASE_DIAGNOSIS_JOB_H_
