// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/gpu/gl/scoped_gl_error_check.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"
#include "canvas/gpu/gl_context.h"
#include "canvas/gpu/texture_shader.h"
#include "canvas/util/texture_format_convertor.h"
#include "canvas/util/texture_util.h"
#include "canvas/webgl/webgl_rendering_context.h"
#include "canvas_resource_provider_3d.h"
#include "config/config.h"
#include "scope_unpack_parameters_reset_restore.h"
#if ENABLE_KRYPTON_EFFECT
#include "effect/krypton_effect_helper.h"
#endif

namespace lynx {
namespace canvas {

WebGLTexture *WebGLRenderingContext::ValidateTexture2DBinding(
    const char *func_name, const uint32_t target, bool allow_cube_face) {
  WebGLTexture *tex = nullptr;
  const auto index = local_cache_.active_texture_ - GL_TEXTURE0;
  switch (target) {
    case GL_TEXTURE_2D:
      tex = local_cache_.texture_2d_bind_[index];
      break;
    case GL_TEXTURE_CUBE_MAP:
      tex = local_cache_.texture_cube_bind_[index];
      break;
    case GL_TEXTURE_CUBE_MAP_POSITIVE_X:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_X:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_Y:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_Z:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:
      if (allow_cube_face) {
        tex = local_cache_.texture_cube_bind_[index];
      }
      break;
    case GL_TEXTURE_2D_ARRAY:
      tex = local_cache_.texture_2d_array_bind_[index];
      break;
    default:
      SynthesizeGLError(GL_INVALID_ENUM, func_name, "invalid target");
      return tex;
  }

  if (!tex || !tex->HasObject()) {
    SynthesizeGLError(GL_INVALID_OPERATION, func_name, "invalid tex");
    return nullptr;
  }
  return tex;
}

bool WebGLRenderingContext::IsFormatColorRenderable(GLenum format,
                                                    GLenum type) {
  if ((format == GL_RGBA &&
       (type == GL_UNSIGNED_BYTE || type == GL_UNSIGNED_SHORT_4_4_4_4 ||
        type == GL_UNSIGNED_SHORT_5_5_5_1)) ||
      (format == GL_RGB &&
       (type == GL_UNSIGNED_BYTE || type == GL_UNSIGNED_SHORT_5_6_5))) {
    return true;
  }
  return false;
}

/** yjk refactor texImage2D */
bool WebGLRenderingContext::ValidateLevel(const char *func_name, GLint level) {
  if (level < 0 || level > std::log2(device_attributes_.max_texture_size_)) {
    SynthesizeGLError(GL_INVALID_VALUE, func_name, "invalid level");
    return false;
  }
  return true;
}

bool WebGLRenderingContext::ValidateSize(const char *func_name, GLint level,
                                         GLint width, GLint height) {
  int32_t max_size = device_attributes_.max_texture_size_ / std::pow(2, level);
  if (width < 0 || width > max_size || height < 0 || height > max_size) {
    SynthesizeGLError(GL_INVALID_VALUE, func_name, "invalid size");
    return false;
  }
  return true;
}

bool WebGLRenderingContext::ValidateFormatAndType(const char *func_name,
                                                  GLenum internal_format,
                                                  GLenum format, GLenum type) {
  /// Some engine uses some non-standard parameters when calling texImage2D.
  /// Starting from version 2.10 of Krypton, texImage2D handles parameters
  /// according to standard behavior, which causes texture upload failures for
  /// some businesses in such scenarios. Here, we will add a workaround to
  /// address this issue.
  KRYPTON_ERROR_CHECK_IF_NEED {
    if (internal_format != format) {
      SynthesizeGLError(GL_INVALID_OPERATION, func_name,
                        "internal format must equal to format");
      return false;
    }

    GLenum err;
    if (!TextureUtil::ComputeBytesPerPixel(format, type, &err)) {
      SynthesizeGLError(GL_INVALID_VALUE, func_name, "invalid format and type");
      return false;
    }
  }
  return true;
}

bool WebGLRenderingContext::ValidateBorder(const char *func_name,
                                           GLint border) {
  if (border != 0) {
    SynthesizeGLError(GL_INVALID_VALUE, func_name, "invalid border");
    return false;
  }
  return true;
}

bool WebGLRenderingContext::ValidateTextureBinding(const char *func_name,
                                                   GLenum target,
                                                   WebGLTexture *&raw_texture) {
  const auto index = local_cache_.active_texture_ - GL_TEXTURE0;
  switch (target) {
    case GL_TEXTURE_2D:
      raw_texture = local_cache_.texture_2d_bind_[index];
      break;
    case GL_TEXTURE_CUBE_MAP:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_X:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_X:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_Y:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_Z:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:
      raw_texture = local_cache_.texture_cube_bind_[index];
      break;
    case GL_TEXTURE_2D_ARRAY:
      raw_texture = local_cache_.texture_2d_array_bind_[index];
      break;
    default:
      SynthesizeGLError(GL_INVALID_ENUM, func_name, "invalid target");
      return false;
  }

  if (!raw_texture || !raw_texture->HasObject()) {
    SynthesizeGLError(GL_INVALID_OPERATION, func_name, "invalid tex");
    return false;
  }

  return true;
}

bool WebGLRenderingContext::ValidateSubTextureBinding(
    const char *func_name, GLenum target, GLenum format, GLenum type,
    WebGLTexture *&raw_texture) {
  if (!ValidateTextureBinding(func_name, target, raw_texture)) {
    return false;
  }

  if (type != raw_texture->type_ || raw_texture->format_ != format) {
    SynthesizeGLError(GL_INVALID_OPERATION, func_name,
                      "type not match original");
    return false;
  }

  return true;
}

bool WebGLRenderingContext::ValidateArrayType(const char *func_name,
                                              const uint32_t type,
                                              const ArrayBufferView &array) {
  if (array.IsEmpty()) {
    return true;
  }

  bool valid = false;
  switch (type) {
    case GL_UNSIGNED_BYTE:
      valid = array.IsUint8Array() || array.IsUint8ClampedArray();
      break;
    case GL_BYTE:
      valid = array.IsInt8Array();
      break;
    case GL_UNSIGNED_SHORT:
    case GL_UNSIGNED_SHORT_4_4_4_4:
    case GL_UNSIGNED_SHORT_5_5_5_1:
    case GL_UNSIGNED_SHORT_5_6_5:
    case GL_HALF_FLOAT:
      valid = array.IsUint16Array();
      break;
    case GL_SHORT:
      valid = array.IsInt16Array();
      break;
    case GL_UNSIGNED_INT:
    case GL_UNSIGNED_INT_5_9_9_9_REV:
    case GL_UNSIGNED_INT_10F_11F_11F_REV:
    case GL_UNSIGNED_INT_2_10_10_10_REV:
    case GL_UNSIGNED_INT_24_8:
      valid = array.IsUint32Array();
      break;
    case GL_INT:
      valid = array.IsInt32Array();
      break;
    case GL_FLOAT:
      valid = array.IsFloat32Array();
      break;
    case GL_FLOAT_32_UNSIGNED_INT_24_8_REV:
      valid = array.IsFloat64Array();
      break;
    default:
      break;
  }

  if (!valid) {
    SynthesizeGLError(GL_INVALID_OPERATION, func_name, "invalid array type");
    return false;
  }

  return true;
}

void WebGLRenderingContext::PollifyLumianceAlpha(GLenum target, GLenum format,
                                                 GLenum type) {
  if (format != GL_LUMINANCE && format != GL_LUMINANCE_ALPHA &&
      format != GL_ALPHA) {
    return;
  }

  /// LumianceAlpha GL_UNSIGNED_BYTE texture is legal in es3, and es3 will
  /// swizzle the color channel by default, so just skip swizzling for this kind
  /// of texture.
  /// Reference:
  ///  https://registry.khronos.org/OpenGL-Refpages/es3.0/html/glTexImage2D.xhtml
  ///  table 1.0
  if (GL_UNSIGNED_BYTE == type) {
    return;
  }

  if (target == GL_TEXTURE_CUBE_MAP_POSITIVE_X ||
      target == GL_TEXTURE_CUBE_MAP_NEGATIVE_X ||
      target == GL_TEXTURE_CUBE_MAP_POSITIVE_Y ||
      target == GL_TEXTURE_CUBE_MAP_NEGATIVE_Y ||
      target == GL_TEXTURE_CUBE_MAP_POSITIVE_Z ||
      target == GL_TEXTURE_CUBE_MAP_NEGATIVE_Z) {
    target = GL_TEXTURE_CUBE_MAP;
  }

  switch (format) {
    case GL_LUMINANCE:
      GL::TexParameteri(target, GL_TEXTURE_SWIZZLE_G, GL_RED);
      GL::TexParameteri(target, GL_TEXTURE_SWIZZLE_B, GL_RED);
      GL::TexParameteri(target, GL_TEXTURE_SWIZZLE_A, GL_ONE);
      break;
    case GL_ALPHA:
      GL::TexParameteri(target, GL_TEXTURE_SWIZZLE_R, GL_ZERO);
      GL::TexParameteri(target, GL_TEXTURE_SWIZZLE_G, GL_ZERO);
      GL::TexParameteri(target, GL_TEXTURE_SWIZZLE_B, GL_ZERO);
      GL::TexParameteri(target, GL_TEXTURE_SWIZZLE_A, GL_RED);
      break;
    case GL_LUMINANCE_ALPHA:
      GL::TexParameteri(target, GL_TEXTURE_SWIZZLE_G, GL_RED);
      GL::TexParameteri(target, GL_TEXTURE_SWIZZLE_B, GL_RED);
      GL::TexParameteri(target, GL_TEXTURE_SWIZZLE_A, GL_GREEN);
      break;
    default:
      break;
  }
}

void WebGLRenderingContext::PollifyOESTextureFloat(GLenum &internalformat,
                                                   GLenum &format,
                                                   GLenum type) {
  if (type != GL_FLOAT && type != GL_HALF_FLOAT) {
    return;
  }

  switch (type) {
    case GL_FLOAT:
      switch (internalformat) {
        case GL_RGBA:
          internalformat = GL_RGBA32F_EXT;
          break;
        case GL_RGB:
          internalformat = GL_RGB32F_EXT;
          break;
        case GL_LUMINANCE:
        case GL_ALPHA:
          internalformat = GL_R32F;
          format = GL_RED;
          break;
        case GL_LUMINANCE_ALPHA:
          internalformat = GL_RG32F;
          format = GL_RG;
          break;
        default:
          break;
      }
      break;
    case GL_HALF_FLOAT:
    case GL_HALF_FLOAT_OES:
      switch (internalformat) {
        case GL_RGBA:
          internalformat = GL_RGBA16F_EXT;
          break;
        case GL_RGB:
          internalformat = GL_RGB16F_EXT;
          break;
        case GL_LUMINANCE:
        case GL_ALPHA:
          internalformat = GL_R16F;
          format = GL_RED;
          break;
        case GL_LUMINANCE_ALPHA:
          internalformat = GL_RG16F;
          format = GL_RG;
          break;
        default:
          break;
      }
      break;
    default:
      break;
  }
}

void WebGLRenderingContext::PollifyEXTSRGB(GLenum &internalformat,
                                           GLenum &format) {
  switch (format) {
    case GL_SRGB_EXT:
      internalformat = GL_SRGB8;
      format = GL_RGB;
      break;
    case GL_SRGB_ALPHA_EXT:
      internalformat = GL_SRGB8_ALPHA8;
      format = GL_RGBA;
    default:
      break;
  }
}

bool WebGLRenderingContext::ValidateArrayBufferForSub(
    const char *func_name, const uint32_t type, const ArrayBufferView &array) {
  if (!ValidateArrayType(func_name, type, array)) {
    return false;
  }

  if (array.IsEmpty()) {
    SynthesizeGLError(GL_INVALID_VALUE, func_name,
                      "arraybuffer can not be empty");
    return false;
  }

  return true;
}

void WebGLRenderingContext::TexImage2D(GLenum target, GLint level,
                                       GLint internalformat, GLsizei width,
                                       GLsizei height, GLint border,
                                       GLenum format, GLenum type,
                                       ArrayBufferView pixels) {
  const char *func_name = "texImage2D";
  WebGLTexture *raw_texture = nullptr;
  if (!ValidateLevel(func_name, level) ||
      !ValidateSize(func_name, level, width, height) ||
      !ValidateFormatAndType(func_name, internalformat, format, type) ||
      !ValidateBorder(func_name, border) ||
      !ValidateTextureBinding(func_name, target, raw_texture) ||
      !ValidateArrayType(func_name, type, pixels)) {
    return;
  }

  TexImage2DHelperArrayBuffer(false, raw_texture, target, level, internalformat,
                              0, 0, width, height, border, format, type,
                              pixels);
}

void WebGLRenderingContext::TexSubImage2D(GLenum target, GLint level,
                                          GLint xoffset, GLint yoffset,
                                          GLsizei width, GLsizei height,
                                          GLenum format, GLenum type,
                                          ArrayBufferView pixels) {
  const char *func_name = "texSubImage2D";
  WebGLTexture *raw_texture = nullptr;
  if (!ValidateLevel(func_name, level) ||
      !ValidateSize(func_name, level, width, height) ||
      !ValidateFormatAndType(func_name, format, format, type) ||
      !ValidateSubTextureBinding(func_name, target, format, type,
                                 raw_texture) ||
      !ValidateArrayBufferForSub(func_name, type, pixels)) {
    return;
  }

  TexImage2DHelperArrayBuffer(true, raw_texture, target, level, format, xoffset,
                              yoffset, width, height, 0, format, type, pixels);
}

void WebGLRenderingContext::TexImage2DHelperArrayBuffer(
    bool is_sub, WebGLTexture *raw_texture, uint32_t target, int32_t level,
    int32_t internalformat, int32_t xoffset, int32_t yoffset, int32_t width,
    int32_t height, int32_t border, uint32_t format, uint32_t type,
    ArrayBufferView pixels) {
  const auto bytes_per_pixel =
      TextureUtil::ComputeBytesPerPixel(format, type, nullptr);
  uint32_t padding = (bytes_per_pixel * width) % local_cache_.unpack_alignment_;
  padding = padding > 0 ? local_cache_.unpack_alignment_ - padding : padding;
  uint32_t bytes_per_row = width * bytes_per_pixel + padding;
  std::unique_ptr<DataHolder> bitmap_pixels;
  size_t data_len = bytes_per_row * height;

  if (pixels.IsEmpty()) {
    bitmap_pixels = DataHolder::MakeWithMalloc(data_len);
  } else if (pixels.ByteLength() < data_len) {
    bitmap_pixels = DataHolder::MakeWithMalloc(data_len);
    memcpy(bitmap_pixels->WritableData(), pixels.Data(), pixels.ByteLength());
  } else {
    bitmap_pixels = DataHolder::MakeWithCopy(
        static_cast<uint8_t *>(pixels.Data()), data_len);
  }

  auto bitmap = std::make_shared<Bitmap>(width, height, format, type,
                                         std::move(bitmap_pixels),
                                         local_cache_.unpack_alignment_);

  TexCommitCommand(is_sub, raw_texture, target, level, internalformat, xoffset,
                   yoffset, width, height, border, format, type, bitmap);
}

void WebGLRenderingContext::TexImage2D(GLenum target, GLint level,
                                       GLint internalformat, GLenum format,
                                       GLenum type, ImageData *image_data) {
  const char *func_name = "texImage2D";
  WebGLTexture *raw_texture = nullptr;
  GLint width = static_cast<int32_t>(image_data->GetWidth());
  GLint height = static_cast<int32_t>(image_data->GetHeight());
  if (!ValidateLevel(func_name, level) ||
      !ValidateSize(func_name, level, width, height) ||
      !ValidateFormatAndType(func_name, internalformat, format, type) ||
      !ValidateTextureBinding(func_name, target, raw_texture)) {
    return;
  }

  TexImage2DHelperImageData(false, raw_texture, target, level, internalformat,
                            0, 0, width, height, format, type, image_data);
}

void WebGLRenderingContext::TexSubImage2D(GLenum target, GLint level,
                                          GLint xoffset, GLint yoffset,
                                          GLenum format, GLenum type,
                                          ImageData *image_data) {
  const char *func_name = "texSubImage2D";
  GLint width = static_cast<int32_t>(image_data->GetWidth());
  GLint height = static_cast<int32_t>(image_data->GetHeight());
  WebGLTexture *raw_texture = nullptr;
  if (!ValidateLevel(func_name, level) ||
      !ValidateSize(func_name, level, width, height) ||
      !ValidateFormatAndType(func_name, format, format, type) ||
      !ValidateSubTextureBinding(func_name, target, format, type,
                                 raw_texture)) {
    return;
  }
  TexImage2DHelperImageData(true, raw_texture, target, level, format, xoffset,
                            yoffset, width, height, format, type, image_data);
}

void WebGLRenderingContext::TexImage2DHelperImageData(
    bool is_sub, WebGLTexture *raw_texture, uint32_t target, int32_t level,
    int32_t internalformat, int32_t xoffset, int32_t yoffset, int32_t width,
    int32_t height, uint32_t format, uint32_t type, ImageData *image_data) {
  ScopedUnpackParametersResetRestore unpackParametersResetRestore(this);

  auto raw_data = image_data->GetRawData();
  if (!raw_data) {
    KRYPTON_LOGE("image data raw data must not be nullptr");
    return;
  }
  auto pixels = DataHolder::MakeWithCopy(
      raw_data, width * height * ImageData::PIXEL_SIZE);
  auto bitmap = std::make_shared<Bitmap>(width, height, GL_RGBA,
                                         GL_UNSIGNED_BYTE, std::move(pixels));
  TexCommitCommand(is_sub, raw_texture, target, level, internalformat, xoffset,
                   yoffset, width, height, 0, format, type, bitmap);
}

void WebGLRenderingContext::TexImage2D(GLenum target, GLint level,
                                       GLint internalformat, GLenum format,
                                       GLenum type,
                                       CanvasImageSource *canvas_image_source) {
  const char *func_name = "texImage2D";
  GLint width = canvas_image_source->GetWidth();
  GLint height = canvas_image_source->GetHeight();
  WebGLTexture *raw_texture = nullptr;
  if (!ValidateLevel(func_name, level) ||
      !ValidateSize(func_name, level, width, height) ||
      !ValidateFormatAndType(func_name, internalformat, format, type) ||
      !ValidateTextureBinding(func_name, target, raw_texture)) {
    return;
  }
  TexImage2DHelperCanvasImageSource(false, raw_texture, target, level,
                                    internalformat, 0, 0, width, height, format,
                                    type, canvas_image_source);
}

void WebGLRenderingContext::TexSubImage2D(
    GLenum target, GLint level, GLint xoffset, GLint yoffset, GLenum format,
    GLenum type, CanvasImageSource *canvas_image_source) {
  const char *func_name = "texSubImage2D";
  GLint width = static_cast<int32_t>(canvas_image_source->GetWidth());
  GLint height = static_cast<int32_t>(canvas_image_source->GetHeight());
  WebGLTexture *raw_texture = nullptr;
  if (!ValidateLevel(func_name, level) ||
      !ValidateSize(func_name, level, width, height) ||
      !ValidateFormatAndType(func_name, format, format, type) ||
      !ValidateSubTextureBinding(func_name, target, format, type,
                                 raw_texture)) {
    return;
  }
  TexImage2DHelperCanvasImageSource(
      true, raw_texture, target, level, format, xoffset, yoffset,
      canvas_image_source->GetWidth(), canvas_image_source->GetHeight(), format,
      type, canvas_image_source);
}

void WebGLRenderingContext::TexImage2DHelperCanvasImageSource(
    bool is_sub, WebGLTexture *raw_texture, uint32_t target, int32_t level,
    int32_t internalformat, int32_t xoffset, int32_t yoffset, int32_t width,
    int32_t height, uint32_t format, uint32_t type,
    CanvasImageSource *canvas_image_source) {
  ScopedUnpackParametersResetRestore unpackParametersResetRestore(this);

  if (canvas_image_source->IsImageElement()) {
    auto image_element = static_cast<ImageElement *>(canvas_image_source);
    TexCommitCommand(is_sub, raw_texture, target, level, internalformat,
                     xoffset, yoffset, image_element->GetWidth(),
                     image_element->GetHeight(), 0, format, type,
                     image_element->GetBitmap());
    image_element->ReleaseUsedMemIfNeed();
  } else {
    canvas_image_source->WillDraw();
    TexCommitCommand(is_sub, raw_texture, target, level, internalformat,
                     xoffset, yoffset, width, height, 0, format, type,
                     canvas_image_source->GetTextureSource());
  }
}

void WebGLRenderingContext::TexCommitCommand(
    bool is_sub, WebGLTexture *raw_texture, uint32_t target, int32_t level,
    int32_t internalformat, int32_t xoffset, int32_t yoffset, int32_t width,
    int32_t height, int32_t border, uint32_t format, uint32_t type,
    const std::shared_ptr<Bitmap> &bitmap) {
  if (!bitmap) {
    return;
  }

  if (!is_sub) {
    raw_texture->internal_format_ = internalformat;
    raw_texture->format_ = format;
    raw_texture->type_ = type;
    raw_texture->width_ = width;
    raw_texture->height_ = height;
  }

#if ENABLE_KRYPTON_EFFECT
  raw_texture->UpdateWidthAndHeight(width, height);
  if (EffectHelper::IsValid()) {
    raw_texture->SetNeedUpdate();
  }
#endif

  DCHECK(Recorder());
  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *) {
      if (flip_y_ != bitmap_->HasFlipY()) {
        bitmap_->FlipY();
      }

      if (premul_alpha_ != bitmap_->HasPremulAlpha() &&
          TextureUtil::CanPremulAlpha(bitmap_->Format())) {
        if (premul_alpha_) {
          bitmap_->PremulAlpha();
        } else {
          bitmap_->UnpremulAlpha();
        }
      }

      if (format_ != bitmap_->Format() || type_ != bitmap_->Type()) {
        auto bitmap = bitmap_->ConvertFormat(format_, type_);
        if (bitmap) {
          bitmap_ = std::move(bitmap);
        } else {
          internalformat_ = bitmap_->Format();
          format_ = bitmap_->Format();
          type_ = bitmap_->Type();
        }
      }

      PollifyLumianceAlpha(target_, format_, type_);
      PollifyOESTextureFloat(internalformat_, format_, type_);
      PollifyEXTSRGB(internalformat_, format_);

      if (is_sub_) {
        GL::TexSubImage2D(target_, level_, xoffset_, yoffset_, width_, height_,
                          format_, type_, bitmap_->Pixels());
      } else {
        GL::TexImage2D(target_, level_, internalformat_, width_, height_,
                       border_, format_, type_, bitmap_->Pixels());
      }
    }

