//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_LEPUS_API_ACTOR_IOS_LEPUS_API_ACTOR_DARWIN_H_
#define LYNX_TASM_LEPUS_API_ACTOR_IOS_LEPUS_API_ACTOR_DARWIN_H_

#include <string>

#include "tasm/lepus_api_actor/lepus_api_actor.h"

namespace lynx {
namespace tasm {

class LepusApiActorDarwin : public LepusApiActor {
 public:
  virtual ~LepusApiActorDarwin() override = default;
  void InvokeLepusApiCallback(const int32_t callback_id,
                              const std::string& entry_name,
                              const lepus::Value& data);
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_LEPUS_API_ACTOR_IOS_LEPUS_API_ACTOR_DARWIN_H_
