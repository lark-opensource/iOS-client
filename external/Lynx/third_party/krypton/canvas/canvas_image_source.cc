//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "canvas_image_source.h"

#include "canvas/2d/lite/nanovg/include/nanovg_gl.h"
#include "canvas/base/log.h"
#include "canvas/canvas_element.h"
#include "canvas/image_element.h"

namespace lynx {
namespace canvas {

#if !defined(OS_WIN) || !defined(ENABLE_RENDERKIT_CANVAS)
int CanvasImageSource::CreateNVGImage(nanovg::NVGcontext* vg,
                                      bool enable_image_smoothing) {
  auto texture_source = this->GetTextureSource();
  int tex = 0, w = GetWidth(), h = GetHeight();
  if (!texture_source) {
    return nanovg::nvgCreateImageRGBA(vg, w, h, 0, nullptr);
  }

  int flag = nanovg::NVG_IMAGE_NODELETE;
  if (enable_image_smoothing) {
    flag |= nanovg::NVG_IMAGE_SMOOTHINGIN;
  }

  WillDraw();
  texture_source->ActSync([&tex, &flag](auto& impl) mutable {
    impl->UpdateTextureOrFramebufferOnGPU();
    tex = impl->Texture();
    if (impl->HasFlipY()) {
      flag |= nanovg::NVG_IMAGE_FLIPY;
    }

    if (impl->HasPremulAlpha()) {
      flag |= nanovg::NVG_IMAGE_PREMULTIPLIED;
    }
  });

  if (!tex) {
    /// Sometimes when drawImage is triggered, the texture of video are not yet
    /// ready. If you create nvgImage using the nvglCreateImageFromHandleGLES3
    /// interface in this case, it will cause an JS exception in the drawImage
    /// interface. At this time, a default empty texture should be created for
    /// rendering.
    return nanovg::nvgCreateImageRGBA(vg, w, h, 0, nullptr);
  }

  return nanovg::nvglCreateImageFromHandleGLES3(vg, tex, w, h, flag);
}
#endif

}  // namespace canvas
}  // namespace lynx
