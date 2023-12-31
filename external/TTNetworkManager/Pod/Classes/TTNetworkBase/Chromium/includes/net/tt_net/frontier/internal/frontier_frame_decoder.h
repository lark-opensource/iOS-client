// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_TTNET_FRONTIER_INTERNAL_FRONTIER_FRAME_DECODER_H_
#define NET_TTNET_FRONTIER_INTERNAL_FRONTIER_FRAME_DECODER_H_

#include "net/third_party/quiche/src/http2/decoder/frame_decoder_state.h"
#include "net/tt_net/frontier/frontier_protocol.h"
#include "net/tt_net/frontier/internal/frontier_frame_decoder_listener.h"
#include "net/tt_net/frontier/internal/payload_decoders/frontier_endstream_decoder.h"
#include "net/tt_net/frontier/internal/payload_decoders/frontier_goaway_decoder.h"
#include "net/tt_net/frontier/internal/payload_decoders/frontier_message_decoder.h"
#include "net/tt_net/frontier/internal/payload_decoders/frontier_ping_decoder.h"
#include "net/tt_net/frontier/internal/payload_decoders/frontier_priority_decoder.h"
#include "net/tt_net/frontier/internal/payload_decoders/frontier_recipt_decoder.h"
#include "net/tt_net/frontier/internal/payload_decoders/frontier_settings_decoder.h"
#include "net/tt_net/frontier/internal/payload_decoders/frontier_stream_decoder.h"

namespace net {

bool IsDefinedFrontierFrameType(const uint8_t frame_type_field);
uint8_t SerializeFrontierFrameType(const FrontierFrameType frame_type);
bool IsValidFrontierFrameStreamId(const int64_t current_frame_stream_id,
                                  const FrontierFrameType type);
bool IsValidFrontierFrameMessageId(const int64_t current_frame_message_id,
                                   const FrontierFrameType type);
uint32_t Crc32(const char* data, int length);

class FrontierFrameDecoder {
 public:
  explicit FrontierFrameDecoder(FrontierFrameDecoderListener* listener);

  FrontierFrameDecoder(const FrontierFrameDecoder&) = delete;
  FrontierFrameDecoder& operator=(const FrontierFrameDecoder&) = delete;

  // Is the remainder of the frame's payload being discarded?
  bool IsDiscardingPayload() const { return state_ == State::kDiscardPayload; }
  size_t remaining_payload() const;
  uint32_t remaining_padding() const;

  http2::DecodeStatus DecodeFrontierFrame(http2::DecodeBuffer* db);

  void set_frontier_listener(FrontierFrameDecoderListener* listener);
  FrontierFrameDecoderListener* frontier_listener() const;

  const FrontierFrameHeader frontier_frame_header() const {
    return frame_decoder_state_.frontier_frame_header();
  }

  void ResetDecodeState() { state_ = State::kStartDecodingHeader; }

 private:
  enum class State {
    // Ready to start decoding a new frame's header.
    kStartDecodingHeader,
    // Was in state kStartDecodingHeader, but unable to read the entire frame
    // header, so needs more input to complete decoding the header.
    kResumeDecodingHeader,

    // Have decoded the frame header, and started decoding the available bytes
    // of the frame's payload, but need more bytes to finish the job.
    kResumeDecodingPayload,

    // Decoding of the most recently started frame resulted in an error:
    // OnPaddingTooLong or OnFrameSizeError was called to indicate that the
    // decoder detected a problem, or OnFrameHeader returned false, indicating
    // that the listener detected a problem. Regardless of which, the decoder
    // will stay in state kDiscardPayload until it has been passed the rest
    // of the bytes of the frame's payload that it hasn't yet seen, after
    // which it will be ready to decode another frame.
    kDiscardPayload,
  };

  friend std::ostream& operator<<(std::ostream& out, State v);

  http2::FrameDecoderState frame_decoder_state_;

  FrontierEndStreamDecoder frontier_endstream_decoder_;
  FrontierGoAwayDecoder frontier_goaway_decoder_;
  FrontierMessageDecoder frontier_message_decoder_;
  FrontierPingDecoder frontier_ping_decoder_;
  FrontierPriorityDecoder frontier_priority_decoder_;
  FrontierReciptDecoder frontier_recipt_decoder_;
  FrontierSettingsDecoder frontier_settings_decoder_;
  FrontierStreamDecoder frontier_stream_decoder_;

  State state_;

  http2::DecodeStatus DecodeFrontierHeaderInternal(http2::DecodeStatus status,
                                                   http2::DecodeBuffer* db);

  http2::DecodeStatus StartDecodingFrontierPayload(http2::DecodeBuffer* db);
  http2::DecodeStatus ResumeDecodingFrontierPayload(http2::DecodeBuffer* db);
  http2::DecodeStatus DiscardFrontierPayload(http2::DecodeBuffer* db);

  http2::DecodeStatus StartDecodingFrontierStreamPayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus StartDecodingFrontierMessagePayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus StartDecodingFrontierReciptPayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus StartDecodingFrontierPriorityPayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus StartDecodingFrontierEndStreamPayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus StartDecodingFrontierPingPayload(http2::DecodeBuffer* db);
  http2::DecodeStatus StartDecodingFrontierGoAwayPayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus StartDecodingFrontierSettingsPayload(
      http2::DecodeBuffer* db);

  http2::DecodeStatus ResumeDecodingFrontierStreamPayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus ResumeDecodingFrontierMessagePayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus ResumeDecodingFrontierReciptPayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus ResumeDecodingFrontierPriorityPayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus ResumeDecodingFrontierEndStreamPayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus ResumeDecodingFrontierPingPayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus ResumeDecodingFrontierGoAwayPayload(
      http2::DecodeBuffer* db);
  http2::DecodeStatus ResumeDecodingFrontierSettingsPayload(
      http2::DecodeBuffer* db);

  FrontierFrameDecoderNoOpListener no_op_frontier_listener_;
};

}  // namespace net

#endif  // NET_TTNET_FRONTIER_INTERNAL_FRONTIER_FRAME_DECODER_H_
