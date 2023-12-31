// Copyright 2022 The Lynx Authors. All rights reserved.

#include "aurum/decoder/chunk_loader.h"
#include "aurum/decoder/mp4_parser.h"
#ifdef OS_ANDROID
#include <endian.h>
#endif

namespace lynx {
namespace canvas {
namespace au {

struct M4AChunkLoader : ChunkLoader, MP4Parser {
  using LoaderRef = FiberLoader<0> &;
  LoaderRef ref;
  uint8_t buffer[4096];

  inline M4AChunkLoader(LoaderRef ref) : ref(ref) {}

  void Rewind() override { MP4Parser::Reset(); }

  virtual bool Read(size_t offset, size_t size, ChunkInfo &result) override {
    auto len = ref.FillData(offset, size, result);
    return len == int(size);
  }

  bool GuessType(int &channels, int &sample_rate_out, int &samples) override {
    if (!MP4Parser::ParseHead()) {
      return false;
    }
    channels = adts_context.channel_conf;
    sample_rate_out = adts_context.sample_rate_index;
    if (!duration_) {
      samples = -1;
    } else if (sample_rate_ == time_scale_) {
      samples = duration_;
    } else {
      samples = duration_ * sample_rate_ / time_scale_;
    }
    return true;
  }

  bool NextChunk(ChunkInfo &info, size_t) override {
    if (!MP4Parser::NextSample(info)) {
      return false;
    }

    size_t info_length = info.Length();
    if (info_length == 0) {  // EOF
      return true;
    }

    MP4Parser::AACSetAdtsHead(buffer, info_length);
    size_t result_length = info_length + ADTS_HEADER_SIZE;
    LoaderData result_data;

    if (result_length > 4096) {
      if (result_data.AllocBuffer(result_length)) {
        result_data.FillBuffer(0, buffer, ADTS_HEADER_SIZE);
        result_data.FillBuffer(ADTS_HEADER_SIZE, info.Data(), info_length);
      } else {
        KRYPTON_LOGE("length too large");
        return false;
      }
    } else {
      memcpy(buffer + ADTS_HEADER_SIZE, info.Data(), info_length);
      result_data.SetData(buffer, result_length, false);
    }

    info.Reset(result_data, 0, result_length);
    return true;
  }
};

template <>
ChunkLoader *ChunkLoader::M4A<FiberLoader<0>>(FiberLoader<0> &loader) {
  return new M4AChunkLoader(loader);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
