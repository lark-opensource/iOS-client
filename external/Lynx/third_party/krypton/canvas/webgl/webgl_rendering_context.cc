// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_rendering_context.h"

#include <memory>
#include <utility>

#include "base/string/string_utils.h"
#include "canvas/base/log.h"
#include "canvas/gpu/gl/gl_api.h"
#include "canvas/gpu/gl_global_device_attributes.h"
#include "canvas/raster.h"
#include "canvas/util/js_object_pair.h"
#include "canvas/webgl/canvas_resource_provider_3d.h"
#include "canvas/webgl/vertex_attrib_pointer.h"
#include "third_party/krypton/canvas/gpu/command_buffer_ng/runnable_buffer.h"

namespace lynx {
namespace canvas {

WebGLRenderingContext::WebGLRenderingContext(
    CanvasElement *canvas, std::shared_ptr<CanvasApp> canvas_app,
    std::unique_ptr<WebGLContextAttributes> context_attributes)
    : CanvasContext(canvas),
      canvas_app_(canvas_app),
      device_attributes_(
          GLGlobalDeviceAttributes::Instance().GetDeviceAttributes()),
      context_attributes_(std::move(context_attributes)),
      unique_id_(GenerateUniqueId()),
      recorder_(ResourceProvider()->GetRecorder()) {
  KRYPTON_CONSTRUCTOR_LOG(WebGLRenderingContext);
}

WebGLRenderingContext::~WebGLRenderingContext() {
  if (local_cache_.default_vertex_array_object_) {
    local_cache_.default_vertex_array_object_->Dispose();
    delete local_cache_.default_vertex_array_object_;
    local_cache_.default_vertex_array_object_ = nullptr;
  }

  KRYPTON_DESTRUCTOR_LOG(WebGLRenderingContext);
}

void WebGLRenderingContext::OnWrapped() { InitNewContext(); }

int WebGLRenderingContext::GetDrawingBufferWidth() {
  return static_cast<CanvasResourceProvider3D *>(
             element_->ResourceProvider().get())
      ->GetDrawingBufferSizeWidth();
}

int WebGLRenderingContext::GetDrawingBufferHeight() {
  return static_cast<CanvasResourceProvider3D *>(
             element_->ResourceProvider().get())
      ->GetDrawingBufferSizeHeight();
}

void WebGLRenderingContext::ActiveTexture(GLenum texture_id) {
  DCHECK(Recorder());
  // check texture_id to prevent overhead crash.
  if (texture_id < KR_GL_TEXTURE0 ||
      texture_id >= KR_GL_TEXTURE0 +
                        device_attributes_.max_combined_texture_image_units_) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "activeTexture", "invalid unit id");
    return;
  }

  local_cache_.active_texture_ = texture_id;

  class Runnable {
   public:
    explicit Runnable(GLenum texture) : cur_texture_(texture) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::ActiveTexture(cur_texture_);
    }

   private:
    GLenum cur_texture_ = 0;
  };
  Recorder()->Alloc<Runnable>(texture_id);
}

void WebGLRenderingContext::BindBuffer(GLenum target, WebGLBuffer *buffer) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    GLenum err;
    const char *err_msg;
    const char *func_name = "bindBuffer";
    if (!ValidateNullableWebGLObject(buffer, &err, &err_msg) ||
        !ValidateBufferBindTarget(target, buffer, &err, &err_msg)) {
      SynthesizeGLError(err, func_name, err_msg);
      return;
    }
  }

  switch (target) {
    case KR_GL_ARRAY_BUFFER:
      if (buffer != local_cache_.array_buffer_bind_) {
        local_cache_.array_buffer_bind_ = buffer;
      }
      break;
    case KR_GL_ELEMENT_ARRAY_BUFFER: {
      const auto &vao = local_cache_.ValidVertexArrayObject();
      if (buffer != vao->BoundElementArrayBuffer()) {
        vao->SetElementArrayBuffer(buffer);
      }
      break;
    }
    default:
      // should not reach here.
      DCHECK(false);
  }

  DCHECK(Recorder());
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::BindBuffer(target_, content_ ? content_->Get() : 0);
    }
    GLenum target_{};
    PuppetContent<GLenum> *content_ = nullptr;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->content_ = buffer ? buffer->related_id_.Get() : nullptr;
  cmd->target_ = target;
}

/*
 * Reviewed by xieguo, 06/25/2021
 */
void WebGLRenderingContext::BindFramebuffer(GLenum target,
                                            WebGLFramebuffer *framebuffer) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    GLenum err;
    const char *err_msg;
    const char *func_name = "bindFramebuffer";
    if (!ValidateNullableWebGLObject(framebuffer, &err, &err_msg) ||
        !ValidateFramebufferBindTarget(target, &err, &err_msg)) {
      SynthesizeGLError(KR_GL_INVALID_ENUM, func_name, "invalid target");
      return;
    }
  }

  PuppetContent<GLenum> *content = nullptr;

  if (!framebuffer) {
    local_cache_.draw_framebuffer_bind_ = nullptr;
    // change GL_COLOR_ATTCHMENTi -> GL_BACK
    if (local_cache_.read_buffer_mode_ != KR_GL_NONE &&
        local_cache_.read_buffer_mode_ != KR_GL_BACK) {
      local_cache_.read_buffer_mode_ = KR_GL_BACK;
    }
    local_cache_.read_framebuffer_bind_ = nullptr;
  } else {
    framebuffer->SetHasEverBeenBound();
    content = framebuffer->related_id_.Get();
    local_cache_.draw_framebuffer_bind_ = framebuffer;
    local_cache_.read_buffer_mode_ = KR_GL_COLOR_ATTACHMENT0;
    local_cache_.read_framebuffer_bind_ = framebuffer;
  }

  DCHECK(Recorder() && element_ != nullptr);
  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      if (!content_) {
        // webgl 1 do not support read / draw
        DCHECK(target_ == GL_FRAMEBUFFER);
        GL::BindFramebuffer(GL_READ_FRAMEBUFFER, default_reading_fbo_);
        GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, default_drawing_fbo_);
      } else {
        auto framebuffer = content_->Get();
        GL::BindFramebuffer(target_, framebuffer);
        GL::ReadBuffer(KR_GL_COLOR_ATTACHMENT0);
      }
    }
    GLenum target_ = 0;
    GLenum default_reading_fbo_ = 0;
    GLenum default_drawing_fbo_ = 0;
    PuppetContent<GLenum> *content_ = nullptr;
  };
  element_->ResourceProvider()->WillAccessRenderBuffer();

  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->default_reading_fbo_ =
      std::static_pointer_cast<CanvasResourceProvider3D>(
          element_->ResourceProvider())
          ->reading_fbo();
  cmd->default_drawing_fbo_ =
      std::static_pointer_cast<CanvasResourceProvider3D>(
          element_->ResourceProvider())
          ->drawing_fbo();
  cmd->content_ = content;
}

void WebGLRenderingContext::BindRenderbuffer(GLenum target,
                                             WebGLRenderbuffer *renderbuffer) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    GLenum err;
    const char *func_name = "bindRenderbuffer";
    const char *err_msg;
    if (!ValidateNullableWebGLObject(renderbuffer, &err, &err_msg) ||
        !ValidateRenderbufferBindTarget(target, &err, &err_msg)) {
      SynthesizeGLError(err, func_name, err_msg);
      return;
    }
  }

  PuppetContent<GLenum> *content = nullptr;
  if (!renderbuffer) {
    local_cache_.renderbuffer_bind_ = nullptr;
  } else {
    content = renderbuffer->related_id_.Get();
    local_cache_.renderbuffer_bind_ = renderbuffer;
    renderbuffer->SetHasEverBeenBound();
  }

  DCHECK(Recorder());
  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      if (!content_) {
        GL::BindRenderbuffer(target_, 0);
      } else {
        GL::BindRenderbuffer(target_, content_->Get());
      }
    }
    GLenum target_{};
    PuppetContent<GLenum> *content_ = nullptr;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->content_ = content;
  cmd->target_ = target;
}

void WebGLRenderingContext::BindTexture(GLenum target, WebGLTexture *texture) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    GLenum err;
    const char *func_name = "bindTexture";
    const char *err_msg;
    if (!ValidateNullableWebGLObject(texture, &err, &err_msg) ||
        !ValidateTextureBindTarget(target, &err, &err_msg)) {
      SynthesizeGLError(err, func_name, err_msg);
      return;
    }

    if (texture && texture->GetTarget() && texture->GetTarget() != target) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "bindTexture",
                        "textures can not be used with multiple targets");
      return;
    }
  }

  auto _index = local_cache_.active_texture_ - KR_GL_TEXTURE0;

  switch (target) {
    case KR_GL_TEXTURE_2D:
      local_cache_.texture_2d_bind_[_index] = texture;
      break;
    case KR_GL_TEXTURE_CUBE_MAP:
      local_cache_.texture_cube_bind_[_index] = texture;
      break;
    case GL_TEXTURE_2D_ARRAY:
      local_cache_.texture_2d_array_bind_[_index] = texture;
      break;
    default:
      DCHECK(false);
      return;
  }

  if (texture) {
    texture->SetTarget(target);
    local_cache_.one_plus_max_non_default_texture_unit_ = std::max(
        _index + 1, local_cache_.one_plus_max_non_default_texture_unit_);
  } else {
    // If the disabled index is the current maximum, trace backwards to find the
    // new max enabled texture index
    if (local_cache_.one_plus_max_non_default_texture_unit_ == _index + 1) {
      FindNewMaxNonDefaultTextureUnit();
    }
  }

  DCHECK(Recorder());
  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::BindTexture(target_, content_ ? content_->Get() : 0);
    }
    GLenum target_ = 0;
    PuppetContent<uint32_t> *content_ = nullptr;
  };

  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->content_ = texture ? texture->related_id_.Get() : nullptr;
}

void WebGLRenderingContext::BlendColor(GLclampf red, GLclampf green,
                                       GLclampf blue, GLclampf alpha) {
  local_cache_.blend_color_[0] = red;
  local_cache_.blend_color_[1] = green;
  local_cache_.blend_color_[2] = blue;
  local_cache_.blend_color_[3] = alpha;

  DCHECK(Recorder());
  class Runnable {
   public:
    explicit Runnable(const GLclampf *color) {
      memcpy(color_, color, 4 * sizeof(GLfloat));
    }
    void Run(command_buffer::RunnableBuffer *buffer) {
      GL::BlendColor(color_[0], color_[1], color_[2], color_[3]);
    }

   private:
    GLclampf color_[4] = {0};
  };
  Recorder()->Alloc<Runnable>(local_cache_.blend_color_);
}

void WebGLRenderingContext::BlendEquation(GLenum mode) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    GLenum err;
    const char *func_name = "blendEquation";
    const char *err_msg;
    if (!ValidateModeEnum(mode, &err, &err_msg)) {
      SynthesizeGLError(err, func_name, err_msg);
      return;
    }
  }

  // save cache
  local_cache_.blend_equation_rgb_mode_ = mode;
  local_cache_.blend_equation_alpha_mode_ = mode;

  DCHECK(Recorder());
  // commit command
  class Runnable {
   public:
    explicit Runnable(GLenum mode) : mode_(mode) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::BlendEquation(mode_);
    }

   private:
    GLenum mode_ = 0;
  };
  Recorder()->Alloc<Runnable>(mode);
}

void WebGLRenderingContext::BlendEquationSeparate(GLenum modeRGB,
                                                  GLenum modeAlpha) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    GLenum err;
    const char *func_name = "blendEquationSeparate";
    const char *err_msg;
    if (!ValidateModeEnum(modeRGB, &err, &err_msg) ||
        !ValidateModeEnum(modeAlpha, &err, &err_msg)) {
      SynthesizeGLError(err, func_name, err_msg);
      return;
    }
  }

  // save cache
  local_cache_.blend_equation_rgb_mode_ = modeRGB;
  local_cache_.blend_equation_alpha_mode_ = modeAlpha;

  DCHECK(Recorder());
  // commit command
  class Runnable {
   public:
    Runnable(GLenum rgb, GLenum alpha) : rgb_mode_(rgb), alpha_mode_(alpha) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::BlendEquationSeparate(rgb_mode_, alpha_mode_);
    }

   private:
    GLenum rgb_mode_, alpha_mode_;
  };

  Recorder()->Alloc<Runnable>(modeRGB, modeAlpha);
}

void WebGLRenderingContext::BlendFunc(GLenum sfactor, GLenum dfactor) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    GLenum err;
    const char *func_name = "blendFunc";
    const char *err_msg;
    if (!ValidateFuncFactor(sfactor, &err, &err_msg) ||
        !ValidateFuncFactor(dfactor, &err, &err_msg)) {
      SynthesizeGLError(err, func_name, err_msg);
      return;
    }

    // src & dst compatible check
    if (((sfactor == KR_GL_CONSTANT_COLOR ||
          sfactor == KR_GL_ONE_MINUS_CONSTANT_COLOR) &&
         (dfactor == KR_GL_CONSTANT_ALPHA ||
          dfactor == KR_GL_ONE_MINUS_CONSTANT_ALPHA)) ||
        ((dfactor == KR_GL_CONSTANT_COLOR ||
          dfactor == KR_GL_ONE_MINUS_CONSTANT_COLOR) &&
         (sfactor == KR_GL_CONSTANT_ALPHA ||
          sfactor == KR_GL_ONE_MINUS_CONSTANT_ALPHA))) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, func_name, "invalid factor");
      return;
    }
  }

  // save cache
  local_cache_.blend_func_src_rgb_ = sfactor;
  local_cache_.blend_func_src_alpha_ = sfactor;
  local_cache_.blend_func_dst_rgb_ = dfactor;
  local_cache_.blend_func_dst_alpha_ = dfactor;

  DCHECK(Recorder());
  // commit command
  class Runnable {
   public:
    Runnable(uint32_t sf, uint32_t df) : sfactor_(sf), dfactor_(df) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::BlendFunc(sfactor_, dfactor_);
    }

   private:
    uint32_t sfactor_, dfactor_;
  };
  Recorder()->Alloc<Runnable>(sfactor, dfactor);
}

void WebGLRenderingContext::BlendFuncSeparate(GLenum srcRGB, GLenum dstRGB,
                                              GLenum srcAlpha,
                                              GLenum dstAlpha) {
  uint32_t factor[4] = {srcRGB, dstRGB, srcAlpha, dstAlpha};
  KRYPTON_ERROR_CHECK_IF_NEED {
    GLenum err;
    const char *func_name = "blendFuncSeparate";
    const char *err_msg;
    if (!ValidateFuncFactor(srcRGB, &err, &err_msg) ||
        !ValidateFuncFactor(dstRGB, &err, &err_msg) ||
        !ValidateFuncFactor(srcAlpha, &err, &err_msg) ||
        !ValidateFuncFactor(dstAlpha, &err, &err_msg)) {
      SynthesizeGLError(err, func_name, err_msg);
      return;
    }

    // src & dst compatibility check
    for (uint32_t i = 0; i < 2; i++) {
      if (((factor[i * 2] == KR_GL_CONSTANT_COLOR ||
            factor[i * 2] == KR_GL_ONE_MINUS_CONSTANT_COLOR) &&
           (factor[2 * i + 1] == KR_GL_CONSTANT_ALPHA ||
            factor[2 * i + 1] == KR_GL_ONE_MINUS_CONSTANT_ALPHA)) ||
          ((factor[2 * i + 1] == KR_GL_CONSTANT_COLOR ||
            factor[2 * i + 1] == KR_GL_ONE_MINUS_CONSTANT_COLOR) &&
           (factor[i * 2] == KR_GL_CONSTANT_ALPHA ||
            factor[i * 2] == KR_GL_ONE_MINUS_CONSTANT_ALPHA))) {
        SynthesizeGLError(KR_GL_INVALID_OPERATION, "blendFuncSeperate",
                          "invalid factor");
        return;
      }
    }
  }

  // save cache
  local_cache_.blend_func_src_rgb_ = srcRGB;
  local_cache_.blend_func_src_alpha_ = dstRGB;
  local_cache_.blend_func_dst_rgb_ = srcAlpha;
  local_cache_.blend_func_dst_alpha_ = dstAlpha;

  DCHECK(Recorder());
  // commit command
  class Runnable {
   public:
    Runnable(uint32_t src_rgb, uint32_t dst_rgb, uint32_t src_alpha,
             uint32_t dst_alpha) {
      src_rgb_ = src_rgb;
      dst_rgb_ = dst_rgb;
      src_alpha_ = src_alpha;
      dst_alpha_ = dst_alpha;
    }
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::BlendFuncSeparate(src_rgb_, dst_rgb_, src_alpha_, dst_alpha_);
    }

   private:
    uint32_t src_rgb_ = 0;
    uint32_t dst_rgb_ = 0;
    uint32_t src_alpha_ = 0;
    uint32_t dst_alpha_ = 0;
  };
  Recorder()->Alloc<Runnable>(srcRGB, dstRGB, srcAlpha, dstAlpha);
}

WebGLBuffer *WebGLRenderingContext::ValidateBufferDataTarget(
    const char *function_name, GLenum target) {
  WebGLBuffer *buffer = nullptr;
  switch (target) {
    case KR_GL_ARRAY_BUFFER:
      buffer = local_cache_.array_buffer_bind_;
      break;
    case KR_GL_ELEMENT_ARRAY_BUFFER:
      buffer = local_cache_.ValidVertexArrayObject()->BoundElementArrayBuffer();
      break;
    case KR_GL_COPY_READ_BUFFER:
    case KR_GL_COPY_WRITE_BUFFER:
    case KR_GL_TRANSFORM_FEEDBACK_BUFFER:
    case KR_GL_UNIFORM_BUFFER:
    case KR_GL_PIXEL_PACK_BUFFER:
    case KR_GL_PIXEL_UNPACK_BUFFER:
    default:
      SynthesizeGLError(GL_INVALID_ENUM, function_name, "invalid target");
      return nullptr;
  }
  if (!buffer) {
    SynthesizeGLError(GL_INVALID_OPERATION, function_name, "no buffer");
    return nullptr;
  }
  return buffer;
}

void WebGLRenderingContext::BufferData(GLenum target, int64_t size,
                                       GLenum usage) {
  DCHECK(Recorder());

  WebGLBuffer *buffer = ValidateBufferDataTarget("BufferData", target);
  if (!buffer) {
    return;
  }

  if (usage != KR_GL_STATIC_DRAW && usage != KR_GL_DYNAMIC_DRAW &&
      usage != KR_GL_STREAM_DRAW) {
    if (usage != KR_GL_STATIC_COPY && usage != KR_GL_DYNAMIC_COPY &&
        usage != KR_GL_STREAM_COPY && usage != KR_GL_STATIC_READ &&
        usage != KR_GL_DYNAMIC_READ && usage != KR_GL_STREAM_READ) {
      SynthesizeGLError(GL_INVALID_ENUM, "BufferData", "invalid usage");
      return;
    }
  }

  if (!ValidateValueFitNonNegInt32("bufferData", "size", size)) {
    return;
  }

  // save cache
  buffer->size_ = size;
  buffer->usage_ = usage;

  // commit command
  class Runnable {
   public:
    Runnable(uint32_t target, uint32_t size, uint32_t usage)
        : target_(target), size_(size), usage_(usage) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      std::unique_ptr<char[]> zero(new char[size_]);
      memset(zero.get(), 0, size_);
      GL::BufferData(target_, (intptr_t)size_, zero.get(), usage_);
    }

   private:
    uint32_t target_, size_, usage_;
  };
  Recorder()->Alloc<Runnable>(target, static_cast<uint32_t>(size), usage);
}

void WebGLRenderingContext::BufferData(GLenum target, ArrayBufferView data,
                                       GLenum usage) {
  if (data.IsEmpty()) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "bufferData", "invalid data");
    return;
  }

  BufferData(target, data.Data(), data.ByteLength(), usage);
}

void WebGLRenderingContext::BufferData(GLenum target, ArrayBuffer data,
                                       GLenum usage) {
  if (data.IsNull() || data.IsUndefined()) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "bufferData", "invalid data");
    return;
  }

  BufferData(target, data.Data(), data.ByteLength(), usage);
}

void WebGLRenderingContext::BufferData(GLenum target, void *data, uint32_t size,
                                       GLenum usage) {
  DCHECK(Recorder());

  WebGLBuffer *buffer = ValidateBufferDataTarget("BufferData", target);
  if (!buffer) {
    return;
  }

  if (usage != KR_GL_STATIC_DRAW && usage != KR_GL_DYNAMIC_DRAW &&
      usage != KR_GL_STREAM_DRAW) {
    if (usage != KR_GL_STATIC_COPY && usage != KR_GL_DYNAMIC_COPY &&
        usage != KR_GL_STREAM_COPY && usage != KR_GL_STATIC_READ &&
        usage != KR_GL_DYNAMIC_READ && usage != KR_GL_STREAM_READ) {
      SynthesizeGLError(GL_INVALID_ENUM, "BufferData", "invalid usage");
      return;
    }
  }

  if (size <= 0) {
    return;
  }

  buffer->size_ = size;
  buffer->usage_ = usage;

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::BufferData(target_, (intptr_t)size_, data_, usage_);
      std::free(data_);
    }
    uint32_t target_, size_, usage_;
    void *data_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->size_ = static_cast<uint32_t>(size);
  cmd->usage_ = usage;
  cmd->data_ = std::malloc(size);
  memcpy(cmd->data_, data, size);
}

void WebGLRenderingContext::BufferSubData(GLenum target, int64_t offset,
                                          ArrayBufferView data) {
  DCHECK(!data.IsEmpty());
  BufferSubData(target, offset, data.Data(), data.ByteLength());
}

void WebGLRenderingContext::BufferSubData(GLenum target, int64_t offset,
                                          ArrayBuffer data) {
  DCHECK(!data.IsNull());
  BufferSubData(target, offset, data.Data(), data.ByteLength());
}

