#ifndef NET_TTNET_FRONTIER_FRONTIER_STRUCTURES_H_
#define NET_TTNET_FRONTIER_FRONTIER_STRUCTURES_H_

#include <map>
#include "base/memory/scoped_refptr.h"

namespace net {

class IOBufferWithSize;

struct FrontierPingFields {
  FrontierPingFields();
  static constexpr size_t EncodedSize() { return 9; }
  uint8_t opaque_bytes[9];
  int64_t stream_id;
  int64_t message_id;
  bool is_ack;
  uint32_t interval;
  uint32_t max_fails;
  uint32_t fails_timeout;
};

struct FrontierMessageFields {
  FrontierMessageFields(int64_t stream_id,
                        int64_t message_id,
                        bool fin,
                        bool need_ack,
                        bool has_meta,
                        scoped_refptr<IOBufferWithSize> data,
                        scoped_refptr<IOBufferWithSize> meta);
  ~FrontierMessageFields();

  int64_t stream_id;
  int64_t message_id;
  bool fin;
  bool need_ack;
  bool has_meta;
  scoped_refptr<IOBufferWithSize> data;
  scoped_refptr<IOBufferWithSize> meta;
};

struct FrontierStreamFields {
  FrontierStreamFields(int64_t stream_id,
                       int64_t message_id,
                       uint64_t connection_id,
                       bool has_priority,
                       int32_t weight,
                       int64_t parent_stream_id,
                       bool exelusive,
                       bool fin,
                       bool need_ack,
                       bool has_data,
                       scoped_refptr<IOBufferWithSize> data,
                       scoped_refptr<IOBufferWithSize> meta);
  ~FrontierStreamFields();

  int64_t stream_id;
  int64_t message_id;
  uint64_t connection_id;
  bool has_priority;
  int32_t weight;
  int64_t parent_stream_id;
  bool exelusive;
  bool fin;
  bool need_ack;
  bool has_data;
  scoped_refptr<IOBufferWithSize> data;
  scoped_refptr<IOBufferWithSize> meta;
};

struct FrontierReciptFields {
  FrontierReciptFields(int64_t stream_id,
                       int64_t message_id,
                       int64_t recipt_message_id,
                       bool has_meta,
                       scoped_refptr<IOBufferWithSize> meta);
  ~FrontierReciptFields();

  int64_t stream_id;
  int64_t message_id;
  int64_t recipt_message_id;
  bool has_meta;
  scoped_refptr<IOBufferWithSize> meta;
};

struct FrontierPriorityFields {
  FrontierPriorityFields();
  FrontierPriorityFields(int64_t stream_id,
                         int64_t message_id,
                         int64_t parent_stream_id,
                         int32_t weight,
                         bool is_exclusive)
      : stream_id(stream_id),
        message_id(message_id),
        parent_stream_id(parent_stream_id),
        weight(weight),
        is_exclusive(is_exclusive) {}

  int64_t stream_id;
  int64_t message_id;
  int64_t parent_stream_id;
  int32_t weight;
  bool is_exclusive;
};

struct FrontierEndStreamFields {
  FrontierEndStreamFields(int64_t stream_id,
                          int64_t message_id,
                          uint32_t error_code,
                          bool is_rst,
                          bool is_ack)
      : stream_id(stream_id),
        message_id(message_id),
        error_code(error_code),
        is_rst(is_rst),
        is_ack(is_ack) {}

  int64_t stream_id;
  int64_t message_id;
  uint32_t error_code;
  bool is_rst;
  bool is_ack;
};

struct FrontierGoAwayFields {
  FrontierGoAwayFields(int64_t stream_id,
                       int64_t message_id,
                       int64_t last_stream_id,
                       uint32_t error_code,
                       scoped_refptr<IOBufferWithSize> data);
  ~FrontierGoAwayFields();

  int64_t stream_id;
  int64_t message_id;
  int64_t last_stream_id;
  uint32_t error_code;
  scoped_refptr<IOBufferWithSize> data;
};

struct FrontierSettingsFields {
  FrontierSettingsFields(int64_t stream_id,
                         int64_t message_id,
                         bool is_ack,
                         const std::map<uint16_t, uint32_t>& values);
  ~FrontierSettingsFields();

  int64_t stream_id;
  int64_t message_id;
  bool is_ack;
  std::map<uint16_t, uint32_t> values;
};

}  // namespace net

#endif  // NET_TTNET_FRONTIER_STRUCTURES_H_
