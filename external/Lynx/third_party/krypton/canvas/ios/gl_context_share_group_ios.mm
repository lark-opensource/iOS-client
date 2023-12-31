//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "gl_context_share_group_ios.h"

namespace lynx {
namespace canvas {

std::unique_ptr<GLContextShareGroup> GLContextShareGroup::Create() {
  return std::make_unique<GLContextShareGroupIOS>();
}

GLContextShareGroupIOS::GLContextShareGroupIOS() {
  context_ = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
}

EAGLSharegroup* GLContextShareGroupIOS::Sharegroup() { return [context_ sharegroup]; }

}  // namespace canvas
}  // namespace lynx
