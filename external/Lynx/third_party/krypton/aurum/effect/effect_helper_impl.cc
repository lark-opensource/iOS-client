// Copyright 2022 The Lynx Authors. All rights reserved.

#include "aurum/effect/effect_helper_impl.h"

#define AUDIO_NODE_IMPL

#include "aurum/audio_node/aec.hpp"
#include "aurum/audio_node/delay.hpp"
#include "aurum/audio_node/equalizer.hpp"
#include "aurum/audio_node/f0_detect.hpp"
#include "aurum/audio_node/fading.hpp"
#include "aurum/audio_node/reverb.hpp"
#include "aurum/audio_node/volume_detect.hpp"
#include "aurum/config.h"

#if defined(__ANDROID__) || defined(ANDROID)
namespace lynx {
namespace canvas {
namespace au {
extern void RegisterAudioEffectHelper(AudioEffectHelper *helper);
}  // namespace au
}  // namespace canvas
}  // namespace lynx

#include <jni.h>

#include "aurum/audio_node/mixer_node.hpp"

extern "C" __attribute__((visibility("default"))) int JNI_OnLoad(JavaVM *vm,
                                                                 void *) {
  lynx::canvas::au::RegisterAudioEffectHelper(
      new lynx::canvas::au::AudioEffectHelperImpl());
  return JNI_VERSION_1_6;
}

#else
namespace lynx {
namespace canvas {
namespace au {
AudioEffectHelper* GetAudioEffectHelper() {
  static AudioEffectHelperImpl impl;
  return &impl;
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
#endif
