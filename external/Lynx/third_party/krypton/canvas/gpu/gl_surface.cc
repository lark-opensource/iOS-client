// Copyright 2021 The Lynx Authors. All rights reserved.

#include "gl_surface.h"

namespace lynx {
namespace canvas {
namespace {
GLSurface** ThreadLocalCurrentSurfacePtr() {
  thread_local GLSurface* current = nullptr;
  return &current;
}
}  // namespace

GLSurface* GLSurface::GetCurrent() { return *ThreadLocalCurrentSurfacePtr(); }

void GLSurface::ClearCurrent() { *ThreadLocalCurrentSurfacePtr() = nullptr; }

void GLSurface::SetCurrent() { *ThreadLocalCurrentSurfacePtr() = this; }
}  // namespace canvas
}  // namespace lynx
