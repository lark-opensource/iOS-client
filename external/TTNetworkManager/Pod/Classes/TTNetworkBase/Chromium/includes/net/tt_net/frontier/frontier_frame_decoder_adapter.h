#ifndef NET_TTNET_FRONTIER_FRONTIER_FRAME_DECODER_ADAPTER_H_
#define NET_TTNET_FRONTIER_FRONTIER_FRAME_DECODER_ADAPTER_H_

#include <stdint.h>
#include <string>

#include "net/net_buildflags.h"

namespace net {

class FrontierFrameDecoder;
class FrontierFrameDecoderListenerImpl;
class FrontierFrameDecoderNoOpListener;
struct FrontierEndStreamFields;
struct FrontierGoAwayFields;
struct FrontierMessageFields;
struct FrontierPingFields;
struct FrontierPriorityFields;
struct FrontierReciptFields;
struct FrontierSettingsFields;
struct FrontierStreamFields;

enum FrontierDecodeError {
  INVALID_STREAM_ID = -100,
  INVALID_MESSAGE_ID = -101,
  UNEXPECTED_FRAME = -102,
  INVALID_PADDING = -103,
  UNEXPECTED_FRAME_SIZE = -104,
  CRC32_CHECK_FAIL = -105,
  INVALID_SETTING_ID = -106,
  UNEXPECTED_HEADER = -107,
};

class FrontierDecoderAdapter {
 public:
  class FrontierFramerVisitorInterface {
   public:
    FrontierFramerVisitorInterface() {}
    virtual ~FrontierFramerVisitorInterface() {}

    virtual void OnError(int64_t current_stream_id,
                         int64_t current_message_id,
                         int32_t error,
                         uint32_t origin_stream_id,
                         bool fin) = 0;

    virtual void OnMessageFrame(const FrontierMessageFields& message_fields,
                                uint32_t origin_stream_id,
                                bool fin) = 0;

    virtual void OnStreamFrame(const FrontierStreamFields& stream_fields,
                               uint32_t origin_stream_id,
                               bool fin) = 0;

    virtual void OnReciptFrame(const FrontierReciptFields& recipt_fields,
                               uint32_t origin_stream_id,
                               bool fin) = 0;

    // control frame callback
    virtual void OnEndStream(const FrontierEndStreamFields& endstream_fields,
                             uint32_t origin_stream_id,
                             bool fin) = 0;

    virtual void OnGoAway(const FrontierGoAwayFields& goaway_fields,
                          uint32_t origin_stream_id,
                          bool fin) = 0;

    virtual void OnPing(const FrontierPingFields& ping_frontier,
                        uint32_t origin_stream_id,
                        bool fin) = 0;

    virtual void OnPriority(const FrontierPriorityFields& priority_fields,
                            uint32_t origin_stream_id,
                            bool fin) = 0;

    virtual void OnSettings(const FrontierSettingsFields& settings_fields,
                            uint32_t origin_stream_id,
                            bool fin) = 0;
  };

  FrontierDecoderAdapter();
  ~FrontierDecoderAdapter();

  void set_visitor(
      FrontierDecoderAdapter::FrontierFramerVisitorInterface* visitor);
  FrontierDecoderAdapter::FrontierFramerVisitorInterface* visitor() const;

  size_t ProcessInput(uint32_t stream_id, const std::string& data, bool fin);

 private:
  friend class FrontierFrameDecoderListenerImpl;
#if BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  friend class FrontierFramerTest;
#endif
  // TODO decoder state
  enum FrontierState {
    FRONTIER_ERROR,
    FRONTIER_UNKNOWN,
    FRONTIER_READY_FOR_FRAME,
    FRONTIER_DECODER_HEADER,
    FRONTIER_IGNORE_PAYLOAD,
    FRONTIER_CONSUME_DATA_FRAME_PAYLOAD,
    FRONTIER_CONSUME_CONTROL_FRAME_PAYLOAD,
  };

  size_t ProcessInputFrame(const char* data, size_t len);
  void ResetBetweenFrames();
  bool IsDiscardingPayload();

  FrontierDecoderAdapter::FrontierState frontier_state() const;
  void set_frontier_state(FrontierDecoderAdapter::FrontierState state);
  uint32_t origin_stream_id() { return origin_stream_id_; }
  bool origin_fin() { return origin_fin_; }

  FrontierState frontier_state_;
  std::unique_ptr<FrontierFrameDecoder> frame_decoder_;

  std::unique_ptr<FrontierFrameDecoderListenerImpl> frame_decoder_listener_;
  std::unique_ptr<FrontierFrameDecoderNoOpListener> no_op_listener_;

  FrontierFramerVisitorInterface* visitor_;

  uint32_t origin_stream_id_;
  bool origin_fin_;
};

}  // namespace net

#endif  // NET_TTNET_FRONTIER_FRONTIER_FRAME_DECODER_ADAPTER_H_
