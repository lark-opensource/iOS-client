//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_TEXTURE_REGISTRY_H
#define KRYPTON_EFFECT_TEXTURE_REGISTRY_H

#include <mutex>
#include <unordered_map>

#include "canvas/base/macros.h"
#include "canvas/webgl/webgl_texture.h"

namespace lynx {
namespace canvas {
using EffectTextureRegistryLine = std::pair<WebGLTexture*, int>;
class EffectTextureRegistry {
 public:
  static EffectTextureRegistry* Instance();

  void Registry(unsigned int id, WebGLTexture* texture);
  void UnRegistry(unsigned int id);

  EffectTextureRegistryLine* Find(unsigned int id);

 private:
  std::mutex mutex_;

  std::unordered_map<unsigned int, EffectTextureRegistryLine> storage_;

  EffectTextureRegistry() = default;

  LYNX_CANVAS_DISALLOW_ASSIGN_COPY(EffectTextureRegistry);
};
}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_EFFECT_TEXTURE_REGISTRY_H */