void WebGLRenderingContext::BufferSubData(GLenum target, int64_t offset,
                                          void *data, uint32_t size) {
  DCHECK(Recorder());

  // TODO(yuyifei): Check this for command buffer.
  // int64_t offset_ = 0;
  // if (!std::isinf(offset.As<Napi::Number>().DoubleValue())) {
  //   offset_ = offset.Int64Value();
  // }
  if (!ValidateValueFitNonNegInt32("bufferSubData", "offset", offset)) {
    return;
  }

  WebGLBuffer *buffer = nullptr;
  switch (target) {
    case KR_GL_ARRAY_BUFFER:
      buffer = local_cache_.array_buffer_bind_;
      break;
    case KR_GL_ELEMENT_ARRAY_BUFFER:
      buffer = local_cache_.ValidVertexArrayObject()->BoundElementArrayBuffer();
      break;
    case KR_GL_COPY_READ_BUFFER:
      buffer = local_cache_.copy_read_buffer_bind_;
      break;
    case KR_GL_COPY_WRITE_BUFFER:
      buffer = local_cache_.copy_write_buffer_bind_;
      break;
    case KR_GL_TRANSFORM_FEEDBACK_BUFFER:
      buffer = local_cache_.tf_buffer_bind_;
      break;
    case KR_GL_UNIFORM_BUFFER:
      buffer = local_cache_.ub_buffer_bind_;
      break;
    case KR_GL_PIXEL_PACK_BUFFER:
      buffer = local_cache_.pixel_pack_buffer_bind_;
      break;
    case KR_GL_PIXEL_UNPACK_BUFFER:
      buffer = local_cache_.pixel_unpack_buffer_bind_;
      break;
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "bufferSubData", "invalid target");
      return;
  }

  if (!buffer) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, "bufferSubData",
                      "no buffer bound.");
    return;
  }

  if (size <= 0) {
    return;
  }
  if (offset + static_cast<int64_t>(size) > buffer->size_) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "bufferSubData", "invalid buffer.");
    return;
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::BufferSubData(target_, (intptr_t)offset_, (intptr_t)size_, data_);
      std::free(data_);
    }
    uint32_t target_, offset_, size_;
    void *data_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->offset_ = static_cast<uint32_t>(offset);
  cmd->size_ = static_cast<uint32_t>(size);
  cmd->data_ = std::malloc(size);
  memcpy(cmd->data_, data, size);
}

/*
 * Reviewed by xieguo, 6/7/2021
 */
GLenum WebGLRenderingContext::CheckFramebufferStatus(GLenum target) {
  DCHECK(Recorder());

  // logic check
  if (target != KR_GL_FRAMEBUFFER) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "checkFramebufferStatus",
                      "invalid target");
    return 0;
  }

  if (local_cache_.read_framebuffer_bind_) {
    GLenum completeness =
        local_cache_.read_framebuffer_bind_->IsPossiblyComplete();
    if (completeness != GL_FRAMEBUFFER_COMPLETE) {
      return completeness;
    }
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      *result_ = GL::CheckFramebufferStatus(target_);
    }
    GLenum target_;
    GLenum *result_ = nullptr;
  };

  GLenum result = 0;
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->result_ = &result;
  Present(true);
  return result;
}

void WebGLRenderingContext::Clear(GLbitfield mask) {
  if (mask & ~(KR_GL_COLOR_BUFFER_BIT | KR_GL_DEPTH_BUFFER_BIT |
               KR_GL_STENCIL_BUFFER_BIT)) {
    SynthesizeGLError(GL_INVALID_VALUE, "clear", "invalid mask");
    return;
  }

  class Runnable {
   public:
    explicit Runnable(uint32_t mask) : mask_(mask) {}
    void Run(command_buffer::RunnableBuffer *buffer) const { GL::Clear(mask_); }

   private:
    uint32_t mask_;
  };
  Recorder()->Alloc<Runnable>(mask);

  DidDraw();
}

void WebGLRenderingContext::ClearColor(GLclampf red, GLclampf green,
                                       GLclampf blue, GLclampf alpha) {
  GLclampf clear_color_[4] = {red, green, blue, alpha};
  for (int i = 0; i < 4; ++i) {
    local_cache_.clear_color_[i] = clear_color_[i];
  }

  class Runnable {
   public:
    Runnable(GLclampf r, GLclampf g, GLclampf b, GLclampf a)
        : r_(r), g_(g), b_(b), a_(a) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::ClearColor(r_, g_, b_, a_);
    }

   private:
    GLclampf r_;
    GLclampf g_;
    GLclampf b_;
    GLclampf a_;
  };
  Recorder()->Alloc<Runnable>(clear_color_[0], clear_color_[1], clear_color_[2],
                              clear_color_[3]);
}

void WebGLRenderingContext::ClearDepth(GLclampf depth) {
  DCHECK(Recorder());
  local_cache_.clear_depth_ = depth;
  // commit command
  class Runnable {
   public:
    Runnable(GLclampf depth) : depth_(depth) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::ClearDepthf(depth_);
    }

   private:
    GLclampf depth_;
  };
  Recorder()->Alloc<Runnable>(depth);
}

void WebGLRenderingContext::ClearStencil(GLint stencil) {
  DCHECK(Recorder());

  local_cache_.clear_stencil_ = stencil;

  // commit command
  class Runnable {
   public:
    explicit Runnable(GLint stencil) : stencil_(stencil) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::ClearStencil(stencil_);
    }

   private:
    GLint stencil_;
  };

  Recorder()->Alloc<Runnable>(stencil);
}

void WebGLRenderingContext::ColorMask(GLboolean red, GLboolean green,
                                      GLboolean blue, GLboolean alpha) {
  DCHECK(Recorder());

  // save cache
  GLboolean mask_[4] = {red, green, blue, alpha};
  for (int i = 0; i < 4; ++i) {
    local_cache_.color_write_mask_[i] = mask_[i];
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLboolean r, GLboolean g, GLboolean b, GLboolean a)
        : r_(r), g_(g), b_(b), a_(a) {}
    void Run(command_buffer::RunnableBuffer *buffer) {
      GL::ColorMask(r_, g_, b_, a_);
    }

   private:
    GLboolean r_, g_, b_, a_;
  };
  Recorder()->Alloc<Runnable>(
      local_cache_.color_write_mask_[0], local_cache_.color_write_mask_[1],
      local_cache_.color_write_mask_[2], local_cache_.color_write_mask_[3]);
}

void WebGLRenderingContext::CompressedTexImage2D(GLenum target, GLint level,
                                                 GLenum internalformat,
                                                 GLsizei width, GLsizei height,
                                                 GLint border,
                                                 ArrayBufferView data) {
  DCHECK(Recorder());
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (target != KR_GL_TEXTURE_2D &&
        target != KR_GL_TEXTURE_CUBE_MAP_POSITIVE_X &&
        target != KR_GL_TEXTURE_CUBE_MAP_POSITIVE_Y &&
        target != KR_GL_TEXTURE_CUBE_MAP_POSITIVE_Z &&
        target != KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_X &&
        target != KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_Y &&
        target != KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_Z) {
      SynthesizeGLError(KR_GL_INVALID_ENUM, "CompressedTexImage2D",
                        "invalid target");
      return;
    }
    if (level < 0 || width < 0 || height < 0) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "CompressedTexImage2D",
                        "invalid size");
      return;
    }

    if (border != 0) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "CompressedTexImage2D",
                        "non 0 border");
      return;
    }

    WebGLTexture *texture = nullptr;
    auto _index = local_cache_.active_texture_ - KR_GL_TEXTURE0;
    if (target == KR_GL_TEXTURE_2D) {
      texture = local_cache_.texture_2d_bind_[_index];
    } else {
      texture = local_cache_.texture_cube_bind_[_index];
    }

    if (!texture) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "CompressedTexImage2D",
                        "has no tex bound.");
      return;
    }
    texture->internal_format_ = internalformat;

    if (data.ByteLength() <= 0) {
      return;
    }
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *) const {
      GL::CompressedTexImage2D(target_, level_, internalformat_, width_,
                               height_, 0, image_size_, data_.data());
    }
    uint32_t target_, internalformat_;
    int32_t level_, width_, height_, image_size_;
    std::string data_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->internalformat_ = internalformat;
  cmd->level_ = level;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->image_size_ = static_cast<uint32_t>(data.ByteLength());
  cmd->data_.append((const char *)data.Data(), (size_t)data.ByteLength());
}

void WebGLRenderingContext::CompressedTexSubImage2D(
    GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width,
    GLsizei height, GLenum format, ArrayBufferView data) {
  DCHECK(Recorder());
  auto array_buffer = data.ArrayBuffer();
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (target != KR_GL_TEXTURE_2D &&
        target != KR_GL_TEXTURE_CUBE_MAP_POSITIVE_X &&
        target != KR_GL_TEXTURE_CUBE_MAP_POSITIVE_Y &&
        target != KR_GL_TEXTURE_CUBE_MAP_POSITIVE_Z &&
        target != KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_X &&
        target != KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_Y &&
        target != KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_Z) {
      SynthesizeGLError(KR_GL_INVALID_ENUM, "CompressedTexSubImage2D",
                        "invalid target");
      return;
    }

    if (level < 0 || xoffset < 0 || yoffset < 0 || width < 0 || height < 0) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "CompressedTexSubImage2D",
                        "invalid size");
      return;
    }

    if (array_buffer.ByteLength() <= 0) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "CompressedTexSubImage2D",
                        "invalid data");
      return;
    }
  }

  struct Runnable {
    void Run(command_buffer::RunnableBuffer *) const {
      GL::CompressedTexSubImage2D(
          target_, level_, xoffset_, yoffset_, width_, height_, format_,
          static_cast<GLsizei>(data_.size()), (void *)data_.data());
    }
    uint32_t target_, format_;
    int32_t level_, xoffset_, yoffset_, width_, height_;
    std::vector<uint8_t> data_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->level_ = level;
  cmd->xoffset_ = xoffset;
  cmd->yoffset_ = yoffset;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->format_ = format;
  cmd->data_.resize(array_buffer.ByteLength());
  memcpy((void *)(&cmd->data_[0]), (void *)(array_buffer.Data()),
         array_buffer.ByteLength());
}

GLint WebGLRenderingContext::MaxLevelsForTarget(GLenum target) const {
  switch (target) {
    case KR_GL_TEXTURE_2D:
    case KR_GL_TEXTURE_2D_ARRAY:
      return device_attributes_.max_levels_from_2d_size_;
    case KR_GL_TEXTURE_3D:
      return device_attributes_.max_levels_from_3d_size_;
    default:
      return 1;
  }
}

// Return true if value is neither a power of two nor zero.
static bool IsNPOT(uint32_t value) { return (value & (value - 1)) != 0; }

bool WebGLRenderingContext::ValidForTarget(GLenum target, GLint level,
                                           GLsizei width, GLsizei height,
                                           GLsizei depth) {
  if (level < 0 || level >= MaxLevelsForTarget(target)) return false;
  GLsizei max_size = MaxSizeForTarget(target) >> level;
  GLsizei max_depth = (target == GL_TEXTURE_2D_ARRAY
                           ? device_attributes_.max_array_texture_layers_
                           : max_size);
  return width >= 0 && height >= 0 && depth >= 0 && width <= max_size &&
         height <= max_size && depth <= max_depth &&
         (level == 0 ||
          (!IsNPOT(width) && !IsNPOT(height) && !IsNPOT(depth))) &&
         (target != GL_TEXTURE_CUBE_MAP || (width == height && depth == 1)) &&
         (target != GL_TEXTURE_2D || (depth == 1));
}

void WebGLRenderingContext::CopyTexImage2D(GLenum target, GLint level,
                                           GLenum internalformat, GLint x,
                                           GLint y, GLsizei width,
                                           GLsizei height, GLint border) {
  DCHECK(Recorder());

  auto raw_texture = ValidateTexture2DBinding("copyTexImage2D", target);
  if (!raw_texture) return;

  if (!ValidForTarget(target, level, width, height, 1) || border != 0) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "copyTexImage2d",
                      "dimensions out of range");
    return;
  }

  if (internalformat != KR_GL_ALPHA && internalformat != KR_GL_LUMINANCE &&
      internalformat != KR_GL_LUMINANCE_ALPHA && internalformat != KR_GL_RGB &&
      internalformat != KR_GL_RGBA && internalformat != KR_GL_R8 &&
      internalformat != KR_GL_RG8 && internalformat != KR_GL_RGB565 &&
      internalformat != KR_GL_RGB8 && internalformat != KR_GL_RGBA4 &&
      internalformat != KR_GL_RGB5_A1 && internalformat != KR_GL_RGBA8 &&
      internalformat != KR_GL_RGB10_A2 && internalformat != KR_GL_SRGB8 &&
      internalformat != KR_GL_SRGB8_ALPHA8 && internalformat != KR_GL_R8I &&
      internalformat != KR_GL_R8UI && internalformat != KR_GL_R16I &&
      internalformat != KR_GL_R16UI && internalformat != KR_GL_R32I &&
      internalformat != KR_GL_R32UI && internalformat != KR_GL_RG8I &&
      internalformat != KR_GL_RG8UI && internalformat != KR_GL_RG16I &&
      internalformat != KR_GL_RG16UI && internalformat != KR_GL_RG32I &&
      internalformat != KR_GL_RG32UI && internalformat != KR_GL_RGBA8I &&
      internalformat != KR_GL_RGBA8UI && internalformat != KR_GL_RGB10_A2UI &&
      internalformat != KR_GL_RGBA16I && internalformat != KR_GL_RGBA16UI &&
      internalformat != KR_GL_RGBA32I && internalformat != KR_GL_RGBA32UI) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "copyTexImage2d",
                      "invalidd internelformat");
    return;
  }

  uint32_t read_format = GetBoundReadFramebufferInternalFormat();
  if (read_format == 0) {
    SynthesizeGLError(GL_INVALID_OPERATION, "copyTexImage2d",
                      "no valid color image");
    return;
  }

  // CheckBoundReadFramebufferValid
  if (local_cache_.read_framebuffer_bind_) {
    GLenum completeness =
        local_cache_.read_framebuffer_bind_->IsPossiblyComplete();
    if (completeness != GL_FRAMEBUFFER_COMPLETE) {
      SynthesizeGLError(GL_INVALID_FRAMEBUFFER_OPERATION, "copyTexImage2d",
                        "bound read framebuffer incomplete");
      return;
    }
  }

  uint32_t channels_exist = GetChannelsForFormat(read_format);
  uint32_t channels_needed = GetChannelsForFormat(internalformat);
  if (!channels_needed ||
      (channels_needed & channels_exist) != channels_needed) {
    SynthesizeGLError(GL_INVALID_OPERATION, "copyTexImage2d",
                      "incompatible format");
    return;
  }

  uint32_t read_type = GetBoundReadFramebufferTextureType();
  GLenum format;
  PollifyOESTextureFloat(internalformat, format, read_type);

  // commit command
  class Runnable {
   public:
    Runnable(uint32_t target, int32_t level, uint32_t internalformat, int32_t x,
             int32_t y, uint32_t width, uint32_t height)
        : target_(target),
          level_(level),
          internalformat_(internalformat),
          x_(x),
          y_(y),
          width_(width),
          height_(height) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::CopyTexImage2D(target_, level_, internalformat_, x_, y_, width_,
                         height_, 0);
    }

   private:
    GLenum target_;
    GLint level_;
    GLenum internalformat_;
    GLint x_, y_;
    GLsizei width_, height_;
  };

  Recorder()->Alloc<Runnable>(target, level, internalformat, x, y, width,
                              height);
}

void WebGLRenderingContext::CopyTexSubImage2D(GLenum target, GLint level,
                                              GLint xoffset, GLint yoffset,
                                              GLint x, GLint y, GLsizei width,
                                              GLsizei height) {
  DCHECK(Recorder());

  auto raw_texture = ValidateTexture2DBinding("CopyTexSubImage2D", target);
  if (!raw_texture) return;

  if (level < 0 || level > std::log2(device_attributes_.max_texture_size_)) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "CopyTexSubImage2D",
                      "invalid level");
    return;
  }

  if (width > device_attributes_.max_texture_size_ || width < 0 ||
      height > device_attributes_.max_texture_size_ || height < 0) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "CopyTexSubImage2D", "invalid size");
    return;
  }

  // commit command
  class Runnable {
   public:
    Runnable(uint32_t target, int32_t level, int32_t xoffset, int32_t yoffset,
             int32_t x, int32_t y, uint32_t width, uint32_t height)
        : target_(target),
          level_(level),
          xoffset_(xoffset),
          yoffset_(yoffset),
          x_(x),
          y_(y),
          width_(width),
          height_(height) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::CopyTexSubImage2D(target_, level_, xoffset_, yoffset_, x_, y_, width_,
                            height_);
    }

   private:
    GLenum target_;
    GLint level_;
    GLint xoffset_, yoffset_;
    GLint x_, y_;
    GLsizei width_, height_;
  };
  Recorder()->Alloc<Runnable>(target, level, xoffset, yoffset, x, y, width,
                              height);
}

void WebGLRenderingContext::CullFace(GLenum mode) {
  DCHECK(Recorder());
  // validate face enumeration
  if (!ValidateFaceEnum("CullFace", mode)) {
    return;
  }

  // save cache
  local_cache_.cull_face_mode_ = mode;

  // commit command
  class Runnable {
   public:
    explicit Runnable(GLenum mode) : mode_(mode) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::CullFace(mode_);
    }

   private:
    GLenum mode_;
  };
  Recorder()->Alloc<Runnable>(mode);
}

WebGLBuffer *WebGLRenderingContext::CreateBuffer() {
  DCHECK(Recorder());
  return new WebGLBuffer(this);
}

/*
 * Reviewed by xieguo, 6/7/2021
 */
WebGLFramebuffer *WebGLRenderingContext::CreateFramebuffer() {
  DCHECK(Recorder());

  // create obj
  auto framebuffer_obj = new WebGLFramebuffer(this);
  framebuffer_obj->setGlobalAttributes(device_attributes_);

  return framebuffer_obj;
}

WebGLRenderbuffer *WebGLRenderingContext::CreateRenderbuffer() {
  DCHECK(Recorder());
  return new WebGLRenderbuffer(this);
}

WebGLTexture *WebGLRenderingContext::CreateTexture() {
  DCHECK(Recorder());

  // create obj
  auto texture_obj = new WebGLTexture(this);
  return texture_obj;
}

void WebGLRenderingContext::DeleteBuffer(WebGLBuffer *buffer) {
  DCHECK(Recorder());

  if (!DeleteObject(buffer)) {
    return;
  }

  // webgl 1
  if (local_cache_.array_buffer_bind_ == buffer) {
    local_cache_.array_buffer_bind_ = nullptr;
  }

  // vao may bound buffer
  if (buffer->HasObject()) {
    local_cache_.ValidVertexArrayObject()->UnbindBuffer(buffer);
  }
}

/*
 * Reviewed by xieguo, 6/26/2021
 */
void WebGLRenderingContext::DeleteFramebuffer(WebGLFramebuffer *framebuffer) {
  DCHECK(Recorder());

  if (!DeleteObject(framebuffer)) {
    return;
  }

  bool need_default_read_framebuffer = false;
  bool need_default_draw_framebuffer = false;

  if (framebuffer == local_cache_.read_framebuffer_bind_) {
    local_cache_.read_framebuffer_bind_ = nullptr;
    need_default_read_framebuffer = true;
  }
  if (framebuffer == local_cache_.draw_framebuffer_bind_) {
    local_cache_.draw_framebuffer_bind_ = nullptr;
    need_default_draw_framebuffer = true;
  }

  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      if (need_default_read_framebuffer_) {
        GL::BindFramebuffer(KR_GL_READ_FRAMEBUFFER, reading_fbo_);
      }
      if (need_default_draw_framebuffer_) {
        GL::BindFramebuffer(KR_GL_DRAW_FRAMEBUFFER, drawing_fbo_);
      }
    }
    bool need_default_read_framebuffer_;
    bool need_default_draw_framebuffer_;
    GLuint reading_fbo_;
    GLuint drawing_fbo_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->need_default_read_framebuffer_ = need_default_read_framebuffer;
  cmd->need_default_draw_framebuffer_ = need_default_draw_framebuffer;
  cmd->reading_fbo_ = std::static_pointer_cast<CanvasResourceProvider3D>(
                          element_->ResourceProvider())
                          ->reading_fbo();
  cmd->drawing_fbo_ = std::static_pointer_cast<CanvasResourceProvider3D>(
                          element_->ResourceProvider())
                          ->drawing_fbo();
}

void WebGLRenderingContext::DeleteRenderbuffer(
    WebGLRenderbuffer *renderbuffer) {
  DCHECK(Recorder());

  if (!DeleteObject(renderbuffer)) {
    return;
  }

  if (local_cache_.renderbuffer_bind_ == renderbuffer) {
    local_cache_.renderbuffer_bind_ = nullptr;
  }

  if (local_cache_.read_framebuffer_bind_)
    local_cache_.read_framebuffer_bind_->DetachRenderbuffer(
        KR_GL_READ_FRAMEBUFFER, renderbuffer);
  if (local_cache_.draw_framebuffer_bind_)
    local_cache_.draw_framebuffer_bind_->DetachRenderbuffer(
        KR_GL_DRAW_FRAMEBUFFER, renderbuffer);
}

void WebGLRenderingContext::DeleteTexture(WebGLTexture *texture) {
  DCHECK(Recorder());

  if (!DeleteObject(texture)) return;

  int max_bound_texture_index = -1;
  for (uint32_t i = 0; i < local_cache_.one_plus_max_non_default_texture_unit_;
       ++i) {
    if (texture == local_cache_.texture_2d_bind_[i]) {
      local_cache_.texture_2d_bind_[i] = nullptr;
      max_bound_texture_index = i;
    }
    if (texture == local_cache_.texture_cube_bind_[i]) {
      local_cache_.texture_cube_bind_[i] = nullptr;
      max_bound_texture_index = i;
    }
    if (texture == local_cache_.texture_3d_bind_[i]) {
      local_cache_.texture_3d_bind_[i] = nullptr;
      max_bound_texture_index = i;
    }
    if (texture == local_cache_.texture_2d_array_bind_[i]) {
      local_cache_.texture_2d_array_bind_[i] = nullptr;
      max_bound_texture_index = i;
    }
  }

  if (local_cache_.read_framebuffer_bind_)
    local_cache_.read_framebuffer_bind_->DetachTexture(KR_GL_READ_FRAMEBUFFER,
                                                       texture);
  if (local_cache_.draw_framebuffer_bind_)
    local_cache_.draw_framebuffer_bind_->DetachTexture(KR_GL_DRAW_FRAMEBUFFER,
                                                       texture);

  if (local_cache_.one_plus_max_non_default_texture_unit_ ==
      static_cast<uint32_t>(max_bound_texture_index + 1)) {
    FindNewMaxNonDefaultTextureUnit();
  }
}

