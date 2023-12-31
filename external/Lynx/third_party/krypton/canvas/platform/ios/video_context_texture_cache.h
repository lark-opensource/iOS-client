// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_PLATFORM_IOS_VIDEO_CONTEXT_TEXTURE_CACHE_H_
#define CANVAS_PLATFORM_IOS_VIDEO_CONTEXT_TEXTURE_CACHE_H_

namespace lynx {
namespace canvas {

class VideoContextTextureCache {
 public:
  virtual ~VideoContextTextureCache() { ReleaseTextureCache(); }

  uint32_t GetCurrentTexture() const { return current_texture_; }
  uint32_t GetTextureWidth() const { return texture_width_; }
  uint32_t GetTextureHeight() const { return texture_height_; }

  void UpdateTextureWithPixelBuffer(CVPixelBufferRef buffer);

 private:
  void DoUpdateTextureWithPixelBuffer(CVPixelBufferRef buffer);
  void AutoGenerateTextureCache();
  void ReleaseTextureCache();

 private:
  uint32_t current_texture_{0};
  uint32_t texture_width_{0}, texture_height_{0};
  CVOpenGLESTextureCacheRef texture_cache_{nullptr};
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_PLATFORM_IOS_VIDEO_CONTEXT_TEXTURE_CACHE_H_
