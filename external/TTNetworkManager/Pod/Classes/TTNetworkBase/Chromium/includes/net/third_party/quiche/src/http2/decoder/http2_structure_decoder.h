// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef QUICHE_HTTP2_DECODER_HTTP2_STRUCTURE_DECODER_H_
#define QUICHE_HTTP2_DECODER_HTTP2_STRUCTURE_DECODER_H_

// Http2StructureDecoder is a class for decoding the fixed size structures in
// the HTTP/2 spec, defined in net/third_party/quiche/src/http2/http2_structures.h. This class
// is in aid of deciding whether to keep the SlowDecode methods which I
// (jamessynge) now think may not be worth their complexity. In particular,
// if most transport buffers are large, so it is rare that a structure is
// split across buffer boundaries, than the cost of buffering upon
// those rare occurrences is small, which then simplifies the callers.

#include <cstdint>

#include "net/third_party/quiche/src/http2/decoder/decode_buffer.h"
#include "net/third_party/quiche/src/http2/decoder/decode_http2_structures.h"
#include "net/third_party/quiche/src/http2/decoder/decode_status.h"
#include "net/third_party/quiche/src/http2/http2_structures.h"
#include "net/third_party/quiche/src/http2/platform/api/http2_logging.h"
#include "net/third_party/quiche/src/common/platform/api/quiche_export.h"

namespace http2 {
namespace test {
class Http2StructureDecoderPeer;
}  // namespace test

class QUICHE_EXPORT_PRIVATE Http2StructureDecoder {
 public:
  // The caller needs to keep track of whether to call Start or Resume.
  //
  // Start has an optimization for the case where the DecodeBuffer holds the
  // entire encoded structure; in that case it decodes into *out and returns
  // true, and does NOT touch the data members of the Http2StructureDecoder
  // instance because the caller won't be calling Resume later.
  //
  // However, if the DecodeBuffer is too small to hold the entire encoded
  // structure, Start copies the available bytes into the Http2StructureDecoder
  // instance, and returns false to indicate that it has not been able to
  // complete the decoding.
  //
  template <class S>
  bool Start(S* out, DecodeBuffer* db) {
    static_assert(S::EncodedSize() <= sizeof buffer_, "buffer_ is too small");
    HTTP2_DVLOG(2) << __func__ << "@" << this
                   << ": db->Remaining=" << db->Remaining()
                   << "; EncodedSize=" << S::EncodedSize();
    if (db->Remaining() >= S::EncodedSize()) {
      DoDecode(out, db);
      return true;
    }
    IncompleteStart(db, S::EncodedSize());
    return false;
  }

  template <class S>
  bool Resume(S* out, DecodeBuffer* db) {
    HTTP2_DVLOG(2) << __func__ << "@" << this << ": offset_=" << offset_
                   << "; db->Remaining=" << db->Remaining();
    if (ResumeFillingBuffer(db, S::EncodedSize())) {
      // We have the whole thing now.
      HTTP2_DVLOG(2) << __func__ << "@" << this << "    offset_=" << offset_
                     << "    Ready to decode from buffer_.";
      DecodeBuffer buffer_db(buffer_, S::EncodedSize());
      DoDecode(out, &buffer_db);
      return true;
    }
    DCHECK_LT(offset_, S::EncodedSize());
    return false;
  }

  // A second pair of Start and Resume, where the caller has a variable,
  // |remaining_payload| that is both tested for sufficiency and updated
  // during decoding. Note that the decode buffer may extend beyond the
  // remaining payload because the buffer may include padding.
  template <class S>
  DecodeStatus Start(S* out, DecodeBuffer* db, uint32_t* remaining_payload) {
    static_assert(S::EncodedSize() <= sizeof buffer_, "buffer_ is too small");
    HTTP2_DVLOG(2) << __func__ << "@" << this
                   << ": *remaining_payload=" << *remaining_payload
                   << "; db->Remaining=" << db->Remaining()
                   << "; EncodedSize=" << S::EncodedSize();
    if (db->MinLengthRemaining(*remaining_payload) >= S::EncodedSize()) {
      DoDecode(out, db);
      *remaining_payload -= S::EncodedSize();
      return DecodeStatus::kDecodeDone;
    }
    return IncompleteStart(db, remaining_payload, S::EncodedSize());
  }