void WebGLRenderingContext::DepthFunc(GLenum func) {
  DCHECK(Recorder());
  if (!ValidateStencilFuncEnum("DepthFunc", func)) {
    return;
  }
  local_cache_.depth_func_ = func;
  // commit command
  class Runnable {
   public:
    Runnable(GLenum func) : func_(func) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::DepthFunc(func_);
    }

   private:
    GLenum func_;
  };
  Recorder()->Alloc<Runnable>(func);
}

void WebGLRenderingContext::DepthMask(GLboolean flag) {
  DCHECK(Recorder());
  local_cache_.depth_writemask_ = flag;
  // commit command
  class Runnable {
   public:
    Runnable(GLboolean flag) : flag_(flag) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::DepthMask(flag_);
    }

   private:
    GLboolean flag_;
  };

  Recorder()->Alloc<Runnable>(flag);
}

void WebGLRenderingContext::DepthRange(GLfloat zNear, GLfloat zFar) {
  if (zNear > zFar) {
    SynthesizeGLError(GL_INVALID_OPERATION, "depthRange",
                      "depthRange: zNear > zFar");
    return;
  }

  GLfloat z_near_clamped = std::max(std::min(zNear, 1.0f), 0.0f);
  GLfloat z_far_clamped = std::max(std::min(zFar, 1.0f), 0.0f);

  // commit command
  device_attributes_.depth_range_[0] = z_near_clamped;
  device_attributes_.depth_range_[1] = z_far_clamped;
  class Runnable {
   public:
    Runnable(GLfloat zNear, GLfloat zFar) : zNear_(zNear), zFar_(zFar) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::DepthRangef(zNear_, zFar_);
    }

   private:
    GLfloat zNear_;
    GLfloat zFar_;
  };

  Recorder()->Alloc<Runnable>(z_near_clamped, z_far_clamped);
}

void WebGLRenderingContext::Disable(GLenum cap) {
  DCHECK(Recorder());

  switch (cap) {
    case KR_GL_BLEND:
      local_cache_.enable_blend_ = false;
      break;
    case KR_GL_CULL_FACE:
      local_cache_.enable_cull_face_ = false;
      break;
    case KR_GL_DEPTH_TEST:
      local_cache_.enable_depth_test_ = false;
      break;
    case KR_GL_DITHER:
      local_cache_.enable_dither_ = false;
      break;
    case KR_GL_POLYGON_OFFSET_FILL:
      local_cache_.enable_polygon_offset_fill_ = false;
      break;
    case KR_GL_SAMPLE_ALPHA_TO_COVERAGE:
      local_cache_.enable_sample_alpha_to_coverage_ = false;
      break;
    case KR_GL_SAMPLE_COVERAGE:
      local_cache_.enable_coverage_ = false;
      break;
    case KR_GL_SCISSOR_TEST:
      local_cache_.enable_scissor_test_ = false;
      break;
    case KR_GL_STENCIL_TEST:
      local_cache_.enable_stencil_test_ = false;
      break;
    case KR_GL_RASTERIZER_DISCARD:
      local_cache_.enable_rasterizer_discard = false;
      break;
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "disable", "invalid cap");
      return;
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLenum cap) : cap_(cap) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Disable(cap_);
    }

   private:
    GLenum cap_;
  };
  Recorder()->Alloc<Runnable>(cap);
}

void WebGLRenderingContext::DrawArrays(GLenum mode, GLint first,
                                       GLsizei count) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (mode != KR_GL_TRIANGLES && mode != KR_GL_TRIANGLE_STRIP &&
        mode != KR_GL_TRIANGLE_FAN && mode != KR_GL_LINES &&
        mode != KR_GL_LINE_STRIP && mode != KR_GL_LINE_LOOP &&
        mode != KR_GL_POINTS) {
      SynthesizeGLError(KR_GL_INVALID_ENUM, "drawArrays", "invalid mode");
      return;
    }
    if (first < 0 || count < 0) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "drawArrays",
                        "invalid first or count");
      return;
    }

    if (!local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawArrays", "invalid state");
      return;
    }

    if (!CheckAttrBeforeDraw()) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawArrays", "invalid state");
      return;
    }

    if (!local_cache_.ValidVertexArrayObject()
             ->IsAllEnabledAttribBufferBound()) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawArrays", "invalid state");
      return;
    }

    if (!local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawArrays", "invalid state");
      return;
    }
  }

  DCHECK(Recorder());

  // commit command
  class Runnable {
   public:
    Runnable(GLenum mode, GLint first, GLsizei count)
        : mode_(mode), first_(first), count_(count) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::DrawArrays(mode_, first_, count_);
    }

   private:
    GLenum mode_;
    GLint first_;
    GLsizei count_;
  };
  Recorder()->Alloc<Runnable>(mode, first, count);

  DidDraw();
}

void WebGLRenderingContext::DrawElements(GLenum mode, GLsizei count,
                                         GLenum type, int64_t offset) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (mode != KR_GL_TRIANGLES && mode != KR_GL_TRIANGLE_STRIP &&
        mode != KR_GL_TRIANGLE_FAN && mode != KR_GL_LINES &&
        mode != KR_GL_LINE_STRIP && mode != KR_GL_LINE_LOOP &&
        mode != KR_GL_POINTS) {
      SynthesizeGLError(KR_GL_INVALID_ENUM, "drawElements", "invalid mode");
      return;
    }

    if (count < 0 || offset < 0) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "drawElements",
                        "invalid count or offset");
      return;
    }

    if (!ValidateValueFitNonNegInt32("DrawElements", "offset", offset)) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "drawElements", "invalid  offset");
      return;
    }

    if (!CheckAttrBeforeDraw()) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawElements",
                        "invalid state");
      return;
    }

    if (!local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawElements",
                        "invalid state");
      return;
    }
  }

  const auto &vao = local_cache_.ValidVertexArrayObject();
  const auto &ebo = vao->BoundElementArrayBuffer();
  if (!ebo || !vao->IsAllEnabledAttribBufferBound()) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawElements", "invalid state");
    return;
  }

  int size_in_byte = 0;
  switch (type) {
    case KR_GL_UNSIGNED_BYTE:
      size_in_byte = 1;
      break;
    case KR_GL_UNSIGNED_SHORT:
      size_in_byte = 2;
      break;
    case KR_GL_UNSIGNED_INT:
      size_in_byte = 4;
      break;
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "drawElements", "invalid type");
      return;
  }

  if (size_in_byte * count + offset > ebo->size_ ||
      offset % size_in_byte != 0) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawElements", "invalid state");
    return;
  }

  DCHECK(Recorder());
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      auto indices = (void *)((char *)(nullptr) + offset_);
      GL::DrawElements(mode_, count_, type_, indices);
    }

    GLenum mode_;
    GLenum type_;
    GLsizei count_;
    int32_t offset_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->mode_ = mode;
  cmd->type_ = type;
  cmd->count_ = count;
  cmd->offset_ = static_cast<int32_t>(offset);

  DidDraw();
}

void WebGLRenderingContext::Enable(GLenum cap) {
  DCHECK(Recorder());

  switch (cap) {
    case KR_GL_BLEND:
      local_cache_.enable_blend_ = true;
      break;
    case KR_GL_CULL_FACE:
      local_cache_.enable_cull_face_ = true;
      break;
    case KR_GL_DEPTH_TEST:
      local_cache_.enable_depth_test_ = true;
      break;
    case KR_GL_DITHER:
      local_cache_.enable_dither_ = true;
      break;
    case KR_GL_POLYGON_OFFSET_FILL:
      local_cache_.enable_polygon_offset_fill_ = true;
      break;
    case KR_GL_SAMPLE_ALPHA_TO_COVERAGE:
      local_cache_.enable_sample_alpha_to_coverage_ = true;
      break;
    case KR_GL_SAMPLE_COVERAGE:
      local_cache_.enable_coverage_ = true;
      break;
    case KR_GL_SCISSOR_TEST:
      local_cache_.enable_scissor_test_ = true;
      break;
    case KR_GL_STENCIL_TEST:
      local_cache_.enable_stencil_test_ = true;
      break;
    case KR_GL_RASTERIZER_DISCARD:
      local_cache_.enable_rasterizer_discard = true;
      break;
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "Enable", "invalid cap");
      return;
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLenum cap) : cap_(cap) {}
    void Run(command_buffer::RunnableBuffer *buffer) const { GL::Enable(cap_); }

   private:
    GLenum cap_;
  };
  Recorder()->Alloc<Runnable>(cap);
}

void WebGLRenderingContext::Finish() {
  DCHECK(Recorder());

  // commit command
  class Runnable {
   public:
    void Run(command_buffer::RunnableBuffer *buffer) { GL::Finish(); }
  };
  Recorder()->Alloc<Runnable>();
  Present(true);
}

void WebGLRenderingContext::Flush() {
  DCHECK(Recorder());

  // commit command
  struct Runnable {
    static void Run(command_buffer::RunnableBuffer *buffer) { GL::Flush(); }
  };
  Recorder()->Alloc<Runnable>();

  DidDraw();
}

/*
 * Reviewed by xieguo, 06/26/2021
 */
void WebGLRenderingContext::FramebufferRenderbuffer(
    GLenum target, GLenum attachment, GLenum renderbuffertarget,
    WebGLRenderbuffer *renderbuffer) {
  DCHECK(Recorder());

  // logic check
  if (target != KR_GL_FRAMEBUFFER) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "FramebufferRenderbuffer",
                      "invalid target");
    return;
  }

  auto framebuffer = ValidateFramebufferBinding(target);
  if (!framebuffer) return;

  // never bound
  if (renderbuffer && (!renderbuffer->HasEverBeenBound())) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, "FramebufferRenderbuffer",
                      "invalid renderbuffer");
    return;
  }

  if (attachment != KR_GL_COLOR_ATTACHMENT0 &&
      attachment != KR_GL_DEPTH_ATTACHMENT &&
      attachment != KR_GL_DEPTH_STENCIL_ATTACHMENT &&
      attachment != KR_GL_STENCIL_ATTACHMENT) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "FramebufferRenderbuffer",
                      "invalid attachment");
    return;
  }

  if (renderbuffertarget != KR_GL_RENDERBUFFER) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "FramebufferRenderbuffer",
                      "invalid renderbuffer target");
    return;
  }

  // save cache
  PuppetContent<uint32_t> *content =
      !renderbuffer ? nullptr : renderbuffer->related_id_.Get();
  framebuffer->AttachAttachment(attachment, renderbuffer);

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      if (!content_) {
        GL::FramebufferRenderbuffer(target_, attachment_, renderbuffer_target_,
                                    0);
      } else {
        auto renderbuffer = content_->Get();
        GL::FramebufferRenderbuffer(target_, attachment_, renderbuffer_target_,
                                    renderbuffer);
      }
    }
    GLenum target_, attachment_, renderbuffer_target_;
    PuppetContent<uint32_t> *content_ = nullptr;
  };

  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->attachment_ = attachment;
  cmd->renderbuffer_target_ = renderbuffertarget;
  cmd->content_ = content;
}

/*
 *  Reviewed by xieguo, 6/7/2021
 */
void WebGLRenderingContext::FramebufferTexture2D(GLenum target,
                                                 GLenum attachment,
                                                 GLenum textarget,
                                                 WebGLTexture *texture,
                                                 GLint level) {
  DCHECK(Recorder());

  auto framebuffer = ValidateFramebufferBinding(target);
  if (!framebuffer) return;

  if (attachment != KR_GL_COLOR_ATTACHMENT0 &&
      attachment != KR_GL_DEPTH_ATTACHMENT &&
      attachment != KR_GL_STENCIL_ATTACHMENT) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "FramebufferTexture2D",
                      "invalid attachment");
    return;
  }

  if (textarget != KR_GL_TEXTURE_2D &&
      textarget != KR_GL_TEXTURE_CUBE_MAP_POSITIVE_X &&
      textarget != KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_X &&
      textarget != KR_GL_TEXTURE_CUBE_MAP_POSITIVE_Y &&
      textarget != KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_Y &&
      textarget != KR_GL_TEXTURE_CUBE_MAP_POSITIVE_Z &&
      textarget != KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_Z) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "FramebufferTexture2D",
                      "invalid tex target");
    return;
  }

  framebuffer->AttachAttachment(attachment, texture);

  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      if (!content_) {
        GL::FramebufferTexture2D(target_, attachment_, textarget_, 0, level_);
      } else {
        GL::FramebufferTexture2D(target_, attachment_, textarget_,
                                 content_->Get(), level_);
      }
    }
    GLenum target_, attachment_, textarget_;
    PuppetContent<uint32_t> *content_ = nullptr;
    GLint level_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->attachment_ = attachment;
  cmd->textarget_ = textarget;
  cmd->content_ = texture ? texture->related_id_.Get() : nullptr;
  cmd->level_ = level;
}

void WebGLRenderingContext::FrontFace(GLenum mode) {
  DCHECK(Recorder());

  // logic check
  if (mode != KR_GL_CW && mode != KR_GL_CCW) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "FrontFace", "invalid mode");
    return;
  }

  // save cache
  local_cache_.front_face_ = mode;

  // commit command
  class Runnable {
   public:
    Runnable(GLenum mode) : mode_(mode) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::FrontFace(mode_);
    }

   private:
    GLenum mode_;
  };
  Recorder()->Alloc<Runnable>(mode);
}

void WebGLRenderingContext::GenerateMipmap(GLenum target) {
  DCHECK(Recorder());

  if (KR_GL_TEXTURE_2D != target && KR_GL_TEXTURE_CUBE_MAP != target &&
      KR_GL_TEXTURE_3D != target && KR_GL_TEXTURE_2D_ARRAY != target) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "GenerateMipmap", "invalid target");
    return;
  }

  WebGLTexture *raw_texture;
  if (!ValidateTextureBinding("GenerateMipmap", target, raw_texture)) {
    return;
  }

  if (raw_texture->format_ == GL_SRGB_EXT ||
      raw_texture->format_ == GL_SRGB_ALPHA_EXT) {
    SynthesizeGLError(GL_INVALID_OPERATION, "GenerateMipmap",
                      "generateMipmaps for sRGB textures is forbidden");
    return;
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLenum target) : target_(target) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::GenerateMipmap(target_);
    }

   private:
    GLenum target_;
  };
  Recorder()->Alloc<Runnable>(target);
}

#define COMMON_IMPL(func)                                                \
  if (!buffer_ptr) {                                                     \
    SynthesizeGLError(KR_GL_INVALID_OPERATION, #func, "invalid buffer"); \
    return Env().Null();                                                 \
  } else {                                                               \
    if (pname == KR_GL_BUFFER_SIZE) {                                    \
      return Number::New(Env(), (int32_t)buffer_ptr->size_);             \
    } else if (pname == KR_GL_BUFFER_USAGE) {                            \
      return Number::New(Env(), (int32_t)buffer_ptr->usage_);            \
    } else {                                                             \
      SynthesizeGLError(KR_GL_INVALID_ENUM, #func, "invalid pname");     \
      return Env().Null();                                               \
    }                                                                    \
  }

Value WebGLRenderingContext::GetBufferParameter(GLenum target, GLenum pname) {
  WebGLBuffer *buffer_ptr = nullptr;
  switch (target) {
    case KR_GL_ARRAY_BUFFER:
      buffer_ptr = local_cache_.array_buffer_bind_;
      COMMON_IMPL(GetBufferParameter)
      break;
    case KR_GL_ELEMENT_ARRAY_BUFFER:
      buffer_ptr =
          local_cache_.ValidVertexArrayObject()->BoundElementArrayBuffer();
      COMMON_IMPL(GetBufferParameter)
      break;
    case KR_GL_COPY_READ_BUFFER:
    case KR_GL_COPY_WRITE_BUFFER:
    case KR_GL_TRANSFORM_FEEDBACK_BUFFER:
    case KR_GL_UNIFORM_BUFFER:
    case KR_GL_PIXEL_PACK_BUFFER:
    case KR_GL_PIXEL_UNPACK_BUFFER:
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "GetBufferParameter",
                        "invalid target");
      return Env().Null();
  }

  if (!buffer_ptr) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "GetBufferParameter",
                      "target not bind to a valid buffer");
    return Env().Null();
  }

  switch (pname) {
    case KR_GL_BUFFER_USAGE:
      return Number::New(Env(), buffer_ptr->usage_);
    case KR_GL_BUFFER_SIZE:
      return Number::New(Env(), buffer_ptr->size_);
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "GetBufferParameter",
                        "invalid parameter name");
      return Env().Null();
  }
}

WebGLContextAttributes *WebGLRenderingContext::GetContextAttributes() {
  // TODO(luchengxuan) make it return real impl property.
  return new WebGLContextAttributes();
}

GLenum WebGLRenderingContext::GetError() {
  DCHECK(Recorder());

  if (local_cache_.current_error_ != KR_GL_NO_ERROR) {
    const auto err = local_cache_.current_error_;
    local_cache_.current_error_ = KR_GL_NO_ERROR;
    struct Runnable {
      void Run(command_buffer::RunnableBuffer *buffer) {
        result_ = GL::GetError();
      }
      int32_t result_;
    };
    Recorder()->Alloc<Runnable>();
    return err;
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      *result_ = GL::GetError();
    }
    std::shared_ptr<int32_t> result_;
  };
  std::shared_ptr<int32_t> result = std::make_shared<int32_t>();
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->result_ = result;
  Present(true);

  return *result;
}

Value WebGLRenderingContext::GetExtension(std::string name) {
  auto supported_extensions = this->device_attributes_.supportd_extensions_;
  if (supported_extensions.find(name) != supported_extensions.end()) {
    return this->JsObject();
  }
  return Env().Null();
}

Value WebGLRenderingContext::GetFramebufferAttachmentParameter(
    GLenum target, GLenum attachment, GLenum pname) {
  DCHECK(Recorder());

  if (target != KR_GL_FRAMEBUFFER) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "GetFramebufferAttachmentParameter",
                      "target is not framebuffer");
    return Env().Null();
  }

  WebGLFramebuffer *framebuffer = nullptr;
  if (target == KR_GL_FRAMEBUFFER) {
    framebuffer = local_cache_.draw_framebuffer_bind_;
  }

  // should always a framebuffer bound.
  DCHECK(framebuffer);

  JsObjectPair<WebGLRenderbuffer> rbuffer;
  JsObjectPair<WebGLTexture> texture;
  if (attachment == KR_GL_COLOR_ATTACHMENT0) {
    int index = attachment - KR_GL_COLOR_ATTACHMENT0;
    rbuffer = framebuffer->colors_rbuffer_[index];
    texture = framebuffer->colors_texture_[index];
  } else if (attachment == KR_GL_DEPTH_ATTACHMENT) {
    rbuffer = framebuffer->depth_rbuffer_;
    texture = framebuffer->depth_texture_;
  } else if (attachment == KR_GL_DEPTH_STENCIL_ATTACHMENT) {
    rbuffer = framebuffer->depth_stencil_rbuffer_;
    texture = framebuffer->depth_stencil_texture_;
  } else if (attachment == KR_GL_STENCIL_ATTACHMENT) {
    rbuffer = framebuffer->stencil_rbuffer_;
    texture = framebuffer->stencil_texture_;
  } else {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "GetFramebufferAttachmentParameter",
                      "invalid attachment");
    return Env().Null();
  }

  switch (pname) {
    case KR_GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE:
      if (rbuffer) {
        return Value::From(Env(), KR_GL_RENDERBUFFER);
      } else if (texture) {
        return Value::From(Env(), KR_GL_TEXTURE);
      } else {
        return Value::From(Env(), KR_GL_NONE);
      }
    case KR_GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME:
      if (rbuffer) {
        return rbuffer.js_value();
      } else if (texture) {
        return texture.js_value();
      } else {
        SynthesizeGLError(GL_INVALID_ENUM, "getFramebufferAttachmentParameter",
                          "invalid parameter name");
        return Env().Null();
      }
    case KR_GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL:
      return Value::From(Env(), int32_t(0));
    case KR_GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE:
      if (texture &&
          texture->GetTarget() >= KR_GL_TEXTURE_CUBE_MAP_POSITIVE_X &&
          texture->GetTarget() <= KR_GL_TEXTURE_CUBE_MAP_NEGATIVE_Z) {
        return Value::From(Env(), texture->GetTarget());
      } else {
        return Value::From(Env(), 0);
      }
    case GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT:
      class Runnable {
       public:
        Runnable(GLenum target, GLenum attachment, GLenum pname, GLint *res_ptr)
            : target_(target),
              attachment_(attachment),
              pname_(pname),
              res_ptr_(res_ptr) {}
        void Run(command_buffer::RunnableBuffer *) const {
          GL::GetFramebufferAttachmentParameteriv(target_, attachment_, pname_,
                                                  res_ptr_);
        }

       private:
        GLenum target_, attachment_, pname_;
        GLint *res_ptr_;
      };
      GLint encoding;
      Recorder()->Alloc<Runnable>(target, attachment, pname, &encoding);
      Present(true);
      return Napi::Value::From(Env(), encoding);
  }

  SynthesizeGLError(KR_GL_INVALID_ENUM, "GetFramebufferAttachmentParameter",
                    "invalid pname");
  return Env().Null();
}

