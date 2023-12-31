// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_BAD_REQUEST_DIAGNOSER_H_
#define NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_BAD_REQUEST_DIAGNOSER_H_

#include "net/base/network_change_notifier.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager.h"

namespace net {
namespace tt_exp {

class TTNetExpBadRequestDiagnoser
    : public NetworkChangeNotifier::IPAddressObserver {
 public:
  TTNetExpBadRequestDiagnoser();
  ~TTNetExpBadRequestDiagnoser() override;

  void OnRequestCompleted(
      const TTNetExperienceManager::TNCConfig::BadRequestDiagnosis& config,
      const URLRequest* url_request,
      int net_error);

  bool IsStarted() const { return is_started_; }

 private:
  friend class TTNetExpBadRequestDiagnoserTest;
  FRIEND_TEST_ALL_PREFIXES(TTNetExpBadRequestDiagnoserTest,
                           CheckDiagnoserStart);
  FRIEND_TEST_ALL_PREFIXES(TTNetExpBadRequestDiagnoserTest, CheckRequestOK);
  FRIEND_TEST_ALL_PREFIXES(TTNetExpBadRequestDiagnoserTest,
                           CheckDiagnosisCount);
  FRIEND_TEST_ALL_PREFIXES(TTNetExpBadRequestDiagnoserTest,
                           CheckDiagnosisInterval);
  FRIEND_TEST_ALL_PREFIXES(TTNetExpBadRequestDiagnoserTest, CheckCoreRequest);
  FRIEND_TEST_ALL_PREFIXES(TTNetExpBadRequestDiagnoserTest, CheckMatchRule);
  FRIEND_TEST_ALL_PREFIXES(TTNetExpBadRequestDiagnoserTest, OnIPAddressChanged);

  static bool IsCoreRequest(const URLRequest* url_request, int net_error);
  static bool IsMatchRules(
      const TTNetExperienceManager::TNCConfig::BadRequestDiagnosis& config,
      const GURL& url,
      int net_error);

  // NetworkChangeNotifier::IPAddressObserver implementation:
  void OnIPAddressChanged() override;

  void StartDiagnosis(int64_t job_timeout_ms);
  void StartDiagnosisInner(int64_t job_timeout_ms);
  void StopDiagnosis();
  void StopDiagnosisInner();
  void OnJobComplete(int error);
  base::TimeTicks GetTimeTicksNow() const;

  bool is_started_{false};
  const base::TickClock* clock_{nullptr};  // Not owned.
  std::unique_ptr<TTNetExperienceManager::Request> request_;

  // Params related to records.
  int bad_request_count_{0};  // Number of continuous failed requests
  int diagnosis_count_{0};
  base::TimeTicks pre_diagnosis_time_;
  NetworkChangeNotifier::ConnectionType connection_type_{
      NetworkChangeNotifier::CONNECTION_NONE};

  base::WeakPtrFactory<TTNetExpBadRequestDiagnoser> factory_;
  DISALLOW_COPY_AND_ASSIGN(TTNetExpBadRequestDiagnoser);
};

}  // namespace tt_exp
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_BAD_REQUEST_DIAGNOSER_H_
