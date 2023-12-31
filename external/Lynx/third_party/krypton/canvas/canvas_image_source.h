// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_CANVAS_IMAGE_SOURCE_H_
#define CANVAS_CANVAS_IMAGE_SOURCE_H_

#include <cstddef>
#include <memory>

#include "canvas/2d/lite/nanovg/include/nanovg.h"
#include "canvas/base/size.h"
#include "canvas/canvas_app.h"
#include "canvas/gpu/texture_shader.h"
#include "canvas/texture_source.h"
#include "gpu/gl/gl_api.h"
#include "shell/lynx_actor.h"
#ifdef ENABLE_LYNX_CANVAS_SKIA
#include "canvas/util/skia.h"
#endif

namespace lynx {
namespace canvas {

enum SourceImageStatus {
  kNormalSourceImageStatus,
  kUndecodableSourceImageStatus,     // Image element with a 'broken' image
  kZeroSizeCanvasSourceImageStatus,  // Source is a canvas with width or heigh
                                     // of zero
  kIncompleteSourceImageStatus,      // Image element with no source media
  kInvalidSourceImageStatus,
};

class CanvasImageSource {
 public:
  CanvasImageSource() = default;
  CanvasImageSource(const CanvasImageSource& other) = delete;
  virtual ~CanvasImageSource() = default;

  CanvasImageSource& operator=(const CanvasImageSource&) = delete;

#ifdef ENABLE_LYNX_CANVAS_SKIA
  virtual sk_sp<SkImage> GetSourceImageForCanvas(SourceImageStatus* status) {
    *status = kInvalidSourceImageStatus;
    return nullptr;
  }
#endif

  virtual void WillDraw() {}

  virtual bool IsCanvasElement() const { return false; }
  virtual bool IsImageElement() const { return false; }
  virtual bool IsVideoElement() const { return false; }

  virtual uint32_t GetWidth() = 0;
  virtual uint32_t GetHeight() = 0;

  virtual uint32_t GetImageIDRenderkit() { return 0; }

#if !defined(OS_WIN) || !defined(ENABLE_RENDERKIT_CANVAS)
  virtual std::shared_ptr<shell::LynxActor<TextureSource>> GetTextureSource() {
    return nullptr;
  }

  int CreateNVGImage(nanovg::NVGcontext* vg, bool enable_image_smoothing);
#endif

  bool CanDetect() { return can_detect_; }

 protected:
  std::shared_ptr<CanvasApp> canvas_app_{nullptr};

  bool can_detect_{false};
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_CANVAS_IMAGE_SOURCE_H_
