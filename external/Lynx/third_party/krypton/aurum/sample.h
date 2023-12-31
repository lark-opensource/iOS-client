// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_SAMPLE_H_
#define LYNX_KRYPTON_AURUM_SAMPLE_H_

namespace lynx {
namespace canvas {
namespace au {
/**
 * Sample has three application modes:
 *
 *1. A function returns a sample. The function is responsible for the
 *application and maintenance of the buffer
 *2. A function accepts a sample, and the function may fill or modify the data
 *of the sample
 *3. A function accepts a sample &. The function may fill the sample and modify
 *the length, or replace the data pointer of sample *
 */
struct Sample {
  int length;
  short *data;  // Staggered storage of data; For mono, only half of the
                // positions are used for storage
  // create from data
  inline Sample(int length, short *data) : length(length), data(data) {}

  inline static Sample Empty() { return {0, nullptr}; }
};
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_SAMPLE_H_
