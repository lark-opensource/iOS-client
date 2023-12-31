// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_MESSAGE_CHANNEL_H
#define KRYPTON_EFFECT_MESSAGE_CHANNEL_H

#include <functional>
#include <string>

namespace lynx {
namespace canvas {

using EffectMessageCallbackType = std::function<void(
    unsigned int msg_type, long arg1, long arg2, std::string arg3)>;

class EffectMessageChannel
    : public std::enable_shared_from_this<EffectMessageChannel> {
 public:
  static EffectMessageChannel* CreateInstance();
  virtual ~EffectMessageChannel() = default;

  virtual bool AddEventCallback(EffectMessageCallbackType*) = 0;
  virtual bool RemoveEventCallback() = 0;
};

}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_EFFECT_MESSAGE_CHANNEL_H */
