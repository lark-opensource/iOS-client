#ifndef NET_TTNET_FRONTIER_FRONTIER_PROTOCOL_H_
#define NET_TTNET_FRONTIER_FRONTIER_PROTOCOL_H_

#include <stdint.h>
#include <map>
#include <string>

namespace net {

const int32_t kPaddingSizePerFrame = 256;
const int32_t kDefaultStreamWeight = 16;
const int32_t kMaxVarintBytes = 10;

enum FrontierFrameType {
  FRAME_TYPE_MESSAGE = 0x00,
  FRAME_TYPE_STREAM = 0x01,
  FRAME_TYPE_RECIPT = 0x02,
  FRAME_TYPE_PRIORITY = 0x03,
  FRAME_TYPE_END_STREAM = 0x04,
  FRAME_TYPE_SETTINGS = 0x05,
  FRAME_TYPE_PING = 0x07,
  FRAME_TYPE_GO_AWAY = 0x08,
};

enum FrontierMessageFlags {
  MESSAGE_FLAG_NONE = 0x00,
  MESSAGE_FLAG_MESSAGE_DIGEST = 0x01,
  MESSAGE_FLAG_PADDED = 0x02,
  MESSAGE_FLAG_ACK = 0x10,
  MESSAGE_FLAG_END_MESSAGE = 0x20,
  MESSAGE_FLAG_DATA = 0x40,
  MESSAGE_FLAG_META = 0x80,
};

enum FrontierStreamFlags {
  STREAM_FLAG_NONE = 0x00,
  STREAM_FLAG_MESSAGE_DIGEST = 0x01,
  STREAM_FLAG_PADDED = 0x02,
  STREAM_FLAG_EXCLUIVENESS = 0x04,
  STREAM_FLAG_PRIORITY = 0x08,
  STREAM_FLAG_ACK = 0x10,
  STREAM_FLAG_END_MESSAGE = 0x20,
  STREAM_FLAG_DATA = 0x40,
  STREAM_FLAG_META = 0x80,
};

enum FrontierReciptFlags {
  RECIPT_FLAG_NONE = 0x00,
  RECIPT_FLAG_MESSAGE_DIGEST = 0x01,
  RECIPT_FLAG_PADDED = 0x02,
  RECIPT_FLAG_META = 0x80,
};

enum FrontierPriorityFlags {
  PRIORITY_FLAG_NONE = 0x00,
  PRIORITY_FLAG_EXCLUSIVE = 0x04
};

enum FrontierEndStreamFlags {
  ENDSTREAM_FLAG_NONE = 0x00,
  ENDSTREAM_FLAG_ACK = 0x10,
  ENDSTREAM_FLAG_RST = 0x20,
};

enum FrontierGoAwayFlags {
  GOAWAY_FLAG_NONE = 0x00,
};

enum FrontierPingFlags {
  PING_FLAG_NONE = 0x00,
  PING_FLAG_ACK = 0x10,
};

enum FrontierSettingsFlags {
  SETTINGS_FLAG_NONE = 0x00,
  SETTINGS_FLAG_ACK = 0x10,
};

enum FrontierFrameFlag {
  MESSAGE_DIGEST = 0x01,
  PADDED = 0x02,
  EXCLUIVENESS = 0x04,
  PRIORITY = 0x08,
  ACK = 0x10,
  END_MESSAGE = 0x20,
  DATA = 0x40,
  META = 0x80,
};

enum FrontierSettingsId {
  SETTINGS_MAX_CONCURRENT_STREAMS =
      0x01,  // this setting's stream id must be 0.
  SETTINGS_MAX_FRAME_SIZE =
      0x02,                    // stream id must be 0, initial value is 16384.
  SETTINGS_MSG_CURSOR = 0x03,  // stream id must be not 0.
  SETTINGS_APP_ON_BACKGROUND = 0x04,  // stream id must be 0.
};

using SettingsMap = std::map<FrontierSettingsId, uint32_t>;

class FrontierFrameIR {
 public:
  virtual ~FrontierFrameIR();

