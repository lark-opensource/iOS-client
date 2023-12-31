// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_PERF_REPORT_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_PERF_REPORT_H_

#include <string>
#include <vector>

#include "base/values.h"
#include "net/base/net_errors.h"
#include "net/tt_net/net_detect/base/tt_network_detect_errors.h"
#include "net/tt_net/net_detect/transactions/reports/tt_base_detect_report.h"

namespace net {
namespace tt_detect {

struct SenderReport {
  struct SectionStats {
    int64_t section_start_time{0};
    int64_t section_end_time{0};
    // The total number of packets had sent.
    int64_t origin_sent_packet_nums{0};
    // The total number of packets actually sent successfully.
    int64_t valid_sent_packet_nums{0};

    std::unique_ptr<base::DictionaryValue> ToJson() const;
  };
  struct TotalStats {
    int64_t perf_start_time{0};
    int64_t perf_end_time{0};
    // The total number of packets had sent.
    int64_t origin_sent_packet_nums{0};
    // The total number of packets actually sent successfully.
    int64_t valid_sent_packet_nums{0};

    std::unique_ptr<base::DictionaryValue> ToJson() const;
  };

  int net_error{OK};
  int detect_error{ND_ERR_OK};
  TotalStats total_stats;
  std::vector<SectionStats> section_stats_group;

  SenderReport();
  virtual ~SenderReport();
  SenderReport(const SenderReport& other);
};
typedef SenderReport::SectionStats SectionStats;
typedef SenderReport::TotalStats TotalStats;

struct BasePerfReport : public BaseDetectReport {
  struct PerfParam {
    uint32_t byte_rate{0};
    uint16_t duration_s{0};
    uint16_t frame_bytes{0};

    std::unique_ptr<base::DictionaryValue> ToJson() const;
  };

  // The identity of the detection.
  uint64_t task_id{0};
  int64_t start_trans_time{0};
  int64_t end_trans_time{0};
  std::string resolved_target;
  PerfParam param;
  TotalStats total_stats;
  std::vector<SectionStats> section_stats_group;

  BasePerfReport();
  ~BasePerfReport() override;
  BasePerfReport(const BasePerfReport& other);
  std::unique_ptr<base::DictionaryValue> ToJson() const override;
};

struct UdpPerfReport : public BasePerfReport {
  // Returns |value| if it is the udp perf report, nullptr otherwise.
  static std::unique_ptr<UdpPerfReport> From(
      std::unique_ptr<BaseDetectReport> value);

  UdpPerfReport();
  ~UdpPerfReport() override;
  std::string GetReportName() const override;
  std::unique_ptr<BaseDetectReport> Clone() override;
};

struct TcpPerfReport : public BasePerfReport {
  // Returns |value| if it is the tcp perf report, nullptr otherwise.
  static std::unique_ptr<TcpPerfReport> From(
      std::unique_ptr<BaseDetectReport> value);

  TcpPerfReport();
  ~TcpPerfReport() override;
  std::string GetReportName() const override;
  std::unique_ptr<BaseDetectReport> Clone() override;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_PERF_REPORT_H_
