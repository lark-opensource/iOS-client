// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/gpu/gl_constants.h"
#include "texture_util.h"

#import <Accelerate/Accelerate.h>

namespace lynx {
namespace canvas {

void TextureUtil::PremultiplyAlpha(uint8_t *src, uint8_t *dst, size_t width_pixel,
                                   size_t height_pixel, uint32_t bytes_per_row,
                                   uint32_t bytes_per_pixel, uint32_t type) {
  if (type == KR_GL_UNSIGNED_BYTE) {
    vImage_Buffer src_buffer, dst_buffer;
    src_buffer.data = src;
    src_buffer.width = width_pixel;
    src_buffer.height = height_pixel;
    src_buffer.rowBytes = bytes_per_row;
    dst_buffer.data = dst;
    dst_buffer.width = width_pixel;
    dst_buffer.height = height_pixel;
    dst_buffer.rowBytes = bytes_per_row;
    vImagePremultiplyData_RGBA8888(&src_buffer, &dst_buffer, 0);
    return;
  }

  for (uint32_t i = 0; i < height_pixel; ++i) {
    for (uint32_t j = 0; j < width_pixel; ++j) {
      auto d_8 = dst + i * bytes_per_row + j * bytes_per_pixel;
      if (type == KR_GL_UNSIGNED_SHORT_4_4_4_4) {
        auto d_16 = (uint16_t *)d_8;
        uint8_t r_8 = d_8[1] >> 4;
        uint8_t g_8 = d_8[1] & 0xf;
        uint8_t b_8 = d_8[0] >> 4;
        uint8_t a_8 = d_8[0] & 0xf;
        auto a_8_plus_1 = a_8 + 1;
        *d_16 = (((r_8 * a_8_plus_1) >> 4) << 12) | (((g_8 * a_8_plus_1) >> 4) << 8) |
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

void TextureUtil::UnpremultiplyAlpha(uint8_t *src, uint8_t *dst, uint32_t width_pixel,
                                     uint32_t height_pixel, uint32_t width_byte,
                                     uint32_t bytes_per_pixel, uint32_t type) {
  if (type == KR_GL_UNSIGNED_BYTE) {
    vImage_Buffer src_buffer, dst_buffer;
    src_buffer.data = src;
    src_buffer.width = width_pixel;
    src_buffer.height = height_pixel;
    src_buffer.rowBytes = width_byte;
    dst_buffer.data = dst;
    dst_buffer.width = width_pixel;
    dst_buffer.height = height_pixel;
    dst_buffer.rowBytes = width_byte;
    vImageUnpremultiplyData_RGBA8888(&src_buffer, &dst_buffer, 0);
    return;
  }

  for (uint32_t i = 0; i < height_pixel; ++i) {
    for (uint32_t j = 0; j < width_pixel; ++j) {
      auto d_8 = dst + i * width_byte + j * bytes_per_pixel;
      if (type == KR_GL_UNSIGNED_SHORT_4_4_4_4) {
        auto d_16 = (uint16_t *)d_8;
        uint8_t r_8 = d_8[1] >> 4;
        uint8_t g_8 = d_8[1] & 0xf;
        uint8_t b_8 = d_8[0] >> 4;
        uint8_t a_8 = d_8[0] & 0xf;
        if (a_8 == 0) {
          *d_16 = 0;
          continue;
        }
        *d_16 = ((r_8 * 16 / a_8) << 12) | ((g_8 * 16 / a_8) << 8) | ((b_8 * 16 / a_8) << 4) | a_8;
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

}  // namespace canvas
}  // namespace lynx