  template <class S>
  bool Resume(S* out, DecodeBuffer* db, uint32_t* remaining_payload) {
    HTTP2_DVLOG(3) << __func__ << "@" << this << ": offset_=" << offset_
                   << "; *remaining_payload=" << *remaining_payload
                   << "; db->Remaining=" << db->Remaining()
                   << "; EncodedSize=" << S::EncodedSize();
    if (ResumeFillingBuffer(db, remaining_payload, S::EncodedSize())) {
      // We have the whole thing now.
      HTTP2_DVLOG(2) << __func__ << "@" << this << ": offset_=" << offset_
                     << "; Ready to decode from buffer_.";
      DecodeBuffer buffer_db(buffer_, S::EncodedSize());
      DoDecode(out, &buffer_db);
      return true;
    }
    DCHECK_LT(offset_, S::EncodedSize());
    return false;
  }

  uint32_t offset() const { return offset_; }

 private:
  friend class test::Http2StructureDecoderPeer;

  uint32_t IncompleteStart(DecodeBuffer* db, uint32_t target_size);
  DecodeStatus IncompleteStart(DecodeBuffer* db,
                               uint32_t* remaining_payload,
                               uint32_t target_size);

  bool ResumeFillingBuffer(DecodeBuffer* db, uint32_t target_size);
  bool ResumeFillingBuffer(DecodeBuffer* db,
                           uint32_t* remaining_payload,
                           uint32_t target_size);

  uint32_t offset_;
  // TODO(sunwenfeng) decode buffer size is 9, need resize sometimes.
  char buffer_[Http2FrameHeader::EncodedSize()];

#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_FRONTIER_SUPPORT)

 public:
  // A third start and resume, use to decode varint
  template <class S>
  DecodeStatus Start(S* out, DecodeBuffer* db, bool is_varint) {
    DCHECK(is_varint);
    // min varint decode size is 1.
    if (db->Remaining() >= S::EncodedSize()) {
      if (DoDecode(out, db)) {
        return DecodeStatus::kDecodeDone;
      }
    }
    // current remaining data size >= 9, but decode fail.
    if (db->Remaining() >= sizeof buffer_) {
      return DecodeStatus::kDecodeError;
    } else {
      // copy all remaining to buffer, wait to read more data.
      IncompleteStart(db, db->Remaining());
      return DecodeStatus::kDecodeInProgress;
    }
  }

  template <class S>
  DecodeStatus Resume(S* out, DecodeBuffer* db, bool is_varint) {
    DCHECK(is_varint);
    // add one bytes to decode varint once.
    for (size_t i = 0; i < db->Remaining(); ++i) {
      if (ResumeFillingBufferForVarint(db, S::EncodedSize())) {
        DecodeBuffer buffer_db(buffer_, offset_);
        if (DoDecode(out, &buffer_db)) {
          return DecodeStatus::kDecodeDone;
        }
      } else {
        return DecodeStatus::kDecodeError;
      }
    }
    return DecodeStatus::kDecodeInProgress;
  }

  // A forth Start and Resume, decode varint in payload.
  template <class S>
  DecodeStatus Start(S* out,
                     DecodeBuffer* db,
                     uint32_t* remaining_payload,
                     bool is_varint) {
    if (db->MinLengthRemaining(*remaining_payload) >= S::EncodedSize()) {
      if (DoDecode(out, db)) {
        *remaining_payload -= out->decode_size;
        return DecodeStatus::kDecodeDone;
      }
    }
    // decode fail with current input data, try to copy to temp buffer.
    // if input data size >= 9 :
    //   * IncompleteStart return error
    //   * |FrameDecoderState::StartDecodingVarintInPayload| report TTNET_FT_UNEXPECTED_FRAME_SIZE.
    //   * |FrontierDecoderAdapter| will ignore remaining payload.
    return IncompleteStart(db, remaining_payload, db->Remaining());
  }

  template <class S>
  DecodeStatus Resume(S* out,
              DecodeBuffer* db,
              uint32_t* remaining_payload,
              bool is_varint) {
    for (size_t i = 0; i < db->MinLengthRemaining(*remaining_payload); ++i) {
      if (ResumeFillingBufferForVarint(db, remaining_payload,
                                       S::EncodedSize())) {
        DecodeBuffer buffer_db(buffer_, offset_);
        if (DoDecode(out, &buffer_db)) {
          return DecodeStatus::kDecodeDone;
        }
      } else {
        return DecodeStatus::kDecodeError;
      }
    }
    return DecodeStatus::kDecodeInProgress;
  }

 private:
  bool ResumeFillingBufferForVarint(DecodeBuffer* db, uint32_t target_size);
  bool ResumeFillingBufferForVarint(DecodeBuffer* db,
                                    uint32_t* remaining_payload,
                                    uint32_t target_size);
#endif
};

}  // namespace http2

#endif  // QUICHE_HTTP2_DECODER_HTTP2_STRUCTURE_DECODER_H_