Value WebGLRenderingContext::GetParameter(GLenum pname) {
  DCHECK(Recorder());

  Napi::Value r_val;
  auto _index = local_cache_.active_texture_ - KR_GL_TEXTURE0;
  std::shared_ptr<int32_t> tmp_res = std::make_shared<int32_t>();

  switch (pname) {
    case KR_GL_ACTIVE_TEXTURE:
      return Napi::Value::From(Env(), (int32_t)local_cache_.active_texture_);
    case KR_GL_ALIASED_LINE_WIDTH_RANGE: {
      Float32Array res = Float32Array::New(Env(), 2);

      res[0u] = device_attributes_.aliased_line_width_range_[0];
      res[1u] = device_attributes_.aliased_line_width_range_[1];
      return res;
    }
    case KR_GL_ALIASED_POINT_SIZE_RANGE: {
      Float32Array res = Float32Array::New(Env(), 2);

      res[0u] = device_attributes_.aliased_point_size_range_[0];
      res[1u] = device_attributes_.aliased_point_size_range_[1];
      return res;
    }
    case KR_GL_ALPHA_BITS: {
      class Runnable {
       public:
        Runnable(GLint *res_ptr) : res_ptr_(res_ptr) {}
        void Run(command_buffer::RunnableBuffer *) const {
          GL::GetIntegerv(KR_GL_ALPHA_BITS, res_ptr_);
        }

       private:
        GLint *res_ptr_;
      };
      GLint alpha_bits;
      Recorder()->Alloc<Runnable>(&alpha_bits);
      Present(true);
      return Napi::Value::From(Env(), alpha_bits);
    }
    case KR_GL_ARRAY_BUFFER_BINDING:
      if (local_cache_.array_buffer_bind_ &&
          local_cache_.array_buffer_bind_->HasObject()) {
        return local_cache_.array_buffer_bind_.js_value();
      } else {
        return Env().Null();
      }
    case KR_GL_BLEND:
      return Napi::Value::From(Env(), local_cache_.enable_blend_);
    case KR_GL_BLEND_COLOR: {
      Float32Array res = Float32Array::New(Env(), 4);

      res[0u] = local_cache_.blend_color_[0];
      res[1u] = local_cache_.blend_color_[1];
      res[2u] = local_cache_.blend_color_[2];
      res[3u] = local_cache_.blend_color_[3];
      return res;
    }
    case KR_GL_BLEND_DST_RGB:
      return Napi::Value::From(Env(),
                               (int32_t)local_cache_.blend_func_dst_rgb_);
    case KR_GL_BLEND_DST_ALPHA:
      return Napi::Value::From(Env(),
                               (int32_t)local_cache_.blend_func_dst_alpha_);
    case KR_GL_BLEND_EQUATION_ALPHA:
      return Napi::Value::From(
          Env(), (int32_t)local_cache_.blend_equation_alpha_mode_);
    case KR_GL_BLEND_EQUATION_RGB:  // has same value with KR_GL_BLEND_EQUATION
      return Napi::Value::From(Env(),
                               (int32_t)local_cache_.blend_equation_rgb_mode_);
    case KR_GL_BLEND_SRC_ALPHA:
      return Napi::Value::From(Env(),
                               (int32_t)local_cache_.blend_func_src_alpha_);
    case KR_GL_BLEND_SRC_RGB:
      return Napi::Value::From(Env(),
                               (int32_t)local_cache_.blend_func_src_rgb_);
    case KR_GL_BLUE_BITS: {
      class Runnable {
       public:
        Runnable(GLint *res_ptr) : res_ptr_(res_ptr) {}
        void Run(command_buffer::RunnableBuffer *) const {
          GL::GetIntegerv(KR_GL_BLUE_BITS, res_ptr_);
        }

       private:
        GLint *res_ptr_;
      };
      GLint blue_bits;
      Recorder()->Alloc<Runnable>(&blue_bits);
      Present(true);
      return Napi::Value::From(Env(), blue_bits);
    }
    case KR_GL_COLOR_CLEAR_VALUE: {
      Float32Array res = Float32Array::New(Env(), 4);

      res[0u] = local_cache_.clear_color_[0];
      res[1u] = local_cache_.clear_color_[1];
      res[2u] = local_cache_.clear_color_[2];
      res[3u] = local_cache_.clear_color_[3];
      return res;
    }
    case KR_GL_COLOR_WRITEMASK: {
      Array res = Array::New(Env(), 4);

      res[0u] = local_cache_.color_write_mask_[0];
      res[1u] = local_cache_.color_write_mask_[1];
      res[2u] = local_cache_.color_write_mask_[2];
      res[3u] = local_cache_.color_write_mask_[3];
      return res;
    }
    case KR_GL_COMPRESSED_TEXTURE_FORMATS: {
      int formats_nums = device_attributes_.compressed_texture_format_nums_;
      auto res = Array::New(Env(), formats_nums);
      for (uint32_t i = 0; i < formats_nums; i++) {
        res[i] = device_attributes_.compressed_texture_format_[i];
      }
      return res;
    }
    case KR_GL_CULL_FACE:
      return Napi::Value::From(Env(), local_cache_.enable_cull_face_);
    case KR_GL_CULL_FACE_MODE:
      return Napi::Value::From(Env(), (int32_t)local_cache_.cull_face_mode_);
    case KR_GL_CURRENT_PROGRAM:
      return local_cache_.current_program_
                 ? local_cache_.current_program_.js_value()
                 : Env().Null();
    case KR_GL_DEPTH_BITS: {
      class Runnable {
       public:
        Runnable(GLint *res_ptr) : res_ptr_(res_ptr) {}
        void Run(command_buffer::RunnableBuffer *) const {
          GL::GetIntegerv(KR_GL_DEPTH_BITS, res_ptr_);
        }

       private:
        GLint *res_ptr_;
      };
      GLint depth_bits;
      Recorder()->Alloc<Runnable>(&depth_bits);
      Present(true);
      return Napi::Value::From(Env(), depth_bits);
    }
    case KR_GL_DEPTH_CLEAR_VALUE:
      return Napi::Value::From(Env(), local_cache_.clear_depth_);
    case KR_GL_DEPTH_FUNC:
      return Napi::Value::From(Env(), local_cache_.depth_func_);
    case KR_GL_DEPTH_RANGE: {
      Float32Array res = Float32Array::New(Env(), 2);

      res[0u] = device_attributes_.depth_range_[0];
      res[1u] = device_attributes_.depth_range_[1];
      return res;
    }
    case KR_GL_DEPTH_TEST:
      return Napi::Value::From(Env(), local_cache_.enable_depth_test_);
    case KR_GL_DEPTH_WRITEMASK:
      return Napi::Value::From(Env(), local_cache_.depth_writemask_);
    case KR_GL_DITHER:
      return Napi::Value::From(Env(), local_cache_.enable_dither_);
    case KR_GL_ELEMENT_ARRAY_BUFFER_BINDING: {
      auto vao = local_cache_.ValidVertexArrayObject();
      if (vao->BoundElementArrayBuffer()) {
        return vao->BoundElementArrayBuffer()->JsObject();
      }
      return Env().Null();
    }
    case KR_GL_FRAMEBUFFER_BINDING:
      return local_cache_.draw_framebuffer_bind_
                 ? local_cache_.draw_framebuffer_bind_.js_value()
                 : Env().Null();
    case KR_GL_FRONT_FACE:
      return Napi::Value::From(Env(), (int32_t)local_cache_.front_face_);
    case KR_GL_GENERATE_MIPMAP_HINT:
      return Napi::Value::From(Env(),
                               (int32_t)local_cache_.generate_mipmap_hint_);
    case GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES:
      return Napi::Value::From(
          Env(), (int32_t)local_cache_.fragment_shader_derivative_hint);
    case KR_GL_GREEN_BITS: {
      class Runnable {
       public:
        Runnable(GLint *res_ptr) : res_ptr_(res_ptr) {}
        void Run(command_buffer::RunnableBuffer *) const {
          GL::GetIntegerv(KR_GL_GREEN_BITS, res_ptr_);
        }

       private:
        GLint *res_ptr_;
      };
      GLint green_bits;
      Recorder()->Alloc<Runnable>(&green_bits);
      Present(true);
      return Napi::Value::From(Env(), green_bits);
    }
    case KR_GL_IMPLEMENTATION_COLOR_READ_FORMAT:
      if (!local_cache_.read_framebuffer_bind_) {
        return Env().Null();
      } else {
        class Runnable {
         public:
          Runnable(GLint *res) : res_(res) {}
          void Run(command_buffer::RunnableBuffer *) const {
            GL::GetIntegerv(KR_GL_IMPLEMENTATION_COLOR_READ_FORMAT, res_);
          }

         private:
          GLint *res_;
        };
        GLint format;
        Recorder()->Alloc<Runnable>(&format);
        Present(true);
        if (format == 0) {
          // framebuffer maybe incomplete.
          return Env().Null();
        }
        return Napi::Value::From(Env(), format);
      }
      break;
    case KR_GL_IMPLEMENTATION_COLOR_READ_TYPE: {
      if (!local_cache_.read_framebuffer_bind_) {
        return Env().Null();
      } else {
        class Runnable {
         public:
          Runnable(GLint *res) : res_(res) {}
          void Run(command_buffer::RunnableBuffer *) const {
            GL::GetIntegerv(KR_GL_IMPLEMENTATION_COLOR_READ_TYPE, res_);
          }

         private:
          GLint *res_;
        };
        GLint format;
        Recorder()->Alloc<Runnable>(&format);
        Present(true);
        if (format == 0) {
          // framebuffer maybe incomplete.
          return Env().Null();
        }
        return Napi::Value::From(Env(), format);
      }
      break;
    }
    case KR_GL_LINE_WIDTH:
      return Napi::Value::From(Env(), local_cache_.line_width_);

    case KR_GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS:
      return Napi::Value::From(
          Env(), device_attributes_.max_combined_texture_image_units_);
    case KR_GL_MAX_CUBE_MAP_TEXTURE_SIZE:
      return Napi::Value::From(Env(),
                               device_attributes_.max_cube_map_texture_size_);
    case KR_GL_MAX_FRAGMENT_UNIFORM_VECTORS:
      return Napi::Value::From(
          Env(), device_attributes_.max_fragment_uniform_vectors_);
    case KR_GL_MAX_RENDERBUFFER_SIZE:
      return Napi::Value::From(Env(),
                               device_attributes_.max_renderbuffer_size_);
    case KR_GL_MAX_TEXTURE_IMAGE_UNITS:
      return Napi::Value::From(Env(),
                               device_attributes_.max_texture_image_units_);
    case KR_GL_MAX_TEXTURE_SIZE:
      return Napi::Value::From(Env(), device_attributes_.max_texture_size_);
    case KR_GL_MAX_VARYING_VECTORS:
      return Napi::Value::From(Env(), device_attributes_.max_varying_vectors_);
    case KR_GL_MAX_VERTEX_ATTRIBS:
      return Napi::Value::From(Env(), device_attributes_.max_vertex_attribs_);
    case KR_GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS:
      return Napi::Value::From(
          Env(), device_attributes_.max_vertex_texture_image_units_);
    case KR_GL_MAX_VERTEX_UNIFORM_VECTORS:
      return Napi::Value::From(Env(),
                               device_attributes_.max_vertex_uniform_vectors_);
    case KR_GL_MAX_VIEWPORT_DIMS: {
      Int32Array res = Int32Array::New(Env(), 2);

      res[0u] = device_attributes_.max_viewport_size_[0];
      res[1u] = device_attributes_.max_viewport_size_[1];
      return res;
    }
    case KR_GL_PACK_ALIGNMENT:
      return Napi::Value::From(Env(), (int32_t)local_cache_.pack_alignment_);
    case KR_GL_POLYGON_OFFSET_FACTOR:
      return Napi::Value::From(Env(), local_cache_.polygon_offset_factor_);
    case KR_GL_POLYGON_OFFSET_FILL:
      return Napi::Value::From(Env(), local_cache_.enable_polygon_offset_fill_);
    case KR_GL_POLYGON_OFFSET_UNITS:
      return Napi::Value::From(Env(), local_cache_.polygon_offset_units_);
    case KR_GL_RED_BITS: {
      class Runnable {
       public:
        Runnable(GLint *res_ptr) : res_ptr_(res_ptr) {}
        void Run(command_buffer::RunnableBuffer *) const {
          GL::GetIntegerv(KR_GL_RED_BITS, res_ptr_);
        }

       private:
        GLint *res_ptr_;
      };
      GLint red_bits;
      Recorder()->Alloc<Runnable>(&red_bits);
      Present(true);
      return Napi::Value::From(Env(), red_bits);
    }
    case KR_GL_RENDERBUFFER_BINDING:
      return OBJECT_OR_NULL(local_cache_.renderbuffer_bind_);
    case KR_GL_RENDERER:
      /** This name is typically specific to a particular configuration of a
       * hardware platform. It does not change from release to release. */
      if (local_cache_.render_str_.empty()) {
        struct Runnable {
          Runnable(std::string &result) : result(result) {}
          void Run(command_buffer::RunnableBuffer *) {
            result = (const char *)GL::GetString(KR_GL_RENDERER);
          }
          std::string &result;
        };
        Recorder()->Alloc<Runnable>(local_cache_.render_str_);
        Present(true);
      }
      return Napi::Value::From(Env(), local_cache_.render_str_.c_str());
    case KR_GL_SAMPLE_BUFFERS: {
      struct Runnable {
        Runnable(GLint *result) : result(result) {}
        void Run(command_buffer::RunnableBuffer *) {
          GL::GetIntegerv(KR_GL_SAMPLE_BUFFERS, result);
        }
        GLint *result;
      };
      GLint res;
      Recorder()->Alloc<Runnable>(&res);
      Present(true);
      return Number::From(Env(), res);
    }
    case KR_GL_SAMPLE_COVERAGE_INVERT:
      return Napi::Value::From(Env(), local_cache_.sample_coverage_invert_);
    case KR_GL_SAMPLE_COVERAGE_VALUE:
      return Napi::Value::From(Env(), local_cache_.sample_coverage_value_);
    case KR_GL_SAMPLES:
      if (GetContextAttributes()->hasAntialias()) {
        // TODO need to read from current bound framebuffer
        return Napi::Value::From(Env(), 4);
      } else {
        /** IF MutiSample is not enable on WebGL, This will always be 0 */
        return Napi::Value::From(Env(), 0);
      }
    case KR_GL_SCISSOR_BOX: {
      Int32Array res = Int32Array::New(Env(), 4);

      res[0u] = local_cache_.scissor_[0];
      res[1u] = local_cache_.scissor_[1];
      res[2u] = local_cache_.scissor_[2];
      res[3u] = local_cache_.scissor_[3];
      return res;
    }
    case KR_GL_SCISSOR_TEST:
      return Napi::Value::From(Env(), local_cache_.enable_scissor_test_);
    case KR_GL_SHADING_LANGUAGE_VERSION:
      if (local_cache_.render_sl_version_.empty()) {
        struct Runnable {
          Runnable(std::string &result) : result(result) {}
          void Run(command_buffer::RunnableBuffer *) {
            result =
                (const char *)GL::GetString(KR_GL_SHADING_LANGUAGE_VERSION);
          }
          std::string &result;
        };
        Recorder()->Alloc<Runnable>(local_cache_.render_sl_version_);
        Present(true);
      }
      return Napi::Value::From(Env(), local_cache_.render_sl_version_.c_str());
    case KR_GL_STENCIL_BACK_FAIL:
      return Napi::Value::From(Env(),
                               (int32_t)local_cache_.back_stencil_op_fail_);
    case KR_GL_STENCIL_BACK_FUNC:
      return Napi::Value::From(Env(),
                               (int32_t)local_cache_.back_face_stencil_func_);
    case KR_GL_STENCIL_BACK_PASS_DEPTH_FAIL:
      return Napi::Value::From(Env(),
                               (int32_t)local_cache_.back_stencil_op_z_fail_);
    case KR_GL_STENCIL_BACK_PASS_DEPTH_PASS:
      return Napi::Value::From(Env(),
                               (int32_t)local_cache_.back_stencil_op_z_pass_);
    case KR_GL_STENCIL_BACK_REF:
      return Napi::Value::From(Env(), local_cache_.back_face_stencil_func_ref_);
    case KR_GL_STENCIL_BACK_VALUE_MASK:
      return Napi::Value::From(Env(),
                               local_cache_.back_face_stencil_func_mask_);
    case KR_GL_STENCIL_BACK_WRITEMASK:
      return Napi::Value::From(Env(), local_cache_.stencil_back_mask_);
    case KR_GL_STENCIL_BITS: {
      // TODO(luchengxuan) can be calculated by local cache
      class Runnable {
       public:
        Runnable(GLint *res_ptr) : res_ptr_(res_ptr) {}
        void Run(command_buffer::RunnableBuffer *) const {
          GL::GetIntegerv(KR_GL_STENCIL_BITS, res_ptr_);
        }

       private:
        GLint *res_ptr_;
      };
      GLint stencil_bits;
      Recorder()->Alloc<Runnable>(&stencil_bits);
      Present(true);
      return Napi::Value::From(Env(), stencil_bits);
    }
    case KR_GL_STENCIL_CLEAR_VALUE:
      return Number::From(Env(), local_cache_.clear_stencil_);
    case KR_GL_STENCIL_FAIL:
      return Napi::Value::From(Env(), local_cache_.front_stencil_op_fail_);
    case KR_GL_STENCIL_FUNC:
      return Napi::Value::From(Env(), local_cache_.front_face_stencil_func_);
    case KR_GL_STENCIL_PASS_DEPTH_FAIL:
      return Napi::Value::From(Env(), local_cache_.front_stencil_op_z_fail_);
    case KR_GL_STENCIL_PASS_DEPTH_PASS:
      return Napi::Value::From(Env(), local_cache_.front_stencil_op_z_pass_);
    case KR_GL_STENCIL_REF:
      return Napi::Value::From(Env(),
                               local_cache_.front_face_stencil_func_ref_);
    case KR_GL_STENCIL_TEST:
      return Napi::Value::From(Env(), local_cache_.enable_stencil_test_);
    case KR_GL_STENCIL_VALUE_MASK:
      return Napi::Value::From(Env(),
                               local_cache_.front_face_stencil_func_mask_);
    case KR_GL_STENCIL_WRITEMASK:
      return Napi::Value::From(Env(), local_cache_.stencil_front_mask_);
    case KR_GL_SUBPIXEL_BITS:
      return Napi::Value::From(Env(),
                               (int32_t)device_attributes_.subpixel_bits_);
    case KR_GL_TEXTURE_BINDING_2D:
      return OBJECT_OR_NULL(local_cache_.texture_2d_bind_[_index]);
    case KR_GL_TEXTURE_BINDING_CUBE_MAP:
      return OBJECT_OR_NULL(local_cache_.texture_cube_bind_[_index]);
    case KR_GL_UNPACK_ALIGNMENT:
      return Napi::Value::From(Env(), (int32_t)local_cache_.unpack_alignment_);
    case KR_GL_UNPACK_COLORSPACE_CONVERSION_WEBGL:
      return Napi::Value::From(
          Env(), (int32_t)local_cache_.unpack_colorspace_conversion_webgl_);
    case KR_GL_UNPACK_FLIP_Y_WEBGL:
      return Napi::Value::From(Env(), local_cache_.unpack_filp_y_webgl_);
    case KR_GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL:
      return Napi::Value::From(Env(), local_cache_.unpack_premul_alpha_webgl_);
    case KR_GL_VENDOR:
      if (local_cache_.render_vendor_.empty()) {
        struct Runnable {
          Runnable(std::string &result) : result(result) {}
          void Run(command_buffer::RunnableBuffer *) {
            result = (const char *)GL::GetString(KR_GL_VENDOR);
          }
          std::string &result;
        };
        Recorder()->Alloc<Runnable>(local_cache_.render_vendor_);
        Present(true);
      }
      return Napi::Value::From(Env(), local_cache_.render_vendor_.c_str());
    case KR_GL_VERSION:
      if (local_cache_.render_version_.empty()) {
        struct Runnable {
          Runnable(std::string &result) : result(result) {}
          void Run(command_buffer::RunnableBuffer *) {
            result = (const char *)GL::GetString(KR_GL_VERSION);
          }
          std::string &result;
        };
        Recorder()->Alloc<Runnable>(local_cache_.render_version_);
        Present(true);
      }
      return Napi::Value::From(Env(), local_cache_.render_version_.c_str());
    case KR_GL_VIEWPORT: {
      uint32_t viewport_result[4] = {0, 0, 0, 0};
      if (local_cache_.viewport_[2] > 0 && local_cache_.viewport_[3] > 0 &&
          device_attributes_.max_viewport_size_[0] > 0 &&
          device_attributes_.max_viewport_size_[1] > 0) {
        viewport_result[0] = local_cache_.viewport_[0];
        viewport_result[1] = local_cache_.viewport_[1];
        viewport_result[2] = local_cache_.viewport_[2];
        viewport_result[3] = local_cache_.viewport_[3];
      }

      Int32Array res = Int32Array::New(Env(), 4);
      res[0u] = viewport_result[0];
      res[1u] = viewport_result[1];
      res[2u] = viewport_result[2];
      res[3u] = viewport_result[3];
      return res;
    }
    case KR_GL_VERTEX_ARRAY_BINDING: {
      if (local_cache_.bound_vertex_array_object_ &&
          local_cache_.bound_vertex_array_object_->HasObject()) {
        return local_cache_.bound_vertex_array_object_.js_value();
      } else {
        return Env().Null();
      }
    }
    case GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT: {
      if (device_attributes_.ExtensionEnabled(
              "EXT_texture_filter_anisotropic")) {
        return Napi::Value::From(
            Env(), device_attributes_.max_texture_max_anisotropy_);
      }
    }
    default:;  // pass
  }
  SynthesizeGLError(GL_INVALID_ENUM, "getParameter", "invalid parameter name");
  return Env().Null();
}

/*
 * Reviewed by guo xie. 06/28/2021.
 */
