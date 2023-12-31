//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/lepus_api_actor/ios/lepus_api_actor_darwin.h"

namespace lynx {
namespace tasm {

void LepusApiActorDarwin::InvokeLepusApiCallback(const int32_t callback_id,
                                                 const std::string& entry_name,
                                                 const lepus::Value& data) {
  if (engine_actor_ == nullptr) {
    return;
  }
  engine_actor_->Act([callback_id, entry_name, data](auto& engine) {
    return engine->InvokeLepusCallback(callback_id, entry_name, data);
  });
}
}  // namespace tasm
}  // namespace lynx
