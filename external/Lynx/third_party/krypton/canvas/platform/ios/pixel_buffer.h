//  Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef CANVAS_PLATFORM_IOS_PIXEL_BUFFER_H_
#define CANVAS_PLATFORM_IOS_PIXEL_BUFFER_H_

#import <CoreVideo/CoreVideo.h>

#include "canvas/base/log.h"
#include "canvas/platform/ios/video_context_texture_cache.h"
#include "canvas/texture_source.h"

namespace lynx {
namespace canvas {
class PixelBuffer : public TextureSource {
 public:
  PixelBuffer(uint32_t width, uint32_t height);
  ~PixelBuffer();

  uint32_t reading_fbo() override;
  uint32_t Texture() override;
  void UpdateTextureOrFramebufferOnGPU() override;

  void UpdatePixelBuffer(double ts, CVPixelBufferRef pixel_buffer);
  double GetTimestamp();

 private:
  CVPixelBufferRef pixel_buffer_;
  std::unique_ptr<Framebuffer> fb_;
  double timestamp_{0};
  VideoContextTextureCache texture_cache_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_PLATFORM_IOS_PIXEL_BUFFER_H_
