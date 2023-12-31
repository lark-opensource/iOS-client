//  Copyright 2023 The Lynx Authors. All rights reserved.

#include "canvas/platform/ios/pixel_buffer.h"

namespace lynx {
namespace canvas {

PixelBuffer::PixelBuffer(uint32_t width, uint32_t height) : pixel_buffer_(nullptr) {
  width_ = width;
  height_ = height;
}

PixelBuffer::~PixelBuffer() {
  if (pixel_buffer_) {
    CVPixelBufferRelease(pixel_buffer_);
  }
}

uint32_t PixelBuffer::reading_fbo() {
  if (!fb_) {
    fb_ = std::make_unique<Framebuffer>(texture_cache_.GetCurrentTexture());
    if (!fb_->InitOnGPUIfNeed()) {
      fb_.reset();
      return 0;
    }
  } else {
    fb_->UpdateTexture(texture_cache_.GetCurrentTexture());
  }
  return fb_->Fbo();
}

uint32_t PixelBuffer::Texture() { return texture_cache_.GetCurrentTexture(); }

void PixelBuffer::UpdateTextureOrFramebufferOnGPU() {
  if (pixel_buffer_) {
    texture_cache_.UpdateTextureWithPixelBuffer(pixel_buffer_);
  }
}

void PixelBuffer::UpdatePixelBuffer(double ts, CVPixelBufferRef pixel_buffer) {
  if (!pixel_buffer) {
    return;
  }

  timestamp_ = ts;
  if (pixel_buffer_) {
    CVPixelBufferRelease(pixel_buffer_);
  }
  pixel_buffer_ = pixel_buffer;
}

double PixelBuffer::GetTimestamp() { return timestamp_; }

}  // namespace canvas
}  // namespace lynx
