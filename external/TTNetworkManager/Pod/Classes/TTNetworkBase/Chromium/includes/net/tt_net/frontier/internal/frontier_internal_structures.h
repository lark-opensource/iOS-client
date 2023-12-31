#ifndef NET_TTNET_FRONTIER_INTERNAL_FRONTIER_INTERNAL_STRUCTURE_H_
#define NET_TTNET_FRONTIER_INTERNAL_FRONTIER_INTERNAL_STRUCTURE_H_

#include "net/tt_net/frontier/frontier_protocol.h"

namespace net {

struct FrontierFrameHeader {
  bool HasMessageDigest() const;

  bool IsPadded() const;

  bool HasPriority() const;

  // stream frame must have meta, message and recipt may have meta.
  bool HasMeta() const;
  // message frame must have data, stream frame may have
  bool HasData() const;
  bool IsExclusive() const;

  bool IsEndMessage() const;

  bool NeedAck() const;

  bool IsRstEndStream() const;
  bool IsAckFrame() const;

  uint8_t magic;
  FrontierFrameType type;
  FrontierFrameFlag flags;
  int64_t payload_length;
  int64_t stream_id;
  int64_t message_id;
};

struct FrontierVarintFields {
  static constexpr size_t EncodedSize() { return 1; }
  int64_t value;
  uint8_t decode_size;
};

struct FrontierUint32Fields {
  static constexpr size_t EncodedSize() { return 4; }
  uint32_t value;
};

struct FrontierStreamConnectinIdFields {
  static constexpr size_t EncodedSize() { return 8; }
  uint64_t connection_id;
  uint8_t connection_id_bytes[8];
};

struct FrontierOneSettingFileds {
  static constexpr size_t EncodedSize() { return 6; }
  uint16_t id;
  uint32_t value;
};

}  // namespace net

#endif  // NET_TTNET_FRONTIER_INTERNAL_FRONTIER_INTERNAL_STRUCTURE_H_