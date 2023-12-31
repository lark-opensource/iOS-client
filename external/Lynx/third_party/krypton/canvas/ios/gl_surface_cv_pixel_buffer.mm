//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "gl_surface_cv_pixel_buffer.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
namespace {};

GLSurfaceCVPixelBuffer::GLSurfaceCVPixelBuffer(int32_t width, int32_t height,
                                               id<DownStreamListener> listener,
                                               CVPixelBufferRef pixel_buffer)
    : texture_(GL_NONE),
      framebuffer_(GL_NONE),
      width_(width),
      height_(height),
      frame_listener_(listener),
      valid_(false) {
  if (pixel_buffer) {
    has_external_pixel_buffer_ = true;
    pixel_buffer_ref_ = ScopedCFTypeRef<CVPixelBufferRef>(pixel_buffer, false);
  } else {
    has_external_pixel_buffer_ = false;
  }
}

GLSurfaceCVPixelBuffer::~GLSurfaceCVPixelBuffer() {
  if (texture_) {
    GL::DeleteTextures(1, &texture_);
  }

  if (framebuffer_) {
    GL::DeleteFramebuffers(1, &framebuffer_);
  }
}

bool GLSurfaceCVPixelBuffer::InitPixelBuffer() {
  // must be delcared as metal compaatible or it can not be used in OpenGL either.
  // but kCVPixelBufferOpenGLCompatibilityKey seems no effect. strange bug.
  NSDictionary* cv_buffer_properties = @{
    (__bridge NSString*)kCVPixelBufferOpenGLCompatibilityKey : @YES,
    (__bridge NSString*)kCVPixelBufferMetalCompatibilityKey : @YES,
  };

  CVPixelBufferRef cv_pixel_buffer_ref = nullptr;

  CVReturn cv_ret =
      CVPixelBufferCreate(kCFAllocatorDefault, width_, height_, kCVPixelFormatType_32BGRA,
                          (__bridge CFDictionaryRef)cv_buffer_properties, &cv_pixel_buffer_ref);

  if (cv_ret != kCVReturnSuccess || cv_pixel_buffer_ref == nullptr) {
    return false;
  }

  pixel_buffer_ref_ = ScopedCFTypeRef<CVPixelBufferRef>(cv_pixel_buffer_ref, true);
  return true;
}

void GLSurfaceCVPixelBuffer::Init() {
  if (!has_external_pixel_buffer_ && !InitPixelBuffer()) {
    return;
  }

  CVOpenGLESTextureCacheRef texture_cache_ref = nullptr;
  CVReturn cv_ret =
      CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
                                   (__bridge CFDictionaryRef)(
                                       @{(id)kCVOpenGLESTextureCacheMaximumTextureAgeKey : @0}),
                                   [EAGLContext currentContext], NULL, &texture_cache_ref);

  if (cv_ret != kCVReturnSuccess || texture_cache_ref == nullptr) {
    return;
  }

  texture_cache_ref_ = ScopedCFTypeRef<CVOpenGLESTextureCacheRef>(texture_cache_ref, true);

  CVOpenGLESTextureRef texture_ref = nullptr;
  cv_ret = CVOpenGLESTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault, texture_cache_ref, (CVPixelBufferRef)pixel_buffer_ref_, NULL,
      GL_TEXTURE_2D, GL_RGBA, (GLsizei)width_, (GLsizei)height_, GL_BGRA, GL_UNSIGNED_BYTE, 0,
      &texture_ref);

  if (cv_ret != kCVReturnSuccess || texture_ref == nullptr) {
    return;
  }

  texture_ref_ = ScopedCFTypeRef<CVOpenGLESTextureRef>(texture_ref, true);

  texture_ = CVOpenGLESTextureGetName(texture_ref);

  CVOpenGLESTextureCacheFlush(texture_cache_ref, 0);

  GL::GenFramebuffers(1, &framebuffer_);

  GLint draw_fbo;
  GLint tex;
  GL::GetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &draw_fbo);
  GL::GetIntegerv(GL_TEXTURE_BINDING_2D, &tex);

  GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer_);
  GL::BindTexture(GL_TEXTURE_2D, texture_);
  GL::FramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture_, 0);

  GL::BindTexture(GL_TEXTURE_2D, tex);
  GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, draw_fbo);

  DCHECK(GL::GetError() == GL_NO_ERROR);
  DCHECK(framebuffer_ == GL_NONE);
  valid_ = true;
}

class ScopedNoLeakedGLContext {
 public:
  ScopedNoLeakedGLContext() : context_([EAGLContext currentContext]) {}

  ~ScopedNoLeakedGLContext() {
    if (context_ != nil) {
      [EAGLContext setCurrentContext:context_];
    }
  }

 private:
  EAGLContext* context_;
};

bool GLSurfaceCVPixelBuffer::GLPresent() {
  DCHECK(valid_);

  GL::Finish();

  // trigger callback
  if (frame_listener_ != nil) {
    ScopedNoLeakedGLContext no_leaked_context;

    [frame_listener_ onFrameAvailable:pixel_buffer_ref_];
  }

  return true;
}

}  // namespace canvas
}  // namespace lynx