Value WebGLRenderingContext::GetRenderbufferParameter(GLenum target,
                                                      GLenum pname) {
  DCHECK(Recorder());

  // logic check
  if (target != KR_GL_RENDERBUFFER) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "GetRenderbufferParameter",
                      "parameter target is not KR_GL_RENDERBUFFER");
    return Env().Null();
  }

  auto raw_renderbuffer = local_cache_.renderbuffer_bind_.native_obj();
  if (!raw_renderbuffer || !raw_renderbuffer->HasObject()) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, "GetRenderbufferParameter",
                      "no renderbuffer bound");
    return Env().Null();
  }

  switch (pname) {
    case KR_GL_RENDERBUFFER_WIDTH:
      return Napi::Value::From(Env(), (int32_t)raw_renderbuffer->width_);
    case KR_GL_RENDERBUFFER_HEIGHT:
      return Napi::Value::From(Env(), (int32_t)raw_renderbuffer->height_);
    case KR_GL_RENDERBUFFER_INTERNAL_FORMAT:
      return Napi::Value::From(Env(),
                               (int32_t)raw_renderbuffer->internal_format_);
    case KR_GL_RENDERBUFFER_GREEN_SIZE:
      switch (raw_renderbuffer->internal_format_) {
        case KR_GL_RGBA4:
          return Napi::Value::From(Env(), (int32_t)4);
        case KR_GL_RGB565:
          return Napi::Value::From(Env(), (int32_t)6);
        case KR_GL_RGB5_A1:
          return Napi::Value::From(Env(), (int32_t)5);
        case KR_GL_DEPTH_COMPONENT16:
        case KR_GL_STENCIL_INDEX8:
        case KR_GL_DEPTH_STENCIL:
          return Napi::Value::From(Env(), (int32_t)0);
          // WebGL 2.0
        case KR_GL_R8:
        case KR_GL_R8UI:
        case KR_GL_R8I:
        case KR_GL_R16UI:
        case KR_GL_R16I:
        case KR_GL_R32UI:
        case KR_GL_R32I:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_RG8:
        case KR_GL_RG8UI:
        case KR_GL_RG8I:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_RG16UI:
        case KR_GL_RG16I:
          return Napi::Value::From(Env(), (int32_t)16);
        case KR_GL_RG32UI:
        case KR_GL_RG32I:
          return Napi::Value::From(Env(), (int32_t)32);
        case KR_GL_RGB8:
        case KR_GL_RGBA8:
        case KR_GL_SRGB8_ALPHA8:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_RGB10_A2:
          return Napi::Value::From(Env(), (int32_t)10);
        case KR_GL_RGBA8UI:
        case KR_GL_RGBA8I:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_RGB10_A2UI:
          return Napi::Value::From(Env(), (int32_t)10);
        case KR_GL_RGBA16UI:
        case KR_GL_RGBA16I:
          return Napi::Value::From(Env(), (int32_t)16);
        case KR_GL_RGBA32I:
        case KR_GL_RGBA32UI:
          return Napi::Value::From(Env(), (int32_t)32);
        case KR_GL_DEPTH_COMPONENT24:
        case KR_GL_DEPTH_COMPONENT32F:
        case KR_GL_DEPTH24_STENCIL8:
        case KR_GL_DEPTH32F_STENCIL8:
        case KR_GL_R16F:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_RG16F:
        case KR_GL_RGBA16F:
          return Napi::Value::From(Env(), (int32_t)16);
        case KR_GL_R32F:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_RG32F:
        case KR_GL_RGBA32F:
          return Napi::Value::From(Env(), (int32_t)32);
        case KR_GL_R11F_G11F_B10F:
          return Napi::Value::From(Env(), (int32_t)11);
      }
      break;
    case KR_GL_RENDERBUFFER_BLUE_SIZE:
      switch (raw_renderbuffer->internal_format_) {
        case KR_GL_RGBA4:
          return Napi::Value::From(Env(), (int32_t)4);
        case KR_GL_RGB565:
        case KR_GL_RGB5_A1:
          return Napi::Value::From(Env(), (int32_t)5);
        case KR_GL_DEPTH_COMPONENT16:
        case KR_GL_STENCIL_INDEX8:
        case KR_GL_DEPTH_STENCIL:
          return Napi::Value::From(Env(), (int32_t)0);
          // WebGL 2.0
        case KR_GL_R8:
        case KR_GL_R8UI:
        case KR_GL_R8I:
        case KR_GL_R16UI:
        case KR_GL_R16I:
        case KR_GL_R32UI:
        case KR_GL_R32I:
        case KR_GL_RG8:
        case KR_GL_RG8UI:
        case KR_GL_RG8I:
        case KR_GL_RG16UI:
        case KR_GL_RG16I:
        case KR_GL_RG32UI:
        case KR_GL_RG32I:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_RGB8:
        case KR_GL_RGBA8:
        case KR_GL_SRGB8_ALPHA8:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_RGB10_A2:
          return Napi::Value::From(Env(), (int32_t)10);
        case KR_GL_RGBA8UI:
        case KR_GL_RGBA8I:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_RGB10_A2UI:
          return Napi::Value::From(Env(), (int32_t)10);
        case KR_GL_RGBA16UI:
        case KR_GL_RGBA16I:
          return Napi::Value::From(Env(), (int32_t)16);
        case KR_GL_RGBA32I:
        case KR_GL_RGBA32UI:
          return Napi::Value::From(Env(), (int32_t)32);
        case KR_GL_DEPTH_COMPONENT24:
        case KR_GL_DEPTH_COMPONENT32F:
        case KR_GL_DEPTH24_STENCIL8:
        case KR_GL_DEPTH32F_STENCIL8:
        case KR_GL_R16F:
        case KR_GL_RG16F:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_RGBA16F:
          return Napi::Value::From(Env(), (int32_t)16);
        case KR_GL_R32F:
        case KR_GL_RG32F:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_RGBA32F:
          return Napi::Value::From(Env(), (int32_t)32);
        case KR_GL_R11F_G11F_B10F:
          return Napi::Value::From(Env(), (int32_t)10);
      }
      break;
    case KR_GL_RENDERBUFFER_RED_SIZE:
      switch (raw_renderbuffer->internal_format_) {
        case KR_GL_RGBA4:
          return Napi::Value::From(Env(), (int32_t)4);
        case KR_GL_RGB565:
        case KR_GL_RGB5_A1:
          return Napi::Value::From(Env(), (int32_t)5);
        case KR_GL_DEPTH_COMPONENT16:
        case KR_GL_STENCIL_INDEX8:
        case KR_GL_DEPTH_STENCIL:
          return Napi::Value::From(Env(), (int32_t)0);
          // WebGL 2.0
        case KR_GL_R8:
        case KR_GL_R8UI:
        case KR_GL_R8I:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_R16UI:
        case KR_GL_R16I:
          return Napi::Value::From(Env(), (int32_t)16);
        case KR_GL_R32UI:
        case KR_GL_R32I:
          return Napi::Value::From(Env(), (int32_t)32);
        case KR_GL_RG8:
        case KR_GL_RG8UI:
        case KR_GL_RG8I:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_RG16UI:
        case KR_GL_RG16I:
          return Napi::Value::From(Env(), (int32_t)16);
        case KR_GL_RG32UI:
        case KR_GL_RG32I:
          return Napi::Value::From(Env(), (int32_t)32);
        case KR_GL_RGB8:
        case KR_GL_RGBA8:
        case KR_GL_SRGB8_ALPHA8:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_RGB10_A2:
          return Napi::Value::From(Env(), (int32_t)10);
        case KR_GL_RGBA8UI:
        case KR_GL_RGBA8I:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_RGB10_A2UI:
          return Napi::Value::From(Env(), (int32_t)10);
        case KR_GL_RGBA16UI:
        case KR_GL_RGBA16I:
          return Napi::Value::From(Env(), (int32_t)16);
        case KR_GL_RGBA32I:
        case KR_GL_RGBA32UI:
          return Napi::Value::From(Env(), (int32_t)32);
        case KR_GL_DEPTH_COMPONENT24:
        case KR_GL_DEPTH_COMPONENT32F:
        case KR_GL_DEPTH24_STENCIL8:
        case KR_GL_DEPTH32F_STENCIL8:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_R16F:
        case KR_GL_RG16F:
        case KR_GL_RGBA16F:
          return Napi::Value::From(Env(), (int32_t)16);
        case KR_GL_R32F:
        case KR_GL_RG32F:
        case KR_GL_RGBA32F:
          return Napi::Value::From(Env(), (int32_t)32);
        case KR_GL_R11F_G11F_B10F:
          return Napi::Value::From(Env(), (int32_t)11);
      }
      break;
    case KR_GL_RENDERBUFFER_ALPHA_SIZE:
      switch (raw_renderbuffer->internal_format_) {
        case KR_GL_RGBA4:
          return Napi::Value::From(Env(), (int32_t)4);
        case KR_GL_RGB565:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_RGB5_A1:
          return Napi::Value::From(Env(), (int32_t)1);
        case KR_GL_DEPTH_COMPONENT16:
        case KR_GL_STENCIL_INDEX8:
        case KR_GL_DEPTH_STENCIL:
          return Napi::Value::From(Env(), (int32_t)0);
          // WebGL 2.0
        case KR_GL_R8:
        case KR_GL_R8UI:
        case KR_GL_R8I:
        case KR_GL_R16UI:
        case KR_GL_R16I:
        case KR_GL_R32UI:
        case KR_GL_R32I:
        case KR_GL_RG8:
        case KR_GL_RG8UI:
        case KR_GL_RG8I:
        case KR_GL_RG16UI:
        case KR_GL_RG16I:
        case KR_GL_RG32UI:
        case KR_GL_RG32I:
        case KR_GL_RGB8:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_RGBA8:
        case KR_GL_SRGB8_ALPHA8:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_RGB10_A2:
          return Napi::Value::From(Env(), (int32_t)2);
        case KR_GL_RGBA8UI:
        case KR_GL_RGBA8I:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_RGB10_A2UI:
          return Napi::Value::From(Env(), (int32_t)2);
        case KR_GL_RGBA16UI:
        case KR_GL_RGBA16I:
          return Napi::Value::From(Env(), (int32_t)16);
        case KR_GL_RGBA32I:
        case KR_GL_RGBA32UI:
          return Napi::Value::From(Env(), (int32_t)32);
        case KR_GL_DEPTH_COMPONENT24:
        case KR_GL_DEPTH_COMPONENT32F:
        case KR_GL_DEPTH24_STENCIL8:
        case KR_GL_DEPTH32F_STENCIL8:
        case KR_GL_R16F:
        case KR_GL_RG16F:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_RGBA16F:
          return Napi::Value::From(Env(), (int32_t)16);
        case KR_GL_R32F:
        case KR_GL_RG32F:
        case KR_GL_RGBA32F:
        case KR_GL_R11F_G11F_B10F:
          return Napi::Value::From(Env(), (int32_t)0);
      }
      break;
    case KR_GL_RENDERBUFFER_DEPTH_SIZE:
      switch (raw_renderbuffer->internal_format_) {
        case KR_GL_RGBA4:
        case KR_GL_RGB565:
        case KR_GL_RGB5_A1:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_DEPTH_COMPONENT16:
          return Napi::Value::From(Env(), (int32_t)16);
        case KR_GL_STENCIL_INDEX8:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_DEPTH_STENCIL:
          return Napi::Value::From(Env(), (int32_t)24);
          // WebGL 2.0
        case KR_GL_R8:
        case KR_GL_R8UI:
        case KR_GL_R8I:
        case KR_GL_R16UI:
        case KR_GL_R16I:
        case KR_GL_R32UI:
        case KR_GL_R32I:
        case KR_GL_RG8:
        case KR_GL_RG8UI:
        case KR_GL_RG8I:
        case KR_GL_RG16UI:
        case KR_GL_RG16I:
        case KR_GL_RG32UI:
        case KR_GL_RG32I:
        case KR_GL_RGB8:
        case KR_GL_RGBA8:
        case KR_GL_SRGB8_ALPHA8:
        case KR_GL_RGB10_A2:
        case KR_GL_RGBA8UI:
        case KR_GL_RGBA8I:
        case KR_GL_RGB10_A2UI:
        case KR_GL_RGBA16UI:
        case KR_GL_RGBA16I:
        case KR_GL_RGBA32I:
        case KR_GL_RGBA32UI:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_DEPTH_COMPONENT24:
          return Napi::Value::From(Env(), (int32_t)24);
        case KR_GL_DEPTH_COMPONENT32F:
          return Napi::Value::From(Env(), (int32_t)32);
        case KR_GL_DEPTH24_STENCIL8:
          return Napi::Value::From(Env(), (int32_t)24);
        case KR_GL_DEPTH32F_STENCIL8:
          return Napi::Value::From(Env(), (int32_t)32);
        case KR_GL_R16F:
        case KR_GL_RG16F:
        case KR_GL_RGBA16F:
        case KR_GL_R32F:
        case KR_GL_RG32F:
        case KR_GL_RGBA32F:
        case KR_GL_R11F_G11F_B10F:
          return Napi::Value::From(Env(), (int32_t)0);
      }
      break;
    case KR_GL_RENDERBUFFER_STENCIL_SIZE:
      switch (raw_renderbuffer->internal_format_) {
        case KR_GL_RGBA4:
        case KR_GL_RGB565:
        case KR_GL_RGB5_A1:
        case KR_GL_DEPTH_COMPONENT16:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_STENCIL_INDEX8:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_DEPTH_STENCIL:
          return Napi::Value::From(Env(), (int32_t)8);
          // WebGL 2.0
        case KR_GL_R8:
        case KR_GL_R8UI:
        case KR_GL_R8I:
        case KR_GL_R16UI:
        case KR_GL_R16I:
        case KR_GL_R32UI:
        case KR_GL_R32I:
        case KR_GL_RG8:
        case KR_GL_RG8UI:
        case KR_GL_RG8I:
        case KR_GL_RG16UI:
        case KR_GL_RG16I:
        case KR_GL_RG32UI:
        case KR_GL_RG32I:
        case KR_GL_RGB8:
        case KR_GL_RGBA8:
        case KR_GL_SRGB8_ALPHA8:
        case KR_GL_RGB10_A2:
        case KR_GL_RGBA8UI:
        case KR_GL_RGBA8I:
        case KR_GL_RGB10_A2UI:
        case KR_GL_RGBA16UI:
        case KR_GL_RGBA16I:
        case KR_GL_RGBA32I:
        case KR_GL_RGBA32UI:
        case KR_GL_DEPTH_COMPONENT24:
        case KR_GL_DEPTH_COMPONENT32F:
          return Napi::Value::From(Env(), (int32_t)0);
        case KR_GL_DEPTH24_STENCIL8:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_DEPTH32F_STENCIL8:
          return Napi::Value::From(Env(), (int32_t)8);
        case KR_GL_R16F:
        case KR_GL_RG16F:
        case KR_GL_RGBA16F:
        case KR_GL_R32F:
        case KR_GL_RG32F:
        case KR_GL_RGBA32F:
        case KR_GL_R11F_G11F_B10F:
          return Napi::Value::From(Env(), (int32_t)0);
      }
      break;
    case KR_GL_RENDERBUFFER_SAMPLES:
    default:
      break;
  }
  SynthesizeGLError(KR_GL_INVALID_ENUM, "GetRenderbufferParameter",
                    "invalid pname");
  return Env().Null();
}

std::vector<std::string> WebGLRenderingContext::GetSupportedExtensions() {
  const auto &exts = device_attributes_.supportd_extensions_;
  size_t elem_size = exts.size();
  std::vector<std::string> elems(elem_size);
  uint32_t index = 0;
  for (const auto &item : exts) {
    elems[index++] = item;
  }
  return elems;
}

Value WebGLRenderingContext::GetTexParameter(GLenum target, GLenum pname) {
  DCHECK(Recorder());

  // logic check
  WebGLTexture *raw_texture =
      ValidateTexture2DBinding("GetTexParameter", target, false);

  if (!raw_texture) {
    return Env().Null();
  }

  switch (pname) {
    case KR_GL_TEXTURE_MAG_FILTER:
      return Napi::Value::From(Env(), raw_texture->mag_filter_);
    case KR_GL_TEXTURE_MIN_FILTER:
      return Napi::Value::From(Env(), raw_texture->min_filter_);
    case KR_GL_TEXTURE_WRAP_S:
      return Napi::Value::From(Env(), raw_texture->wrap_s_);
    case KR_GL_TEXTURE_WRAP_T:
      return Napi::Value::From(Env(), raw_texture->wrap_t_);
    case GL_TEXTURE_MAX_ANISOTROPY_EXT:
      if (device_attributes_.ExtensionEnabled(
              "EXT_texture_filter_anisotropic")) {
        return Napi::Value::From(Env(), raw_texture->max_anisotropy_ext_);
      }
    case KR_GL_TEXTURE_WRAP_R:
    case KR_GL_TEXTURE_BASE_LEVEL:
    case KR_GL_TEXTURE_MAX_LEVEL:
    case KR_GL_TEXTURE_COMPARE_FUNC:
    case KR_GL_TEXTURE_COMPARE_MODE:
    case KR_GL_TEXTURE_MAX_LOD:
    case KR_GL_TEXTURE_MIN_LOD:
    case KR_GL_TEXTURE_IMMUTABLE_FORMAT:
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "GetTexParameter", "invalid pname");
      return Env().Null();
  }
}

void WebGLRenderingContext::Hint(GLenum target, GLenum mode) {
  DCHECK(Recorder());

  // logic check
  if (mode == KR_GL_FASTEST || mode == KR_GL_NICEST ||
      mode == KR_GL_DONT_CARE) {
    if (target == KR_GL_GENERATE_MIPMAP_HINT) {
      local_cache_.generate_mipmap_hint_ = mode;
    } else if (target == GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES) {
      local_cache_.fragment_shader_derivative_hint = mode;
    } else {
      SynthesizeGLError(KR_GL_INVALID_ENUM, "hint", "invalid target");
      return;
    }
  } else {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "hint", "invalid mode");
    return;
  }

  // commit command
  class Runnable {
   public:
    Runnable(GLenum target, GLenum mode) : target_(target), mode_(mode) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Hint(target_, mode_);
    }

   private:
    GLenum target_;
    GLenum mode_;
  };
  Recorder()->Alloc<Runnable>(target, mode);

  return;
}

GLboolean WebGLRenderingContext::IsBuffer(WebGLBuffer *buffer) {
  DCHECK(Recorder());

  if (!buffer || !buffer->Validate(this)) {
    return GL_FALSE;
  }
  if (buffer->MarkedForDeletion()) {
    return GL_FALSE;
  }
  if (!buffer->HasEverBeenBound()) {
    return GL_FALSE;
  }
  return GL_TRUE;
}

/*
 * Reviewd by xieguo 06/24/2021
 * No need to consider contextLost mode currently, please check the MDN.
 */
GLboolean WebGLRenderingContext::IsContextLost() {
  DCHECK(Recorder());
  return GL_FALSE;
}

GLboolean WebGLRenderingContext::IsEnabled(GLenum cap) {
  DCHECK(Recorder());

  // logic check
  bool return_val = false;
  switch (cap) {
    case KR_GL_BLEND:
      return_val = local_cache_.enable_blend_;
      break;
    case KR_GL_CULL_FACE:
      return_val = local_cache_.enable_cull_face_;
      break;
    case KR_GL_DEPTH_TEST:
      return_val = local_cache_.enable_depth_test_;
      break;
    case KR_GL_DITHER:
      return_val = local_cache_.enable_dither_;
      break;
    case KR_GL_POLYGON_OFFSET_FILL:
      return_val = local_cache_.enable_polygon_offset_fill_;
      break;
    case KR_GL_SAMPLE_ALPHA_TO_COVERAGE:
      return_val = local_cache_.enable_sample_alpha_to_coverage_;
      break;
    case KR_GL_SAMPLE_COVERAGE:
      return_val = local_cache_.enable_coverage_;
      break;
    case KR_GL_SCISSOR_TEST:
      return_val = local_cache_.enable_scissor_test_;
      break;
    case KR_GL_STENCIL_TEST:
      return_val = local_cache_.enable_stencil_test_;
      break;
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "IsEnabled", "invalid cap");
      return GL_FALSE;
  }

  return return_val;
}

/*
 * Reviewed by xieguo, 06/25/2021
 */
GLboolean WebGLRenderingContext::IsFramebuffer(WebGLFramebuffer *framebuffer) {
  DCHECK(Recorder());

  if (!framebuffer || !framebuffer->Validate(this)) {
    return GL_FALSE;
  }
  if (framebuffer->MarkedForDeletion()) {
    return GL_FALSE;
  }
  if (!framebuffer->HasEverBeenBound()) {
    return GL_FALSE;
  }
  return GL_TRUE;
}

/*
 *  Reviewed by guo xie. 06/28/2021.
 */
GLboolean WebGLRenderingContext::IsRenderbuffer(
    WebGLRenderbuffer *renderbuffer) {
  DCHECK(Recorder());

  if (!renderbuffer || !renderbuffer->Validate(this)) {
    return GL_FALSE;
  }
  if (renderbuffer->MarkedForDeletion()) {
    return GL_FALSE;
  }
  if (!renderbuffer->HasEverBeenBound()) {
    return GL_FALSE;
  }
  return GL_TRUE;
}

GLboolean WebGLRenderingContext::IsTexture(WebGLTexture *texture) {
  DCHECK(Recorder());

  if (!texture || !texture->Validate(this)) {
    return GL_FALSE;
  }
  if (texture->MarkedForDeletion()) {
    return GL_FALSE;
  }
  if (!texture->GetTarget()) {
    return GL_FALSE;
  }
  return GL_TRUE;
}

void WebGLRenderingContext::LineWidth(GLfloat width) {
  DCHECK(Recorder());

  // save cache
  if (width <= 0 || isnan(width)) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "lineWidth", "invalid width");
    return;
  }
  local_cache_.line_width_ = width;

  // commit command
  class Runnable {
   public:
    Runnable(GLfloat width) : width_(width) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::LineWidth(width_);
    }

   private:
    GLfloat width_;
  };
  Recorder()->Alloc<Runnable>(width);
}

