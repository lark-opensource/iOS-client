// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_INCLUDE_SHADER_H_
#define ANIMAX_RENDER_INCLUDE_SHADER_H_

#include <memory>

#include "animax/model/basic_model.h"
#include "animax/render/include/matrix.h"

namespace lynx {
namespace animax {

enum class ShaderTileMode : uint8_t { kClamp = 0, kRepeat, kMirror, kDecal };

class Shader {
 public:
  virtual ~Shader() = default;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_INCLUDE_SHADER_H_
