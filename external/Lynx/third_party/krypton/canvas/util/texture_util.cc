
#include "texture_util.h"

#include <vector>

#include "canvas/gpu/frame_buffer.h"
#include "canvas/gpu/gl/gl_api.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"
#include "canvas/gpu/gl_constants.h"

namespace lynx {
namespace canvas {

void TextureUtil::FilpVertical(uint8_t *src, uint8_t *dst, size_t height_pixel,
                               size_t width_byte) {
  if (!src || !dst || 0 == width_byte || 0 == height_pixel) {
    return;
  }

  if (src == dst) {
    std::vector<uint8_t> temp(width_byte);
    for (uint32_t i = 0; i < height_pixel / 2; ++i) {
      memcpy(temp.data(), src + i * width_byte, width_byte);
      memcpy(src + i * width_byte, src + (height_pixel - i - 1) * width_byte,
             width_byte);
      memcpy(src + (height_pixel - i - 1) * width_byte, temp.data(),
             width_byte);
    }
  } else {
    for (uint32_t i = 0; i < height_pixel; ++i) {
      memcpy(dst + i * width_byte, src + (height_pixel - i - 1) * width_byte,
             width_byte);
    }
  }
}

#ifdef __ANDROID__
void TextureUtil::PremultiplyAlpha(uint8_t *src, uint8_t *dst,
                                   size_t width_pixel, size_t height_pixel,
                                   uint32_t bytes_per_row,
                                   uint32_t bytes_per_pixel, uint32_t type) {
  for (uint32_t i = 0; i < height_pixel; ++i) {
    for (uint32_t j = 0; j < width_pixel; ++j) {
      auto s_8 = src + i * bytes_per_row + j * bytes_per_pixel;
      auto d_8 = dst + i * bytes_per_row + j * bytes_per_pixel;
      if (type ==
          KR_GL_UNSIGNED_BYTE) {  /// TODO: use vImagePremultiplyData_RGBA8888
                                  /// for iOS
        auto d_32 = (uint32_t *)d_8;
        auto r_8 = s_8[0];
        auto g_8 = s_8[1];
        auto b_8 = s_8[2];
        auto a_8 = s_8[3];
        auto a_8_plus_1 = a_8 + 1;
        *d_32 = ((r_8 * a_8_plus_1 >> 8) << 0) |
                ((g_8 * a_8_plus_1 >> 8) << 8) |
                ((b_8 * a_8_plus_1 >> 8) << 16) | a_8 << 24;
      } else if (type == KR_GL_UNSIGNED_SHORT_4_4_4_4) {
        auto d_16 = (uint16_t *)d_8;
        uint8_t r_8 = d_8[1] >> 4;
        uint8_t g_8 = d_8[1] & 0xf;
        uint8_t b_8 = d_8[0] >> 4;
        uint8_t a_8 = d_8[0] & 0xf;
        auto a_8_plus_1 = a_8 + 1;
        *d_16 = (((r_8 * a_8_plus_1) >> 4) << 12) |
                (((g_8 * a_8_plus_1) >> 4) << 8) |
                (((b_8 * a_8_plus_1) >> 4) << 4) | a_8;
      } else if (type == KR_GL_UNSIGNED_SHORT_5_5_5_1) {
        auto d_16 = (uint16_t *)d_8;
        uint8_t r_8 = (d_16[0] & 0xF800) >> 11;
        uint8_t g_8 = (d_16[0] & 0x7C0) >> 6;
        uint8_t b_8 = (d_16[0] & 0x3e) >> 1;
        uint8_t a_8 = d_16[0] & 0x1;
        uint16_t tmp = 0;
        tmp = (tmp | (r_8 * a_8)) << 5;
        tmp = (tmp | (g_8 * a_8)) << 5;
        tmp = (tmp | (b_8 * a_8)) << 1;
        tmp = tmp | a_8;
        *d_16 = tmp;
      }
    }
  }
}

void TextureUtil::UnpremultiplyAlpha(uint8_t *src, uint8_t *dst,
                                     uint32_t width_pixel,
                                     uint32_t height_pixel, uint32_t width_byte,
                                     uint32_t bytes_per_pixel, uint32_t type) {
  for (uint32_t i = 0; i < height_pixel; ++i) {
    for (uint32_t j = 0; j < width_pixel; ++j) {
      auto s_8 = src + i * width_byte + j * bytes_per_pixel;
      auto d_8 = dst + i * width_byte + j * bytes_per_pixel;
      if (type ==
          KR_GL_UNSIGNED_BYTE) {  /// TODO: use vImageUnpremultiplyData_RGBA8888
                                  /// for iOS
        auto d_32 = (uint32_t *)d_8;
        auto r_8 = s_8[0];
        auto g_8 = s_8[1];
        auto b_8 = s_8[2];
        auto a_8 = s_8[3];
        if (a_8 == 0) {
          *d_32 = 0;
          continue;
        }
        *d_32 = ((r_8 * 255 / a_8) << 0) | ((g_8 * 255 / a_8) << 8) |
                ((b_8 * 255 / a_8) << 16) | a_8 << 24;
      } else if (type == KR_GL_UNSIGNED_SHORT_4_4_4_4) {
        auto d_16 = (uint16_t *)d_8;
        uint8_t r_8 = d_8[1] >> 4;
        uint8_t g_8 = d_8[1] & 0xf;
        uint8_t b_8 = d_8[0] >> 4;
        uint8_t a_8 = d_8[0] & 0xf;
        if (a_8 == 0) {
          *d_16 = 0;
          continue;
        }
        *d_16 = ((r_8 * 16 / a_8) << 12) | ((g_8 * 16 / a_8) << 8) |
                ((b_8 * 16 / a_8) << 4) | a_8;
      } else if (type == KR_GL_UNSIGNED_SHORT_5_5_5_1) {
        auto d_16 = (uint16_t *)d_8;
        uint8_t a_8 = d_8[0] & 0x1;
        if (a_8 == 0) {
          *d_16 = 0;
          continue;
        }
      }
    }
  }
}
#endif

bool TextureUtil::ConvertFormat(uint32_t src_format, uint32_t dst_format,
                                uint32_t src_type, uint32_t dst_type,
                                unsigned int size, void *src_pixels,
                                void *dst_pixels) {
  if (src_format == KR_GL_RGBA && src_type == KR_GL_UNSIGNED_BYTE) {
    if (dst_format == KR_GL_RGB) {
      if (dst_type == KR_GL_UNSIGNED_SHORT_5_6_5) {
        uint8_t *src = static_cast<uint8_t *>(src_pixels);
        unsigned short *dst = static_cast<unsigned short *>(dst_pixels);
        for (unsigned int i = 0; i < size; i++) {
          uint8_t r = src[i * 4] & 0xff;
          uint8_t g = src[i * 4 + 1];
          uint8_t b = src[i * 4 + 2];
          dst[i] = ((r >> 3) << 11) | ((g >> 2) << 5) | ((b >> 3) << 0);
        }
        return true;
      } else if (dst_type == KR_GL_UNSIGNED_BYTE) {
        uint8_t *src = static_cast<uint8_t *>(src_pixels);
        uint8_t *dst = static_cast<uint8_t *>(dst_pixels);
        for (unsigned int i = 0; i < size; i++) {
          memcpy(dst + i * 3, src + i * 4, 3);
        }
        return true;
      }
    } else if (dst_format == KR_GL_RGBA) {
      if (dst_type == KR_GL_UNSIGNED_SHORT_5_5_5_1) {
        uint8_t *src = static_cast<uint8_t *>(src_pixels);
        unsigned short *dst = static_cast<unsigned short *>(dst_pixels);
        for (unsigned int i = 0; i < size; i++) {
          uint8_t r = src[i * 4];
          uint8_t g = src[i * 4 + 1];
          uint8_t b = src[i * 4 + 2];
          uint8_t a = src[i * 4 + 3];
          dst[i] = ((r >> 3) << 11) | ((g >> 3) << 6) | ((b >> 3) << 1) |
                   ((a >> 7) << 0);
        }
        return true;
      } else if (dst_type == KR_GL_UNSIGNED_SHORT_4_4_4_4) {
        uint8_t *src = static_cast<uint8_t *>(src_pixels);
        unsigned short *dst = static_cast<unsigned short *>(dst_pixels);
        for (unsigned int i = 0; i < size; i++) {
          uint8_t r = src[i * 4];
          uint8_t g = src[i * 4 + 1];
          uint8_t b = src[i * 4 + 2];
          uint8_t a = src[i * 4 + 3];
          dst[i] = ((r >> 4) << 12) | ((g >> 4) << 8) | ((b >> 4) << 4) |
                   ((a >> 4) << 0);
        }
        return true;
      }
    } else if (dst_format == KR_GL_LUMINANCE_ALPHA) {
      if (dst_type == KR_GL_UNSIGNED_BYTE) {
        uint8_t *src = static_cast<uint8_t *>(src_pixels);
        uint8_t *dst = static_cast<uint8_t *>(dst_pixels);
        for (unsigned int i = 0; i < size; i++) {
          uint8_t r = src[i * 4];
          uint8_t a = src[i * 4 + 3];
          dst[i * 2] = r;
          dst[i * 2 + 1] = a;
        }
        return true;
      }
    } else if (dst_format == KR_GL_LUMINANCE) {
      if (dst_type == KR_GL_UNSIGNED_BYTE) {
        uint8_t *src = static_cast<uint8_t *>(src_pixels);
        uint8_t *dst = static_cast<uint8_t *>(dst_pixels);
        for (unsigned int i = 0; i < size; i++) {
          uint8_t r = src[i * 4];
          dst[i] = r;
        }
        return true;
      }
    } else if (dst_format == KR_GL_ALPHA) {
      if (dst_type == KR_GL_UNSIGNED_BYTE) {
        uint8_t *src = static_cast<uint8_t *>(src_pixels);
        uint8_t *dst = static_cast<uint8_t *>(dst_pixels);
        for (unsigned int i = 0; i < size; i++) {
          uint8_t a = src[i * 4 + 3];
          dst[i] = a;
        }
        return true;
      }
    }
  } else {
    // no supported.
  }

  return false;
}

bool TextureUtil::ImageCopy(uint8_t *dst, uint8_t *src, uint32_t width,
                            uint32_t height, bool flip_y,
                            bool premultiply_alpha, uint32_t alignment,
                            uint32_t bytesPerPixel, uint32_t type) {
  if (!dst || !src || !width || !height) {
    return false;
  }

  bool filp_vertical = flip_y;
  bool premul_alpha = premultiply_alpha;

  uint32_t actualWidth = width;
  uint32_t padding = (bytesPerPixel * actualWidth) % alignment;
  padding = padding > 0 ? alignment - padding : padding;
  uint32_t bytesPerRow = actualWidth * bytesPerPixel + padding;
  uint32_t width_byte = bytesPerRow;

  if ((dst > src && dst < src + width_byte * height) ||
      (src > dst && src < dst + width_byte * height)) {
    return false;  // overlap
  }

  if (filp_vertical) {
    TextureUtil::FilpVertical(src, dst, height, width_byte);
  } else {
    if (src != dst) {
      memcpy(dst, src, width_byte * height);
    }
  }

  if (premul_alpha) {
    TextureUtil::PremultiplyAlpha(src, dst, width, height, width_byte,
                                  bytesPerPixel, type);
  }

  return true;
}

void TextureUtil::TextureCanvasProcessor(
    uint32_t target, int32_t level, uint32_t internal_format, uint32_t format,
    uint32_t type, bool flipY, uint32_t canvas_fb, uint32_t target_tex,
    uint32_t width, uint32_t height, bool isSub, uint32_t xoff, uint32_t yoff) {
  int32_t read_buffer = 0, draw_buffer = 0;
  GL::GetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &read_buffer);
  GL::GetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &draw_buffer);
  unsigned char test_scissor = 0;
  GL::GetBooleanv(GL_SCISSOR_TEST, &test_scissor);