void WebGLRenderingContext::PixelStorei(GLenum pname, GLint param) {
  DCHECK(Recorder());

  // logic check
  // TODO(yuyifei): Check this.
  // uint32_t param_ = 0;
  // if (param.IsNumber()) {
  //     param_ = param.Uint32Value();
  // } else if (param.IsBoolean()) {
  //     param_ = param;
  // } else {
  //     return;
  // }
  //  uint32_t size_pname_ = sizeof(webgl2_pname_) / sizeof(webgl2_pname_[0]);

  switch (pname) {
    /* 1.0 */
    case KR_GL_PACK_ALIGNMENT:
      if (param != 1 && param != 2 && param != 4 && param != 8) {
        SynthesizeGLError(KR_GL_INVALID_VALUE, "pixelStorei", "invalid param");
        return;
      }
      local_cache_.pack_alignment_ = param;
      break;
    case KR_GL_UNPACK_ALIGNMENT:
      if (param != 1 && param != 2 && param != 4 && param != 8) {
        SynthesizeGLError(KR_GL_INVALID_VALUE, "pixelStorei", "invalid param");
        return;
      }
      local_cache_.unpack_alignment_ = param;
      break;
      /* 2.0 */
    case KR_GL_PACK_ROW_LENGTH:
      local_cache_.pack_row_length_ = param;
      break;
    case KR_GL_PACK_SKIP_PIXELS:
      local_cache_.pack_skip_pixels_ = param;
      break;
    case KR_GL_PACK_SKIP_ROWS:
      local_cache_.pack_skip_rows_ = param;
      break;
    case KR_GL_UNPACK_ROW_LENGTH:
      local_cache_.unpack_row_length_ = param;
      break;
    case KR_GL_UNPACK_SKIP_PIXELS:
      local_cache_.unpack_skip_pixels_ = param;
      break;
    case KR_GL_UNPACK_SKIP_ROWS:
      local_cache_.unpack_skip_rows_ = param;
      break;
    case KR_GL_UNPACK_SKIP_IMAGES:
      local_cache_.unpack_skip_images_ = param;
      break;
    case KR_GL_UNPACK_IMAGE_HEIGHT:
      local_cache_.unpack_image_height_ = param;
      break;
      /* webgl */
    case KR_GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL:
      local_cache_.unpack_premul_alpha_webgl_ = param;
      return;
    case KR_GL_UNPACK_FLIP_Y_WEBGL:
      local_cache_.unpack_filp_y_webgl_ = param;
      return;
    case KR_GL_UNPACK_COLORSPACE_CONVERSION_WEBGL:
      local_cache_.unpack_colorspace_conversion_webgl_ =
          param == KR_GL_BROWSER_DEFAULT_WEBGL ? param : KR_GL_NONE;
      return;
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "pixelStorei", "invalid pname");
      return;
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::PixelStorei(pname_, param_);
    }
    GLenum pname_;
    GLint param_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->pname_ = pname;
  cmd->param_ = param;
}

void WebGLRenderingContext::PolygonOffset(GLfloat factor, GLfloat units) {
  DCHECK(Recorder());

  // logic check
  local_cache_.polygon_offset_factor_ = factor;
  local_cache_.polygon_offset_units_ = units;

  // commit command
  class Runnable {
   public:
    Runnable(GLfloat factor, GLfloat units) : factor_(factor), units_(units) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::PolygonOffset(factor_, units_);
    }

   private:
    GLfloat factor_;
    GLfloat units_;
  };
  Recorder()->Alloc<Runnable>(factor, units);
}

bool WebGLRenderingContext::ValidateReadPixelsFormatAndTypeCompatible(
    uint32_t format, uint32_t type) {
  GLenum src_internal_format = GetBoundReadFramebufferInternalFormat();
  if (src_internal_format == 0) {
    return false;
  }
  std::vector<GLenum> accepted_formats;
  std::vector<GLenum> accepted_types;
  switch (src_internal_format) {
    case KR_GL_R8UI:
    case KR_GL_R16UI:
    case KR_GL_R32UI:
    case KR_GL_RG8UI:
    case KR_GL_RG16UI:
    case KR_GL_RG32UI:
      // All the RGB_INTEGER formats are not renderable.
    case KR_GL_RGBA8UI:
    case KR_GL_RGB10_A2UI:
    case KR_GL_RGBA16UI:
    case KR_GL_RGBA32UI:
      accepted_formats.push_back(KR_GL_RGBA_INTEGER);
      accepted_types.push_back(KR_GL_UNSIGNED_INT);
      break;
    case KR_GL_R8I:
    case KR_GL_R16I:
    case KR_GL_R32I:
    case KR_GL_RG8I:
    case KR_GL_RG16I:
    case KR_GL_RG32I:
    case KR_GL_RGBA8I:
    case KR_GL_RGBA16I:
    case KR_GL_RGBA32I:
      accepted_formats.push_back(KR_GL_RGBA_INTEGER);
      accepted_types.push_back(KR_GL_INT);
      break;
    case KR_GL_RGB10_A2:
      accepted_formats.push_back(KR_GL_RGBA);
      accepted_types.push_back(KR_GL_UNSIGNED_BYTE);
      // Special case with an extra supported format/type.
      accepted_formats.push_back(KR_GL_RGBA);
      accepted_types.push_back(KR_GL_UNSIGNED_INT_2_10_10_10_REV);
      break;
    default:
      accepted_formats.push_back(KR_GL_RGBA);
      {
        // TODO(luchengxuan) need to get/set actual type for webgl2
        GLenum src_type = GetBoundReadFramebufferTextureType();
        switch (src_type) {
          case KR_GL_HALF_FLOAT:
          case KR_GL_HALF_FLOAT_OES:
          case KR_GL_FLOAT:
          case KR_GL_UNSIGNED_INT_10F_11F_11F_REV:
            accepted_types.push_back(KR_GL_FLOAT);
            break;
          default:
            accepted_types.push_back(KR_GL_UNSIGNED_BYTE);
            break;
        }
      }
      break;
  }
  DCHECK(accepted_formats.size() == accepted_types.size());
  bool format_type_acceptable = false;
  for (size_t ii = 0; ii < accepted_formats.size(); ++ii) {
    if (format == accepted_formats[ii] && type == accepted_types[ii]) {
      format_type_acceptable = true;
      break;
    }
  }
  if (!format_type_acceptable) {
    // format and type are acceptable enums but not guaranteed to be supported
    // for this framebuffer.  Have to ask gl if they are valid.

    struct Runnable {
      void Run(command_buffer::RunnableBuffer *) const {
        glGetIntegerv(KR_GL_IMPLEMENTATION_COLOR_READ_FORMAT, preferred_format);
        glGetIntegerv(KR_GL_IMPLEMENTATION_COLOR_READ_TYPE, preferred_type);
      }
      GLint *preferred_format;
      GLint *preferred_type;
    };

    GLint preferred_format = 0;
    GLint preferred_type = 0;

    auto *cmd = Recorder()->Alloc<Runnable>();
    cmd->preferred_format = &preferred_format;
    cmd->preferred_type = &preferred_type;

    Present(true);

    if (format == static_cast<GLenum>(preferred_format) &&
        type == static_cast<GLenum>(preferred_type)) {
      format_type_acceptable = true;
    }
  }
  return format_type_acceptable;
}

void WebGLRenderingContext::ReadPixels(GLint x, GLint y, GLsizei width,
                                       GLsizei height, GLenum format,
                                       GLenum type, ArrayBufferView pixels) {
  DCHECK(Recorder());

  if (width < 0 || height < 0) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "ReadPixels", "invalid size");
    return;
  }

  const auto bytes_per_pixel = ComputeBytesPerPixelForReadPixels(format, type);
  if (!bytes_per_pixel) return;

  if (local_cache_.pixel_pack_buffer_bind_) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, "ReadPixels",
                      "has pixel pack buffer bound.");
    return;
  }

  if (!ValidateArrayType("ReadPixels", type, pixels)) {
    return;
  }

  if (!ValidateReadPixelsFuncParameters("readpixels", width, height,
                                        bytes_per_pixel, pixels.ByteLength()))
    return;

  if (!ValidateReadPixelsFormatAndTypeCompatible(format, type)) {
    SynthesizeGLError(
        GL_INVALID_OPERATION, "ReadPixels",
        "format and type incompatible with the current read framebuffer");
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *) const {
      if (raw_resource_provider_) {
        raw_resource_provider_->WillAccessRenderBuffer();
      }
      GL::ReadPixels(x_, y_, width_, height_, format_, type_, pixels_);
    }
    int32_t x_, y_, width_, height_;
    uint32_t format_, type_;
    void *pixels_;
    CanvasResourceProvider *raw_resource_provider_;
  };

  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->x_ = x;
  cmd->y_ = y;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->format_ = format;
  cmd->type_ = type;
  cmd->pixels_ = pixels.Data();

  if (local_cache_.read_framebuffer_bind_ == nullptr) {
    // default fbo
    auto raw_resource_provider = ResourceProvider().get();
    cmd->raw_resource_provider_ = raw_resource_provider;
  } else {
    cmd->raw_resource_provider_ = nullptr;
  }
  Present(true);
}

/*
 * Reviewed by guo xie. 06/28/2021.
 */
void WebGLRenderingContext::RenderbufferStorage(GLenum target,
                                                GLenum internalformat,
                                                GLsizei width, GLsizei height) {
  DCHECK(Recorder());

  if (target != KR_GL_RENDERBUFFER) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "RenderbufferStorage",
                      "target is not RENDERBUFFER");
    return;
  }

  const auto type = ExtractTypeFromStorageFormat(internalformat);
  if (!type) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "RenderbufferStorage",
                      "internal format error");
    return;
  }

  if (width < 0 || height < 0) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "RenderbufferStorage",
                      "width_ < 0 || height_ < 0");
    return;
  }

  auto raw_renderbuffer = local_cache_.renderbuffer_bind_.native_obj();
  if (!raw_renderbuffer) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, "RenderbufferStorage",
                      "raw_renderbuffer is null");
    return;
  }
  raw_renderbuffer->width_ = width;
  raw_renderbuffer->height_ = height;
  raw_renderbuffer->samples_ = 1;
  raw_renderbuffer->internal_format_ = internalformat;
  raw_renderbuffer->type_ = type;

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      if (internalFormat_ == KR_GL_DEPTH_STENCIL) {
        // convert gl.DEPTH_STENCIL to DEPTH24_STENCIL8
        // https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/modules/webgl/webgl_rendering_context_base.cc;l=4754
        internalFormat_ = KR_GL_DEPTH24_STENCIL8;
      } else if (internalFormat_ == KR_GL_DEPTH_COMPONENT16) {
        // convert gl.DEPTH_COMPONENT16 to DEPTH_COMPONENT24
        // https://source.chromium.org/chromium/chromium/src/+/main:gpu/command_buffer/service/renderbuffer_manager.cc;l=319;drc=49d15ccc40feff608d1319c517bf63ab6a646797
        internalFormat_ = KR_GL_DEPTH_COMPONENT24;
      }
      GL::RenderbufferStorage(target_, internalFormat_, width_, height_);
    }
    GLenum target_;
    GLenum internalFormat_;
    GLsizei width_, height_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->internalFormat_ = internalformat;
  cmd->width_ = width;
  cmd->height_ = height;
}

void WebGLRenderingContext::SampleCoverage(GLfloat value, bool invert) {
  DCHECK(Recorder());

  // logic check
  // coverage value clamped to the range [0,1]. The default value is 1.0.
  if (value < 0 || value > 1.0) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "SampleCoverage", "invalid value");
    return;
  }
  local_cache_.sample_coverage_value_ = value;
  local_cache_.sample_coverage_invert_ = invert;

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::SampleCoverage(value_, invert_);
    }
    GLfloat value_;
    bool invert_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->value_ = value;
  cmd->invert_ = invert;
}

void WebGLRenderingContext::Scissor(GLint x, GLint y, GLsizei width,
                                    GLsizei height) {
  DCHECK(Recorder());

  // logic check
  if ((width < 0) || (height < 0)) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "SampleCoverage", "invalid size");
    return;
  }

  // save cache
  local_cache_.scissor_[0] = x;
  local_cache_.scissor_[1] = y;
  local_cache_.scissor_[2] = width;
  local_cache_.scissor_[3] = height;

  // commit command
  class Runnable {
   public:
    Runnable(int32_t x, int32_t y, int32_t width, int32_t height)
        : x_(x), y_(y), width_(width), height_(height) {}
    void Run(command_buffer::RunnableBuffer *buffer) {
      GL::Scissor(x_, y_, width_, height_);
    }

   private:
    int32_t x_, y_, width_, height_;
  };
  Recorder()->Alloc<Runnable>(x, y, width, height);
}

/*
 * validate the stencil func is one of the enumeration
 * reference by StencilFunc StencilFuncSeparate TexParameteri
 */
bool WebGLRenderingContext::ValidateStencilFuncEnum(const char *func_name,
                                                    GLenum func) {
  switch (func) {
    case KR_GL_NEVER:
    case KR_GL_LESS:
    case KR_GL_EQUAL:
    case KR_GL_LEQUAL:
    case KR_GL_GREATER:
    case KR_GL_NOTEQUAL:
    case KR_GL_GEQUAL:
    case KR_GL_ALWAYS:
      return true;
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, func_name, "invalid func");
      return false;
  }
}

void WebGLRenderingContext::StencilFunc(GLenum func, GLint ref, GLuint mask) {
  DCHECK(Recorder());
  // logic check
  if (!ValidateStencilFuncEnum("StencilFunc", func)) {
    return;
  }

  if (ref < 0) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "stencilFunc", "invalid ref");
    return;
  }

  local_cache_.front_face_stencil_func_ = func;
  local_cache_.front_face_stencil_func_ref_ = ref;
  local_cache_.front_face_stencil_func_mask_ = mask;
  local_cache_.back_face_stencil_func_ = func;
  local_cache_.back_face_stencil_func_ref_ = ref;
  local_cache_.back_face_stencil_func_mask_ = mask;

  // commit command
  class Runnable {
   public:
    Runnable(uint32_t func, int ref, uint32_t mask)
        : func_(func), ref_(ref), mask_(mask) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::StencilFunc(func_, ref_, mask_);
    }

   private:
    uint32_t func_;
    int ref_;
    uint32_t mask_;
  };
  Recorder()->Alloc<Runnable>(func, ref, mask);
}

/**
 * owned by Zhongyue
 * The face value should be one the following enumeration.
 * referred by StencilFuncSeparate StencilOpSeparate CullFace
 */

bool WebGLRenderingContext::ValidateFaceEnum(const char *func_name,
                                             GLenum face) {
  switch (face) {
    case KR_GL_FRONT:
    case KR_GL_BACK:
    case KR_GL_FRONT_AND_BACK:
      return true;
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, func_name, "invalid func");
      return false;
  }
}

void WebGLRenderingContext::StencilFuncSeparate(GLenum face, GLenum func,
                                                GLint ref, GLuint mask) {
  DCHECK(Recorder());
  if (!ValidateStencilFuncEnum("StencilFuncSeparate", func) ||
      !ValidateFaceEnum("StencilFuncSeparate", face)) {
    return;
  }
  if (ref < 0) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "stencilFuncSeparate",
                      "invalid ref");
    return;
  }

  if (face == KR_GL_FRONT || face == KR_GL_FRONT_AND_BACK) {
    local_cache_.front_face_stencil_func_ = func;
    local_cache_.front_face_stencil_func_ref_ = ref;
    local_cache_.front_face_stencil_func_mask_ = mask;
  }
  if (face == KR_GL_BACK || face == KR_GL_FRONT_AND_BACK) {
    local_cache_.back_face_stencil_func_ = func;
    local_cache_.back_face_stencil_func_ref_ = ref;
    local_cache_.back_face_stencil_func_mask_ = mask;
  }

  // commit command
  class Runnable {
   public:
    Runnable(uint32_t face, uint32_t func, int32_t ref, uint32_t mask)
        : face_(face), func_(func), ref_(ref), mask_(mask) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::StencilFuncSeparate(face_, func_, ref_, mask_);
    }

   private:
    uint32_t face_;
    uint32_t func_;
    int32_t ref_;
    uint32_t mask_;
  };
  Recorder()->Alloc<Runnable>(face, func, ref, mask);
}

void WebGLRenderingContext::StencilMask(GLuint mask) {
  DCHECK(Recorder());

  // logic check
  local_cache_.stencil_front_mask_ = mask;
  local_cache_.stencil_back_mask_ = mask;

  // commit command
  class Runnable {
   public:
    Runnable(uint32_t mask) : mask_(mask) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::StencilMask(mask_);
    }

   private:
    uint32_t mask_;
  };
  Recorder()->Alloc<Runnable>(mask);
}

void WebGLRenderingContext::StencilMaskSeparate(GLenum face, GLuint mask) {
  DCHECK(Recorder());

  // logic check
  if (!ValidateFaceEnum("StencilMaskSeparate", face)) {
    return;
  }

  if (face == KR_GL_FRONT_FACE) {
    local_cache_.stencil_front_mask_ = mask;
  } else {
    local_cache_.stencil_back_mask_ = mask;
  }

  // commit command
  class Runnable {
   public:
    Runnable(uint32_t face, uint32_t mask) : face_(face), mask_(mask) {}
    void Run(command_buffer::RunnableBuffer *buffer) {
      GL::StencilMaskSeparate(face_, mask_);
    }

   private:
    uint32_t face_;
    uint32_t mask_;
  };
  Recorder()->Alloc<Runnable>(face, mask);
}

void WebGLRenderingContext::StencilOp(GLenum fail, GLenum zfail, GLenum zpass) {
  DCHECK(Recorder());

  // logic check
  local_cache_.back_stencil_op_fail_ = fail;
  local_cache_.back_stencil_op_z_fail_ = zfail;
  local_cache_.back_stencil_op_z_pass_ = zpass;
  local_cache_.front_stencil_op_fail_ = fail;
  local_cache_.front_stencil_op_z_fail_ = zfail;
  local_cache_.front_stencil_op_z_pass_ = zpass;

  // commit command
  class Runnable {
   public:
    Runnable(uint32_t fail, uint32_t zfail, uint32_t zpass)
        : fail_(fail), zfail_(zfail), zpass_(zpass) {}
    void Run(command_buffer::RunnableBuffer *buffer) {
      GL::StencilOp(fail_, zfail_, zpass_);
    }

   private:
    uint32_t fail_;
    uint32_t zfail_;
    uint32_t zpass_;
  };
  Recorder()->Alloc<Runnable>(fail, zfail, zpass);
}

void WebGLRenderingContext::StencilOpSeparate(GLenum face, GLenum fail,
                                              GLenum zfail, GLenum zpass) {
  DCHECK(Recorder());
  // logic check
  if (!ValidateFaceEnum("StencilOpSeparate", face)) {
    return;
  }

  if (face == KR_GL_FRONT || face == KR_GL_FRONT_AND_BACK) {
    local_cache_.front_stencil_op_fail_ = fail;
    local_cache_.front_stencil_op_z_fail_ = zfail;
    local_cache_.front_stencil_op_z_pass_ = zpass;
  }

  if (face == KR_GL_BACK || face == KR_GL_FRONT_AND_BACK) {
    local_cache_.back_stencil_op_fail_ = fail;
    local_cache_.back_stencil_op_z_fail_ = zfail;
    local_cache_.back_stencil_op_z_pass_ = zpass;
  }

  // commit command
  class Runnable {
   public:
    Runnable(uint32_t face, uint32_t fail, uint32_t zfail, uint32_t zpass)
        : face_(face), fail_(fail), zfail_(zfail), zpass_(zpass) {}
    void Run(command_buffer::RunnableBuffer *buffer) {
      GL::StencilOpSeparate(face_, fail_, zfail_, zpass_);
    }

   private:
    uint32_t face_;
    uint32_t fail_;
    uint32_t zfail_;
    uint32_t zpass_;
  };
  Recorder()->Alloc<Runnable>(face, fail, zfail, zpass);
}

void WebGLRenderingContext::TexParameterf(GLenum target, GLenum pname,
                                          GLfloat param) {
  DCHECK(Recorder());

  // logic check
  WebGLTexture *texture =
      ValidateTexture2DBinding("TexParameterf", target, false);

  if (!texture) {
    return;
  }

  switch (pname) {
    case KR_GL_TEXTURE_MAX_LOD:
      param = param > 1000 ? 1000 : param;
      texture->max_lod_ = param;
      break;
    case KR_GL_TEXTURE_MIN_LOD:
      param = param < -1000 ? -1000 : param;
      texture->min_lod_ = param;
      break;
    case KR_GL_TEXTURE_MAG_FILTER:
    case KR_GL_TEXTURE_MIN_FILTER:
    case KR_GL_TEXTURE_WRAP_S:
    case KR_GL_TEXTURE_WRAP_T:
      break;
    case GL_TEXTURE_MAX_ANISOTROPY_EXT:
      if (device_attributes_.ExtensionEnabled(
              "EXT_texture_filter_anisotropic")) {
        param = param > device_attributes_.max_texture_max_anisotropy_
                    ? device_attributes_.max_texture_max_anisotropy_
                    : param;
        texture->max_anisotropy_ext_ = param;
        break;
      }
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "TexParameterf", "invalid pname");
      return;
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::TexParameterf(target_, pname_, param_);
    }
    uint32_t target_;
    uint32_t pname_;
    GLfloat param_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->pname_ = pname;
  cmd->param_ = param;
}

