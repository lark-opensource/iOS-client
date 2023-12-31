// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_MEDIA_DECODE_PATTERN_H_
#define LYNX_KRYPTON_AURUM_MEDIA_DECODE_PATTERN_H_

#include <functional>
#include <vector>

#include "aurum/audio_context.h"
#include "aurum/converter.h"
#include "aurum/decoder.h"
#include "aurum/decoder/decode_buffer.h"
#include "aurum/decoder/type.h"
#include "aurum/loader.h"

namespace lynx {
namespace canvas {
namespace au {

static constexpr uint32_t AU_DECODE_ALIGN = 4096;

class DecodePattern : public DecoderBase {
 public:
  inline DecodePattern(LoaderBase &loader)
      : DecoderBase(loader),
        stream_end_(false),
        byte_offset_(0),
        sample_offset_(0) {}

  void Decode(Sample &output, int current_sample, int samples) override {
    // Set To Current Data Position.
    if (current_sample < int(sample_offset_)) {
      sample_offset_ = 0;
      byte_offset_ = 0;

      if (!Reset()) {
        // change status in Reset if error, not here
        return;
      }
      if (!Skip(current_sample)) {
        // change status in Skip if error, not here
        return;
      }
      sample_offset_ = current_sample;
    } else if (current_sample >
               int(sample_offset_ + buffer_.Size() / format_.SampleByte())) {
      DecodePattern::Reset();
      if (!Skip(current_sample - sample_offset_)) {
        // change status in Skip if error, not here
        return;
      }
      sample_offset_ = current_sample;
    }

    if (!Next(samples, output)) {
      // change status in Next if error, not here
      return;
    }

    sample_offset_ += samples;
  }

 protected:
  virtual bool Skip(size_t skipped_sample_count) = 0;

  virtual bool Reset() {
    buffer_.Reset();
    return true;
  }

  virtual bool Decode(uint8_t **out_data, size_t *out_bytes) = 0;

  bool Next(size_t wanted_sample_param, Sample &output) {
    size_t buffer_byte;
    size_t filled_sample;
    SampleFormat *data = output.data;
    size_t wanted_byte = format_.SampleByte() * wanted_sample_param;
    size_t wanted_sample = wanted_sample_param;

    // 1. Fetch Decoded Data From Middle Buffer.
    buffer_byte = buffer_.Size();
    while (buffer_byte && wanted_byte) {
      size_t fetched_byte;

      if (wanted_byte > AU_DECODE_ALIGN) {
        fetched_byte =
            buffer_byte > AU_DECODE_ALIGN ? AU_DECODE_ALIGN : buffer_byte;
      } else {
        fetched_byte = buffer_byte > wanted_byte ? wanted_byte : buffer_byte;
      }
      buffer_.Fetch(cache_, fetched_byte);

      filled_sample = fetched_byte / format_.SampleByte();
      wanted_byte -= fetched_byte;
      buffer_byte -= fetched_byte;

      FillData(data, cache_, filled_sample);
      data += filled_sample << 1;
    }

    if (buffer_.IsEmpty()) {
      buffer_.Reset();
    }

    // 2. Decode And Fetch Data
    uint8_t *out_data = nullptr;
    size_t out_byte = 0;
    while (wanted_byte > 0) {
      if (!Decode(&out_data, &out_byte)) {
        return false;
      }
      if (out_byte == 0) {
        break;
      }
      if (out_byte < wanted_byte) {
        filled_sample = out_byte / format_.SampleByte();
        FillData(data, out_data, filled_sample);
        data += filled_sample << 1;
        wanted_byte -= out_byte;
      } else {
        filled_sample = wanted_byte / format_.SampleByte();
        FillData(data, out_data, filled_sample);
        data += filled_sample << 1;
        out_byte -= wanted_byte;
        out_data += wanted_byte;
        wanted_byte = 0;
      }
    }

    // 3. Fill The Left Decoded Data into Middle Buffer
    if (out_byte > 0) {
      buffer_.Fill(out_data, out_byte);
    }

    output.length = int(wanted_sample - wanted_byte / format_.SampleByte());
    return true;
  }

  size_t Read(ChunkInfo &result, size_t size) {
    if (stream_end_) {
      state_ = DecoderState::EndOfFile;
      return 0;
    }

    auto total_length = loader_.TotalContentLength();
    if (total_length >= 0 && size > total_length - byte_offset_) {
      size = total_length - byte_offset_;
    }

    if (size <= 0) {
      state_ = DecoderState::EndOfFile;
      return 0;
    }

    LoaderData loader_data;
    LoadResult load_result =
        loader_.Read(byte_offset_, byte_offset_ + size, loader_data);
    if (load_result == LoadResult::Pending) {
      return 0;
    }

    if (byte_offset_ == size_t(loader_.TotalContentLength())) {
      stream_end_ = true;
    }

    result.Reset(loader_data, byte_offset_, size);
    byte_offset_ += size;
    return size;
  }

  inline void FillData(SampleFormat *output, const void *input, size_t length) {
    if (format_.channel == ChannelType::Mono) {
      switch (format_.data) {
        case DataType::Fixed8:
          return Convert<true, int8_t>(output, input, length);
        case DataType::Fixed16:
          return Convert<true, int16_t>(output, input, length);
        case DataType::Fixed32:
          return Convert<true, int32_t>(output, input, length);
        case DataType::Real32:
          return Convert<true, float>(output, input, length);
        default:
          return;
      }
    } else {
      switch (format_.data) {
        case DataType::Fixed8:
          return Convert<false, int8_t>(output, input, length);
        case DataType::Fixed16:
          return Convert<false, int16_t>(output, input, length);
        case DataType::Real32:
          return Convert<false, float>(output, input, length);
        default:
          return;
      }
    }
  }

 protected:
  bool stream_end_;
  Format format_;

  uint8_t cache_[AU_DECODE_ALIGN];
  DecodeBuffer buffer_;

  size_t byte_offset_;
  size_t sample_offset_;
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_MEDIA_DECODE_PATTERN_H_
