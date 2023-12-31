// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_DIAGNOSIS_PINGER_H_
#define NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_DIAGNOSIS_PINGER_H_

#include "base/callback.h"
#include "base/memory/weak_ptr.h"
#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_base_diagnosis_reporter.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager_request.h"
#include "net/tt_net/net_detect/transactions/reports/tt_ping_report.h"
#include "net/tt_net/net_detect/tt_network_detect_dispatched_manager_request.h"

namespace net {
namespace tt_exp {

class TTNetExpDiagnosisPinger {
 public:
  explicit TTNetExpDiagnosisPinger();
  virtual ~TTNetExpDiagnosisPinger();
  virtual int Start(const std::vector<std::string>& targets,
                    CompletionOnceCallback callback);
  void Cancel(int error);
  const BaseDiagnosisReport::PingGroupNode& GetPingerReport() const;
  bool IsRunning() const { return is_running_; }
  bool HasStarted() const { return has_started_; }
  void SetParallelNum(uint16_t parallel_num);
  void SetPingCount(uint32_t ping_count);
  void SetPingTimeoutMs(int64_t ping_timeout_ms);
  void SetPingProtocol(
      TTNetworkDetectDispatchedManager::NetDetectAction protocol);
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  void SetMultiNetAction(TTMultiNetworkUtils::MultiNetAction multi_net_action);
#endif
  void SetResolveHostFlag(
      HostResolver::ResolveHostParameters::TTFlag resolve_host_flag);

 private:
  friend class MockDiagnosisPinger;
  friend class TTNetExpDiagnosisPingerTest;
  enum State {
    STATE_INIT,
    STATE_PING,
    STATE_PING_COMPLETE,
    STATE_NONE,
  };

  int DoLoop(int result);
  int DoInit();
  int DoPing();
  int DoPingComplete(int result);
  void OnIOComplete(int result);
  void DoJobComplete(int result);
  void CollectPingNodeFromTransaction(const tt_detect::PingReport& ping_data,
                                      BaseDiagnosisReport::PingNode& ping_node);

  State next_state_{STATE_NONE};
  bool has_started_{false};
  bool is_running_{false};
  uint16_t parallel_num_{0};
  BaseDiagnosisReport::PingGroupNode ping_group_node_;
  CompletionOnceCallback callback_;
  // the iterator of |ping_targets|, limit the number of concurrent detection.
  std::vector<std::string>::iterator batch_iter_;
  TTNetworkDetectDispatchedManager::RequestConfig detect_config_;
  std::unique_ptr<TTNetworkDetectDispatchedManager::Request> detect_request_{
      nullptr};

  base::WeakPtrFactory<TTNetExpDiagnosisPinger> factory_;
  DISALLOW_COPY_AND_ASSIGN(TTNetExpDiagnosisPinger);
};

}  // namespace tt_exp
}  // namespace net

#endif