void WebGLRenderingContext::TexParameteri(GLenum target, GLenum pname,
                                          GLint param) {
  DCHECK(Recorder());

  // logic check
  WebGLTexture *texture =
      ValidateTexture2DBinding("TexParameteri", target, false);

  if (!texture) {
    return;
  }

  switch (pname) {
    case KR_GL_TEXTURE_MAG_FILTER:
      if (KR_GL_NEAREST != param && KR_GL_LINEAR != param) {
        SynthesizeGLError(KR_GL_INVALID_ENUM, "TexParameteri", "invalid param");
        return;
      }
      texture->mag_filter_ = param;
      break;
    case KR_GL_TEXTURE_MIN_FILTER:
      if (param != KR_GL_NEAREST && param != KR_GL_LINEAR &&
          param != KR_GL_NEAREST_MIPMAP_NEAREST &&
          param != KR_GL_LINEAR_MIPMAP_NEAREST &&
          param != KR_GL_NEAREST_MIPMAP_LINEAR &&
          param != KR_GL_LINEAR_MIPMAP_LINEAR) {
        SynthesizeGLError(KR_GL_INVALID_ENUM, "TexParameteri", "invalid param");
        return;
      }
      texture->min_filter_ = param;
      break;
    case KR_GL_TEXTURE_WRAP_S:
      if (param != KR_GL_REPEAT && param != KR_GL_CLAMP_TO_EDGE &&
          param != KR_GL_MIRRORED_REPEAT) {
        SynthesizeGLError(KR_GL_INVALID_ENUM, "TexParameteri", "invalid param");
        return;
      }
      texture->wrap_s_ = param;
      break;
    case KR_GL_TEXTURE_WRAP_T:
      if (param != KR_GL_REPEAT && param != KR_GL_CLAMP_TO_EDGE &&
          param != KR_GL_MIRRORED_REPEAT) {
        SynthesizeGLError(KR_GL_INVALID_ENUM, "TexParameteri", "invalid param");
        return;
      }
      texture->wrap_t_ = param;
      break;
    case KR_GL_TEXTURE_WRAP_R:
      if (param != KR_GL_REPEAT && param != KR_GL_CLAMP_TO_EDGE &&
          param != KR_GL_MIRRORED_REPEAT) {
        SynthesizeGLError(KR_GL_INVALID_ENUM, "TexParameteri", "invalid param");
        return;
      }
      texture->wrap_r_ = param;
      break;
    case KR_GL_TEXTURE_BASE_LEVEL:
      texture->base_level_ = param;
      break;
    case KR_GL_TEXTURE_MAX_LEVEL:
      texture->max_level_ = param;
      break;
    case KR_GL_TEXTURE_COMPARE_FUNC:
      if (!ValidateStencilFuncEnum("TexParameteri", param)) {
        return;
      }
      texture->compare_func_ = param;
      break;
    case KR_GL_TEXTURE_COMPARE_MODE:
      if (param != KR_GL_COMPARE_REF_TO_TEXTURE && param != KR_GL_NONE) {
        SynthesizeGLError(KR_GL_INVALID_ENUM, "texParameteri", "invalid param");
        return;
      }
      texture->compare_mode_ = param;
      break;
    case GL_TEXTURE_MAX_ANISOTROPY_EXT:
      if (device_attributes_.ExtensionEnabled(
              "EXT_texture_filter_anisotropic")) {
        param = param > device_attributes_.max_texture_max_anisotropy_
                    ? device_attributes_.max_texture_max_anisotropy_
                    : param;
        texture->max_anisotropy_ext_ = param;
        break;
      }
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "TexParameteri", "invalid pname");
      return;
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::TexParameteri(target_, pname_, param_);
    }
    uint32_t target_;
    uint32_t pname_;
    int param_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->pname_ = pname;
  cmd->param_ = param;
}

void WebGLRenderingContext::InitNewContext() {
  local_cache_.Init(this);
  auto *vao = new WebGLVertexArrayObjectOES(
      this, WebGLVertexArrayObjectOES::kVaoTypeDefault);

  local_cache_.default_vertex_array_object_ = vao;

  // init viewport
  local_cache_.viewport_[2] = GetDrawingBufferWidth();
  local_cache_.viewport_[3] = GetDrawingBufferHeight();

  // init scissor box
  local_cache_.scissor_[2] = local_cache_.viewport_[2];
  local_cache_.scissor_[3] = local_cache_.viewport_[3];
}

bool WebGLRenderingContext::CheckAttrBeforeDraw() const {
  if (!local_cache_.current_program_) {
    return false;
  }
  auto shader_status = local_cache_.current_program_->GetShaderStatus();
  size_t size = shader_status->attribs.size();
  for (uint32_t i = 0; i < size; ++i) {
    auto location = shader_status->attribs[i].location_;
    if (location < 0 || location > 63) {
      return false;
    }
    auto &attr_pointer =
        local_cache_.ValidVertexArrayObject()->GetAttrPointerRef(location);

    uint32_t type =
        (attr_pointer.array_buffer_ && attr_pointer.enable_)
            ? attr_pointer.array_elem_type_
            : local_cache_.vertex_attrib_values_[location].attr_type_;
    auto shader_attr_type = shader_status->attribs[i].type_;
    switch (type) {
      case KR_GL_FLOAT:
        if (shader_attr_type != KR_GL_FLOAT &&
            shader_attr_type != KR_GL_FLOAT_VEC2 &&
            shader_attr_type != KR_GL_FLOAT_VEC3 &&
            shader_attr_type != KR_GL_FLOAT_VEC4 &&
            shader_attr_type != GL_FLOAT_MAT2 &&
            shader_attr_type != GL_FLOAT_MAT3 &&
            shader_attr_type != GL_FLOAT_MAT4) {
          return false;
        }
        break;
      case KR_GL_INT:
        if (shader_attr_type != KR_GL_INT &&
            shader_attr_type != KR_GL_INT_VEC2 &&
            shader_attr_type != KR_GL_INT_VEC3 &&
            shader_attr_type != KR_GL_INT_VEC4) {
          return false;
        }
        break;
      case KR_GL_UNSIGNED_INT:
        if (shader_attr_type != KR_GL_UNSIGNED_INT &&
            shader_attr_type != KR_GL_UNSIGNED_INT_VEC2 &&
            shader_attr_type != KR_GL_UNSIGNED_INT_VEC3 &&
            shader_attr_type != KR_GL_UNSIGNED_INT_VEC4) {
          return false;
        }
        break;
      case KR_GL_BYTE:
      case KR_GL_UNSIGNED_BYTE:
      case KR_GL_SHORT:
      case KR_GL_UNSIGNED_SHORT:
      case KR_GL_HALF_FLOAT:
        break;
      default:
        return false;
    }
  }
  return true;
}

bool WebGLRenderingContext::CheckDivisorBeforeDraw() const {
  if (local_cache_.vertex_attrib_divisors_.size() == 0) {
    return true;
  }

  auto &attribs = local_cache_.current_program_->GetShaderStatus()->attribs;
  for (auto it = attribs.begin(); it < attribs.end(); it++) {
    if (local_cache_.vertex_attrib_divisors_[it->location_] == 0) {
      return true;
    }
  }
  return false;
}

WebGLFramebuffer *WebGLRenderingContext::ValidateFramebufferBinding(
    const uint32_t target) {
  WebGLFramebuffer *framebuffer = nullptr;
  switch (target) {
    case KR_GL_FRAMEBUFFER:
      framebuffer = local_cache_.draw_framebuffer_bind_;
      break;
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "ValidateFramebufferBinding",
                        "invalid target");
      return nullptr;
  }
  if (!framebuffer || framebuffer->MarkedForDeletion()) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, "ValidateFramebufferBinding",
                      "invalid framebuffer");
    return nullptr;
  }
  return framebuffer;
}

GLenum WebGLRenderingContext::ExtractTypeFromStorageFormat(
    GLenum internalformat) {
  switch (internalformat) {
    case KR_GL_R8:
      return KR_GL_UNSIGNED_BYTE;
    case KR_GL_R16F:
      return KR_GL_HALF_FLOAT;
    case KR_GL_R32F:
      return KR_GL_FLOAT;
    case KR_GL_R8UI:
      return KR_GL_UNSIGNED_BYTE;
    case KR_GL_R8I:
      return KR_GL_BYTE;
    case KR_GL_R16UI:
      return KR_GL_UNSIGNED_SHORT;
    case KR_GL_R16I:
      return KR_GL_SHORT;
    case KR_GL_R32UI:
      return KR_GL_UNSIGNED_INT;
    case KR_GL_R32I:
      return KR_GL_INT;
    case KR_GL_RG8:
      return KR_GL_UNSIGNED_BYTE;
    case KR_GL_RG16F:
      return KR_GL_HALF_FLOAT;
    case KR_GL_RG32F:
      return KR_GL_FLOAT;
    case KR_GL_RG8UI:
      return KR_GL_UNSIGNED_BYTE;
    case KR_GL_RG8I:
      return KR_GL_BYTE;
    case KR_GL_RG16UI:
      return KR_GL_UNSIGNED_SHORT;
    case KR_GL_RG16I:
      return KR_GL_SHORT;
    case KR_GL_RG32UI:
      return KR_GL_UNSIGNED_INT;
    case KR_GL_RG32I:
      return KR_GL_INT;
    case KR_GL_RGB8:
      return KR_GL_UNSIGNED_BYTE;
    case KR_GL_R11F_G11F_B10F:
      return KR_GL_UNSIGNED_INT_10F_11F_11F_REV;
    case KR_GL_RGB565:
      return KR_GL_UNSIGNED_SHORT_5_6_5;
    case KR_GL_RGBA8:
      return KR_GL_UNSIGNED_BYTE;
    case KR_GL_SRGB8_ALPHA8:
      return KR_GL_UNSIGNED_BYTE;
    case KR_GL_RGBA4:
      return KR_GL_UNSIGNED_SHORT_4_4_4_4;
    case KR_GL_RGB10_A2:
      return KR_GL_UNSIGNED_INT_2_10_10_10_REV;
    case KR_GL_RGB5_A1:
      return KR_GL_UNSIGNED_SHORT_5_5_5_1;
    case KR_GL_RGBA16F:
      return KR_GL_HALF_FLOAT;
    case KR_GL_RGBA32F:
      return KR_GL_FLOAT;
    case KR_GL_RGBA8UI:
      return KR_GL_UNSIGNED_BYTE;
    case KR_GL_RGBA8I:
      return KR_GL_BYTE;
    case KR_GL_RGB10_A2UI:
      return KR_GL_UNSIGNED_INT_2_10_10_10_REV;
    case KR_GL_RGBA16UI:
      return KR_GL_UNSIGNED_SHORT;
    case KR_GL_RGBA16I:
      return KR_GL_SHORT;
    case KR_GL_RGBA32I:
      return KR_GL_INT;
    case KR_GL_RGBA32UI:
      return KR_GL_UNSIGNED_INT;
    case KR_GL_DEPTH_COMPONENT16:
      return KR_GL_UNSIGNED_SHORT;
    case KR_GL_DEPTH_COMPONENT24:
      return KR_GL_UNSIGNED_INT;
    case KR_GL_DEPTH_COMPONENT32F:
      return KR_GL_FLOAT;
    case KR_GL_DEPTH24_STENCIL8:
      return KR_GL_UNSIGNED_INT_24_8;
    case KR_GL_DEPTH32F_STENCIL8:
      return KR_GL_FLOAT_32_UNSIGNED_INT_24_8_REV;
    case KR_GL_STENCIL_INDEX8:
    case KR_GL_DEPTH_STENCIL:
      return KR_GL_UNSIGNED_INT_24_8;
    default:
      return KR_GL_NONE;
  }
}

uint32_t WebGLRenderingContext::ComputeBytesPerPixelForReadPixels(GLenum format,
                                                                  GLenum type) {
  uint32_t elem_num = 0, size_in_byte = 0;

  // first check valid webgl 1
  if (format != KR_GL_ALPHA && format != KR_GL_RGB && format != KR_GL_RGBA) {
    SynthesizeGLError(GL_INVALID_ENUM, "ComputeBytesPerPixelForReadPixels",
                      "invalid format");
    return 0;
  }

  if (type != KR_GL_UNSIGNED_BYTE && type != KR_GL_UNSIGNED_SHORT_5_6_5 &&
      type != KR_GL_UNSIGNED_SHORT_4_4_4_4 &&
      type != KR_GL_UNSIGNED_SHORT_5_5_5_1 && type != KR_GL_FLOAT) {
    SynthesizeGLError(KR_GL_INVALID_ENUM, "ComputeBytesPerPixelForReadPixels",
                      "invalid type");
    return 0;
  }

  switch (format) {
    case KR_GL_RGBA:
    case KR_GL_RGBA_INTEGER:
      elem_num = 4;
      break;
    case KR_GL_RGB:
    case KR_GL_RGB_INTEGER:
      elem_num = 3;
      break;
    case KR_GL_RG:
    case KR_GL_RG_INTEGER:
      elem_num = 2;
      break;
    case KR_GL_ALPHA:
    case KR_GL_RED:
    case KR_GL_RED_INTEGER:
      elem_num = 1;
      break;
    default:
      SynthesizeGLError(GL_INVALID_ENUM, "ComputeBytesPerPixelForReadPixels",
                        "invalid format");
      return 0;
  }
  switch (type) {
    case KR_GL_UNSIGNED_BYTE:
    case KR_GL_BYTE:
      size_in_byte = 1;
      break;
    case KR_GL_FLOAT:
    case KR_GL_INT:
    case KR_GL_UNSIGNED_INT:
      size_in_byte = 4;
      break;
    case KR_GL_UNSIGNED_INT_2_10_10_10_REV: {
      if (format != KR_GL_RGBA && format != KR_GL_RGBA_INTEGER) {
        SynthesizeGLError(KR_GL_INVALID_OPERATION,
                          "ComputeBytesPerPixelForReadPixels",
                          "type is GL_UNSIGNED_INT_2_10_10_10_REV but format "
                          "is not RGBA or RGBA_INTEGER");
        return 0;
      }
      elem_num = 1;
      size_in_byte = 4;
      break;
    }
    case KR_GL_UNSIGNED_INT_10F_11F_11F_REV: {
      if (format != KR_GL_RGB && format != KR_GL_RGB_INTEGER) {
        SynthesizeGLError(KR_GL_INVALID_OPERATION,
                          "ComputeBytesPerPixelForReadPixels",
                          "type is GL_UNSIGNED_INT_10F_11F_11F_REV but format "
                          "is not RGB or RGB_INTEGER");
        return 0;
      }
      elem_num = 1;
      size_in_byte = 4;
      break;
    }
    case KR_GL_UNSIGNED_INT_5_9_9_9_REV: {
      if (format != KR_GL_RGBA && format != KR_GL_RGBA_INTEGER) {
        SynthesizeGLError(KR_GL_INVALID_OPERATION,
                          "ComputeBytesPerPixelForReadPixels",
                          "type is GL_UNSIGNED_INT_5_9_9_9_REV but format is "
                          "not RGBA or RGBA_INTEGER");
        return 0;
      }
      elem_num = 1;
      size_in_byte = 4;
      break;
    }
    case KR_GL_UNSIGNED_SHORT_5_6_5: {
      if (format != KR_GL_RGB) {
        SynthesizeGLError(
            KR_GL_INVALID_OPERATION, "ComputeBytesPerPixelForReadPixels",
            "type is GL_UNSIGNED_SHORT_5_6_5 but format is not RGBA");
        return 0;
      }
      elem_num = 1;
      size_in_byte = 2;
      break;
    }
    case KR_GL_UNSIGNED_SHORT_4_4_4_4: {
      if (format != KR_GL_RGBA) {
        SynthesizeGLError(
            KR_GL_INVALID_OPERATION, "ComputeBytesPerPixelForReadPixels",
            "type is GL_UNSIGNED_SHORT_4_4_4_4 but format is not RGBA");
        return 0;
      }
      elem_num = 1;
      size_in_byte = 2;
      break;
    }
    case KR_GL_UNSIGNED_SHORT_5_5_5_1: {
      if (format != KR_GL_RGBA) {
        SynthesizeGLError(
            KR_GL_INVALID_OPERATION, "ComputeBytesPerPixelForReadPixels",
            "type is GL_UNSIGNED_SHORT_5_5_5_1 but format is not RGBA");
        return 0;
      }
      elem_num = 1;
      size_in_byte = 2;
      break;
    }
    case KR_GL_HALF_FLOAT:
    case KR_GL_SHORT:
    case KR_GL_UNSIGNED_SHORT:
      size_in_byte = 2;
      break;
    default:
      SynthesizeGLError(KR_GL_INVALID_ENUM, "ComputeBytesPerPixelForReadPixels",
                        "invalid type");
      return 0;
  }
  return elem_num * size_in_byte;
}

bool WebGLRenderingContext::ValidateReadPixelsFuncParameters(
    const char *func_name, uint32_t width, uint32_t height,
    uint32_t bytes_per_pixel, int64_t buffer_size) {
  // check pack params
  if (local_cache_.pack_skip_pixels_ + width >
      (local_cache_.pack_row_length_ ? local_cache_.pack_row_length_ : width)) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, func_name, "invalid width");
    return false;
  }
  uint32_t total_bytes_required = 0, total_skip_bytes = 0;
  auto err = ComputeImageSizeInBytes(bytes_per_pixel, width, height, 1, true,
                                     &total_bytes_required, nullptr,
                                     &total_skip_bytes);
  if (err != KR_GL_NO_ERROR) {
    SynthesizeGLError(err, func_name, "");
    return false;
  }

  if (buffer_size <
      static_cast<int64_t>(total_bytes_required + total_skip_bytes)) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, func_name, "not enough buffer");
    return false;
  }
  return true;
}

uint32_t WebGLRenderingContext::ComputeImageSizeInBytes(
    int64_t bytes_per_pixel, uint32_t width, uint32_t height, uint32_t depth,
    bool is_pack, uint32_t *image_size_in_bytes, uint32_t *padding_in_bytes,
    uint32_t *skip_size_in_bytes) {
#define CheckFitUint32(x)                                                      \
  if (x < 0 || x > static_cast<int64_t>(std::numeric_limits<uint32_t>::max())) \
    return KR_GL_INVALID_VALUE;

  if (width < 0 || height < 0 || depth < 0) return KR_GL_INVALID_VALUE;
  if (!width || !height || !depth) {
    *image_size_in_bytes = 0;
    if (padding_in_bytes) *padding_in_bytes = 0;
    if (skip_size_in_bytes) *skip_size_in_bytes = 0;
    return KR_GL_NO_ERROR;
  }

  int64_t pixel_row_length =
      is_pack ? local_cache_.pack_row_length_ : local_cache_.unpack_row_length_;
  int64_t pixel_image_height = is_pack ? 0 : local_cache_.unpack_row_length_;
  int64_t pixel_skip_pixels = is_pack ? local_cache_.pack_skip_pixels_
                                      : local_cache_.unpack_skip_pixels_;
  int64_t pixel_skip_rows =
      is_pack ? local_cache_.pack_skip_rows_ : local_cache_.unpack_skip_rows_;
  int64_t pixel_alignment =
      is_pack ? local_cache_.pack_alignment_ : local_cache_.unpack_alignment_;
  int64_t pixel_skip_images = is_pack ? 0 : local_cache_.unpack_skip_images_;

  int64_t row_length = pixel_row_length > 0 ? pixel_row_length : width;
  int64_t image_height = pixel_image_height > 0 ? pixel_image_height : height;

  //  uint32_t bytes_per_component, components_per_pixel;
  int64_t checked_value = row_length * bytes_per_pixel;
  CheckFitUint32(checked_value);

  uint32_t last_row_size;
  if (pixel_row_length != width) {
    int64_t tmp = static_cast<int64_t>(width) * bytes_per_pixel;
    CheckFitUint32(tmp);
    last_row_size = static_cast<uint32_t>(tmp);
  } else {
    last_row_size = static_cast<uint32_t>(checked_value);
  }

  int64_t padding = 0;
  int64_t checked_residual = checked_value;
  checked_residual %= static_cast<int64_t>(pixel_alignment);

  if (checked_residual) {
    padding = static_cast<int64_t>(pixel_alignment) - checked_residual;
    checked_value += padding;
  }
  CheckFitUint32(checked_value);
  int64_t padded_row_size = checked_value;

  int64_t rows = image_height * (depth - 1);
  // Last image is not affected by IMAGE_HEIGHT parameter.
  rows += static_cast<int64_t>(height);
  CheckFitUint32(rows);
  checked_value *= (rows - 1);
  // Last row is not affected by ROW_LENGTH parameter.
  checked_value += last_row_size;
  CheckFitUint32(checked_value);
  *image_size_in_bytes = static_cast<uint32_t>(checked_value);
  if (padding_in_bytes) *padding_in_bytes = static_cast<uint32_t>(padding);

  int64_t skip_size = 0;
  if (pixel_skip_images > 0) {
    int64_t tmp = padded_row_size * image_height * pixel_skip_images;
    CheckFitUint32(tmp);
    skip_size += tmp;
  }
  if (pixel_skip_rows > 0) {
    int64_t tmp = padded_row_size * pixel_skip_rows;
    CheckFitUint32(tmp);
    skip_size += tmp;
  }
  if (pixel_skip_pixels > 0) {
    int64_t tmp = bytes_per_pixel * pixel_skip_pixels;
    CheckFitUint32(tmp);
    skip_size += tmp;
  }
  CheckFitUint32(skip_size);
  if (skip_size_in_bytes)
    *skip_size_in_bytes = static_cast<uint32_t>(skip_size);

  checked_value += skip_size;
  CheckFitUint32(checked_value);
  return KR_GL_NO_ERROR;
}

bool WebGLRenderingContext::ValidateUnpackParams(const char *func_name,
                                                 const uint32_t width) {
  const auto actul_width =
      local_cache_.unpack_row_length_ ? local_cache_.unpack_row_length_ : width;
  if (local_cache_.unpack_skip_pixels_ + width > actul_width) {
    SynthesizeGLError(KR_GL_INVALID_OPERATION, func_name, "invalid width");
    return false;
  }
  return true;
}

uint32_t WebGLRenderingContext::ComputeNeedSize2D(uint32_t bytesPerPixel,
                                                  uint32_t w, uint32_t h) {
  uint32_t actualWidth = local_cache_.unpack_row_length_ == 0
                             ? w
                             : local_cache_.unpack_row_length_;
  uint32_t padding =
      (bytesPerPixel * actualWidth) % local_cache_.unpack_alignment_;
  padding = padding > 0 ? local_cache_.unpack_alignment_ - padding : padding;
  uint32_t bytesPerRow = actualWidth * bytesPerPixel + padding;
  uint32_t bytesLastRow = bytesPerPixel * w;
  uint32_t size = bytesPerRow * (h - 1) + bytesLastRow;
  uint32_t skipSize = 0;
  if (local_cache_.unpack_skip_pixels_ > 0)
    skipSize += bytesPerPixel * local_cache_.unpack_skip_pixels_;
  if (local_cache_.unpack_skip_rows_ > 0)
    skipSize += bytesPerRow * local_cache_.unpack_skip_rows_;
  return size + skipSize;
}

