// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/raster.h"

#include "canvas/canvas_context.h"
#include "canvas/canvas_element.h"
#include "canvas/canvas_resource_provider.h"
#include "canvas/gpu/gl/scoped_gl_error_check.h"
#include "canvas/gpu/gl_surface.h"

namespace lynx {
namespace canvas {

Raster::~Raster() {
  GLMakeCurrent(nullptr);
  if (canvas_renderbuffer_) {
    canvas_renderbuffer_->Dispose();
  }
}

void Raster::Init() {
  DCHECK(CheckOnGPUThread());
  DCHECK(GetGLContext());

  GetGLContext()->Init();

  if (surface_client_) {
    surface_client_->Init();
  }
}

bool Raster::GLMakeCurrent(Surface *surface) const {
  DCHECK(CheckOnGPUThread());
  GLSurface *gl_surface = nullptr;
  if (surface) {
    gl_surface = static_cast<GLSurface *>(surface);
  } else if (IsSurfaceAvailable()) {
    const auto &surface_vector = GetSurfaceVector();
    gl_surface = static_cast<GLSurface *>(surface_vector[0]->surface.get());
  }
  if (!GetGLContext()->IsCurrent(gl_surface)) {
    return GetGLContext()->MakeCurrent(gl_surface);
  }
  return true;
}

void Raster::GLClearCurrent() {
  DCHECK(CheckOnGPUThread());
  GetGLContext()->ClearCurrent();
}

void Raster::OnCanvasSizeChanged(int width, int height) {
  DCHECK(CheckOnGPUThread());

  if (offscreen_surface_size_.width != width ||
      offscreen_surface_size_.height != height) {
    offscreen_surface_size_.Set(width, height);
  }

  offscreen_surface_size_changed_ = true;
}

bool Raster::CheckOnGPUThread() const {
  return gpu_task_runner_->RunsTasksOnCurrentThread();
}

void Raster::CreateOrRecreateCanvasRenderbuffer() {
  DCHECK_SCOPED_NO_GL_ERROR;

  if (!canvas_renderbuffer_) {
    canvas_renderbuffer_ = std::make_unique<CanvasRenderbuffer>();
  }

  KRYPTON_LOGI("canvas renderbuffer build with ")
      << offscreen_surface_size_.width << ", "
      << offscreen_surface_size_.height;
  canvas_renderbuffer_->Build(offscreen_surface_size_.width,
                              offscreen_surface_size_.height,
                              drawing_buffer_option_.msaa_sample_count);
  offscreen_reading_fbo_id_ = canvas_renderbuffer_->reading_fbo();
  offscreen_drawing_fbo_id_ = canvas_renderbuffer_->drawing_fbo();
}

void Raster::DidRaster() const { gpu_waitable_event_->CountUp(); }

GLContext *Raster::GetGLContext() const {
  if (!gl_context_) {
    gl_context_ = GLContext::CreateVirtual();
  }
  return gl_context_.get();
}

}  // namespace canvas
}  // namespace lynx
