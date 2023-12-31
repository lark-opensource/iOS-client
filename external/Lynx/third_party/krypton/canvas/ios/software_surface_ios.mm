// Copyright 2023 The Lynx Authors. All rights reserved.

#include "canvas/ios/software_surface_ios.h"

namespace lynx {
namespace canvas {

SoftwareSurfaceIOS::SoftwareSurfaceIOS(CAEAGLLayer *layer) : layer_(layer) {
  width_ = layer.frame.size.width * layer.contentsScale;
  height_ = layer.frame.size.height * layer.contentsScale;
  instance_guard_ = InstanceGuard<SoftwareSurfaceIOS>::CreateSharedGuard(this);
}

SoftwareSurfaceIOS::~SoftwareSurfaceIOS() {
  if (context_) {
    CGContextRelease(context_);
    context_ = nullptr;
  }
  if (color_space_) {
    CFRelease(color_space_);
    color_space_ = nullptr;
  }
  if (buffer_) {
    free(buffer_);
    buffer_ = nullptr;
  }
}

void SoftwareSurfaceIOS::Init() {
  if (Valid()) {
    return;
  }
  int32_t size = Height() * BytesPerRow();
  if (size <= 0) {
    return;
  }
  buffer_ = (uint8_t *)malloc(size);
  if (!buffer_) {
    return;
  }
  color_space_ = CGColorSpaceCreateDeviceRGB();
  context_ = CGBitmapContextCreate(Buffer(), Width(), Height(),
                                   8,  // bitsPerComponent
                                   BytesPerRow(), color_space_, kCGImageAlphaPremultipliedLast);
}

uint8_t *SoftwareSurfaceIOS::Buffer() const { return buffer_; }

int32_t SoftwareSurfaceIOS::Width() const { return width_; }

int32_t SoftwareSurfaceIOS::Height() const { return height_; }

int32_t SoftwareSurfaceIOS::BytesPerRow() const {
  return Width() << 2;  // RGBA
}

bool SoftwareSurfaceIOS::Valid() const { return !!Buffer(); }

void SoftwareSurfaceIOS::Flush() {
  if (!context_) {
    return;
  }
  if (blocked_.load()) {
    return;
  }
  CGImageRef image = CGBitmapContextCreateImage(context_);
  if (!image) {
    return;
  }
  blocked_.store(true);

  std::weak_ptr<InstanceGuard<SoftwareSurfaceIOS>> instance_guard = instance_guard_;
  dispatch_async(dispatch_get_main_queue(), ^{
    auto instance = instance_guard.lock();
    if (!instance) {
      CGImageRelease(image);
      return;
    }
    SoftwareSurfaceIOS *surface = instance->Get();
    surface->layer_.contents = (__bridge id)image;
    CGImageRelease(image);
    surface->blocked_.store(false);
  });
}

}  // namespace canvas
}  // namespace lynx
