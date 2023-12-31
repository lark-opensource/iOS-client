// Copyright (c) 2020 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NQE_TT_NQE_CONSTANTS_H_
#define NET_TT_NET_NQE_TT_NQE_CONSTANTS_H_

namespace net {
enum PacketLossAnalyzerProtocol {
  PROTOCOL_TCP = 0,
  PROTOCOL_QUIC,
  PROTOCOL_COUNT
};
}

#endif