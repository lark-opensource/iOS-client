#ifndef NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_GOAWAY_PAYLOAD_DECODER_H_
#define NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_GOAWAY_PAYLOAD_DECODER_H_

#include "net/third_party/quiche/src/http2/decoder/decode_buffer.h"
#include "net/third_party/quiche/src/http2/decoder/decode_status.h"
#include "net/third_party/quiche/src/http2/decoder/frame_decoder_state.h"
#include "net/tt_net/frontier/internal/frontier_internal_structures.h"

namespace net {

class FrontierGoAwayDecoder {
 public:
  // Starts decoding a Frontier GoAway frame's payload, and completes it if
  // the entire payload is in the provided decode buffer.
  http2::DecodeStatus StartDecodingPayload(http2::FrameDecoderState* state,
                                           http2::DecodeBuffer* db);

  // Resumes decoding a Frontier GoAway frame's payload that has been split
  // across decode buffers.
  http2::DecodeStatus ResumeDecodingPayload(http2::FrameDecoderState* state,
                                            http2::DecodeBuffer* db);

  enum class PayloadState {
    kStartDecodingLastStreamId,
    kResumeDecodingLastStreamId,
    kStartDecodingErrorCode,
    kResumeDecodingErrorCode,
    kReadDebugData,
  };

 private:
  PayloadState payload_state_;

  FrontierVarintFields last_stream_id_;
  FrontierUint32Fields error_code_;
  size_t data_length_{0};
};

}  // namespace net

#endif  // NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_GOAWAY_PAYLOAD_DECODER_H_
