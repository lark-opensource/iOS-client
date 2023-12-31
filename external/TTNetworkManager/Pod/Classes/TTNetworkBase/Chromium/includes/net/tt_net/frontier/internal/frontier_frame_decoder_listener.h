#ifndef NET_TTNET_FRONTIER_INTERNAL_FRONTIER_FRAME_DECODER_LISTENER_H_
#define NET_TTNET_FRONTIER_INTERNAL_FRONTIER_FRAME_DECODER_LISTENER_H_

#include "net/tt_net/frontier/frontier_protocol.h"
#include "net/tt_net/frontier/frontier_structures.h"
#include "net/tt_net/frontier/internal/frontier_internal_structures.h"

namespace net {

class FrontierFrameDecoderListener {
 public:
  FrontierFrameDecoderListener() {}
  virtual ~FrontierFrameDecoderListener() {}

  // check header when header decode completed, if return false, discard payload
  virtual bool OnFrontierFrameHeader(const FrontierFrameHeader& header) = 0;

  // message frame listener
  virtual void OnMessageStart(const FrontierFrameHeader& header) = 0;
  virtual void OnMessageEnd() = 0;

  // stream frame listener
  virtual void OnStreamStart(const FrontierFrameHeader& header) = 0;
  virtual void OnStreamPriority(
      const FrontierPriorityFields& priority_fields) = 0;
  virtual void OnStreamConnetionId(const uint64_t connection_id) = 0;
  virtual void OnStreamEnd() = 0;

  // message or stream frame listener
  virtual void OnMessageDigest(const uint32_t message_digest,
                               FrontierFrameType frontier_frame_type) = 0;
  virtual void OnMetaLength(size_t meta_length,
                            FrontierFrameType frontier_frame_type) = 0;
  virtual void OnMeta(const char* data, size_t len) = 0;
  virtual void OnDataPayload(const char* data,
                             size_t len,
                             size_t data_length) = 0;

  // recipt frame listener
  virtual void OnReciptStart(const FrontierFrameHeader& header) = 0;
  virtual void OnReciptEnd() = 0;
  virtual void OnReciptMessageId(int64_t message_id) = 0;

  // padding fields
  virtual void OnPadLength(size_t pad_length,
                           FrontierFrameType frontier_frame_type) = 0;
  virtual void OnPadding(const char* padding, size_t skipped_length) = 0;
  virtual void OnPaddingTooLong(const FrontierFrameHeader& header,
                                size_t missing_length) = 0;

  virtual void OnFrameSizeError(const FrontierFrameHeader& header) = 0;

  // control frame listener
  virtual void OnEndStream(const FrontierFrameHeader& header,
                           uint32_t error_code) = 0;
  virtual void OnEndStreamAck(const FrontierFrameHeader& header,
                              uint32_t error_code) = 0;

  virtual void OnGoAwayStart(const FrontierFrameHeader& header,
                             int64_t last_stream_id,
                             uint32_t error_code,
                             size_t data_length) = 0;
  virtual void OnGoAwayAdditionalDebugData(const char* data,
                                           size_t len,
                                           size_t data_length) = 0;
  virtual void OnGoAwayEnd() = 0;

  virtual void OnPing(const FrontierFrameHeader& header,
                      const FrontierPingFields& ping_fields) = 0;
  virtual void OnPingAck(const FrontierFrameHeader& header,
                         const FrontierPingFields& ping_fields) = 0;

  virtual void OnPriority(const FrontierFrameHeader& header,
                          const FrontierPriorityFields& priority_fields) = 0;

  virtual void OnSettingsStart(const FrontierFrameHeader& header) = 0;
  virtual void OnSetting(
      const FrontierOneSettingFileds& one_setting_fields) = 0;
  virtual void OnSettingsEnd() = 0;
  virtual void OnSettingsAck(const FrontierFrameHeader& header) = 0;
};

// Do nothing for each call. Useful for ignoring a frame that is invalid.
class FrontierFrameDecoderNoOpListener : public FrontierFrameDecoderListener {
 public:
  FrontierFrameDecoderNoOpListener() {}
  ~FrontierFrameDecoderNoOpListener() override;

  bool OnFrontierFrameHeader(const FrontierFrameHeader& header) override;
  void OnMessageStart(const FrontierFrameHeader& header) override {}
  void OnDataPayload(const char* data,
                     size_t len,
                     size_t data_length) override {}
  void OnMessageEnd() override {}

  // stream frame listener
  void OnStreamStart(const FrontierFrameHeader& header) override {}
  void OnMessageDigest(const uint32_t message_digest,
                       FrontierFrameType frontier_frame_type) override {}
  void OnStreamPriority(
      const FrontierPriorityFields& priority_fields) override {}
  void OnStreamConnetionId(const uint64_t connection_id) override {}
  void OnStreamEnd() override {}

  // stream or message frame listener
  void OnMetaLength(size_t meta_length,
                    FrontierFrameType frontier_frame_type) override {}
  void OnMeta(const char* data, size_t len) override {}

  // recipt frame listener
  void OnReciptStart(const FrontierFrameHeader& header) override {}
  void OnReciptEnd() override {}
  void OnReciptMessageId(int64_t message_id) override {}

  void OnPadLength(size_t pad_length,
                   FrontierFrameType frontier_frame_type) override {}

  void OnPadding(const char* padding, size_t skipped_length) override {}
  void OnPaddingTooLong(const FrontierFrameHeader& header,
                        size_t missing_length) override {}
  void OnFrameSizeError(const FrontierFrameHeader& header) override {}

  void OnEndStream(const FrontierFrameHeader& header,
                   uint32_t error_code) override {}
  void OnEndStreamAck(const FrontierFrameHeader& header,
                      uint32_t error_code) override {}

  void OnGoAwayStart(const FrontierFrameHeader& header,
                     int64_t last_stream_id,
                     uint32_t error_code,
                     size_t data_length) override {}
  void OnGoAwayAdditionalDebugData(const char* data,
                                   size_t len,
                                   size_t data_length) override {}
  void OnGoAwayEnd() override {}

  void OnPing(const FrontierFrameHeader& header,
              const FrontierPingFields& ping_fields) override {}
  void OnPingAck(const FrontierFrameHeader& header,
                 const FrontierPingFields& ping_fields) override {}

  void OnPriority(const FrontierFrameHeader& header,
                  const FrontierPriorityFields& priority_fields) override {}

  void OnSettingsStart(const FrontierFrameHeader& header) override {}
  void OnSetting(const FrontierOneSettingFileds& one_setting_fields) override {}
  void OnSettingsEnd() override {}
  void OnSettingsAck(const FrontierFrameHeader& header) override {}
};

static_assert(!std::is_abstract<FrontierFrameDecoderNoOpListener>(),
              "FrontierFrameDecoderNoOpListener ought to be concrete.");

}  // namespace net

#endif  // NET_TTNET_FRONTIER_INTERNAL_FRONTIER_FRAME_DECODER_LISTENER_H_
