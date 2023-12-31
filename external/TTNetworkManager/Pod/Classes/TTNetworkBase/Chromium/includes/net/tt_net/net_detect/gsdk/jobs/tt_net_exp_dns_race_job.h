// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_DNS_RACE_JOB_H_
#define NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_DNS_RACE_JOB_H_

#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_dns_race_reporter.h"
#include "net/tt_net/net_detect/gsdk/tt_net_experience_manager_job.h"
#include "net/tt_net/net_detect/transactions/reports/tt_full_dns_report.h"
#include "net/tt_net/net_detect/transactions/reports/tt_http_get_report.h"
#include "net/tt_net/net_detect/transactions/reports/tt_ping_report.h"

namespace net {
namespace tt_exp {

class TTNetExperienceManager::TTNetExpDnsRaceJob
    : public TTNetExperienceManager::Job {
 public:
  TTNetExpDnsRaceJob(const TNCConfig& tnc_config,
                     TTNetExperienceManager::Request* request);
  ~TTNetExpDnsRaceJob() override;

 private:
  friend class TTNetExpDnsRaceJobTest;
  enum State {
    STATE_RESOLVE_HOST,
    STATE_RESOLVE_HOST_COMPLETE,
    STATE_RACE,
    STATE_RACE_COMPLETE,
    STATE_NONE,
  };

  // TTNetExperienceManager::Job implementation:
  int StartInternal() override;
  void CollectReport(int result) override;

  int DoLoop(int result);
  int DoResolveHost();
  int DoResolveHostComplete(int result);
  int DoRace();
  int DoRaceComplete(int result);
  void OnIOComplete(int result);
  bool ShouldAccelerate(const tt_detect::FullDnsReport& dns_data) const;
  void CollectDnsNode(const tt_detect::FullDnsReport& full_dns_data,
                      DnsRaceReport::DnsNode& dns_node);
  void CollectRaceNode(const tt_detect::HttpGetReport& http_get_data,
                       DnsRaceReport::RaceNode& race_node);
  void CollectRaceNode(const tt_detect::PingReport& ping_data,
                       DnsRaceReport::RaceNode& race_node);
  void CollectBasicNode(DnsRaceReport::BasicNode& basic_node);

  uint32_t max_ping_count_{0};
  int64_t ping_timeout_ms_{0};
  TTNetworkDetectDispatchedManager::NetDetectAction race_actions_{
      TTNetworkDetectDispatchedManager::ACTION_INVALID};
  TTNetExperienceManager::RequestType request_type_{REQ_TYPE_INVALID};

  State next_state_{STATE_NONE};
  std::vector<std::string> dns_targets_;
  std::vector<std::string> race_targets_;
  // the iterator of |race_targets_|, limit the number of concurrent detection.
  std::vector<std::string>::iterator batch_iter_;
  DnsRaceReport report_;

  base::WeakPtrFactory<TTNetExpDnsRaceJob> factory_;
  DISALLOW_COPY_AND_ASSIGN(TTNetExpDnsRaceJob);
};

}  // namespace tt_exp
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_TT_NET_EXP_DNS_RACE_JOB_H_