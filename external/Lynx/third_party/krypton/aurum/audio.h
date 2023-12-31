// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_AUDIO_H_
#define LYNX_KRYPTON_AURUM_AUDIO_H_

#include "aurum/audio_node.h"
#include "aurum/decoder.h"
#include "aurum/loader.h"
#include "aurum/util/pool.hpp"

namespace lynx {
namespace canvas {
namespace au {

class Audio {
  enum class Status : uint32_t {
    Idle = 0,
    Playing,
    Paused,
    Stopped,
    Ended,
  };
  enum class Action : uint32_t {
    Play = 0,
    Seek,
    Pause,
    Stop,
  };
  friend class AudioContext;
  friend class AudioElementSourceNode;

  int loader = -1;
  Ref<DecoderBase> decoder;

  bool loop = false;
  bool autoplay = false;
  bool started = false;
  bool current_time_is_dirty =
      false;             // JS has updated currenttime and has not been applied
  bool canplay = false;  // False means that the audio cannot be played, and
                         // wait for the trigger of canplay

  Status status = Status::Idle;
  double current_time = 0;
  int current_sample = 0;  // current_time * sample_rate
  double time_offset = 0;  // CurrentTimeUs()/1e6 - current_time
  double volume = 1;       // volume  0~1
  double start_time = 0;   // time to start playing
  double duration = 0;

  struct ActionClass {
    Action action;
    inline ActionClass(int id, Action action) : action(action) {}
  };
  Pool<ActionClass, 8> actions;
  int action_lock = 0;

  void executeActions(AudioContext &ctx, AudioNodeBase *node) {
    AU_LOCK(action_lock);
    int should_dispatch_seeked_num =
        0;  // ensure seeking appears paired with seeked
    bool should_dispatch_play = false;
    if (this->autoplay && this->status == Audio::Status::Idle) {
      this->status = Audio::Status::Playing;
      this->current_time = this->start_time;
      this->current_time_is_dirty = true;
      this->started = true;
      should_dispatch_play = true;
    }

    for (auto it = this->actions.Begin(); it.Next();) {
      // apply and distribute events one by one according to actions
      Audio::ActionClass &act = *it;
      switch (act.action) {
        case Audio::Action::Pause:
          node->Dispatch(AudioNodeBase::NodeEvent::Pause, ctx);
          break;
        case Audio::Action::Stop:
          node->Dispatch(AudioNodeBase::NodeEvent::Stop, ctx);
          break;
        case Audio::Action::Seek:
          node->Dispatch(AudioNodeBase::NodeEvent::Seeking, ctx);
          should_dispatch_seeked_num++;
          break;
        case Audio::Action::Play:
          should_dispatch_play = true;
          break;
      }
    }
    this->actions.Clear();

    if (started && should_dispatch_play) {
      node->Dispatch(AudioNodeBase::NodeEvent::Playing, ctx);
    }

    while (should_dispatch_seeked_num > 0) {
      node->Dispatch(AudioNodeBase::NodeEvent::Seeked, ctx);
      should_dispatch_seeked_num--;
    }
    AU_UNLOCK(action_lock);
  }

 public:
  inline Audio(int id) {}

  inline void ResetAudioIdle() {
    status = Status::Idle;
    current_sample = 0;
    current_time = 0.;
    started = false;
    canplay = false;
    duration = 0;
  }

  inline ~Audio() {}
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_AUDIO_H_
