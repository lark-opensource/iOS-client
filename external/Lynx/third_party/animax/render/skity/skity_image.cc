// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_image.h"

#include <cstring>

#include "animax/render/skity/skity_canvas.h"

namespace lynx {
namespace animax {

std::shared_ptr<Image> SkityImage::MakeImage(canvas::Bitmap &bitmap,
                                             RealContext *real_context) {
  auto skity_raw_data = skity::Data::MakeWithProc(
      bitmap.Pixels(), bitmap.PixelsLen(), nullptr, nullptr);
  auto pixmap = std::make_shared<skity::Pixmap>(
      skity_raw_data, bitmap.BytesPerRow(), bitmap.Width(), bitmap.Height(),
      skity::AlphaType::kPremul_AlphaType);
  skity::RenderContext *context = nullptr;
  if (real_context) {
    context = static_cast<SkityRealContext *>(real_context)->Get();
  }
  auto image = skity::Image::MakeImage(pixmap, context);
  return std::make_shared<SkityImage>(image);
}

float SkityImage::GetWidth() const {
  if (image_) {
    return image_->Width();
  }
  return 0;
}

float SkityImage::GetHeight() const {
  if (image_) {
    return image_->Height();
  }

  return 0;
}

}  // namespace animax
}  // namespace lynx
