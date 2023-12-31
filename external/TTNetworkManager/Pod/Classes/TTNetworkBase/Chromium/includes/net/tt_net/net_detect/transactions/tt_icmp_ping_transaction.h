// Copyright (c) 2023 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_ICMP_PING_TRANSACTION_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_TT_ICMP_PING_TRANSACTION_

#include <string>
#include <vector>

#include "base/callback.h"
#include "net/tt_net/net_detect/base/tt_tcpip_protocol.h"
#include "net/tt_net/net_detect/transactions/tt_ping_transaction.h"
#if defined(OS_WIN)
// iphlpapi.h must be in front of icmpapi.h
#include <iphlpapi.h>
#include <icmpapi.h>
#endif

namespace net {
namespace tt_detect {

#if defined(OS_WIN)
using Callback = base::OnceCallback<void(const ICMP_ECHO_REPLY& echoreply)>;
struct WinPingInput {
  WinPingInput(const std::string& host, int timeout, Callback callback);
  ~WinPingInput();
  HANDLE event_handle{nullptr};
  scoped_refptr<base::SingleThreadTaskRunner> net_thread_task_runner;
  std::string host;
  int timeout{2000};
  Callback callback;
  const base::Location location = base::Location::Current();
  DISALLOW_COPY_AND_ASSIGN(WinPingInput);
};
#endif

class TTIcmpPingTransaction : public TTPingTransaction {
 public:
  TTIcmpPingTransaction(const DetectTarget& parsed_target,
                        base::WeakPtr<TTNetDetectTransactionCallback> callback);
  std::unique_ptr<BaseDetectReport> GetDetectReport() const override;

 private:
  size_t icmp_pkg_len_{ttnet::ICMP_PKG_SIZE};
  char icmp_pkg_[ttnet::ICMP_PKG_SIZE];
#if defined(OS_WIN)
  int64_t echo_time_{-1};
  void OnComplete(const ICMP_ECHO_REPLY& echo_reply);
  static void IcmpTaskCompletedOnNetworkThread(
      base::WeakPtr<TTIcmpPingTransaction> transaction,
      const ICMP_ECHO_REPLY& echo_reply);
  static void CALLBACK IcmpTaskOnWinThread(void* param, BOOLEAN timed_out);
#endif
  void SendEcho() override;
  scoped_refptr<IOBuffer> MakeEchoMsg(int* buffer_size,
                                      int64_t echo_time) override;
  bool ParseAndCheckReplyMsg(int size, uint16_t seq) override;
  bool SetClientSocketOption() override;

  bool ParseIcmpPkg(char* icmp_pkg, size_t icmp_pkg_len, ttnet::ICMPHeader** reply_header, ttnet::ICMPPayload** reply_playload);
  int IcmpHeaderOffsetInResp(char* recv_buffer, size_t recved_len);

  ~TTIcmpPingTransaction() override;
  base::WeakPtrFactory<TTIcmpPingTransaction> weak_ptr_factory_{this};
  DISALLOW_COPY_AND_ASSIGN(TTIcmpPingTransaction);
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TT_ICMP_PING_TRANSACTION_
