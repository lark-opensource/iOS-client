// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_JOB_CACHE_H_
#define NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_JOB_CACHE_H_

#include "base/memory/singleton.h"
#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_base_diagnosis_reporter.h"

namespace net {
namespace tt_exp {

class TTNetExpJobCache : public NetworkChangeNotifier::ConnectionTypeObserver {
 public:
  static TTNetExpJobCache* GetInstance();
  void AddTraceRouteCache(const std::string& target,
                          BaseDiagnosisReport::TraceNode& trace_node);
  // Get cache with the same target.
  bool GetTraceRouteCache(const std::string& target,
                          BaseDiagnosisReport::TraceNode& trace_node) const;
  // Get cache with the same target and connect type.
  bool GetTraceRouteCache(const std::string& target,
                          NetworkChangeNotifier::ConnectionType type,
                          BaseDiagnosisReport::TraceNode& trace_node) const;
  void ClearTraceRouteCache();

 private:
  friend struct base::DefaultSingletonTraits<TTNetExpJobCache>;
  TTNetExpJobCache();
  ~TTNetExpJobCache() override;
  // NetworkChangeNotifier::ConnectionTypeObserver implementation:
  void OnConnectionTypeChanged(
      NetworkChangeNotifier::ConnectionType type) override;

  std::map<std::string, BaseDiagnosisReport::TraceNode> trace_node_cache_;

  DISALLOW_COPY_AND_ASSIGN(TTNetExpJobCache);
};

}  // namespace tt_exp
}  // namespace net

#endif