// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_IMAGE_H_
#define ANIMAX_RENDER_SKITY_SKITY_IMAGE_H_

#include <skity/graphic/image.hpp>

#include "animax/render/include/image.h"
#include "canvas/bitmap.h"
#include "skity/skity.hpp"

namespace lynx {
namespace animax {
class RealContext;

class SkityImage : public Image {
 public:
  static std::shared_ptr<Image> MakeImage(canvas::Bitmap &bitmap,
                                          RealContext *real_context);

  explicit SkityImage(std::shared_ptr<skity::Image> image)
      : image_(std::move(image)) {}
  ~SkityImage() override = default;

  float GetWidth() const override;

  float GetHeight() const override;

  std::shared_ptr<skity::Image> const &GetImage() const { return image_; }

 private:
  std::shared_ptr<skity::Image> image_ = {};
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_IMAGE_H_
