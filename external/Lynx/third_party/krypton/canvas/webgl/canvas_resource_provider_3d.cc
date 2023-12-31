// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas_resource_provider_3d.h"

#include <memory>
#include <utility>

#include "canvas/gpu/gl_constants.h"
#include "canvas/util/texture_util.h"
#include "canvas/webgl/raster_3d.h"

namespace lynx {
namespace canvas {
namespace {
const uint32_t kDefaultMSAASampleCount = 4;
}
CanvasResourceProvider3D::CanvasResourceProvider3D(
    CanvasElement* element,
    std::shared_ptr<shell::LynxActor<CanvasRuntime>> actor,
    std::shared_ptr<shell::LynxActor<SurfaceRegistry>> surface_actor,
    Option option)
    : CanvasResourceProvider(element, std::move(actor),
                             std::move(surface_actor), std::move(option)),
      drawing_buffer_width_(0),
      drawing_buffer_height_(0),
      max_viewport_size_{std::numeric_limits<int>::max(),
                         std::numeric_limits<int>::max()} {}

Raster* CanvasResourceProvider3D::CreateRaster(
    CanvasResourceProvider* resource_provider,
    CountDownWaitableEvent* gpu_waitable_event,
    const fml::RefPtr<fml::TaskRunner>& gpu_task_runner, const Option& option) {
  // consider to move device support to here for query, but it needs gl context
  auto& attribute_Ref =
      GLGlobalDeviceAttributes::Instance().GetDeviceAttributesRef();
  DrawingBufferOption drawing_buffer_option{
      .msaa_sample_count = option.antialias ? kDefaultMSAASampleCount : 0,
      .need_workaround_finish_per_frame =
          attribute_Ref.need_workaround_finish_per_frame,
      .need_workaround_egl_sync_after_resize =
          attribute_Ref.need_workaround_egl_sync_after_resize};
  return new Raster3D(gpu_task_runner, drawing_buffer_option,
                      gpu_waitable_event, GetCanvasWidth(), GetCanvasHeight());
}

void CanvasResourceProvider3D::DoRaster(bool blit_to_screen, bool is_sync) {
  FlushCommandBufferInternal(blit_to_screen, is_sync);
}

int CanvasResourceProvider3D::GetDrawingBufferSizeWidth() {
  DCHECK(drawing_buffer_width_);
  return drawing_buffer_width_;
}

int CanvasResourceProvider3D::GetDrawingBufferSizeHeight() {
  DCHECK(drawing_buffer_height_);
  return drawing_buffer_height_;
}

CanvasResourceProvider3D::~CanvasResourceProvider3D() = default;

void CanvasResourceProvider3D::AdjustCanvasSizeInResizeIfNeeded(int& width,
                                                                int& height) {
  if (max_viewport_size_[0] == std::numeric_limits<int>::max()) {
    auto attribute = GLGlobalDeviceAttributes::Instance().GetDeviceAttributes();
    max_viewport_size_[0] = attribute.max_viewport_size_[0];
    max_viewport_size_[1] = attribute.max_viewport_size_[1];
  }

  // drawing buffer size for 3d need to be clamp to valid value
  width = std::min(std::max(1, width), max_viewport_size_[0]);
  height = std::min(std::max(1, height), max_viewport_size_[1]);

  drawing_buffer_width_ = width;
  drawing_buffer_height_ = height;
}

void CanvasResourceProvider3D::ReadPixels(int x, int y, int width, int height,
                                          void* data, bool premultiply_alpha) {
  WillAccessRenderBuffer();

  struct Runnable {
    void Run(command_buffer::RunnableBuffer* buffer) {
      int32_t rbo, readFbo, drawFbo, enableScissorTest;
      enableScissorTest = GL::IsEnabled(KR_GL_SCISSOR_TEST);
      GL::GetIntegerv(KR_GL_RENDERBUFFER_BINDING, &rbo);
      GL::GetIntegerv(KR_GL_READ_FRAMEBUFFER_BINDING, &readFbo);
      GL::GetIntegerv(KR_GL_DRAW_FRAMEBUFFER_BINDING, &drawFbo);

      if (enableScissorTest) {
        GL::Disable(KR_GL_SCISSOR_TEST);
      }

      uint32_t newFbo, newRbo;
      GL::GenFramebuffers(1, &newFbo);
      GL::GenRenderbuffers(1, &newRbo);
      GL::BindFramebuffer(KR_GL_FRAMEBUFFER, newFbo);
      GL::BindRenderbuffer(KR_GL_RENDERBUFFER, newRbo);
      GL::RenderbufferStorage(KR_GL_RENDERBUFFER, KR_GL_RGBA8, width_, height_);
      GL::FramebufferRenderbuffer(KR_GL_FRAMEBUFFER, KR_GL_COLOR_ATTACHMENT0,
                                  KR_GL_RENDERBUFFER, newRbo);
      int32_t srcX0 = x_, srcY0 = y_;
      int32_t srcX1 = srcX0 + width_, srcY1 = srcY0 + height_;
      int32_t dstX0 = 0, dstY0 = height_;
      int32_t dstX1 = dstX0 + width_, dstY1 = dstY0 - height_;
      GL::BindFramebuffer(KR_GL_READ_FRAMEBUFFER, fbo_);
      GL::BlitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1,
                          dstY1, KR_GL_COLOR_BUFFER_BIT, KR_GL_LINEAR);
      GL::BindFramebuffer(KR_GL_READ_FRAMEBUFFER, newFbo);
      GL::ReadPixels(0, 0, width_, height_, KR_GL_RGBA, KR_GL_UNSIGNED_BYTE,
                     pixels_);
      if (!premultiply_alpha_) {
        TextureUtil::UnpremultiplyAlpha((uint8_t*)pixels_, (uint8_t*)pixels_,
                                        width_, height_, width_ * 4, 4,
                                        KR_GL_UNSIGNED_BYTE);
      }

      if (enableScissorTest) {
        GL::Enable(KR_GL_SCISSOR_TEST);
      }
      GL::BindFramebuffer(KR_GL_READ_FRAMEBUFFER, readFbo);
      GL::BindFramebuffer(KR_GL_DRAW_FRAMEBUFFER, drawFbo);
      GL::BindRenderbuffer(KR_GL_RENDERBUFFER, rbo);
      GL::DeleteFramebuffers(1, &newFbo);
      GL::DeleteRenderbuffers(1, &newRbo);
    }

    int32_t x_;
    int32_t y_;
    int32_t width_;
    int32_t height_;
    void* pixels_ = nullptr;
    uint32_t fbo_;
    bool premultiply_alpha_;
  };

  auto cmd = recorder()->Alloc<Runnable>();
  cmd->x_ = x;
  cmd->y_ = y;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->pixels_ = data;
  cmd->fbo_ = reading_fbo();
  cmd->premultiply_alpha_ = premultiply_alpha;

  recorder()->Commit(true);
}

void CanvasResourceProvider3D::WillAccessRenderBuffer() {
  DCHECK(gpu_actor());
  gpu_actor()->Act([](auto& impl) { impl->WillAccessContent(true); });
}

}  // namespace canvas
}  // namespace lynx
