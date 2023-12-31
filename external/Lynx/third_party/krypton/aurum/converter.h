// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_CONVERTER_H_
#define LYNX_KRYPTON_AURUM_CONVERTER_H_

#include <stdint.h>
#include <string.h>

namespace lynx {
namespace canvas {
namespace au {

template <bool mono, typename DataType>
inline void Convert(short *output, const void *input, size_t length);

template <bool mono, typename DataType>
inline void Convert(float *output, const void *input, size_t length);

template <typename DataType>
inline void ConvertMonoToStereo(short *output, const DataType *input,
                                size_t length) {
  // The low bit of i32 is used to store the left channel of mono
  int32_t *out32 = reinterpret_cast<int32_t *>(output);

  for (size_t i = 0; i < length; ++i) {
    out32[i] = input[i];
  }
}

template <>  // i8 mono -> i16 stereo
inline void Convert<true, int8_t>(short *output, const void *input,
                                  size_t length) {
  ConvertMonoToStereo(output, static_cast<const int8_t *>(input), length);
}

template <>  // i16 mono -> i16 stereo
inline void Convert<true, int16_t>(short *output, const void *input,
                                   size_t length) {
  ConvertMonoToStereo(output, static_cast<const int16_t *>(input), length);
}

template <>  // i32 mono -> i16 stereo
inline void Convert<true, int32_t>(short *output, const void *input,
                                   size_t length) {
  const uint32_t *in32 = reinterpret_cast<const uint32_t *>(input);
  // the low bit of I32 is used to store the left channel of mono
  uint32_t *out32 = reinterpret_cast<uint32_t *>(output);

  for (size_t i = 0; i < length; ++i) {
    out32[i] = in32[i] >> 16;
  }
}

template <>  // f32 mono -> i16 stereo
inline void Convert<true, float>(short *output, const void *input,
                                 size_t length) {
  const float *inf32 = reinterpret_cast<const float *>(input);

  for (size_t i = 0; i < length; ++i) {
    output[i << 1] = inf32[i] * 32767;
  }
}

template <>  // i8 stereo -> i16 stereo
inline void Convert<false, int8_t>(short *output, const void *input,
                                   size_t length) {
  const int8_t *in8 = reinterpret_cast<const int8_t *>(input);

  length <<= 1;
  for (size_t i = 0; i < length; ++i) {
    output[i] = in8[i];
  }
}

template <>  // i16 stereo -> i16 stereo
inline void Convert<false, int16_t>(short *output, const void *input,
                                    size_t length) {
  memcpy(output, input, length << 2);
}

template <>  // i32 stereo -> i16 stereo
inline void Convert<false, int32_t>(short *output, const void *input,
                                    size_t length) {
  const int32_t *in32 = reinterpret_cast<const int32_t *>(input);

  length <<= 1;
  for (size_t i = 0; i < length; ++i) {
    output[i] = in32[i] >> 16;
  }
}

template <>  // f32 stereo -> i16 stereo
inline void Convert<false, float>(short *output, const void *input,
                                  size_t length) {
  const float *inf32 = reinterpret_cast<const float *>(input);

  length <<= 1;
  for (size_t i = 0; i < length; ++i) {
    output[i] = inf32[i] * 32767;
  }
}
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_CONVERTER_H_
