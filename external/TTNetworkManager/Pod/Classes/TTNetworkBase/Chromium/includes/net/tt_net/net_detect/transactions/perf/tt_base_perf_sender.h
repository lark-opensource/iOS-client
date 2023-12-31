// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_BASE_PERF_SENDER_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_BASE_PERF_SENDER_H_

#include "base/callback.h"
#include "base/timer/elapsed_timer.h"
#include "base/timer/timer.h"
#include "net/base/completion_once_callback.h"
#include "net/base/io_buffer.h"
#include "net/base/ip_endpoint.h"
#include "net/socket/client_socket_factory.h"
#include "net/tt_net/net_detect/transactions/reports/tt_perf_report.h"

namespace net {
namespace tt_detect {

class TTBasePerfSender {
 public:
  typedef base::RepeatingCallback<void(scoped_refptr<DrainableIOBuffer>&)>
      PacketWritingCallback;
  TTBasePerfSender();
  virtual ~TTBasePerfSender();
  virtual int Start(const IPEndPoint& target,
                    PacketWritingCallback write_callback,
                    CompletionOnceCallback completion_callback);
  virtual void Cancel();

  void set_duration_us(int64_t duration_us) { duration_us_ = duration_us; }
  void set_sending_interval_us(int64_t sending_interval_us) {
    sending_interval_us_ = sending_interval_us;
  }
  void set_stats_interval_us(int64_t stats_interval_us) {
    stats_interval_us_ = stats_interval_us;
  }
  const SenderReport& sender_report() const { return report_; }
  bool is_running() const { return next_state_ != STATE_NONE; }

 protected:
  enum State {
    STATE_INIT = 0,
    STATE_CONNECT,
    STATE_CONNECT_COMPLETE,
    STATE_PACKAGE_WRITE,
    STATE_PACKAGE_WRITE_COMPLETE,
    STATE_PERF_COMPLETE,
    STATE_NONE,
  };
  virtual int SocketConnectImpl();
  virtual int SocketWriteImpl(const scoped_refptr<DrainableIOBuffer>&
                                  buffer);  // Notice: it will run multi times
  virtual void Stop();

  void OnIOComplete(int result);
  void OnSocketWriteComplete(const scoped_refptr<DrainableIOBuffer>& buffer,
                             int result);

  IPEndPoint detect_target_;
  // Packet sending duration.
  int64_t duration_us_{0};
  // Packet sending interval.
  int64_t sending_interval_us_{0};
  // Packet statistics interval.
  int64_t stats_interval_us_{0};

  SectionStats section_stats_;
  SenderReport report_;
  PacketWritingCallback write_callback_;
  CompletionOnceCallback completion_callback_;
  ClientSocketFactory* socket_factory_{nullptr};

 private:
  friend class TTBasePerfTransactionTest;
  int DoLoop(int result);
  int DoInit();
  int DoConnect();
  int DoConnectComplete(int result);
  int DoPackageWrite();  // Notice: it will run multi times
  int SocketWrite(const scoped_refptr<DrainableIOBuffer>& buffer);
  int DoPackageWriteComplete(int result);  // Notice: it will run multi times
  int DoPerfComplete(int result);

  void OnPerfTimeout();         // |duration_timer_| timeout callback
  void OnStatisticsInterval();  // |stats_interval_timer_| timeout callback
  void OnJobComplete(int result);

  State next_state_{STATE_NONE};
  base::TimeTicks start_time_tick_;
  base::OneShotTimer duration_timer_;
  base::RepeatingTimer stats_interval_timer_;

 protected:
  base::WeakPtrFactory<TTBasePerfSender> weak_factory_{this};
};

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_BASE_PERF_SENDER_H_
