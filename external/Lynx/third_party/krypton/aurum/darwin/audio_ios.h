// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_IOS_AUDIO_H_
#define LYNX_KRYPTON_AURUM_IOS_AUDIO_H_

#import <AudioToolbox/AUComponent.h>
#import <AudioToolbox/AudioOutputUnit.h>
#include <TargetConditionals.h>

#include "aurum/audio_interface.h"

namespace lynx {
namespace canvas {
namespace au {

class AudioIOS : public AudioInterface {
 public:
  inline AudioIOS() = default;
  ~AudioIOS();

  Status Init(AudioEngine*) override;

  inline void Pause() override {
    if (paused_) {
      return;
    }
    paused_ = true;
    AudioOutputUnitStop(audio_unit_);
  }

  void Resume() override;

  void OnCaptureStart();
  void OnCaptureStop();

  bool Interrupted() const { return interrupted_; }
  void SetInterrupted(bool val) { interrupted_ = val; }
  bool IsRunning();

  AudioUnit GetAudioUnit() const { return audio_unit_; }

  void OnInitError();
  void RetryInit();
  void AddInterruptionListener();
  void RemoveInterruptionListener();

 private:
  AudioUnit audio_unit_ = 0;
  bool recording_ = false;
  bool interrupted_ = false;

#if TARGET_OS_IPHONE
#ifdef __OBJC__
  id interruption_listener_ = nil;
#else
  void *interruption_listener_ = nullptr;
#endif

#endif
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_IOS_AUDIO_H_
