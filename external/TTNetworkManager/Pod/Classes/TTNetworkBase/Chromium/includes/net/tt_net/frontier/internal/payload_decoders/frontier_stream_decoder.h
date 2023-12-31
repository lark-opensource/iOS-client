#ifndef NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_STREAM_DECODER_H_
#define NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_STREAM_DECODER_H_

#include "net/third_party/quiche/src/http2/decoder/decode_buffer.h"
#include "net/third_party/quiche/src/http2/decoder/decode_status.h"
#include "net/third_party/quiche/src/http2/decoder/frame_decoder_state.h"
#include "net/tt_net/frontier/frontier_structures.h"
#include "net/tt_net/frontier/internal/frontier_internal_structures.h"

namespace net {

class FrontierStreamDecoder {
 public:
  FrontierStreamDecoder();
  ~FrontierStreamDecoder();
  // Starts decoding a Frontier Stream frame's payload, and completes it if
  // the entire payload is in the provided decode buffer.
  http2::DecodeStatus StartDecodingPayload(http2::FrameDecoderState* state,
                                           http2::DecodeBuffer* db);

  // Resumes decoding a Frontier Stream frame's payload that has been split
  // across decode buffers.
  http2::DecodeStatus ResumeDecodingPayload(http2::FrameDecoderState* state,
                                            http2::DecodeBuffer* db);

  enum class PayloadState {
    kStartDecodingMessageDigestSize,
    kResumeDecodingMessageDigestSize,
    kStartDecodingMessageDigest,
    kResumeDecodingMessageDigest,
    kStartDecodingParentStreamId,
    kResumeDecodingParentStreamId,
    kStartDecodingConnectionId,
    kResumeDecodingConnectionId,
    kReadWeight,
    kReadPadLength,
    kStartDecodingMetaLength,
    kResumeDecodingMetaLength,
    kReadMeta,
    kReadData,
    kSkipPadding,
  };

 private:
  FrontierStreamDecoder::PayloadState DecodeConnectionIdComplete(
      http2::FrameDecoderState* state);

  PayloadState payload_state_;

  FrontierVarintFields message_digest_size_;
  FrontierUint32Fields message_digest_;
  FrontierVarintFields parent_stream_id_;
  uint32_t weight_;
  uint32_t pad_length_;
  size_t data_length_{0};
  FrontierVarintFields meta_length_;
  FrontierPriorityFields frontier_priority_fields_;
  FrontierStreamConnectinIdFields connection_id_fields_;
};

}  // namespace net

#endif  // NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_STREAM_DECODER_H_
