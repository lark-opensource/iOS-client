// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_DNS_RACE_REPORTER_H_
#define NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_DNS_RACE_REPORTER_H_

#include "net/tt_net/net_detect/gsdk/reports/tt_net_exp_base_experience_reporter.h"

#include "net/base/net_errors.h"

namespace net {
namespace tt_exp {

// The whole job result
struct DnsRaceReport : BaseExperienceReport {
  // DNS result
  struct DnsNode {
    int detect_error{ND_ERR_OK};
    int net_error{OK};
    std::string host;
    std::vector<std::string> resolved_ips;

    DnsNode();
    ~DnsNode();
    DnsNode(const DnsNode& other);
  };

  // Race result
  struct RaceNode {
    struct ScoreResult {
      double score{0};
      std::string origin_target;
    };
    std::vector<ScoreResult> http_score_results;
    std::vector<ScoreResult> icmp_score_results;
    std::vector<ScoreResult> udp_score_results;

    RaceNode();
    ~RaceNode();
    RaceNode(const RaceNode& other);
    std::map<std::string, std::vector<ScoreResult>> GetAllScoreResults() const;
  };
  typedef RaceNode::ScoreResult ScoreResult;

  base::Optional<DnsNode> dns_node;
  base::Optional<RaceNode> race_node;

  DnsRaceReport();
  ~DnsRaceReport() override;
  DnsRaceReport(const DnsRaceReport& other);
  DnsRaceReport& operator=(const DnsRaceReport& other);
  DnsNode& GetDnsNodeValue();
  RaceNode& GetRaceNodeValue();
};

class TTNetExpDnsRaceReporter : public TTNetExpBaseExperienceReporter {
 public:
  TTNetExpDnsRaceReporter();
  ~TTNetExpDnsRaceReporter() override;

  std::unique_ptr<base::DictionaryValue> ToJson(
      const DnsRaceReport::DnsNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DnsRaceReport::RaceNode& root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DnsRaceReport::DnsNode& dns_root,
      const DnsRaceReport::RaceNode& race_root) const;
  std::unique_ptr<base::DictionaryValue> ToJson(
      const DnsRaceReport& root) const;

 private:
  DnsRaceReport report_;
};

}  // namespace tt_exp
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_GSDK_REPORTS_TT_NET_EXP_DNS_RACE_REPORTER_H_
