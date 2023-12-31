//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "krypton_effect_texture_registry.h"

namespace lynx {
namespace canvas {

EffectTextureRegistry* EffectTextureRegistry::Instance() {
  static EffectTextureRegistry* instance_ = nullptr;
  if (!instance_) {
    instance_ = new EffectTextureRegistry();
  }
  return instance_;
}

void EffectTextureRegistry::Registry(unsigned int id, WebGLTexture* texture) {
  std::lock_guard<std::mutex> lock(mutex_);
  EffectTextureRegistryLine line = {texture, 0};
  storage_.emplace(id, line);
}

void EffectTextureRegistry::UnRegistry(unsigned int id) {
  std::lock_guard<std::mutex> lock(mutex_);
  storage_.erase(storage_.find(id));
}

EffectTextureRegistryLine* EffectTextureRegistry::Find(unsigned int id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = storage_.find(id);
  if (it != storage_.end()) {
    return &(it->second);
  }
  return nullptr;
}

}  // namespace canvas
}  // namespace lynx
