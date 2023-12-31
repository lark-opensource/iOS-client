// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skia/skia_surface.h"

#include "animax/bridge/animax_onscreen_surface.h"
#include "animax/render/skia/skia_canvas.h"

namespace {
#define GPU_GL_RGBA8 0x8058

inline sk_sp<SkSurface> WrapOnscreenSurface(GrRecordingContext *context,
                                            int32_t width, int32_t height,
                                            intptr_t fbo,
                                            int32_t stencil_bits) {
  const SkColorType color_type = SkColorType::kRGBA_8888_SkColorType;

  GrGLFramebufferInfo framebuffer_info = {};
  framebuffer_info.fFBOID = static_cast<GrGLuint>(fbo);
  framebuffer_info.fFormat = GPU_GL_RGBA8;

  GrBackendRenderTarget render_target(width,            // width
                                      height,           // height
                                      0,                // sample count
                                      stencil_bits,     // stencil bits
                                      framebuffer_info  // framebuffer info
  );

  sk_sp<SkColorSpace> colorspace = SkColorSpace::MakeSRGB();
  SkSurfaceProps surface_props(0, kUnknown_SkPixelGeometry);

  return SkSurface::MakeFromBackendRenderTarget(
      context,                                       // Gr context
      render_target,                                 // render target
      GrSurfaceOrigin::kBottomLeft_GrSurfaceOrigin,  // origin
      color_type,                                    // color type
      colorspace,                                    // colorspace
      &surface_props                                 // surface properties
  );
}
}  // namespace

namespace lynx {
namespace animax {

SkiaSurface::SkiaSurface(AnimaXOnScreenSurface *surface, int32_t width,
                         int32_t height)
    : Surface(surface, width, height) {
  Resize(surface, width, height);
}

SkiaSurface::~SkiaSurface() {}

Canvas *SkiaSurface::GetCanvas() { return skia_canvas_.get(); }

void SkiaSurface::Resize(AnimaXOnScreenSurface *surface, int32_t width,
                         int32_t height) {
  int current_width = sk_surface_ ? sk_surface_->width() : 0;
  int current_height = sk_surface_ ? sk_surface_->height() : 0;
  if (current_width == width && current_height == height) {
    return;
  }
  if (surface->IsGPUBacked()) {
    sk_sp<const GrGLInterface> gl_interface = GrGLMakeNativeInterface();
    sk_sp<GrDirectContext> context = GrDirectContext::MakeGL(gl_interface);
    context->setResourceCacheLimit(0);
    sk_surface_ = WrapOnscreenSurface(context.get(), width, height,
                                      surface->GLContextFBO(), 0);
  } else {
    SkImageInfo info = SkImageInfo::Make({width, height}, kN32_SkColorType,
                                         kPremul_SkAlphaType);
    sk_surface_ = SkSurface::MakeRasterDirect(info, surface->Buffer(),
                                              info.minRowBytes());
  }
  SkCanvas *canvas = nullptr;
  if (enable_recorder_) {
    recorder_.beginRecording(sk_surface_->width(), sk_surface_->height());
    // recorder的canvas只有在录制的时候才能取到
    canvas = recorder_.getRecordingCanvas();
    recorder_.finishRecordingAsPicture();
  } else {
    canvas = sk_surface_->getCanvas();
  }
  skia_canvas_ = std::make_unique<SkiaCanvas>(canvas, sk_surface_->width(),
                                              sk_surface_->height());
}

void SkiaSurface::Clear() {
  if (enable_recorder_) {
    recorder_.beginRecording(sk_surface_->width(), sk_surface_->height());
  } else {
    sk_surface_->getCanvas()->clear(SK_ColorTRANSPARENT);
  }
}

void SkiaSurface::Flush() {
  if (enable_recorder_) {
    auto picture = recorder_.finishRecordingAsPicture();
    sk_surface_->getCanvas()->clear(SK_ColorTRANSPARENT);
    sk_surface_->getCanvas()->drawPicture(picture);
  }
  sk_surface_->flush();
}

void SkiaSurface::Destroy() {}

}  // namespace animax
}  // namespace lynx
