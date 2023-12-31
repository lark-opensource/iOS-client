// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_IMAGE_H_
#define ANIMAX_RENDER_SKIA_SKIA_IMAGE_H_

#include "animax/render/include/image.h"
#include "animax/render/skia/skia_util.h"
#include "canvas/bitmap.h"

namespace lynx {
namespace animax {
class RealContext;
class SkiaRealContext;

class SkiaImage : public Image {
 public:
  static std::shared_ptr<Image> MakeSkiaImage(canvas::Bitmap &bitmap,
                                              RealContext *real_context);

  SkiaImage(canvas::Bitmap &bitmap, RealContext *real_context);
  ~SkiaImage() override;

  float GetWidth() const override;

  float GetHeight() const override;

  sk_sp<SkImage> GetSkImage() const { return sk_image_; }

 private:
  sk_sp<SkImage> sk_image_;
  SkiaRealContext *real_context_ = nullptr;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_IMAGE_H_
