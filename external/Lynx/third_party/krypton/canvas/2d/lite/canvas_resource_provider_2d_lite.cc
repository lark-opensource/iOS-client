// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas_resource_provider_2d_lite.h"

#include "canvas/2d/lite/nanovg/include/nanovg_gl-inl.h"
#include "canvas/2d/lite/nanovg/include/nanovg_gl.h"
#include "canvas/2d/lite/raster_2d_lite.h"
#include "canvas/base/log.h"
#include "canvas/canvas_element.h"

namespace lynx {
namespace canvas {

#ifdef LYNX_KRYPTON_TEST
namespace test {
extern void AccumulateJSTime(const std::function<void()> &task);
}
#endif

class CanvasResourceProvider2DLite::ScopedNVGContext {
 public:
  explicit ScopedNVGContext(GLCommandBuffer *gl_interface) : context_(nullptr) {
    KRYPTON_CONSTRUCTOR_LOG(ScopedNVGContext);
    auto context = nanovg::nvgCreateGLES3(nanovg::NVG_ANTIALIAS, gl_interface);
    if (context) {
      context_ = context;
    }
  }

  nanovg::NVGcontext *Get() const { return context_; }

  ~ScopedNVGContext() {
    if (context_) {
      nanovg::nvgDeleteGLES3(context_);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdelete-incomplete"
      delete context_;
#pragma clang diagnostic pop
      context_ = nullptr;
    }
    KRYPTON_DESTRUCTOR_LOG(ScopedNVGContext);
  }

 private:
  nanovg::NVGcontext *context_;
};

CanvasResourceProvider2DLite::CanvasResourceProvider2DLite(
    CanvasElement *element,
    std::shared_ptr<shell::LynxActor<CanvasRuntime>> runtime_actor,
    std::shared_ptr<shell::LynxActor<SurfaceRegistry>> surface_actor)
    : CanvasResourceProvider(element, runtime_actor, surface_actor,
                             {.antialias = false}),
      during_nvg_flush(false) {
  gl_interface_ = std::make_unique<GLCommandBuffer>(recorder());
}

CanvasResourceProvider2DLite::~CanvasResourceProvider2DLite() {
  nvg_context_.reset();
}

Raster *CanvasResourceProvider2DLite::CreateRaster(
    CanvasResourceProvider *resource_provider,
    CountDownWaitableEvent *gpu_waitable_event,
    const fml::RefPtr<fml::TaskRunner> &gpu_task_runner, const Option &option) {
  auto &attribute_ref =
      GLGlobalDeviceAttributes::Instance().GetDeviceAttributesRef();
  return new Raster2DLite(
      gpu_task_runner,
      {.msaa_sample_count = 0,
       .need_workaround_finish_per_frame =
           attribute_ref.need_workaround_finish_per_frame,
       .need_workaround_egl_sync_after_resize =
           attribute_ref.need_workaround_egl_sync_after_resize},
      gpu_waitable_event, GetCanvasWidth(), GetCanvasHeight());
}

void CanvasResourceProvider2DLite::ReadPixels(int x, int y, int width,
                                              int height, void *data,
                                              bool premultiply_alpha) {
  WillAccessRenderBuffer();
  gl_interface_->GetPixels(x, y, width, height, data, reading_fbo(), true,
                           premultiply_alpha);
}

void CanvasResourceProvider2DLite::PutPixels(void *data, int width, int height,
                                             int srcX, int srcY, int srcWidth,
                                             int srcHeight, int dstX, int dstY,
                                             int dstWidth, int dstHeight) {
  gl_interface_->PutPixels(data, width, height, drawing_fbo(), srcX, srcY,
                           srcWidth, srcHeight, dstX, dstY, dstWidth,
                           dstHeight);
  SetNeedRedraw();
}

bool CanvasResourceProvider2DLite::HasCanvasRenderBuffer() {
  return static_cast<Raster2DLite *>(raster())->HasCanvasRenderBuffer();
}

void CanvasResourceProvider2DLite::DoRaster(bool blit_to_screen, bool is_sync) {
  if (nvg_context_ && !during_nvg_flush) {
    during_nvg_flush = true;
#ifdef LYNX_KRYPTON_TEST
    test::AccumulateJSTime([&] { nanovg::nvgFlush(nvg_context_->Get()); });
#else
    nanovg::nvgFlush(nvg_context_->Get());
#endif
    during_nvg_flush = false;
  }

  FlushCommandBufferInternal(blit_to_screen, is_sync);
}

nanovg::NVGcontext *CanvasResourceProvider2DLite::GetNVGContext() const {
  if (!nvg_context_) {
    nvg_context_ = std::make_unique<ScopedNVGContext>(gl_interface_.get());
    DCHECK(nvg_context_->Get());
    nanovg::nvgCancelFrame(nvg_context_->Get());
    nanovg::nvgBeginFrame(GetNVGContext(), GetCanvasWidth(), GetCanvasHeight(),
                          1.0);
  }
  return nvg_context_->Get();
}

void CanvasResourceProvider2DLite::OnCanvasSizeChangedInternal() {
  if (nvg_context_) {
    nanovg::nvgCancelFrame(nvg_context_->Get());
    nanovg::nvgBeginFrame(nvg_context_->Get(), GetCanvasWidth(),
                          GetCanvasHeight(), 1.0);

    element()->DidCanvasRecreated();
  }
}

}  // namespace canvas
}  // namespace lynx
