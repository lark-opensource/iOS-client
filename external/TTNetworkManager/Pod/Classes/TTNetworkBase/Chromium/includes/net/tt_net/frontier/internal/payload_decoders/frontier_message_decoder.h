#ifndef NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_MESSAGE_PAYLOAD_DECODER_H_
#define NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_MESSAGE_PAYLOAD_DECODER_H_

#include "net/third_party/quiche/src/http2/decoder/decode_buffer.h"
#include "net/third_party/quiche/src/http2/decoder/decode_status.h"
#include "net/third_party/quiche/src/http2/decoder/frame_decoder_state.h"
#include "net/tt_net/frontier/internal/frontier_internal_structures.h"

namespace net {

class FrontierMessageDecoder {
 public:
  // Starts decoding a Frontier Message frame's payload, and completes it if
  // the entire payload is in the provided decode buffer.
  http2::DecodeStatus StartDecodingPayload(http2::FrameDecoderState* state,
                                           http2::DecodeBuffer* db);

  // Resumes decoding a Frontier Message frame's payload that has been split
  // across decode buffers.
  http2::DecodeStatus ResumeDecodingPayload(http2::FrameDecoderState* state,
                                            http2::DecodeBuffer* db);

  enum class PayloadState {
    kStartDecodingMessageDigestSize,
    kResumeDecodingMessageDigestSize,
    kStartDecodingMessageDigest,
    kResumeDecodingMessageDigest,
    kReadPadLength,
    kStartDecodingMetaLength,
    kResumeDecodingMetaLength,
    kReadMeta,
    kReadData,
    kSkipPadding,
  };

 private:
  PayloadState payload_state_;

  FrontierVarintFields message_digest_size_;
  // TODO... current message digest is crc32, size is fixed 4 bytes.
  // can also computed from mssdk.
  FrontierUint32Fields message_digest_;
  uint32_t pad_length_;
  FrontierVarintFields meta_length_;
  size_t data_length_;
};

}  // namespace net

#endif  // NET_TTNET_FRONTIER_INTERNAL_PAYLOAD_DECODERS_FRONTIER_MESSAGE_PAYLOAD_DECODER_H_
