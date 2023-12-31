// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skia/skia_real_context.h"

namespace lynx {
namespace animax {

SkiaRealContext::~SkiaRealContext() { assert(textures_.empty()); }

void SkiaRealContext::Destroy() {}

void SkiaRealContext::AddTexture(SkImage *image, GrBackendTexture &&texture) {
  textures_[image] = texture;
}

void SkiaRealContext::DeleteTexture(SkImage *image) {
  context_->deleteBackendTexture(textures_[image]);
  textures_.erase(image);
}

}  // namespace animax
}  // namespace lynx
