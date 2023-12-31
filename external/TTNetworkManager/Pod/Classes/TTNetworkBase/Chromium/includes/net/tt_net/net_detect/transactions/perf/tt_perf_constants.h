// Copyright (c) 2022 The ByteDance Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_PERF_CONSTANTS_H_
#define NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_PERF_CONSTANTS_H_

#include <stdint.h>

// Definitions of constant values used throughout the Perf code.
namespace net {
namespace tt_detect {
// The maximum number of sending byte per second.
const uint32_t kMaxSendingByteRate = 128 * 1024 * 1024;

// The maximum sending packet duration second.
const uint32_t kMaxSendingDurationS = 60 * 60;

// The default statistics interval for |PerfSender|.
const uint32_t kDefaultStatsIntervalUs = 1 * 1000 * 1000;

// The max payload size of data link frame.
const uint16_t kMaxEthernetFramePayloadSize = 1500;

// This includes the source and destination physical addresses, the type/length
// field.
// There are also 8 more bytes that carry the packet preamble and the
// start frame delimiter. For convenience, we won't use these in our
// calculations.
const uint8_t kEthernetFrameHeaderSize = 14;

// The Ethernet CRC/FCS.
const uint8_t kEthernetFrameCheckSequenceSize = 4;

// Maximum Ethernet frame over the link layer.
// 1500(Ethernet payload) + 14(Ethernet header) + 4(Ethernet CheckSequence) =
// 1518.
const uint16_t kMaxEthernetFrameSize = kMaxEthernetFramePayloadSize +
                                       kEthernetFrameHeaderSize +
                                       kEthernetFrameCheckSequenceSize;

// Maximum transmission unit on Ethernet.
const uint16_t kEthernetMTU = kMaxEthernetFramePayloadSize;

// The fixed header size of IP packet over IPv4.
const uint8_t kIPV4HeaderSize = 20;

// The fixed header size of IP packet over IPv6.
const uint8_t kIPV6HeaderSize = 40;

// The fixed header size of UDP packet.
const uint8_t kUdpHeaderSize = 8;

// The fixed header size of TCP packet.
const uint8_t kTcpHeaderSize = 20;

}  // namespace tt_detect
}  // namespace net

#endif  // NET_TT_NET_NET_DETECT_TRANSACTIONS_PERF_TT_PERF_CONSTANTS_H_