void WebGLRenderingContext::FindNewMaxNonDefaultTextureUnit() {
  // Trace backwards from the current max to find the new max non-default
  // texture unit
  uint32_t start_index =
      local_cache_.one_plus_max_non_default_texture_unit_ - 1;
  for (int i = start_index; i >= 0; --i) {
    if (local_cache_.texture_2d_bind_[i] ||
        local_cache_.texture_cube_bind_[i]) {
      local_cache_.one_plus_max_non_default_texture_unit_ = i + 1;
      return;
    }
  }
  local_cache_.one_plus_max_non_default_texture_unit_ = 0;
}

void WebGLRenderingContext::Present(bool is_sync) {
  // when enter webgl impl, all client side command buffer is flushed, so we do
  // not need to check to improve performance.
  element_->ResourceProvider()->FlushIgnoreClientSide(false, is_sync, true);
}

void WebGLRenderingContext::Viewport(GLint x, GLint y, GLsizei width,
                                     GLsizei height) {
  if (width < 0 || height < 0) {
    SynthesizeGLError(KR_GL_INVALID_VALUE, "viewport", "invalid size");
    return;
  }

  // save cache
  local_cache_.viewport_[0] = x;
  local_cache_.viewport_[1] = y;
  local_cache_.viewport_[2] = width;
  local_cache_.viewport_[3] = height;

  // commit command
  class Runnable {
   public:
    Runnable(int x, int y, int width, int height)
        : x_(x), y_(y), width_(width), height_(height) {}
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::Viewport(x_, y_, width_, height_);
    }

   private:
    int x_, y_;
    int width_;
    int height_;
  };
  Recorder()->Alloc<Runnable>(x, y, width, height);
}

namespace {

std::string GetErrorString(GLenum error) {
  switch (error) {
    case KR_GL_INVALID_ENUM:
      return "INVALID_ENUM";
    case KR_GL_INVALID_VALUE:
      return "INVALID_VALUE";
    case KR_GL_INVALID_OPERATION:
      return "INVALID_OPERATION";
    case KR_GL_OUT_OF_MEMORY:
      return "OUT_OF_MEMORY";
    case KR_GL_INVALID_FRAMEBUFFER_OPERATION:
      return "INVALID_FRAMEBUFFER_OPERATION";
      //    case GC3D_CONTEXT_LOST_WEBGL:
      //      return "CONTEXT_LOST_WEBGL";
    default:
      char buff[1024];
      snprintf(buff, sizeof(buff), "WebGL ERROR(0x%04X)", error);
      return std::string(buff);
  }
}

}  // namespace

void WebGLRenderingContext::SynthesizeGLError(
    GLenum error, const char *function_name, const char *description,
    ConsoleDisplayPreference display) {
  std::string error_type = GetErrorString(error);
  if (display == kDisplayInConsole) {
    KRYPTON_LOGW("WebGL: " << error_type << ": " << function_name << ": "
                           << description);
  }
  local_cache_.current_error_ = error;
}

bool WebGLRenderingContext::ValidateWebGLObject(WebGLObjectNG *object,
                                                GLenum *err,
                                                const char **err_msg) {
  DCHECK(object);
  if (object->MarkedForDeletion()) {
    *err = KR_GL_INVALID_OPERATION;
    *err_msg = "attempt to use a deleted object";
    return false;
  }
  if (!object->Validate(this)) {
    *err = KR_GL_INVALID_OPERATION;
    *err_msg = "object does not belong to this context";
    return false;
  }
  return true;
}

bool WebGLRenderingContext::ValidateNullableWebGLObject(WebGLObjectNG *object,
                                                        GLenum *err,
                                                        const char **err_msg) {
  if (!object) {
    // This differs in behavior to ValidateWebGLObject; null objects are allowed
    // in these entry points.
    return true;
  }
  return ValidateWebGLObject(object, err, err_msg);
}

bool WebGLRenderingContext::ValidateBufferBindTarget(GLenum target,
                                                     WebGLBuffer *buffer,
                                                     GLenum *err,
                                                     const char **err_msg) {
  if (target != KR_GL_ARRAY_BUFFER && target != KR_GL_ELEMENT_ARRAY_BUFFER) {
    *err = KR_GL_INVALID_ENUM;
    *err_msg = "invalid target";
    return false;
  }

  if (buffer) {
    auto &initial_target = buffer->initial_target_;
    if (initial_target != KR_GL_NONE) {
      if ((initial_target == KR_GL_ELEMENT_ARRAY_BUFFER &&
           target != KR_GL_ELEMENT_ARRAY_BUFFER) ||
          (initial_target != KR_GL_ELEMENT_ARRAY_BUFFER &&
           target == KR_GL_ELEMENT_ARRAY_BUFFER)) {
        *err = KR_GL_INVALID_OPERATION;
        *err_msg = "buffers can not be used with multiple targets";
        return false;
      }
    } else {
      initial_target = target;
    }
  }

  return true;
}

bool WebGLRenderingContext::ValidateFramebufferBindTarget(
    GLenum target, GLenum *err, const char **err_msg) {
  if (target != KR_GL_FRAMEBUFFER) {
    *err = KR_GL_INVALID_ENUM;
    *err_msg = "invalid target";
    return false;
  }
  return true;
}

bool WebGLRenderingContext::ValidateRenderbufferBindTarget(
    GLenum target, GLenum *err, const char **err_msg) {
  if (target != KR_GL_RENDERBUFFER) {
    *err = KR_GL_INVALID_ENUM;
    *err_msg = "invalid target";
    return false;
  }
  return true;
}

bool WebGLRenderingContext::ValidateTextureBindTarget(GLenum target,
                                                      GLenum *err,
                                                      const char **err_msg) {
  if (target != KR_GL_TEXTURE_2D && target != KR_GL_TEXTURE_CUBE_MAP &&
      target != GL_TEXTURE_2D_ARRAY) {
    *err = KR_GL_INVALID_ENUM;
    *err_msg = "invalid target";
    return false;
  }
  return true;
}

// validate the enum value for mode, called by
// BlendEquation, BlendEquationSeparate
bool WebGLRenderingContext::ValidateModeEnum(GLenum mode, GLenum *err,
                                             const char **err_msg) {
  switch (mode) {
    case KR_GL_FUNC_ADD:
    case KR_GL_FUNC_SUBTRACT:
    case KR_GL_FUNC_REVERSE_SUBTRACT:
    case GL_MIN_EXT:
    case GL_MAX_EXT:
      return true;
    default:
      *err = GL_INVALID_ENUM;
      *err_msg = "invalid blend mode";
  }
  return false;
}

// validate the factor range. Called by Blend Func and blend func saparate.
bool WebGLRenderingContext::ValidateFuncFactor(GLenum factor, GLenum *err,
                                               const char **err_msg) {
  if (factor != KR_GL_ZERO && factor != KR_GL_ONE &&
      !(factor >= KR_GL_SRC_COLOR && factor <= KR_GL_SRC_ALPHA_SATURATE) &&
      !(factor >= KR_GL_CONSTANT_COLOR &&
        factor <= KR_GL_ONE_MINUS_CONSTANT_ALPHA)) {
    *err = KR_GL_INVALID_ENUM;
    *err_msg = "invalid factor.";
    return false;
  }
  return true;
}

bool WebGLRenderingContext::ValidateLocationLength(const char *function_name,
                                                   const std::string &string) {
  const unsigned max_web_gl_location_length = 256;
  if (string.length() > max_web_gl_location_length) {
    SynthesizeGLError(GL_INVALID_VALUE, function_name, "location length > 256");
    return false;
  }
  return true;
}

bool WebGLRenderingContext::IsPrefixReserved(const std::string &name) {
  if (base::BeginsWith(name, "gl_") || base::BeginsWith(name, "webgl_") ||
      base::BeginsWith(name, "_webgl_")) {
    return true;
  }
  return false;
}

bool WebGLRenderingContext::DeleteObject(WebGLObjectNG *object) {
  if (!object) return false;
  if (!object->Validate(this)) {
    SynthesizeGLError(GL_INVALID_OPERATION, "delete",
                      "object does not belong to this context");
    return false;
  }
  if (object->MarkedForDeletion()) {
    // This is specified to be a no-op, including skipping all unbinding from
    // the context's attachment points that would otherwise happen.
    return false;
  }
  if (object->HasObject()) {
    // We need to pass in context here because we want
    // things in this context unbound.
    object->DeleteObject(Recorder());
  }
  return true;
}

unsigned WebGLRenderingContext::MaxVertexAttribs() {
  return device_attributes_.max_vertex_attribs_;
}

unsigned WebGLRenderingContext::MaxCombinedTextureImageUnits() {
  return device_attributes_.max_combined_texture_image_units_;
}

void WebGLRenderingContext::ResetUnpackParameters() {
  if (local_cache_.unpack_alignment_ != 1) {
    PixelStorei(Number::New(Env(), KR_GL_UNPACK_ALIGNMENT),
                Number::New(Env(), 1));
  }
}

void WebGLRenderingContext::RestoreUnpackParameters() {
  if (local_cache_.unpack_alignment_ != 1) {
    PixelStorei(Number::New(Env(), KR_GL_UNPACK_ALIGNMENT),
                Number::New(Env(), local_cache_.unpack_alignment_));
  }
}

bool WebGLRenderingContext::ValidateString(const char *function_name,
                                           const std::string &string) {
  for (size_t i = 0; i < string.length(); ++i) {
    if (!ValidateCharacter(string[i])) {
      SynthesizeGLError(GL_INVALID_VALUE, function_name, "string not ASCII");
      return false;
    }
  }
  return true;
}

bool WebGLRenderingContext::ValidateCharacter(unsigned char c) {
  // Printing characters are valid except " $ ` @ \ ' DEL.
  if (c >= 32 && c <= 126 && c != '"' && c != '$' && c != '`' && c != '@' &&
      c != '\\' && c != '\'')
    return true;
  // Horizontal tab, line feed, vertical tab, form feed, carriage return
  // are also valid.
  if (c >= 9 && c <= 13) return true;
  return false;
}

bool WebGLRenderingContext::ValidateValueFitNonNegInt32(
    const char *function_name, const char *param_name, int64_t value) {
  if (value < 0) {
    std::string error_msg = std::string(param_name) + " < 0";
    SynthesizeGLError(GL_INVALID_VALUE, function_name, error_msg.c_str());
    return false;
  }
  if (value > static_cast<int64_t>(std::numeric_limits<int>::max())) {
    std::string error_msg = std::string(param_name) + " more than 32-bit";
    SynthesizeGLError(GL_INVALID_OPERATION, function_name, error_msg.c_str());
    return false;
  }
  return true;
}

void WebGLRenderingContext::DidDraw() {
  element_->ResourceProvider()->SetNeedRedraw();
}

void WebGLRenderingContext::SetClientOnFrameCallback(
    std::function<void()> on_frame) {
  element_->ResourceProvider()->SetClientOnFrameCallback(std::move(on_frame));
}

GLenum WebGLRenderingContext::GetBoundReadFramebufferInternalFormat() const {
  if (local_cache_.read_framebuffer_bind_) {
    return local_cache_.read_framebuffer_bind_->GetAttachmentInternalFormat(
        local_cache_.read_buffer_mode_);
  }
  // default fbo
  return KR_GL_RGBA;
}

GLenum WebGLRenderingContext::GetBoundReadFramebufferTextureType() const {
  if (local_cache_.read_framebuffer_bind_) {
    return local_cache_.read_framebuffer_bind_->GetAttachmentType(
        local_cache_.read_buffer_mode_);
  }
  // default fbo
  return KR_GL_UNSIGNED_BYTE;
}

uint32_t WebGLRenderingContext::GetChannelsForFormat(int format) {
  switch (format) {
    case KR_GL_ALPHA:
      return kAlpha;
    case KR_GL_LUMINANCE:
      return kRGB;
    case KR_GL_LUMINANCE_ALPHA:
      return kRGBA;
    case KR_GL_RGB:
    case KR_GL_RGB565:
    case KR_GL_RGB16F_EXT:
    case KR_GL_SRGB8:
    case KR_GL_RGB8_SNORM:
    case KR_GL_R11F_G11F_B10F:
    case KR_GL_RGB9_E5:
    case KR_GL_RGB8UI:
    case KR_GL_RGB8I:
    case KR_GL_RGB16UI:
    case KR_GL_RGB16I:
    case KR_GL_RGB32UI:
    case KR_GL_RGB32I:
      return kRGB;
    case KR_GL_BGRA_EXT:
    case KR_GL_BGRA8_EXT:
    case KR_GL_RGBA16F_EXT:
    case KR_GL_RGBA:
    case KR_GL_RGBA4:
    case KR_GL_RGB5_A1:
    case KR_GL_RGBA8_SNORM:
    case KR_GL_RGB10_A2:
    case KR_GL_RGBA8UI:
    case KR_GL_RGBA8I:
    case KR_GL_RGB10_A2UI:
    case KR_GL_RGBA16UI:
    case KR_GL_RGBA16I:
    case KR_GL_RGBA32UI:
    case KR_GL_RGBA32I:
      return kRGBA;
    case KR_GL_DEPTH_COMPONENT16:
    case KR_GL_DEPTH_COMPONENT:
    case KR_GL_DEPTH_COMPONENT32F:
      return kDepth;
    case KR_GL_STENCIL_INDEX8:
      return kStencil;
    case KR_GL_DEPTH32F_STENCIL8:
      return kDepth | kStencil;
    case KR_GL_R8:
    case KR_GL_R8_SNORM:
    case KR_GL_R16F:
    case KR_GL_R32F:
    case KR_GL_R8UI:
    case KR_GL_R8I:
    case KR_GL_R16UI:
    case KR_GL_R16I:
    case KR_GL_R32UI:
    case KR_GL_R32I:
      return kRed;
    case KR_GL_RG8:
    case KR_GL_RG8_SNORM:
    case KR_GL_RG16F:
    case KR_GL_RG32F:
    case KR_GL_RG8UI:
    case KR_GL_RG8I:
    case KR_GL_RG16UI:
    case KR_GL_RG16I:
    case KR_GL_RG32UI:
    case KR_GL_RG32I:
      return kRed | kGreen;
    default:
      return 0x0000;
  }
}

/// extension ANGLE_instanced_arrays
void WebGLRenderingContext::DrawArraysInstancedANGLE(GLenum mode, GLint first,
                                                     GLsizei count,
                                                     GLsizei primcount) {
  DCHECK(Recorder());

  KRYPTON_ERROR_CHECK_IF_NEED {
    if (mode != KR_GL_TRIANGLES && mode != KR_GL_TRIANGLE_STRIP &&
        mode != KR_GL_TRIANGLE_FAN && mode != KR_GL_LINES &&
        mode != KR_GL_LINE_STRIP && mode != KR_GL_LINE_LOOP &&
        mode != KR_GL_POINTS) {
      SynthesizeGLError(KR_GL_INVALID_ENUM, "drawArraysInstancedANGLE",
                        "invalid mode");
      return;
    }
    if (first < 0 || count < 0) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "drawArraysInstancedANGLE",
                        "invalid first or count");
      return;
    }

    if (!local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawArraysInstancedANGLE",
                        "invalid state");
      return;
    }

    if (!CheckAttrBeforeDraw()) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawArraysInstancedANGLE",
                        "invalid state");
      return;
    }

    if (!local_cache_.ValidVertexArrayObject()
             ->IsAllEnabledAttribBufferBound()) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawArraysInstancedANGLE",
                        "invalid state");
      return;
    }

    if (!CheckDivisorBeforeDraw()) {
      SynthesizeGLError(
          KR_GL_INVALID_OPERATION, "drawArraysInstancedANGLE",
          " attempt to draw with all attributes having non-zero divisors");
      return;
    }
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::DrawArraysInstanced(mode, first, count, instancecount);
    }
    GLenum mode;
    GLint first;
    GLsizei count;
    GLsizei instancecount;
  };

  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->mode = mode;
  cmd->first = first;
  cmd->count = count;
  cmd->instancecount = primcount;

  DidDraw();
}

void WebGLRenderingContext::DrawElementsInstancedANGLE(GLenum mode,
                                                       GLsizei count,
                                                       GLenum type,
                                                       int64_t offset,
                                                       GLsizei primcount) {
  DCHECK(Recorder());

  KRYPTON_ERROR_CHECK_IF_NEED {
    if (mode != KR_GL_TRIANGLES && mode != KR_GL_TRIANGLE_STRIP &&
        mode != KR_GL_TRIANGLE_FAN && mode != KR_GL_LINES &&
        mode != KR_GL_LINE_STRIP && mode != KR_GL_LINE_LOOP &&
        mode != KR_GL_POINTS) {
      SynthesizeGLError(KR_GL_INVALID_ENUM, "drawElementsInstancedANGLE",
                        "invalid mode");
      return;
    }

    int size_in_byte = 0;
    switch (type) {
      case KR_GL_UNSIGNED_BYTE:
        size_in_byte = 1;
        break;
      case KR_GL_UNSIGNED_SHORT:
        size_in_byte = 2;
        break;
      case KR_GL_UNSIGNED_INT:
        size_in_byte = 4;
        break;
      default:
        SynthesizeGLError(KR_GL_INVALID_ENUM, "drawElementsInstancedANGLE",
                          "invalid type");
        return;
    }

    if (count < 0 || offset < 0) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "drawElementsInstancedANGLE",
                        "invalid count or offset");
      return;
    }

    if (!ValidateValueFitNonNegInt32("DrawElements", "offset", offset)) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "drawElementsInstancedANGLE",
                        "invalid  offset");
      return;
    }

    const auto &vao = local_cache_.ValidVertexArrayObject();
    const auto &ebo = vao->BoundElementArrayBuffer();
    if (!ebo || !vao->IsAllEnabledAttribBufferBound()) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawElementsInstancedANGLE",
                        "invalid state");
      return;
    }

    if (size_in_byte * count + offset > ebo->size_ ||
        offset % size_in_byte != 0) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawElementsInstancedANGLE",
                        "invalid state");
      return;
    }

    if (!CheckAttrBeforeDraw()) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawElementsInstancedANGLE",
                        "invalid state");
      return;
    }

    if (!local_cache_.current_program_) {
      SynthesizeGLError(KR_GL_INVALID_OPERATION, "drawElementsInstancedANGLE",
                        "invalid state");
      return;
    }

    if (!CheckDivisorBeforeDraw()) {
      SynthesizeGLError(
          KR_GL_INVALID_OPERATION, "drawElementsInstancedANGLE",
          "There must be at least one vertex attribute with a divisor of zero");
      return;
    }
  }

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::DrawElementsInstanced(mode, count, type, (void *)offset,
                                instancecount);
    }
    GLenum mode;
    GLsizei count;
    GLenum type;
    GLintptr offset;
    GLsizei instancecount;
  };

  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->mode = mode;
  cmd->count = count;
  cmd->type = type;
  cmd->offset = offset;
  cmd->instancecount = primcount;

  DidDraw();
}

void WebGLRenderingContext::VertexAttribDivisorANGLE(GLuint index,
                                                     GLuint divisor) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (index >= device_attributes_.max_vertex_attribs_) {
      SynthesizeGLError(KR_GL_INVALID_VALUE, "VertexAttribDivisorANGLE",
                        "index >= max_vertex_attribs");
      return;
    }
  }

  if (local_cache_.vertex_attrib_divisors_.size() !=
      device_attributes_.max_vertex_attribs_) {
    local_cache_.vertex_attrib_divisors_.resize(
        device_attributes_.max_vertex_attribs_, 0);
  }
  local_cache_.vertex_attrib_divisors_[index] = divisor;

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::VertexAttribDivisor(index, divisor);
    }
    GLuint index;
    GLuint divisor;
  };

  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->index = index;
  cmd->divisor = divisor;
}

/// extension OES_vertex_array_object
WebGLVertexArrayObjectOES *WebGLRenderingContext::CreateVertexArrayOES() {
  DCHECK(Recorder());
  return new WebGLVertexArrayObjectOES(this,
                                       WebGLVertexArrayObjectOES::kVaoTypeUser);
}

GLboolean WebGLRenderingContext::IsVertexArrayOES(
    WebGLVertexArrayObjectOES *arrayObject) {
  DCHECK(Recorder());

  if (!arrayObject || !arrayObject->Validate(this)) {
    return GL_FALSE;
  }
  if (arrayObject->MarkedForDeletion()) {
    return GL_FALSE;
  }
  if (!arrayObject->has_ever_been_bound_) {
    return GL_FALSE;
  }

  return GL_TRUE;
}

void WebGLRenderingContext::DeleteVertexArrayOES(
    WebGLVertexArrayObjectOES *arrayObject) {
  DCHECK(Recorder());

  if (!DeleteObject(arrayObject)) {
    return;
  }

  if (local_cache_.bound_vertex_array_object_ == arrayObject) {
    local_cache_.bound_vertex_array_object_ = nullptr;
  }
}

void WebGLRenderingContext::BindVertexArrayOES(
    WebGLVertexArrayObjectOES *arrayObject) {
  KRYPTON_ERROR_CHECK_IF_NEED {
    GLenum err;
    const char *err_msg;
    const char *func_name = "bindVertexArrayOES";
    if (!ValidateNullableWebGLObject(arrayObject, &err, &err_msg)) {
      SynthesizeGLError(err, func_name, err_msg);
      return;
    }
  }

  local_cache_.bound_vertex_array_object_ = arrayObject;
  if (arrayObject) {
    arrayObject->SetHasEverBeenBound();
  }

  DCHECK(Recorder());
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) const {
      GL::BindVertexArray(content_ ? content_->Get() : 0);
    }
    PuppetContent<uint32_t> *content_ = nullptr;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->content_ = arrayObject ? arrayObject->related_id_ : nullptr;
}

/// extension WEBGL_compressed_texture_astc
std::vector<std::string> WebGLRenderingContext::GetSupportedProfiles() {
  return device_attributes_.astc_support_profiles_;
}

}  // namespace canvas
}  // namespace lynx
