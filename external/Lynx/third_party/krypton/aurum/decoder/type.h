// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_DECODE_TYPE_H_
#define LYNX_KRYPTON_AURUM_DECODE_TYPE_H_

#include <cstddef>
#include <cstdint>

namespace lynx {
namespace canvas {
namespace au {

enum class FileType : uint32_t {
  FileTypeWav,
  FileTypeMp3,
  FileTypeVorbis,
  FileTypeAAC,
};

enum class DataType : uint32_t {
  Fixed8 = 0,
  Fixed16,
  Fixed32,
  Real32,
};

enum class ChannelType : uint32_t {
  Mono = 0,
  Stereo,
};

struct Format {
  DataType data;
  ChannelType channel;

  uint32_t ChannelCount() {
    static constexpr uint32_t channels[] = {
        1,
        2,
    };
    return channels[uint32_t(channel)];
  }

  uint32_t BitsPerChannel() {
    static constexpr uint32_t bits_per_channel[] = {
        8,
        16,
        32,
        32,
    };
    return bits_per_channel[uint32_t(data)];
  }

  uint32_t SampleByte() { return ChannelCount() * BitsPerChannel() / 8; }
};
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_DECODE_TYPE_H_
