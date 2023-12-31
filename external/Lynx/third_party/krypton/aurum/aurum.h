// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_H_
#define LYNX_KRYPTON_AURUM_H_

#include <inttypes.h>

#include <string>

namespace lynx {
namespace canvas {
namespace au {

class AudioEngine;
class Decoder;
class PlatformLoaderDelegate;

namespace decoder {
extern class Decoder &WAV();
extern class Decoder &MP3();
extern class Decoder &Vorbis();
extern class Decoder &AAC();
extern class Decoder &AudioToolbox();
extern class Decoder &MediaCodec();
extern void Use(class Decoder &);
}  // namespace decoder

struct Platform {
  void *user_ptr;
  void (*OnInitFail)(void *user_ptr, int type, int data);
  void (*Dispatch)(void *user_ptr, void *task, void (*callback)(void *));
  void (*Execute)(void *user_ptr, void *task, void (*callback)(void *));
  void (*LoadAsync)(void *user_ptr, const char *url,
                    PlatformLoaderDelegate *delegate);
};

class SampleCallback {
 public:
  virtual void OnSample(const short *data, int length, int samples) = 0;
  virtual ~SampleCallback() {}
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // #define LYNX_KRYPTON_AURUM_H_
