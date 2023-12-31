// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_DIAGNOSIS_V1_JOB_H_
#define NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_DIAGNOSIS_V1_JOB_H_

#include "net/base/network_change_notifier.h"
#include "net/tt_net/net_detect/gsdk/jobs/tt_net_exp_base_diagnosis_job.h"
#include "net/tt_net/net_detect/gsdk/jobs/tt_net_exp_diagnosis_tracer.h"
#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_diagnosis_v1_reporter.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager_job.h"

namespace net {
namespace tt_exp {

class TTNetExpDiagnosisPinger;

class TTNetExperienceManager::TTNetExpDiagnosisV1Job
    : public TTNetExpBaseDiagnosisJob {
 public:
  TTNetExpDiagnosisV1Job(const TNCConfig& tnc_config,
                         TTNetExperienceManager::Request* request);
  ~TTNetExpDiagnosisV1Job() override;

 private:
  friend class TTNetExpDiagnosisV1JobTest;
  enum State {
    STATE_INIT,
    STATE_HANDLE_MULTI_NET,
    STATE_HANDLE_MULTI_NET_COMPLETE,
    STATE_LAN_SCAN,
    STATE_LAN_SCAN_COMPLETE,
    STATE_TCP_CONNECT,
    STATE_TCP_CONNECT_COMPLETE,
    STATE_TRACEROUTE,
    STATE_TRACEROUTE_COMPLETE,
    STATE_PING,
    STATE_PING_COMPLETE,
    STATE_NONE,
  };

  // NetworkChangeNotifier::IPAddressObserver implementation:
  void OnIPAddressChanged() override;

  // TTNetExperienceManager::Job implementation:
  int StartInternal() override;
  void CollectReport(int result) override;

  int DoLoop(int result);
  int DoInit();
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  int DoHandleMultiNet();
  void OnCellularActivated(bool success);
  void OnCellularActivatingTimeout();
  int DoHandleMultiNetComplete(int result);
#endif
  int DoLanScan();
  int DoLanScanComplete(int result);
  int DoTcpConnect();
  int DoTcpConnectComplete(int result);
  int DoTraceroute();
  int DoTracerouteComplete(int result);
  int DoPing();
  void KeyPointCallback(int result);
  void FallbackCallback(int result);
  int DoPingComplete(int result);
  void OnIOComplete(int result);
  int CheckDiagnosisInterval();  // Diagnosis interval is limited to avoid
                                 // frequent diagnosis.

  // For component such as pinger or tracer.
  std::unique_ptr<TTNetExpDiagnosisPinger> lan_scan_pinger_{nullptr};
  std::unique_ptr<TTNetExpDiagnosisPinger> key_point_pinger_{nullptr};
  std::unique_ptr<TTNetExpDiagnosisPinger> fallback_pinger_{nullptr};
  std::unique_ptr<TTNetExpDiagnosisTracer> target_tracer_{nullptr};

  // For reporter.
  DiagnosisV1Report report_;

  // For job.
  State next_state_{STATE_NONE};
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  base::OneShotTimer cell_activating_timer_;
#endif

  base::WeakPtrFactory<TTNetExpDiagnosisV1Job> factory_;
  DISALLOW_COPY_AND_ASSIGN(TTNetExpDiagnosisV1Job);
};

}  // namespace tt_exp
}  // namespace net

#endif