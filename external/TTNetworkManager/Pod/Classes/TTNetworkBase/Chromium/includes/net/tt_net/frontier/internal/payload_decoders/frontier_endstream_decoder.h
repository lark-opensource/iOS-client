#ifndef NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_ENDSTREAM_PAYLOAD_DECODER_H_
#define NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_ENDSTREAM_PAYLOAD_DECODER_H_

#include "net/third_party/quiche/src/http2/decoder/decode_buffer.h"
#include "net/third_party/quiche/src/http2/decoder/decode_status.h"
#include "net/third_party/quiche/src/http2/decoder/frame_decoder_state.h"
#include "net/tt_net/frontier/internal/frontier_internal_structures.h"

namespace net {

class FrontierEndStreamDecoder {
 public:
  // Starts decoding a Frontier EndStream frame's payload, and completes it if
  // the entire payload is in the provided decode buffer.
  http2::DecodeStatus StartDecodingPayload(http2::FrameDecoderState* state,
                                           http2::DecodeBuffer* db);

  // Resumes decoding a Frontier EndStream frame's payload that has been split
  // across decode buffers.
  http2::DecodeStatus ResumeDecodingPayload(http2::FrameDecoderState* state,
                                            http2::DecodeBuffer* db);

  enum class PayloadState {
    kStartDecodingErrorCode,
    kResumeDecodingErrorCode,
  };

 private:
  http2::DecodeStatus HandleStatus(http2::FrameDecoderState* state,
                                   http2::DecodeStatus status);
  FrontierUint32Fields error_code_;
  PayloadState payload_state_;
};

}  // namespace net

#endif  // NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_ENDSTREAM_PAYLOAD_DECODER_H_
