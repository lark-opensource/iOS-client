// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_SURFACE_H_
#define ANIMAX_RENDER_SKITY_SKITY_SURFACE_H_

#include "animax/render/include/surface.h"
#include "animax/render/skity/skity_canvas.h"
#include "animax/render/skity/skity_gpu_context.h"
#include "skity/skity.hpp"

#if OS_IOS
#import <CoreFoundation/CoreFoundation.h>
#import <OpenGLES/ES3/gl.h>
#else
#include <EGL/egl.h>
#include <GLES3/gl3.h>
#endif

namespace lynx {
namespace animax {

class SkitySurface : public Surface {
 public:
  SkitySurface(AnimaXOnScreenSurface *surface, int32_t width, int32_t height);
  ~SkitySurface() override = default;

  Canvas *GetCanvas() override;
  void Resize(AnimaXOnScreenSurface *surface, int32_t width,
              int32_t height) override;
  void Clear() override;
  void Flush() override;
  void Destroy() override;

 private:
  void InitMSAARootFBO(int32_t width, int32_t height);
  void InitFXAARootFBO(int32_t width, int32_t height);
  void ReleaseMSAARootFBO();
  void ReleaseFXAARootFBO();
  void *GetProcLoader() const;

  bool is_gpu_ = true;
  std::unique_ptr<skity::GPUGLContext> ctx_ = {};
  std::shared_ptr<skity::RenderContext> render_ctx_ = {};
  std::unique_ptr<skity::Bitmap> bitmap_ = {};
  std::unique_ptr<skity::Canvas> canvas_ = {};
  std::unique_ptr<SkityCanvas> wrap_ = {};
  GLuint root_fbo_ = 0;
  // [color, stencil]
  std::array<GLuint, 2> fbo_buffers_ = {};

  const bool fxaa_ = true;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_SURFACE_H_
