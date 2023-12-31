// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_DECODERS_H_
#define LYNX_KRYPTON_AURUM_DECODERS_H_

namespace lynx {
namespace canvas {
namespace au {

class LoaderBase;
class DecoderBase;

class Decoder {
 public:
  Decoder *next;
  virtual DecoderBase *Create(const void *head, LoaderBase &) = 0;
};
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_DECODERS_H_
