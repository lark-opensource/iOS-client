// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_ENCODER_H_
#define LYNX_KRYPTON_AURUM_ENCODER_H_

#include "aurum/sample.h"

namespace lynx {
namespace canvas {
namespace au {

class EncoderBase {
 public:
  virtual ~EncoderBase() = default;
  virtual void Write(Sample) = 0;
};

namespace encoder {
EncoderBase *Mp4aAac(const char *path);
EncoderBase *RiffWav(const char *path);
}  // namespace encoder

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_ENCODER_H_
