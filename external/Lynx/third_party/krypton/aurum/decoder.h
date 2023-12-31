// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_DECODER_H_
#define LYNX_KRYPTON_AURUM_DECODER_H_

#include <stdint.h>

#include "aurum/sample.h"
#include "aurum/util/ref.hpp"

namespace lynx {
namespace canvas {
namespace au {

class LoaderBase;
class AudioContext;

enum class DecoderState : uint32_t {
  Init,
  Meta,
  EndOfFile,
  Error,
};

enum class DecoderType : uint32_t {
  UnSupported,
  WAV,
  MP3,
  VORBIS,
  MP4,
  AAC,
};

class DecoderBase {
 public:
  inline DecoderBase(LoaderBase &loader) : loader_(loader) {}
  virtual ~DecoderBase() = default;
  virtual void ReadMeta() = 0;
  virtual void Decode(Sample &output, int current_ample, int samples) = 0;

  inline void Ref() { __sync_add_and_fetch(&refs_, 1); }
  void UnRef();

  struct Meta {
    int32_t samples;
    uint32_t sample_rate;
    int channels;
  };

  const Meta &GetMetaRef() const { return meta_; }
  DecoderType GetType() const { return type_; }
  DecoderState GetState() const { return state_; }
  void SetState(DecoderState state) { state_ = state; }

 protected:
  Meta meta_;
  DecoderState state_ = DecoderState::Init;
  DecoderType type_ = DecoderType::UnSupported;
  LoaderBase &loader_;

 private:
  int refs_ = 0;
};

namespace decoder {
DecoderBase *Decoder(LoaderBase &);
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_DECODER_H_
