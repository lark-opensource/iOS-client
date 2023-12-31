#ifndef NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_PRIORITY_PAYLOAD_DECODER_H_
#define NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_PRIORITY_PAYLOAD_DECODER_H_

#include "net/third_party/quiche/src/http2/decoder/decode_buffer.h"
#include "net/third_party/quiche/src/http2/decoder/decode_status.h"
#include "net/third_party/quiche/src/http2/decoder/frame_decoder_state.h"

namespace net {

class FrontierPriorityDecoder {
 public:
  // Starts decoding a Frontier Priority frame's payload, and completes it if
  // the entire payload is in the provided decode buffer.
  http2::DecodeStatus StartDecodingPayload(http2::FrameDecoderState* state,
                                           http2::DecodeBuffer* db);

  // Resumes decoding a Frontier Priority frame's payload that has been split
  // across decode buffers.
  http2::DecodeStatus ResumeDecodingPayload(http2::FrameDecoderState* state,
                                            http2::DecodeBuffer* db);

  enum class PayloadState {
    kStartDecodingParentStreamId,
    kResumeDecodingParentStreamId,
    kReadWeight,
  };

 private:
  PayloadState payload_state_;

  uint32_t weight_;
  FrontierVarintFields parent_stream_id_;
};

}  // namespace net

#endif  // NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_PRIORITY_PAYLOAD_DECODER_H_