    bool is_sub_, flip_y_, premul_alpha_;
    uint32_t target_, format_, internalformat_, type_;
    int32_t level_, xoffset_, yoffset_, width_, height_, border_;
    std::shared_ptr<Bitmap> bitmap_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->is_sub_ = is_sub;
  cmd->target_ = target;
  cmd->level_ = level;
  cmd->internalformat_ = internalformat;
  cmd->xoffset_ = xoffset;
  cmd->yoffset_ = yoffset;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->border_ = border;
  cmd->format_ = format;
  cmd->type_ = type;
  cmd->bitmap_ = bitmap;
  cmd->flip_y_ = local_cache_.unpack_filp_y_webgl_;
  cmd->premul_alpha_ = local_cache_.unpack_premul_alpha_webgl_;
}

void WebGLRenderingContext::TexCommitCommand(
    bool is_sub, WebGLTexture *raw_texture, uint32_t target, int32_t level,
    int32_t internalformat, int32_t xoffset, int32_t yoffset, int32_t width,
    int32_t height, int32_t border, uint32_t format, uint32_t type,
    const std::shared_ptr<shell::LynxActor<TextureSource>> &texture_source) {
  if (!texture_source) {
    return;
  }

  if (!is_sub) {
    raw_texture->internal_format_ = internalformat;
    raw_texture->format_ = format;
    raw_texture->type_ = type;
    raw_texture->width_ = width;
    raw_texture->height_ = height;
  }

#if ENABLE_KRYPTON_EFFECT
  raw_texture->UpdateWidthAndHeight(width, height);
  if (EffectHelper::IsValid()) {
    raw_texture->SetNeedUpdate();
  }
#endif

  DCHECK(Recorder());
  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *) {
      auto tex_source = texture_source_->Impl();
      if (!tex_source) {
        return;
      }

      PollifyLumianceAlpha(target_, format_, type_);
      PollifyOESTextureFloat(internalformat_, format_, type_);
      PollifyEXTSRGB(internalformat_, format_);

      tex_source->UpdateTextureOrFramebufferOnGPU();

      if (!is_sub_) {
        GL::TexImage2D(target_, level_, internalformat_, width_, height_,
                       border_, format_, type_, nullptr);
      }

      if (tex_source->HasFlipY()) {
        flip_y_ = !flip_y_;
      }

      uint32_t src_fb;
      std::unique_ptr<Framebuffer> src_fb_ptr;
      if (tex_source->HasPremulAlpha() != premul_alpha_) {
        src_fb_ptr = std::make_unique<Framebuffer>(width_, height_);
        if (!src_fb_ptr->InitOnGPUIfNeed()) {
          return;
        }

        ScopedGLResetRestore s1(GL_VIEWPORT);
        ScopedGLResetRestore s2(GL_DRAW_FRAMEBUFFER_BINDING);
        GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, src_fb_ptr->Fbo());
        GL::Viewport(0, 0, width_, height_);
        tex_source->GetShader()->Draw(tex_source->Texture(), false, false,
                                      true);
        src_fb = src_fb_ptr->Fbo();
      } else {
        src_fb = tex_source->reading_fbo();
      }

