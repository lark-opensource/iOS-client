// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_PACKET_LOSS_OBSERVER_H_
#define NET_TT_NET_NQE_TT_PACKET_LOSS_OBSERVER_H_

#include "base/macros.h"
#include "net/base/net_export.h"
#include "net/tt_net/nqe/tt_nqe_constants.h"

namespace net {
class NET_EXPORT_PRIVATE TTPacketLossObserver {
 public:
  virtual void OnPacketLossComputed(PacketLossAnalyzerProtocol protocol,
                                    double send_loss_rate,
                                    double send_loss_variance,
                                    double receive_loss_rate,
                                    double receive_loss_variance) = 0;

  virtual ~TTPacketLossObserver() {}

 protected:
  TTPacketLossObserver() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(TTPacketLossObserver);
};
}  // namespace net

#endif