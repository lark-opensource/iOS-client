//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/lepus_api_actor/lepus_api_actor.h"

#include <string>

namespace lynx {
namespace tasm {
std::shared_ptr<shell::LynxActor<shell::LynxEngine>>
LepusApiActor::getEngineActor() {
  return engine_actor_;
}

bool LepusApiActor::SendTouchEvent(const std::string& name, int32_t tag,
                                   float x, float y, float client_x,
                                   float client_y, float page_x, float page_y) {
  if (engine_actor_ == nullptr) {
    LOGE("LepusApiActor::SendTouchEvent failed since engine_actor_ is nullptr");
    return false;
  }
  engine_actor_->Act(
      [name, tag, x, y, client_x, client_y, page_x, page_y](auto& engine) {
        (void)engine->SendTouchEvent(name, tag, x, y, client_x, client_y,
                                     page_x, page_y);
      });
  return false;
}

void LepusApiActor::SendCustomEvent(const std::string& name, int32_t tag,
                                    const lepus::Value& params,
                                    const std::string& params_name) {
  if (engine_actor_ == nullptr) {
    LOGE(
        "LepusApiActor::SendCustomEvent failed since engine_actor_ is nullptr");
    return;
  }
  engine_actor_->Act([name, tag, params, params_name](auto& engine) {
    engine->SendCustomEvent(name, tag, params, params_name);
  });
}

void LepusApiActor::OnPseudoStatusChanged(int32_t id, int32_t pre_status,
                                          int32_t current_status) {
  if (engine_actor_ == nullptr) {
    LOGE(
        "LepusApiActor::OnTouchStatusChanged failed since engine_actor_ is "
        "nullptr");
    return;
  }
  engine_actor_->Act([id, pre_status, current_status](auto& engine) {
    (void)engine->OnPseudoStatusChanged(id, pre_status, current_status);
  });
}

}  // namespace tasm
}  // namespace lynx
