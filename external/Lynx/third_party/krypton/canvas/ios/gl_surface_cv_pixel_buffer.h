//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_IOS_GL_SURFACE_CV_PIXEL_BUFFER_H_
#define CANVAS_IOS_GL_SURFACE_CV_PIXEL_BUFFER_H_

#import <Foundation/Foundation.h>

#import "DownStreamListener.h"
#include "canvas/base/scoped_cftypedref.h"
#include "canvas/gpu/gl/gl_api.h"
#include "canvas/gpu/gl_surface.h"

namespace lynx {
namespace canvas {

class GLSurfaceCVPixelBuffer : public GLSurface {
 public:
  GLSurfaceCVPixelBuffer(int32_t width, int32_t height,
                         id<DownStreamListener> listener,
                         CVPixelBufferRef pixel_buffer = nullptr);
  ~GLSurfaceCVPixelBuffer() override;

  void Init() override;

  int32_t Width() const override { return width_; }
  int32_t Height() const override { return height_; }

  GLuint GLContextFBO() override { return framebuffer_; }

  bool GLPresent() override;

  bool Valid() const override { return valid_; }

  bool NeedFlipY() const override { return true; }

 private:
  bool InitPixelBuffer();

 private:
  ScopedCFTypeRef<CVPixelBufferRef> pixel_buffer_ref_;
  ScopedCFTypeRef<CVOpenGLESTextureCacheRef> texture_cache_ref_;
  ScopedCFTypeRef<CVOpenGLESTextureRef> texture_ref_;
  GLuint texture_;
  GLuint framebuffer_;
  int32_t width_;
  int32_t height_;
  id<DownStreamListener> frame_listener_;
  bool valid_;
  bool has_external_pixel_buffer_;

  GLSurfaceCVPixelBuffer(const GLSurfaceCVPixelBuffer &) = delete;
  GLSurfaceCVPixelBuffer &operator==(const GLSurfaceCVPixelBuffer &) = delete;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_IOS_GL_SURFACE_CV_PIXEL_BUFFER_H_
