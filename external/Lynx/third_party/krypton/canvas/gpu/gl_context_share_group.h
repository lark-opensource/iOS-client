//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_CONTEXT_SHARE_GROUP_H_
#define CANVAS_GPU_GL_CONTEXT_SHARE_GROUP_H_

#include <memory>

namespace lynx {
namespace canvas {

class GLContextShareGroup {
 public:
  static std::unique_ptr<GLContextShareGroup> Create();

  static void MakeSureShareGroupCreated();
};

GLContextShareGroup** GlobalShareGroupPtr();
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_CONTEXT_SHARE_GROUP_H_