  GL::BindFramebuffer(GL_FRAMEBUFFER, canvas_fb);

  GL::Disable(GL_SCISSOR_TEST);
  if (flipY) {
    if (!isSub) {
      GL::TexImage2D(target, level, internal_format, width, height, 0, format,
                     type, nullptr);
    }
    // create temp framebuffer
    uint32_t fb;
    GL::GenFramebuffers(1, &fb);
    GL::BindFramebuffer(GL_FRAMEBUFFER, fb);
    GL::FramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                             GL_TEXTURE_2D, target_tex, 0);
    Blit(canvas_fb, 0, 0, width, height, fb, xoff, yoff + height, width,
         -height);
    GL::DeleteFramebuffers(1, &fb);
  } else {
    if (isSub) {
      GL::CopyTexSubImage2D(target, level, xoff, yoff, 0, 0, width, height);
    } else {
      GL::CopyTexImage2D(target, level, internal_format, 0, 0, width, height,
                         0);
    }
  }

  GL::BindFramebuffer(GL_READ_FRAMEBUFFER, read_buffer);
  GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, draw_buffer);
  if (test_scissor) {
    GL::Enable(GL_SCISSOR_TEST);
  }
}

void TextureUtil::Blit(uint32_t src_fb, int32_t src_x, int32_t src_y,
                       int32_t src_w, int32_t src_h, uint32_t dst_fb,
                       int32_t dst_x, int32_t dst_y, int32_t dst_w,
                       int32_t dst_h) {
  GL::BindFramebuffer(GL_READ_FRAMEBUFFER, src_fb);
  GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, dst_fb);
  GL::BlitFramebuffer(src_x, src_y, src_x + src_w, src_y + src_h, dst_x, dst_y,
                      dst_x + dst_w, dst_y + dst_h, GL_COLOR_BUFFER_BIT,
                      GL_LINEAR);
}

