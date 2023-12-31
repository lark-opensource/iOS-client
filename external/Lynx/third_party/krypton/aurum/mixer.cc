// Copyright 2022 The Lynx Authors. All rights reserved.

#include "aurum/mixer.h"

#include <stdio.h>
#include <string.h>

#include "aurum/config.h"

namespace lynx {
namespace canvas {
namespace au {

template <int inputs>
inline void MixFast(Sample *entry, short *output) {
  const int samples = entry->length << 1;
  if (inputs == 2) {
    const short *data0 = entry[0].data;
    const short *data1 = entry[1].data;
    for (int i = 0; i < samples; i++) {
      int sum = data0[i] + data1[i];
      output[i] = AU_MIN_MAX(sum, -0x8000, 0x7fff);
    }
  } else if (inputs == 3) {
    const short *data0 = entry[0].data;
    const short *data1 = entry[1].data;
    const short *data2 = entry[2].data;
    for (int i = 0; i < samples; i++) {
      int sum = data0[i] + data1[i] + data2[i];
      output[i] = AU_MIN_MAX(sum, -0x8000, 0x7fff);
    }
  } else if (inputs == 4) {
    const short *data0 = entry[0].data;
    const short *data1 = entry[1].data;
    const short *data2 = entry[2].data;
    const short *data3 = entry[3].data;
    for (int i = 0; i < samples; i++) {
      int sum = data0[i] + data1[i] + data2[i] + data3[i];
      output[i] = AU_MIN_MAX(sum, -0x8000, 0x7fff);
    }
  }
}

inline void DoMix(Sample *entry, int inputs, short *output) {
  // Use 8KB memory on the stack; Increase the length of the array appropriately
  // to prevent writing out of range when the input is too long
  int32_t results[1024 * 2];
  memset(results, 0, sizeof(results));

  const int samples = entry->length << 1;
  for (int j = 0; j < inputs; j++) {
    const short *data = entry[j].data;
    for (int i = 0; i < samples; i++) {
      results[i] += data[i];
    }
  }

  for (int i = 0; i < samples; i++) {
    int sum = results[i];
    output[i] = AU_MIN_MAX(sum, -0x8000, 0x7fff);
  }
}

Sample Mixer::Mix(MixerInfo &&mixer_info) {
  if (!mixer_info.size()) {
    return Sample::Empty();
  }
  Sample &first = mixer_info[0];
  if (mixer_info.size() == 1) {
    memcpy(buffer_, first.data, first.length << 2);
  } else if (mixer_info.size() == 2) {
    MixFast<2>(&first, buffer_);
  } else if (mixer_info.size() == 3) {
    MixFast<3>(&first, buffer_);
  } else if (mixer_info.size() == 4) {
    MixFast<4>(&first, buffer_);
  } else {
    DoMix(&first, int(mixer_info.size()), buffer_);
  }

  return {first.length, buffer_};
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