      if (!src_fb) {
        return;
      }

      bool need_copy =
          !IsFormatColorRenderable(format_, type_) || target_ != GL_TEXTURE_2D;
      std::unique_ptr<Framebuffer> dst_fb;
      if (!need_copy) {
        dst_fb = std::make_unique<Framebuffer>(target_texture_->Get());
      } else {
        dst_fb = std::make_unique<Framebuffer>(width_, height_, internalformat_,
                                               format_, type_);
      }

      if (!(dst_fb->InitOnGPUIfNeed())) {
        return;
      }

      ScopedGLResetRestore s1(GL_READ_FRAMEBUFFER_BINDING);
      ScopedGLResetRestore s2(GL_DRAW_FRAMEBUFFER_BINDING);
      ScopedGLResetRestore s3(GL_SCISSOR_TEST);
      GL::Disable(GL_SCISSOR_TEST);
      GL::BindFramebuffer(GL_READ_FRAMEBUFFER, src_fb);
      GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, dst_fb->Fbo());
      GL::BlitFramebuffer(0, flip_y_ ? height_ : 0, width_,
                          flip_y_ ? 0 : height_, xoffset_, yoffset_,
                          xoffset_ + width_, yoffset_ + height_,
                          GL_COLOR_BUFFER_BIT, GL_LINEAR);

      if (need_copy) {
        GL::BindFramebuffer(GL_READ_FRAMEBUFFER, dst_fb->Fbo());
        if (is_sub_) {
          GL::CopyTexSubImage2D(target_, level_, xoffset_, yoffset_, 0, 0,
                                width_, height_);
        } else {
          GL::CopyTexImage2D(target_, level_, internalformat_, 0, 0, width_,
                             height_, border_);
        }
      }
    }

    bool is_sub_, flip_y_, premul_alpha_;
    uint32_t target_, internalformat_, format_, type_;
    int32_t level_, xoffset_, yoffset_, width_, height_, border_;
    std::shared_ptr<shell::LynxActor<TextureSource>> texture_source_;
    PuppetContent<GLuint> *target_texture_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->is_sub_ = is_sub;
  cmd->target_ = target;
  cmd->level_ = level;
  cmd->internalformat_ = internalformat;
  cmd->xoffset_ = xoffset;
  cmd->yoffset_ = yoffset;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->border_ = border;
  cmd->format_ = format;
  cmd->type_ = type;
  cmd->texture_source_ = texture_source;
  cmd->flip_y_ = local_cache_.unpack_filp_y_webgl_;
  cmd->target_texture_ = raw_texture->related_id_;
  cmd->premul_alpha_ = local_cache_.unpack_premul_alpha_webgl_;

  /**
   Trigger flush after texImage2D(texSource). The reason is that other rasters
   may be accessed in the command recorder, and not triggering the flush
   immediately may lead to out-of-order execution of GL commands.
   */
  Present(false);
}

}  // namespace canvas
}  // namespace lynx