uint32_t TextureUtil::ComputeBytesPerPixel(uint32_t pixel_format,
                                           uint32_t pixel_type, uint32_t *err) {
  switch (pixel_type) {
    case GL_UNSIGNED_BYTE:
      switch (pixel_format) {
        case GL_SRGB_ALPHA_EXT:
        case GL_RGBA:
          return 4;
        case GL_SRGB_EXT:
        case GL_RGB:
          return 3;
        case GL_LUMINANCE_ALPHA:
          return 2;
        case GL_LUMINANCE:
        case GL_ALPHA:
          return 1;
        default:
          if (err != nullptr) {
            *err = GL_INVALID_ENUM;
          }
          return 0;
      }
    case GL_FLOAT:
      switch (pixel_format) {
        case GL_RGBA:
          return 16;
        case GL_RGB:
          return 12;
        case GL_LUMINANCE_ALPHA:
          return 8;
        case GL_LUMINANCE:
        case GL_ALPHA:
          return 4;
        default:
          if (err != nullptr) {
            *err = GL_INVALID_ENUM;
          }
          return 0;
      }
    case GL_HALF_FLOAT:
    case KR_GL_HALF_FLOAT_OES:
      switch (pixel_format) {
        case GL_RGBA:
          return 8;
        case GL_RGB:
          return 6;
        case GL_LUMINANCE_ALPHA:
          return 4;
        case GL_LUMINANCE:
        case GL_ALPHA:
          return 2;
        default:
          if (err != nullptr) {
            *err = GL_INVALID_ENUM;
          }
          return 0;
      }
    case GL_UNSIGNED_SHORT_4_4_4_4:
    case GL_UNSIGNED_SHORT_5_5_5_1:
      switch (pixel_format) {
        case GL_RGBA:
          return 2;
        case GL_RGB:
        case GL_LUMINANCE_ALPHA:
        case GL_LUMINANCE:
        case GL_ALPHA:
          if (err != nullptr) {
            *err = GL_INVALID_OPERATION;
          }
          return 0;
        default:
          if (err != nullptr) {
            *err = GL_INVALID_ENUM;
          }
          return 0;
      }
    case GL_UNSIGNED_SHORT_5_6_5:
      switch (pixel_format) {
        case GL_RGB:
          return 2;
        case GL_RGBA:
        case GL_LUMINANCE_ALPHA:
        case GL_LUMINANCE:
        case GL_ALPHA:
          if (err != nullptr) {
            *err = GL_INVALID_OPERATION;
          }
          return 0;
        default:
          if (err != nullptr) {
            *err = GL_INVALID_ENUM;
          }
          return 0;
      }
    default:
      if (err != nullptr) {
        *err = GL_INVALID_ENUM;
      }
      return 0;
  }
}

