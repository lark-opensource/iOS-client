// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_UDP_PING_TRANSACTION_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_UDP_PING_TRANSACTION_

#include <string>
#include <vector>

#include "base/callback.h"
#include "net/tt_net/net_detect/transactions/tt_ping_transaction.h"

namespace net {
namespace tt_detect {

class TTUdpPingTransaction : public TTPingTransaction {
 public:
  TTUdpPingTransaction(const DetectTarget& parsed_target,
                       base::WeakPtr<TTNetDetectTransactionCallback> callback);
  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

 private:
  scoped_refptr<IOBuffer> MakeEchoMsg(int* buffer_size,
                                      int64_t echo_time) override;
  bool ParseAndCheckReplyMsg(int size, uint16_t seq) override;
  bool SetClientSocketOption() override;

  ~TTUdpPingTransaction() override;
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TT_UDP_PING_TRANSACTION_
