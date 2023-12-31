// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skia/skia_image.h"

#include "animax/base/log.h"
#include "animax/base/thread_assert.h"
#include "animax/render/skia/skia_real_context.h"

namespace lynx {
namespace animax {

SkiaImage::SkiaImage(canvas::Bitmap &bitmap, RealContext *real_context)
    : real_context_((SkiaRealContext *)real_context) {
  SkImageInfo image_info = SkImageInfo::Make(
      SkISize::Make(bitmap.Width(), bitmap.Height()),
      SkColorType::kRGBA_8888_SkColorType, SkAlphaType::kPremul_SkAlphaType);
  auto sk_pixmap =
      SkPixmap(image_info, bitmap.Pixels(), image_info.minRowBytes());
  if (real_context_) {
    ThreadAssert::Assert(ThreadAssert::Type::kGPU);
    GrDirectContext *context = real_context_->Get();
    GrBackendTexture texture = context->createBackendTexture(
        sk_pixmap, GrRenderable::kNo, GrProtected::kNo);
    sk_image_ =
        SkImage::MakeFromTexture(context, texture, kTopLeft_GrSurfaceOrigin,
                                 SkColorType::kRGBA_8888_SkColorType,
                                 SkAlphaType::kPremul_SkAlphaType, nullptr);
    real_context_->AddTexture(sk_image_.get(), std::move(texture));
  } else {
    sk_image_ = SkImage::MakeFromRaster(sk_pixmap, nullptr, nullptr);
  }
}

SkiaImage::~SkiaImage() {
  if (sk_image_ && sk_image_->isTextureBacked()) {
    ThreadAssert::Assert(ThreadAssert::Type::kGPU);
    real_context_->DeleteTexture(sk_image_.get());
  }
}

std::shared_ptr<Image> SkiaImage::MakeSkiaImage(canvas::Bitmap &bitmap,
                                                RealContext *real_context) {
  return std::make_shared<SkiaImage>(bitmap, real_context);
}

float SkiaImage::GetWidth() const {
  if (sk_image_) {
    return sk_image_->width();
  } else {
    return 0.f;
  }
}

float SkiaImage::GetHeight() const {
  if (sk_image_) {
    return sk_image_->height();
  } else {
    return 0.f;
  }
}

}  // namespace animax
}  // namespace lynx
