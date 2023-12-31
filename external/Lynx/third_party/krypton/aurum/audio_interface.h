// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_AUDIO_INTERFACE_H_
#define LYNX_KRYPTON_AURUM_AUDIO_INTERFACE_H_

#include "aurum/aurum.h"
#include "aurum/config.h"
#include "aurum/sample.h"
namespace lynx {
namespace canvas {
namespace au {

class AudioEngine;

class AudioInterface {
 public:
  virtual Status Init(AudioEngine*) = 0;
  virtual void Pause() = 0;
  virtual void Resume() = 0;
  virtual ~AudioInterface(){};

  AudioEngine* GetAudioEngine() const { return audio_engine_; }
  bool IsPaused() const { return paused_; }

 protected:
  AudioEngine* audio_engine_{nullptr};
  bool paused_{false};
};
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_AUDIO_INTERFACE_H_
