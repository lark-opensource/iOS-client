// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_BAD_REQUEST_DIAGNOSIS_JOB_H_
#define NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_BAD_REQUEST_DIAGNOSIS_JOB_H_

#include "base/optional.h"
#include "net/tt_net/net_detect/gsdk/jobs/tt_net_exp_base_diagnosis_job.h"
#include "net/tt_net/net_detect/gsdk/jobs/tt_net_exp_diagnosis_pinger.h"
#include "net/tt_net/net_detect/gsdk/jobs/tt_net_exp_diagnosis_tracer.h"
#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_bad_request_diagnosis_reporter.h"

namespace net {
namespace tt_exp {

class TTNetExperienceManager::TTNetExpBadRequestDiagnosisJob
    : public TTNetExpBaseDiagnosisJob {
 public:
  TTNetExpBadRequestDiagnosisJob(const TNCConfig& tnc_config,
                                 TTNetExperienceManager::Request* request);
  ~TTNetExpBadRequestDiagnosisJob() override;

 private:
  friend class TTNetExpBadRequestDiagnosisJobTest;
  enum State {
    STATE_NONE = 0,
    STATE_INIT = 1,
    STATE_HTTP_GET_NON_BLOCKING = 2,  // Non-blocking, continue to traceroute.
    STATE_HTTP_GET_COMPLETE = 3,
    STATE_TRACEROUTE = 4,  // Blocking
    STATE_TRACEROUTE_COMPLETE = 5,
    STATE_PING = 6,  // Blocking
    STATE_PING_COMPLETE = 7,
    STATE_WAIT = 8,  // wait for the http-get callback, and the traceroute
                     // callback or the ping callback to complete.
  };

  // NetworkChangeNotifier::IPAddressObserver implementation:
  void OnIPAddressChanged() override;

  // TTNetExperienceManager::Job implementation:
  int StartInternal() override;
  void CollectReport(int result) override;

  int DoLoop(int result);
  int DoInit();
  int DoHttpGetNonBlocking();
  int DoHttpGetComplete(int result);
  int DoTraceroute();
  int DoTracerouteComplete(int result);
  int DoPing();
  int DoPingComplete(int result);
  int DoWait(int result);
  void OnIOComplete(State state, int result);

  State next_state_{STATE_NONE};
  std::unique_ptr<BadRequestDiagnosisReport> report_;
  std::unique_ptr<TTNetworkDetectDispatchedManager::Request> http_get_request_;
  std::unique_ptr<TTNetExpDiagnosisTracer> public_access_tracer_;
  std::unique_ptr<TTNetExpDiagnosisPinger> key_point_pinger_;

  base::WeakPtrFactory<TTNetExpBadRequestDiagnosisJob> factory_;
  DISALLOW_COPY_AND_ASSIGN(TTNetExpBadRequestDiagnosisJob);
};

}  // namespace tt_exp
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_BAD_REQUEST_DIAGNOSIS_JOB_H_
