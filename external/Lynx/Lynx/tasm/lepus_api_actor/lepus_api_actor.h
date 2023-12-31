//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_LEPUS_API_ACTOR_LEPUS_API_ACTOR_H_
#define LYNX_TASM_LEPUS_API_ACTOR_LEPUS_API_ACTOR_H_

#include <memory>
#include <string>

#include "shell/lynx_actor.h"
#include "shell/lynx_engine.h"

namespace lynx {
namespace tasm {

class LepusApiActor {
 public:
  LepusApiActor() = default;
  virtual ~LepusApiActor() = default;
  inline void SetEngineActor(
      std::shared_ptr<shell::LynxActor<shell::LynxEngine>> actor) {
    engine_actor_ = actor;
  }
  std::shared_ptr<shell::LynxActor<shell::LynxEngine>> getEngineActor();

  bool SendTouchEvent(const std::string& name, int32_t tag, float x, float y,
                      float client_x, float client_y, float page_x,
                      float page_y);
  void SendCustomEvent(const std::string& name, int32_t tag,
                       const lepus::Value& params,
                       const std::string& params_name);
  void OnPseudoStatusChanged(int32_t id, int32_t pre_status,
                             int32_t current_status);

 protected:
  std::shared_ptr<shell::LynxActor<shell::LynxEngine>> engine_actor_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_LEPUS_API_ACTOR_LEPUS_API_ACTOR_H_
