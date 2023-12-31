// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_BASE_PERF_TRANSACTION_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_BASE_PERF_TRANSACTION_H_

#include "base/big_endian.h"
#include "base/callback.h"
#include "base/timer/elapsed_timer.h"
#include "net/base/io_buffer.h"
#include "net/base/ip_endpoint.h"
#include "net/dns/host_resolver_manager.h"
#include "net/log/net_log_with_source.h"
#include "net/tt_net/net_detect/transactions/perf/tt_base_perf_sender.h"
#include "net/tt_net/net_detect/transactions/reports/tt_perf_report.h"
#include "net/tt_net/net_detect/transactions/tt_net_detect_transaction.h"

namespace net {
namespace tt_detect {

class TTBasePerfTransaction : public TTNetDetectTransaction {
 public:
  TTBasePerfTransaction(const DetectTarget& parsed_target,
                        base::WeakPtr<TTNetDetectTransactionCallback> callback);

  void StartInternal() override;
  void CancelInternal(int error) override;
  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

  void set_byte_rate(uint32_t byte_rate) { byte_rate_ = byte_rate; }
  void set_frame_bytes(uint16_t frame_bytes) {
    link_frame_bytes_ = frame_bytes;
  }
  void set_duration_s(uint16_t duration_s) { duration_s_ = duration_s; }

 protected:
  friend class TTBasePerfTransactionTest;
  ~TTBasePerfTransaction() override;
  virtual void OnProtocolPreparing() = 0;  // Populate protocol data
  virtual void OnProtocolWriting(
      scoped_refptr<DrainableIOBuffer>& io_buffer) = 0;
  virtual int GetTransportPacketHeader() const = 0;
  virtual int GetPerfProtocolLength() const = 0;

  // Number of sending bytes per second.
  // Valid value range: (0, kMaxSendingByteRate].
  uint32_t byte_rate_{0};
  // The duration second of packet sending.
  // Valid value range: (0, kMaxSendingDurationS].
  uint32_t duration_s_{0};
  // |link_frame_bytes_| is the byte nums of any transport packet.
  // transport packet bytes = protocol header bytes + payload data bytes.
  // Valid value range: (0, kEthernetMTU].
  uint16_t link_frame_bytes_{0};
  // transport packet payload data bytes.
  int16_t transport_payload_bytes_{0};

  HostPortPair origin_host_port_;
  IPEndPoint resolved_dest_;
  std::unique_ptr<BasePerfReport> report_;
  scoped_refptr<DrainableIOBuffer> write_buffer_{nullptr};
  std::unique_ptr<TTBasePerfSender> sender_{nullptr};

 private:
  enum State {
    STATE_INIT,
    STATE_HOST_RESOLVE,
    STATE_HOST_RESOLVE_COMPLETE,
    STATE_PERF_SEND,
    STATE_PERF_SEND_COMPLETE,
    STATE_NONE,
  };

  int DoLoop(int result);
  int DoInit();
  int DoHostResolve();
  int DoHostResolveComplete(int result);
  int DoPerfSend();
  int DoPerfSendComplete(int result);
  void OnIOComplete(int result);
  void DoTransactionCompletion(int result);

  bool CheckParam() const;
  void Stop();

  State next_state_{STATE_NONE};
  HostResolver* host_resolver_{nullptr};
  std::unique_ptr<HostResolver::ResolveHostRequest> resolve_request_{nullptr};
  base::WeakPtrFactory<TTBasePerfTransaction> weak_factory_{this};
  DISALLOW_COPY_AND_ASSIGN(TTBasePerfTransaction);
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_BASE_PERF_TRANSACTION_H_
