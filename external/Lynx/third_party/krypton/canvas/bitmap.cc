// Copyright 2022 The Lynx Authors. All rights reserved.

#include "bitmap.h"

#include <cmath>

#include "Lynx/base/log/logging.h"
#include "canvas/util/texture_format_convertor.h"
#include "canvas/util/texture_util.h"

namespace lynx {
namespace canvas {

Bitmap::Bitmap(uint32_t width, uint32_t height, uint32_t format, uint32_t type,
               std::unique_ptr<DataHolder> pixels, uint32_t aligment,
               bool has_premultiplied, bool has_flip_y)
    : pixels_(std::move(pixels)),
      width_(width),
      height_(height),
      format_(format),
      type_(type),
      aligment_(aligment),
      has_premul_alpha_(has_premultiplied),
      has_flip_y_(has_flip_y) {
#if !defined(OS_WIN) || !defined(ENABLE_RENDERKIT_CANVAS)
  bytes_per_pixel_ = TextureUtil::ComputeBytesPerPixel(format_, type_, nullptr);
#endif
  uint32_t padding = (bytes_per_pixel_ * width) % aligment_;
  padding = padding > 0 ? aligment_ - padding : padding;
  bytes_per_row_ = width * bytes_per_pixel_ + padding;
  pixels_len_ = bytes_per_row_ * height;
}

void Bitmap::PremulAlpha() {
#if defined(OS_WIN) && defined(ENABLE_RENDERKIT_CANVAS)
  DCHECK(false);
#else
  has_premul_alpha_ = true;
  TextureUtil::PremultiplyAlpha(
      (uint8_t*)pixels_->WritableData(), (uint8_t*)pixels_->WritableData(),
      width_, height_, bytes_per_row_, bytes_per_pixel_, type_);
#endif
}

void Bitmap::UnpremulAlpha() {
#if defined(OS_WIN) && defined(ENABLE_RENDERKIT_CANVAS)
  DCHECK(false);
#else
  has_premul_alpha_ = false;
  TextureUtil::UnpremultiplyAlpha(
      (uint8_t*)pixels_->WritableData(), (uint8_t*)pixels_->WritableData(),
      width_, height_, bytes_per_row_, bytes_per_pixel_, type_);
#endif
}

void Bitmap::FlipY() {
#if defined(OS_WIN) && defined(ENABLE_RENDERKIT_CANVAS)
  DCHECK(false);
#else
  has_flip_y_ = !has_flip_y_;
  TextureUtil::FilpVertical((uint8_t*)pixels_->WritableData(),
                            (uint8_t*)pixels_->WritableData(), height_,
                            bytes_per_row_);
#endif
}

std::unique_ptr<Bitmap> Bitmap::ConvertFormat(uint32_t format, uint32_t type) {
#if defined(OS_WIN) && defined(ENABLE_RENDERKIT_CANVAS)
  DCHECK(false);
#else
  uint32_t bpp = TextureUtil::ComputeBytesPerPixel(format, type, nullptr);
  uint32_t padding =
      TextureFormatConvertor::ComputePadding(width_, bpp, aligment_);
  uint32_t bpr = bpp * width_ + padding;
  auto dst_pixels = DataHolder::MakeWithMalloc(bpr * height_);

  bool res = TextureFormatConvertor::ConvertFormat(
      format_, type_, format, type, width_, height_, aligment_,
      pixels_->WritableData(), dst_pixels->WritableData());
  if (!res) {
    return nullptr;
  }

  return std::make_unique<Bitmap>(width_, height_, format, type,
                                  std::move(dst_pixels), aligment_,
                                  has_premul_alpha_, has_flip_y_);
#endif
}

bool Bitmap::HasPremulAlpha() { return has_premul_alpha_; }

bool Bitmap::HasFlipY() { return has_flip_y_; }

uint32_t Bitmap::Width() const { return width_; }

uint32_t Bitmap::Height() const { return height_; }

uint32_t Bitmap::Format() const { return format_; }

uint32_t Bitmap::Type() const { return type_; }

uint32_t Bitmap::Alignment() const { return aligment_; }

uint32_t Bitmap::PixelsLen() const { return pixels_len_; }

uint32_t Bitmap::BytesPerRow() const { return bytes_per_row_; }

const void* Bitmap::Pixels() const { return pixels_->Data(); }

bool Bitmap::IsValidate() {
  return width_ && height_ && pixels_ && pixels_->Data() &&
         pixels_len_ == pixels_->Size();
}

}  // namespace canvas
}  // namespace lynx
