// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_EXP_DIAGNOSIS_TRACER_H_
#define NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_EXP_DIAGNOSIS_TRACER_H_

#include "base/callback.h"
#include "base/memory/weak_ptr.h"
#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_base_diagnosis_reporter.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager_request.h"
#include "net/tt_net/net_detect/transactions/reports/tt_traceroute_report.h"
#include "net/tt_net/net_detect/tt_network_detect_dispatched_manager_request.h"

namespace net {
namespace tt_exp {

class TTNetExpDiagnosisTracer {
 public:
  explicit TTNetExpDiagnosisTracer();
  virtual ~TTNetExpDiagnosisTracer();
  virtual int Start(const std::string& target, CompletionOnceCallback callback);
  void Cancel(int error);
  const BaseDiagnosisReport::TraceNode& GetTracerReport() const;
  void SetParallelNum(uint16_t parallel_num);
  void SetSpecifiedHops(const std::string& specified_hops);
  void SetTracerouteProtocol(
      TTNetworkDetectDispatchedManager::NetDetectAction ping_protocol);
  void SetHopTimeoutMs(int64_t hop_timeout_ms);
#if BUILDFLAG(ENABLE_MULTINETWORK_ON_MOBILE)
  void SetMultiNetAction(TTMultiNetworkUtils::MultiNetAction multi_net_action);
#endif
  void SetResolveHostFlag(
      HostResolver::ResolveHostParameters::TTFlag resolve_host_flag);
  void SetEdgePoints(const std::vector<std::string>& edge_points) {
    edge_points_ = edge_points;
  }
  void SetFallbackEnabled(bool fallback_enabled) {
    fallback_enabled_ = fallback_enabled;
  }
  bool HasStarted() const { return has_started_; }
  bool IsRunning() const { return is_running_; }

 private:
  friend class MockDiagnosisTracer;
  friend class TTNetExpDiagnosisTracerTest;
  enum State {
    STATE_INIT,
    STATE_TRACEROUTE,
    STATE_TRACEROUTE_PROGRESS,
    STATE_TRACEROUTE_COMPLETE,
    STATE_NONE,
  };

  int DoLoop(int result);
  int DoInit();
  int DoTraceroute();
  int DoTracerouteProgress(int result);
  int DoTracerouteComplete(int result);
  void OnIOProgress(int result);
  void OnIOComplete(int result);
  void DoJobComplete(int result);
  void CollectTraceNodeFromTransaction(
      const tt_detect::TracerouteReport& trace_data,
      BaseDiagnosisReport::TraceNode& trace_node);
  void CollectFallbackNodeFromManualConfig(
      BaseDiagnosisReport::TraceNode& trace_node);

  State next_state_{STATE_NONE};
  bool has_started_{false};
  bool is_running_{false};
  bool fallback_enabled_{true};
  std::vector<std::string> edge_points_;
  BaseDiagnosisReport::TraceNode trace_node_;
  CompletionOnceCallback callback_;
  TTNetworkDetectDispatchedManager::RequestConfig detect_config_;
  std::unique_ptr<TTNetworkDetectDispatchedManager::Request> detect_request_{
      nullptr};

  base::WeakPtrFactory<TTNetExpDiagnosisTracer> factory_;
  DISALLOW_COPY_AND_ASSIGN(TTNetExpDiagnosisTracer);
};

}  // namespace tt_exp
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_JOBS_TT_NET_EXP_DIAGNOSIS_TRACER_H_