  virtual FrontierFrameType frontier_frame_type() const = 0;
  virtual std::string SerializeFrameToString() const = 0;

  int64_t message_id() const { return message_id_; }
  void set_message_id(int64_t message_id) { message_id_ = message_id; }

  int64_t frontier_stream_id() const { return frontier_stream_id_; }
  void set_frontier_stream_id(int64_t stream_id) {
    frontier_stream_id_ = stream_id;
  }

 protected:
  FrontierFrameIR(int64_t stream_id, int64_t message_id);
  FrontierFrameIR(const FrontierFrameIR&) = delete;
  FrontierFrameIR& operator=(const FrontierFrameIR&) = delete;

 private:
  int64_t frontier_stream_id_;
  int64_t message_id_;
};

class FrontierMetaFrameIR : public FrontierFrameIR {
 public:
  ~FrontierMetaFrameIR() override;

  void enable_message_digest(bool enable_message_digest) {
    enable_message_digest_ = enable_message_digest;
  }
  bool message_digest_enabled() const { return enable_message_digest_; }

  void set_need_ack(bool need_ack) { need_ack_ = need_ack; }
  bool need_ack() const { return need_ack_; }

  void set_end_message(bool end_message) { end_message_ = end_message; }
  bool end_message() const { return end_message_; }

  bool padded() const { return padded_; }
  size_t padding_payload_len() const { return padding_payload_len_; }
  void set_padding_len(size_t padding_len);

  const char* meta() const { return meta_store_.c_str(); }
  size_t meta_len() const { return meta_store_.length(); }

  const char* data() const { return data_store_.c_str(); }
  size_t data_len() const { return data_store_.length(); }

 protected:
  FrontierMetaFrameIR(int64_t stream_id, int64_t message_id);

  FrontierMetaFrameIR(const FrontierMetaFrameIR&) = delete;
  FrontierMetaFrameIR& operator=(const FrontierMetaFrameIR&) = delete;

  void set_meta(const std::string& meta) { meta_store_ = meta; }

  void set_data(const std::string& data) { data_store_ = data; }

 private:
  bool enable_message_digest_;
  bool need_ack_;
  bool end_message_;

  bool padded_;
  // padding_payload_len_ = desired padding length - len(padding length field).
  size_t padding_payload_len_;

  std::string meta_store_;
  std::string data_store_;
};

// meta is optional is message frame
class FrontierMessageFrameIR : public FrontierMetaFrameIR {
 public:
  FrontierMessageFrameIR(int64_t stream_id,
                         int64_t message_id,
                         const std::string& meta,
                         const std::string& data);
  FrontierMessageFrameIR(int64_t stream_id,
                         int64_t message_id,
                         const std::string& meta,
                         const std::string& data,
                         bool enable_message_digest,
                         bool need_ack,
                         bool is_end_message,
                         size_t padding_len);

  FrontierMessageFrameIR(const FrontierMessageFrameIR&) = delete;
  FrontierMessageFrameIR& operator=(const FrontierMessageFrameIR&) = delete;

  ~FrontierMessageFrameIR() override;

  std::string SerializeFrameToString() const override;

 private:
  FrontierFrameType frontier_frame_type() const override;
};

// stream frame must have meta, data and priority is optional
class FrontierStreamFrameIR : public FrontierMetaFrameIR {
 public:
  FrontierStreamFrameIR(int64_t stream_id,
                        int64_t message_id,
                        uint64_t connection_id,
                        const std::string& meta,
                        const std::string& data);

  FrontierStreamFrameIR(int64_t stream_id,
                        int64_t message_id,
                        uint64_t connection_id,
                        const std::string& meta,
                        const std::string& data,
                        int64_t parent_stream_id,
                        int32_t weight,
                        bool is_exclusive);

