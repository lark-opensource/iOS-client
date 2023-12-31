// Copyright (c) 2021 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_TCP_ECHO_TRANSACTION_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_TCP_ECHO_TRANSACTION_H_

#include "net/base/io_buffer.h"
#include "net/tt_net/net_detect/transactions/reports/tt_tcp_echo_report.h"
#include "net/tt_net/net_detect/transactions/tt_tcp_connect_transaction.h"

namespace net {
namespace tt_detect {

class TTTCPEchoTransaction : public TTTCPConnectTransaction {
 public:
  TTTCPEchoTransaction(const DetectTarget& parsed_target,
                       base::WeakPtr<TTNetDetectTransactionCallback> callback);
  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

 private:
  enum State {
    STATE_RESOLVE_HOST,
    STATE_RESOLVE_HOST_COMPLETE,
    STATE_TCP_CONNECT,
    STATE_TCP_CONNECT_COMPLETE,
    STATE_TCP_WRITE,
    STATE_TCP_WRITE_COMPLETE,
    STATE_TCP_READ,
    STATE_TCP_READ_COMPLETE,
    STATE_NONE,
  };
  ~TTTCPEchoTransaction() override;
  void StartInternal() override;

  int DoLoop(int result) override;
  int DoResolveHost() override;
  int DoResolveHostComplete(int result) override;
  int DoTCPConnect() override;
  int DoTCPConnectComplete(int result) override;
  int DoTCPWrite();
  int DoTCPWriteComplete(int result);
  int DoTCPRead();
  int DoTCPReadComplete(int result);
  TcpEchoReport* GetReport() const;

  base::TimeTicks tcp_write_start_;
  base::TimeTicks tcp_read_start_;

  State next_state_{STATE_NONE};
  scoped_refptr<IOBufferWithSize> read_buffer_{nullptr};
  std::string echo_send_msg_;
  std::string echo_reply_msg_;
  base::WeakPtrFactory<TTTCPConnectTransaction> factory_;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_RAW_DETECT_TRANSACTIONS_TT_TCP_ECHO_TRANSACTION_H_
