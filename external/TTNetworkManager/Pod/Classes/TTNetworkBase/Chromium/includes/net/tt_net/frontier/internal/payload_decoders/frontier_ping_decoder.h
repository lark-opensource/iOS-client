#ifndef NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_PING_PAYLOAD_DECODER_H_
#define NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_PING_PAYLOAD_DECODER_H_

#include "net/third_party/quiche/src/http2/decoder/decode_buffer.h"
#include "net/third_party/quiche/src/http2/decoder/decode_status.h"
#include "net/third_party/quiche/src/http2/decoder/frame_decoder_state.h"
#include "net/tt_net/frontier/frontier_structures.h"

namespace net {

class FrontierPingDecoder {
 public:
  // Starts decoding a Frontier Ping frame's payload, and completes it if
  // the entire payload is in the provided decode buffer.
  http2::DecodeStatus StartDecodingPayload(http2::FrameDecoderState* state,
                                           http2::DecodeBuffer* db);

  // Resumes decoding a Frontier Ping frame's payload that has been split across
  // decode buffers.
  http2::DecodeStatus ResumeDecodingPayload(http2::FrameDecoderState* state,
                                            http2::DecodeBuffer* db);

  enum class PayloadState {
    kStartDecodingOpaqueData,
    kResumeDecodingOpaqueData,
  };

 private:
  http2::DecodeStatus HandleStatus(http2::FrameDecoderState* state,
                                   http2::DecodeStatus status);
  PayloadState payload_state_;
  FrontierPingFields frontier_ping_fields_;
};

}  // namespace net

#endif  // NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_PING_PAYLOAD_DECODER_H_
