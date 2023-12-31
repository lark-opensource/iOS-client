// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_REAL_CONTEXT_H_
#define ANIMAX_RENDER_SKIA_SKIA_REAL_CONTEXT_H_

#include <unordered_map>

#include "animax/render/include/real_context.h"
#include "animax/render/skia/skia.h"

namespace lynx {
namespace animax {

class SkiaRealContext : public RealContext {
 public:
  SkiaRealContext(GrDirectContext *context) : context_(context) {}
  ~SkiaRealContext() override;
  GrDirectContext *Get() const { return context_; }

  void Destroy();
  void AddTexture(SkImage *image, GrBackendTexture &&texture);
  void DeleteTexture(SkImage *image);

 private:
  GrDirectContext *context_ = nullptr;
  std::unordered_map<SkImage *, GrBackendTexture> textures_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_REAL_CONTEXT_H_
