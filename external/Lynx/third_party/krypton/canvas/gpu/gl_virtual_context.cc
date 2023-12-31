// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/gpu/gl_virtual_context.h"

#include "canvas/base/log.h"
#include "canvas/gpu/gl_global_device_attributes.h"

namespace lynx {
namespace canvas {

GLVirtualContext::GLVirtualContext(GLContext* real_context)
    : real_context_(real_context), state_restorer_(nullptr) {
  KRYPTON_CONSTRUCTOR_LOG(GLVirtualContext);
  DCHECK(real_context_);
  real_context_->Ref();
}

GLVirtualContext::~GLVirtualContext() {
  if (GetCurrent() == this) {
    KRYPTON_LOGI("GLVirtualContext destructor but current is this. ");
    // clear current but no need to save
    SetCurrent(nullptr, nullptr);
  }
  real_context_->UnRef();
  KRYPTON_DESTRUCTOR_LOG(GLVirtualContext);
}

void GLVirtualContext::Init() { real_context_->Init(); }

bool GLVirtualContext::MakeCurrent(GLSurface* gl_surface) {
  // if only surface changed, no need to save / restore state.
  bool need_switch_state =
      !GLContext::GetCurrent() || GLContext::GetCurrent() != this;

  if (need_switch_state && GLContext::GetCurrent()) {
    // clear last current, it need to save state
    GLContext::GetCurrent()->ClearCurrent();
  }

  if (!real_context_->MakeCurrent(gl_surface)) {
    return false;
  }

  thread_local Estate* initial_state = nullptr;

  if (!initial_state) {
    initial_state = new Estate();
    initial_state->Save();

    DCHECK(need_switch_state);
  }

  if (!state_restorer_) {
    state_restorer_ = initial_state->Clone();
  }
  if (need_switch_state) {
    state_restorer_->SetCurrent();
  }

  SetCurrent(this, gl_surface);

  return true;
}

bool GLVirtualContext::IsCurrent(GLSurface* gl_surface) {
  if (GetCurrent() != this) {
    return false;
  }

  return GLSurface::GetCurrent() == gl_surface;
}

void GLVirtualContext::ClearCurrent() {
  // save exist error
  auto err = glGetError();
  if (err != GL_NO_ERROR) {
    error_ = err;
  }

  state_restorer_->Save();
  SetCurrent(nullptr, nullptr);
}

GLenum GLVirtualContext::GetSavedError() {
  auto err = error_;
  error_ = GL_NO_ERROR;
  return err;
}

void GLVirtualContext::SetErrorToSave(GLenum error) {
  DCHECK(error != GL_NO_ERROR);
  error_ = error;
}

}  // namespace canvas
}  // namespace lynx
