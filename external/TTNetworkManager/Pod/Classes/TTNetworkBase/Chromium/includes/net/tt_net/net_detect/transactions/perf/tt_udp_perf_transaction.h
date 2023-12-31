// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_UDP_PERF_TRANSACTION_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_UDP_PERF_TRANSACTION_H_

#include "net/tt_net/net_detect/transactions/perf/tt_base_perf_transaction.h"

namespace net {
namespace tt_detect {

class TTUdpPerfTransaction : public TTBasePerfTransaction {
 public:
  TTUdpPerfTransaction(const DetectTarget& parsed_target,
                       base::WeakPtr<TTNetDetectTransactionCallback> callback);
  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

 private:
  struct PerfUdpProtocol {
    uint8_t version{0};
    uint16_t data_len{0};
    uint64_t task_id{0};
    uint64_t packet_id{0};
    uint64_t sending_time{0};
    BasePerfReport::PerfParam param;
  };

  ~TTUdpPerfTransaction() override;
  void OnProtocolPreparing() override;
  void OnProtocolWriting(scoped_refptr<DrainableIOBuffer>& io_buffer) override;
  int GetTransportPacketHeader() const override;
  int GetPerfProtocolLength() const override;

  PerfUdpProtocol protocol_;
  base::WeakPtrFactory<TTBasePerfTransaction> weak_factory_{this};
  DISALLOW_COPY_AND_ASSIGN(TTUdpPerfTransaction);
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_PERF_TT_UDP_PERF_TRANSACTION_H_
