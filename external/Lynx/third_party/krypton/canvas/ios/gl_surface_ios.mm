// Copyright 2021 The Lynx Authors. All rights reserved.
#include "canvas/ios/gl_surface_ios.h"

#include <UIKit/UIKit.h>
#include "canvas/background_lock.h"
#include "canvas/base/log.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"
#include "canvas/gpu/gl_virtual_context.h"

namespace lynx {
namespace canvas {

GLSurfaceIOS::GLSurfaceIOS(CAEAGLLayer *layer) : layer_(layer), valid_(false) {
  KRYPTON_CONSTRUCTOR_LOG(GLSurfaceIOS);
  DCHECK(layer_);
  NSString *drawableColorFormat = kEAGLColorFormatRGBA8;
  layer_.drawableProperties = @{
    kEAGLDrawablePropertyColorFormat : drawableColorFormat,
    kEAGLDrawablePropertyRetainedBacking : @(NO),
  };
}

GLSurfaceIOS::~GLSurfaceIOS() {
  DeInitialize();
  KRYPTON_DESTRUCTOR_LOG(GLSurfaceIOS);
}

void GLSurfaceIOS::PrepareFrameBuffer() {
  GL::GenFramebuffers(1, &framebuffer_);
  DCHECK(GL::GetError() == GL_NO_ERROR);
  DCHECK(framebuffer_ != GL_NONE);
}

void GLSurfaceIOS::PrepareRenderBuffer() {
  GL::GenRenderbuffers(1, &renderbuffer_);
  DCHECK(GL::GetError() == GL_NO_ERROR);
  DCHECK(renderbuffer_ != GL_NONE);
}

void GLSurfaceIOS::Init() { Initialize(); }

void GLSurfaceIOS::Initialize() {
  DCHECK(GLContext::GetCurrent());
  DCHECK(GL::GetError() == GL_NO_ERROR);
  DCHECK(framebuffer_ == GL_NONE);

  PrepareFrameBuffer();
  PrepareRenderBuffer();
  valid_ = ResizeIfNecessary(layer_.frame.size.width * layer_.contentsScale,
                             layer_.frame.size.height * layer_.contentsScale);
}

void GLSurfaceIOS::DeInitialize() {
  if (framebuffer_ && renderbuffer_) {
    DCHECK(GL::GetError() == GL_NO_ERROR);

    GL::DeleteFramebuffers(1, &framebuffer_);
    GL::DeleteRenderbuffers(1, &renderbuffer_);

    DCHECK(GL::GetError() == GL_NO_ERROR);
  }
}

bool GLSurfaceIOS::ResizeIfNecessary(int size_width, int size_height) {
  if (size_width == pre_size_width_ && size_height == pre_size_height_) {
    return true;
  }

  if (size_width == 0 || size_height == 0) {
    // renderbufferStorage must fail due to zero size.
    // maybe can resize renderbuffer to 1 x 1 to save memory.
    KRYPTON_LOGW("resize surface to 0 x 0");
    pre_size_width_ = 0;
    pre_size_height_ = 0;
    return true;
  }

  ScopedGLResetRestore framebuffer_protector(GL_FRAMEBUFFER_BINDING);
  ScopedGLResetRestore renderbuffer_protector(GL_RENDERBUFFER_BINDING);

  GL::BindFramebuffer(GL_READ_FRAMEBUFFER, framebuffer_);
  GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer_);
  GL::BindRenderbuffer(GL_RENDERBUFFER, renderbuffer_);

  auto virtual_context = static_cast<GLVirtualContext *>(GLContext::GetCurrent());
  auto gl_context = static_cast<GLContextIOS *>(virtual_context->GetRealContext());

  @try {
    if (![gl_context->context() renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer_]) {
      return false;
    }
  } @catch (NSException *e) {
    KRYPTON_LOGE("renderbufferStorage throw exception ") << [[e description] UTF8String];
    return false;
  }

  GL::FramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer_);

  DCHECK(GL::GetError() == GL_NO_ERROR);
  DCHECK(GL::CheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);

  // Fetch the dimensions of the color buffer whose backing was just updated.
  GL::GetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &pre_size_width_);
  DCHECK(GL::GetError() == GL_NO_ERROR);

  GL::GetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &pre_size_height_);
  DCHECK(GL::GetError() == GL_NO_ERROR);

  return true;
}

GLuint GLSurfaceIOS::GLContextFBO() { return framebuffer_; }

bool GLSurfaceIOS::GLPresent() {
  BackgroundLock::Instance().WaitForForeground();
#if 1
  const GLenum discards[] = {
      GL_DEPTH_ATTACHMENT,
      GL_STENCIL_ATTACHMENT,
  };

  GL::InvalidateFramebuffer(GL_FRAMEBUFFER, sizeof(discards) / sizeof(GLenum), discards);
  GLint rbo;
  GL::GetIntegerv(GL_RENDERBUFFER_BINDING, &rbo);
  GL::BindRenderbuffer(GL_RENDERBUFFER, renderbuffer_);
#endif
  BOOL res = [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
  GL::BindRenderbuffer(GL_RENDERBUFFER, rbo);
  return res;
}

bool GLSurfaceIOS::Resize(int32_t width, int32_t height) {
  // make sure visible in this thread
  valid_ = ResizeIfNecessary(width, height);
  return true;
}

int32_t GLSurfaceIOS::Width() const { return pre_size_width_; }

int32_t GLSurfaceIOS::Height() const { return pre_size_height_; }

}  // namespace canvas
}  // namespace lynx