bool TextureUtil::CanPremulAlpha(uint32_t format) {
  switch (format) {
    case GL_RGBA:
      return true;
    case GL_LUMINANCE_ALPHA:
      // TODO Support GL_LUMINANCE_ALPHA premual
    case GL_ALPHA:
    case GL_RGB:
    case GL_LUMINANCE:
    default:
      return false;
  }
  return false;
}

bool TextureUtil::CopyTextureOnGPU(uint32_t src, uint32_t dst, uint32_t width,
                                   uint32_t height) {
  if (!src || !dst) {
    return false;
  }

  Framebuffer src_fb(src);
  if (!src_fb.InitOnGPUIfNeed()) {
    return false;
  }

  Framebuffer dst_fb(dst);
  if (!dst_fb.InitOnGPUIfNeed()) {
    return false;
  }

  ScopedGLResetRestore s(GL_FRAMEBUFFER_BINDING);
  GL::BindFramebuffer(GL_READ_FRAMEBUFFER, src_fb.Fbo());
  GL::BindFramebuffer(GL_DRAW_FRAMEBUFFER, dst_fb.Fbo());
  GL::BlitFramebuffer(0, 0, width, height, 0, 0, width, height,
                      GL_COLOR_BUFFER_BIT, GL_LINEAR);

  //  DebugTextureWithUIImage(src, width, height);
  //  DebugTextureWithUIImage(dst, width, height);

  return true;
}

}  // namespace canvas
}  // namespace lynx
