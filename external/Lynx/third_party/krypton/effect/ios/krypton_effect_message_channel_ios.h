// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_MESSAGE_CHANNEL_IOS_H
#define KRYPTON_EFFECT_MESSAGE_CHANNEL_IOS_H

#include "krypton_effect_message_channel.h"

@class KryptonEffectMessageChannel;

namespace lynx {
namespace canvas {

class EffectMessageChannelIOS : public EffectMessageChannel {
 public:
  EffectMessageChannelIOS();
  ~EffectMessageChannelIOS();

  bool AddEventCallback(EffectMessageCallbackType*) override;
  bool RemoveEventCallback() override;

 private:
  KryptonEffectMessageChannel* message_channel_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // KRYPTON_EFFECT_MESSAGE_CHANNEL_IOS_H