  FrontierStreamFrameIR(int64_t stream_id,
                        int64_t message_id,
                        uint64_t connection_id,
                        const std::string& meta,
                        const std::string& data,
                        bool enable_message_digest,
                        bool need_ack,
                        bool is_end_message,
                        size_t padding_len,
                        int64_t parent_stream_id,
                        int32_t weight,
                        bool is_exclusive);

  FrontierStreamFrameIR(const FrontierStreamFrameIR&) = delete;
  FrontierStreamFrameIR& operator=(const FrontierStreamFrameIR&) = delete;

  ~FrontierStreamFrameIR() override;

  std::string SerializeFrameToString() const override;

  bool has_priority() const { return has_priority_; }
  int32_t weight() const { return weight_; }
  void set_weight(int32_t weight) {
    has_priority_ = true;
    weight_ = weight;
  }
  int64_t parent_stream_id() const { return parent_stream_id_; }
  void set_parent_stream_id(int64_t id) {
    has_priority_ = true;
    parent_stream_id_ = id;
  }
  bool exclusive() const { return exclusive_; }
  void set_exclusive(bool exclusive) {
    has_priority_ = true;
    exclusive_ = exclusive;
  }

  uint64_t connection_id() const { return connection_id_; }

 private:
  FrontierFrameType frontier_frame_type() const override;

  uint64_t connection_id_;
  bool has_priority_;
  int64_t parent_stream_id_;
  int32_t weight_;
  bool exclusive_;
};

class FrontierReciptFrameIR : public FrontierFrameIR {
 public:
  FrontierReciptFrameIR(int64_t stream_id,
                        int64_t message_id,
                        int64_t recipt_message_id);

  FrontierReciptFrameIR(int64_t stream_id,
                        int64_t message_id,
                        int64_t recipt_message_id,
                        const std::string& meta);

  FrontierReciptFrameIR(int64_t stream_id,
                        int64_t message_id,
                        bool enable_message_digest,
                        int64_t recipt_message_id,
                        const std::string& meta,
                        size_t padding_len);

  FrontierReciptFrameIR(const FrontierReciptFrameIR&) = delete;
  FrontierReciptFrameIR& operator=(const FrontierReciptFrameIR&) = delete;

  ~FrontierReciptFrameIR() override;

  int64_t recipt_message_id() const { return recipt_message_id_; }

  std::string SerializeFrameToString() const override;

  const char* meta() const { return meta_store_.c_str(); }
  size_t meta_len() const { return meta_store_.length(); }
  void set_meta(const std::string& meta) { meta_store_ = meta; }

  bool padded() const { return padded_; }
  size_t padding_payload_len() const { return padding_payload_len_; }
  void set_padding_len(size_t padding_len);

  void enable_message_digest(bool enable_message_digest) {
    enable_message_digest_ = enable_message_digest;
  }
  bool message_digest_enabled() const { return enable_message_digest_; }

 private:
  FrontierFrameType frontier_frame_type() const override;

  bool enable_message_digest_;
  int64_t recipt_message_id_;
  bool padded_;
  size_t padding_payload_len_;
  std::string meta_store_;
};

class FrontierPriorityFrameIR : public FrontierFrameIR {
 public:
  FrontierPriorityFrameIR(int64_t stream_id,
                          int64_t message_id,
                          int32_t weight);
  FrontierPriorityFrameIR(int64_t stream_id,
                          int64_t message_id,
                          int64_t parent_stream_id,
                          int32_t weight,
                          bool is_exclusive);
  FrontierPriorityFrameIR(const FrontierPriorityFrameIR&) = delete;
  FrontierPriorityFrameIR& operator=(const FrontierPriorityFrameIR&) = delete;

  ~FrontierPriorityFrameIR() override;

  std::string SerializeFrameToString() const override;

