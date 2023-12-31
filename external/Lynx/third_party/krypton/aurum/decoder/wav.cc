// Copyright 2022 The Lynx Authors. All rights reserved.

#include "aurum/audio_context.h"
#include "aurum/aurum.h"
#include "aurum/config.h"
#include "aurum/converter.h"
#include "aurum/decoder.h"
#include "aurum/decoder/buffered_fiber_decoder.h"
#include "aurum/decoders.h"
#include "aurum/loader.h"
#include "canvas/base/log.h"
#ifdef OS_ANDROID
#include <endian.h>
#endif

namespace lynx {
namespace canvas {
namespace au {

struct __attribute__((__packed__)) Head {
  uint32_t riff_chunk_head;  // "RIFF"
  uint32_t riff_size;        // size of fmt chunk and data chunk
  uint32_t format;           // "WAVE"
};

struct __attribute__((__packed__)) Format {
  uint32_t fmt_chunk_head;  // "fmt "
  uint32_t fmt_chunk_size;  // = 16
  uint16_t audio_format;    // = 1
  uint16_t channels;        // 1 or 2
  uint32_t sample_rate;
  uint32_t byte_rate;    // sample_rate * block_align
  uint16_t block_align;  //  channels * bits_per_sample / 8
  uint16_t bits_per_sample;
};

struct __attribute__((__packed__)) Data {
  uint32_t data_chunk_head;  // "data"
  uint32_t data_chunk_size;  //
};

struct __attribute__((__packed__)) ChunkHead {
  uint32_t head;
  uint32_t size;
};

class MonoWavDecoder : public DecoderBase {
 public:
  inline MonoWavDecoder(LoaderBase &loader, const Format &format,
                        const Data &data, size_t data_offset_in)
      : DecoderBase(loader), data_offset_(data_offset_in) {
    KRYPTON_LOGI("WAVDecoderImpl MonoWavDecoder");
    meta_.channels = 1;
    meta_.sample_rate = format.sample_rate;
    meta_.samples = data.data_chunk_size >> 1;
    state_ = DecoderState::Meta;
    type_ = DecoderType::WAV;
  }

  virtual void ReadMeta() override {}

  void Decode(Sample &output, int current_ample, int samples) final override {
    size_t offset = data_offset_ + (current_ample << 1);
    LoaderData data;
    LoadResult ret = loader_.Read(offset, offset + (samples << 1), data);
    if (ret == LoadResult::Pending) {
      return;
    }
    if (ret == LoadResult::EndOfFile) {  // read out of range
      state_ = DecoderState::EndOfFile;
      return;
    }
    for (int i = 0; i < samples; i++) {
      reinterpret_cast<uint32_t *>(output.data)[i] =
          reinterpret_cast<uint16_t *>(
              (static_cast<uint8_t *>(data.Data()) + offset))[i];
    }
    output.length = samples;
  }

 private:
  size_t data_offset_{0};
};

// Only two channel short type wav is supported
class StereoWavDecoder : public DecoderBase {
 public:
  inline StereoWavDecoder(LoaderBase &loader, const Format &format,
                          const Data &data, size_t data_offset_in)
      : DecoderBase(loader), data_offset_(data_offset_in) {
    KRYPTON_LOGI("WAVDecoderImpl StereoWavDecoder");
    meta_.channels = 2;
    meta_.sample_rate = format.sample_rate;
    meta_.samples = data.data_chunk_size >> 2;
    state_ = DecoderState::Meta;
    type_ = DecoderType::WAV;
  }

  virtual void ReadMeta() override {}

  void Decode(Sample &output, int current_ample, int samples) final override {
    size_t offset = data_offset_ + (current_ample << 2);
    LoaderData data;
    LoadResult ret = loader_.Read(offset, offset + (samples << 2), data);
    if (ret == LoadResult::Pending) {
      return;
    }
    if (ret == LoadResult::EndOfFile) {
      // read out of range
      state_ = DecoderState::EndOfFile;
      return;
    }
    output.data =
        reinterpret_cast<short *>(static_cast<uint8_t *>(data.Data()) + offset);
    output.length = samples;
  }

 private:
  size_t data_offset_{0};
};

class WAVDecoderImpl : public Decoder {
 public:
  static WAVDecoderImpl &Instance() {
    static WAVDecoderImpl decoder_impl;
    return decoder_impl;
  }
  virtual DecoderBase *Create(const void *head, LoaderBase &loader) override;
};

DecoderBase *WAVDecoderImpl::Create(const void *head, LoaderBase &loader) {
  const Head &h = *reinterpret_cast<const Head *>(head);
  if (h.riff_chunk_head != htonl('RIFF') || h.format != htonl('WAVE')) {
    return nullptr;
  }

  KRYPTON_LOGI("WAVDecoderImpl::Create");

  const char *pos = (char *)head + sizeof(Head);
  const Data *data = nullptr;
  const Format *format = nullptr;
  size_t data_offset = sizeof(Head);

  KRYPTON_LOGI("WAVDecoderImpl length ") << loader.ReceivedContentLength();

  while (pos - (char *)head <
         long(loader.ReceivedContentLength() - sizeof(Head))) {
    const ChunkHead &chunk_head = *reinterpret_cast<const ChunkHead *>(pos);
    if (chunk_head.head == htonl('data')) {
      data = reinterpret_cast<const Data *>(pos);
      KRYPTON_LOGI("WAVDecoderImpl find data");
      if (format != nullptr) {
        break;
      }
    } else if (chunk_head.head == htonl('fmt ')) {
      format = reinterpret_cast<const Format *>(pos);
      KRYPTON_LOGI("WAVDecoderImpl find format");
      if (data != nullptr) {
        break;
      }
    }
    pos += chunk_head.size + sizeof(chunk_head);
    data_offset += chunk_head.size + sizeof(chunk_head);
  }

  if (data == nullptr) {
    KRYPTON_LOGW("WAVDecoderImpl data == nullptr");
    return nullptr;  // unsupported decoder
  }

  if (format == nullptr) {
    KRYPTON_LOGW("WAVDecoderImpl format == nullptr");
    return nullptr;  // unsupported decoder
  }

  if (format->audio_format != 1) {
    KRYPTON_LOGW("WAVDecoderImpl format->audio_format != 1");
    return nullptr;  // unsupported decoder
  }

  data_offset += sizeof(Data);

  if (format->channels == 2) {
    return new StereoWavDecoder(loader, *format, *data, data_offset);
  } else {
    return new MonoWavDecoder(loader, *format, *data, data_offset);
  }
}

namespace decoder {
class Decoder &WAV() { return WAVDecoderImpl::Instance(); }
}  // namespace decoder

}  // namespace au
}  // namespace canvas
}  // namespace lynx
