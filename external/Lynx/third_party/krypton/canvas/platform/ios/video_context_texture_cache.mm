// Copyright 2022 The Lynx Authors. All rights reserved.

#include "video_context_texture_cache.h"
#include "canvas/base/log.h"
#include "canvas/gpu/gl/gl_api.h"

namespace lynx {
namespace canvas {

void VideoContextTextureCache::UpdateTextureWithPixelBuffer(CVPixelBufferRef buffer) {
  if (buffer == nullptr) {
    return;
  }
  AutoGenerateTextureCache();
  CVPixelBufferLockBaseAddress(buffer, 0);
  DoUpdateTextureWithPixelBuffer(buffer);
  CVPixelBufferUnlockBaseAddress(buffer, 0);
  CVOpenGLESTextureCacheFlush(texture_cache_, 0);
}

void VideoContextTextureCache::DoUpdateTextureWithPixelBuffer(CVPixelBufferRef buffer) {
  size_t width = CVPixelBufferGetWidth(buffer);
  size_t height = CVPixelBufferGetHeight(buffer);
  CVOpenGLESTextureRef texture_ref = nullptr;
  CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault, texture_cache_, buffer, nullptr, GL_TEXTURE_2D, GL_RGBA, (GLsizei)width,
      (GLsizei)height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &texture_ref);
  if (err != kCVReturnSuccess || !texture_ref) {
    KRYPTON_LOGE("video texture create texutre from image failed: ") << err;
    return;
  }

  current_texture_ = CVOpenGLESTextureGetName(texture_ref);
  texture_width_ = static_cast<uint32_t>(width);
  texture_height_ = static_cast<uint32_t>(height);
  CFRelease(texture_ref);
  return;
}

void VideoContextTextureCache::AutoGenerateTextureCache() {
  if (texture_cache_ == nullptr) {
    CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
                                 (__bridge CFDictionaryRef)(
                                     @{(id)kCVOpenGLESTextureCacheMaximumTextureAgeKey : @0}),
                                 [EAGLContext currentContext], NULL, &texture_cache_);
  }
}

void VideoContextTextureCache::ReleaseTextureCache() {
  if (texture_cache_) {
    CVOpenGLESTextureCacheFlush(texture_cache_, 0);
    CFRelease(texture_cache_);
    texture_cache_ = nullptr;
  }
}

}  // namespace canvas
}  // namespace lynx
