// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_DIAGNOSIS_V2_JOB_H_
#define NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_DIAGNOSIS_V2_JOB_H_

#include "base/timer/timer.h"
#include "net/base/network_change_notifier.h"
#include "net/tt_net/net_detect/gsdk/jobs/tt_net_exp_base_diagnosis_job.h"
#include "net/tt_net/net_detect/gsdk/jobs/tt_net_exp_diagnosis_pinger.h"
#include "net/tt_net/net_detect/gsdk/jobs/tt_net_exp_diagnosis_tracer.h"
#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_diagnosis_v2_reporter.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager_job.h"

namespace net {
namespace tt_exp {

class TTNetExperienceManager::TTNetExpDiagnosisV2Job
    : public TTNetExpBaseDiagnosisJob {
 public:
  TTNetExpDiagnosisV2Job(const TNCConfig& tnc_config,
                         TTNetExperienceManager::Request* request);
  ~TTNetExpDiagnosisV2Job() override;

  void DoExtraCommand(const std::string& command,
                      const std::string& extra_message) override;

 private:
  friend class TTNetExpDiagnosisV2JobTest;
  enum State {
    STATE_INIT,
    STATE_ENV_COLLECTION,
    STATE_LAN_SCAN,
    STATE_LAN_SCAN_COMPLETE,
    STATE_TRACEROUTE,
    STATE_TRACEROUTE_COMPLETE,
    STATE_SELF_POLL,
    STATE_WAIT_FOR_FINISH,
    STATE_NONE,
  };

  // NetworkChangeNotifier::IPAddressObserver implementation:
  void OnIPAddressChanged() override;
  // TTNetExperienceManager::Job implementation:
  int StartInternal() override;
  void CollectReport(int result) override;

  int DoLoop(int result);
  int DoInit();
  int DoEnvCollection();
  int DoLanScan();
  int DoLanScanComplete(int result);
  int DoTraceroute();
  int DoTracerouteComplete(int result);
  int DoSelfPoll();
  void DoSelfPollImpl();
  void SelfPollCallback(int result);
  void EstimateRtt();
  void DoFullDiagnose(const std::string& bid);
  void KeyPointCallback(int result);
  void FallbackCallback(int result);
  int DoWaitForFinish();
  void OnIOComplete(int result);
  void ReEnableJob();  // used in network change case.
  void DisableJob();

  // For component such as pinger or tracer.
  std::unique_ptr<TTNetExpDiagnosisPinger> lan_scan_pinger_{nullptr};
  std::unique_ptr<TTNetExpDiagnosisPinger> self_poll_pinger_{nullptr};
  std::unique_ptr<TTNetExpDiagnosisPinger> key_point_pinger_{nullptr};
  std::unique_ptr<TTNetExpDiagnosisPinger> fallback_pinger_{nullptr};
  std::unique_ptr<TTNetExpDiagnosisTracer> target_tracer_{nullptr};
  base::RepeatingTimer self_poll_timer_;

  // For reporter.
  DiagnosisV2Report::LanScanNode lan_scan_node_;
  DiagnosisV2Report::KeyPointNode key_point_node_;
  DiagnosisV2Report::SelfPollNode self_poll_node_;
  DiagnosisV2Report::FullDiagNode full_diag_node_;
  DiagnosisV2Report report_;

  // For job.
  bool job_enable_{true};
  State next_state_{STATE_NONE};
  std::string diagnosis_target_;
  NetworkChangeNotifier::ConnectionType default_connection_type_{
      NetworkChangeNotifier::CONNECTION_NONE};

  base::WeakPtrFactory<TTNetExpDiagnosisV2Job> factory_;
  DISALLOW_COPY_AND_ASSIGN(TTNetExpDiagnosisV2Job);
};

}  // namespace tt_exp
}  // namespace net

#endif