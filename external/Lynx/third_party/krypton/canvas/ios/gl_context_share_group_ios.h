//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_IOS_GL_CONTEXT_SHARE_GROUP_IOS_H_
#define CANVAS_IOS_GL_CONTEXT_SHARE_GROUP_IOS_H_

#import <OpenGLES/EAGL.h>

#include "canvas/gpu/gl_context_share_group.h"

namespace lynx {
namespace canvas {

class GLContextShareGroupIOS : public GLContextShareGroup {
 public:
  GLContextShareGroupIOS();

  EAGLSharegroup* Sharegroup();

 private:
  EAGLContext* context_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_IOS_GL_CONTEXT_SHARE_GROUP_IOS_H_
