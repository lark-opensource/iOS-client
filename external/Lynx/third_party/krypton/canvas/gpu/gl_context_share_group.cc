//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "gl_context_share_group.h"

namespace lynx {
namespace canvas {

GLContextShareGroup** GlobalShareGroupPtr() {
  static GLContextShareGroup* group = nullptr;
  return &group;
}

void GLContextShareGroup::MakeSureShareGroupCreated() {
  if (*GlobalShareGroupPtr() == nullptr) {
    *GlobalShareGroupPtr() = GLContextShareGroup::Create().release();
  }
}

}  // namespace canvas
}  // namespace lynx
