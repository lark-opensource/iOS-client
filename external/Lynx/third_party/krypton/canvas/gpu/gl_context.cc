// Copyright 2021 The Lynx Authors. All rights reserved.

#include "gl_context.h"

#include "canvas/base/log.h"
#include "canvas/gpu/gl_virtual_context.h"

namespace lynx {
namespace canvas {

GLContext** ThreadLocalRealContextPtr() {
  thread_local GLContext* real_context = nullptr;
  return &real_context;
}

GLContext** ThreadLocalCurrentContextPtr() {
  thread_local GLContext* current_context = nullptr;
  return &current_context;
}

void GLContext::MakeSureRealContextCreated() {
  if (*ThreadLocalRealContextPtr() == nullptr) {
    *ThreadLocalRealContextPtr() = GLContext::CreateReal().release();
  }
}

std::unique_ptr<GLContext> GLContext::CreateVirtual() {
  MakeSureRealContextCreated();
  return std::make_unique<GLVirtualContext>(*ThreadLocalRealContextPtr());
}

GLContext* GLContext::GetCurrent() { return *ThreadLocalCurrentContextPtr(); }

void GLContext::SetCurrent(GLContext* gl_context, GLSurface* gl_surface) {
  // real context always used as delegate
  DCHECK(!gl_context || !gl_context->IsRealContext());

  *ThreadLocalCurrentContextPtr() = gl_context;

  if (gl_surface) {
    gl_surface->SetCurrent();
  } else {
    GLSurface::ClearCurrent();
  }
}

}  // namespace canvas
}  // namespace lynx