  int64_t parent_stream_id() const { return parent_stream_id_; }
  int32_t weight() const { return weight_; }
  bool is_exclusive() const { return is_exclusive_; }

 private:
  FrontierFrameType frontier_frame_type() const override;
  int64_t parent_stream_id_;
  int32_t weight_;
  bool is_exclusive_;
};

class FrontierEndStreamFrameIR : public FrontierFrameIR {
 public:
  FrontierEndStreamFrameIR(int64_t stream_id,
                           int64_t message_id,
                           uint32_t error_code,
                           bool is_ack,
                           bool is_rst);
  FrontierEndStreamFrameIR(int64_t stream_id,
                           int64_t message_id,
                           uint32_t error_code,
                           bool is_ack);
  FrontierEndStreamFrameIR(const FrontierEndStreamFrameIR&) = delete;
  FrontierEndStreamFrameIR& operator=(const FrontierEndStreamFrameIR&) = delete;

  ~FrontierEndStreamFrameIR() override;

  std::string SerializeFrameToString() const override;

  uint32_t error_code() const { return error_code_; }

  bool is_ack() const { return is_ack_; }

  bool is_rst() const { return is_rst_; }

 private:
  FrontierFrameType frontier_frame_type() const override;

  uint32_t error_code_;
  bool is_ack_;
  bool is_rst_;
};

class FrontierGoAwayFrameIR : public FrontierFrameIR {
 public:
  FrontierGoAwayFrameIR(int64_t stream_id,
                        int64_t message_id,
                        int64_t last_stream_id,
                        uint32_t error_code,
                        const std::string& description);

  FrontierGoAwayFrameIR(const FrontierGoAwayFrameIR&) = delete;
  FrontierGoAwayFrameIR& operator=(const FrontierGoAwayFrameIR&) = delete;

  ~FrontierGoAwayFrameIR() override;

  std::string SerializeFrameToString() const override;

  int64_t last_stream_id() const { return last_stream_id_; }

  uint32_t error_code() const { return error_code_; }

 private:
  FrontierFrameType frontier_frame_type() const override;

  int64_t last_stream_id_;
  uint32_t error_code_;
  std::string desctiption_store_;
};

class FrontierPingFrameIR : public FrontierFrameIR {
 public:
  FrontierPingFrameIR(int64_t stream_id, int64_t message_id, bool is_ack);
  FrontierPingFrameIR(int64_t stream_id,
                      int64_t message_id,
                      bool is_ack,
                      uint32_t interval,
                      uint8_t max_fails,
                      uint32_t fails_timeout);

  FrontierPingFrameIR(const FrontierPingFrameIR&) = delete;
  FrontierPingFrameIR& operator=(const FrontierPingFrameIR&) = delete;

  ~FrontierPingFrameIR() override;

  std::string SerializeFrameToString() const override;

  bool is_ack() const { return is_ack_; }

 private:
  FrontierFrameType frontier_frame_type() const override;

  bool is_ack_;
  uint32_t interval_;
  uint8_t max_fails_;
  uint32_t fails_timeout_;
};

class FrontierSettingsFrameIR : public FrontierFrameIR {
 public:
  FrontierSettingsFrameIR(int64_t stream_id, int64_t message_id, bool is_ack);

  FrontierSettingsFrameIR(const FrontierSettingsFrameIR&) = delete;
  FrontierSettingsFrameIR& operator=(const FrontierSettingsFrameIR&) = delete;

  ~FrontierSettingsFrameIR() override;

  std::string SerializeFrameToString() const override;

  bool is_ack() const { return is_ack_; }
  const SettingsMap& values() const { return values_; }

  void AddSetting(FrontierSettingsId id, uint32_t value) {
    values_[id] = value;
  }

 private:
  FrontierFrameType frontier_frame_type() const override;

  SettingsMap values_;
  bool is_ack_;
};

}  // namespace net

#endif  // NET_TTNET_FRONTIER_FRONTIER_PROTOCOL_H_
