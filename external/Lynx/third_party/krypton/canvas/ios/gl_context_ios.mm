// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/ios/gl_context_ios.h"

#include "canvas/gpu/gl_context_share_group.h"
#include "canvas/gpu/gl_virtual_context.h"
#include "canvas/ios/gl_context_share_group_ios.h"
#include "canvas/ios/gl_surface_ios.h"
#include "config/config.h"

namespace lynx {
namespace canvas {

std::unique_ptr<GLContext> GLContext::CreateReal() {
  return std::unique_ptr<GLContext>(new GLContextIOS());
}

GLContextIOS::GLContextIOS() { KRYPTON_CONSTRUCTOR_LOG(GLContextIOS); }

void GLContextIOS::Init() {
  if (context_ != nil) {
    return;
  }

#if ENABLE_KRYPTON_EFFECT
  GLContextShareGroup::MakeSureShareGroupCreated();
  auto sharegroup = static_cast<GLContextShareGroupIOS*>(*GlobalShareGroupPtr());
  context_ = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3
                                   sharegroup:sharegroup->Sharegroup()];
#else
  context_ = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
#endif

  if (context_ == nil) {
    KRYPTON_LOGE("Initialize GLContext failed.");
  }
}

bool GLContextIOS::MakeCurrent(GLSurface* gl_surface) {
  if (context_ != nil) {
    return [EAGLContext setCurrentContext:context_];
  }
  return false;
}

bool GLContextIOS::IsCurrent(GLSurface* gl_surface) {
  BOOL context_is_current = context_ == [EAGLContext currentContext];

  if (!context_is_current) {
    return false;
  }

  return true;
}

void GLContextIOS::ClearCurrent() { [EAGLContext setCurrentContext:nil]; }

}  // namespace canvas
}  // namespace lynx
