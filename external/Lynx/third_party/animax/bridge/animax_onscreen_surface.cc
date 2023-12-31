// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/bridge/animax_onscreen_surface.h"

#include "canvas/gpu/gl_context.h"
#include "canvas/surface/software_surface.h"

namespace lynx {
namespace animax {

AnimaXOnScreenSurface::AnimaXOnScreenSurface(
    std::unique_ptr<lynx::canvas::Surface> surface)
    : surface_(std::move(surface)) {}

void AnimaXOnScreenSurface::Init() {
  if (IsGPUBacked()) {
    context_ = lynx::canvas::GLContext::CreateVirtual();
    context_->Init();
    context_->MakeCurrent(nullptr);
  }
  surface_->Init();
}

void AnimaXOnScreenSurface::MakeRelatedContextCurrent() {
  if (IsGPUBacked()) {
    context_->MakeCurrent(
        reinterpret_cast<lynx::canvas::GLSurface *>(surface_.get()));
  }
}

void AnimaXOnScreenSurface::Flush() { surface_->Flush(); }

bool AnimaXOnScreenSurface::Resize(int32_t width, int32_t height) {
  MakeRelatedContextCurrent();
  return surface_->Resize(width, height);
}

int32_t AnimaXOnScreenSurface::Width() const { return surface_->Width(); }

int32_t AnimaXOnScreenSurface::Height() const { return surface_->Height(); }

bool AnimaXOnScreenSurface::IsGPUBacked() const {
  return surface_->IsGPUBacked();
}

GLuint AnimaXOnScreenSurface::GLContextFBO() {
  if (IsGPUBacked()) {
    return reinterpret_cast<lynx::canvas::GLSurface *>(surface_.get())
        ->GLContextFBO();
  }
  return 0;
}

uint8_t *AnimaXOnScreenSurface::Buffer() const {
  if (!IsGPUBacked()) {
    return reinterpret_cast<lynx::canvas::SoftwareSurface *>(surface_.get())
        ->Buffer();
  }
  return nullptr;
}

int32_t AnimaXOnScreenSurface::BytesPerRow() {
  if (!IsGPUBacked()) {
    return reinterpret_cast<lynx::canvas::SoftwareSurface *>(surface_.get())
        ->BytesPerRow();
  }
  return 0;
}

}  // namespace animax
}  // namespace lynx
