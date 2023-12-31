//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "texture_format_convertor.h"

#include "canvas/base/log.h"
#include "canvas/gpu/gl/gl_api.h"
#include "canvas/util/texture_util.h"

namespace lynx {
namespace canvas {

typedef void (*ReaderFn)(void* pixels, void* dst);

void Read_RGBA_UNSIGNED_BYTE(void* pixels, void* dst) {
  uint8_t* view = static_cast<uint8_t*>(pixels);
  uint8_t* dst_view = static_cast<uint8_t*>(dst);
  dst_view[0] = view[0];
  dst_view[1] = view[1];
  dst_view[2] = view[2];
  dst_view[3] = view[3];
  dst_view[4] = 0xFF;
  dst_view[5] = 0xFF;
  dst_view[6] = 0xFF;
  dst_view[7] = 0xFF;
}

void Read_RGBA_UNSIGNED_SHORT_4444(void* pixels, void* dst) {
  uint16_t* view = static_cast<uint16_t*>(pixels);
  uint8_t* dst_view = static_cast<uint8_t*>(dst);
  dst_view[0] = static_cast<uint8_t>((*view & 0xF000) >> 12);
  dst_view[1] = static_cast<uint8_t>((*view & 0x0F00) >> 8);
  dst_view[2] = static_cast<uint8_t>((*view & 0x00F0) >> 4);
  dst_view[3] = static_cast<uint8_t>((*view & 0x000F));
  dst_view[4] = 0xF;
  dst_view[5] = 0xF;
  dst_view[6] = 0xF;
  dst_view[7] = 0xF;
}

void Read_RGBA_UNSIGNED_SHORT_5551(void* pixels, void* dst) {
  uint16_t* view = static_cast<uint16_t*>(pixels);
  uint8_t* dst_view = static_cast<uint8_t*>(dst);
  dst_view[0] = static_cast<uint8_t>((*view & 0xF800) >> 11);
  dst_view[1] = static_cast<uint8_t>((*view & 0x07C0) >> 6);
  dst_view[2] = static_cast<uint8_t>((*view & 0x003E) >> 1);
  dst_view[3] = static_cast<uint8_t>((*view & 0x0001));
  dst_view[4] = 0x1F;
  dst_view[5] = 0x1F;
  dst_view[6] = 0x1F;
  dst_view[7] = 0x1;
}

void Read_RGB_UNSIGNED_BYTE(void* pixels, void* dst) {
  uint8_t* view = static_cast<uint8_t*>(pixels);
  uint8_t* dst_view = static_cast<uint8_t*>(dst);
  dst_view[0] = view[0];
  dst_view[1] = view[1];
  dst_view[2] = view[2];
  dst_view[3] = 0xFF;
  dst_view[4] = 0xFF;
  dst_view[5] = 0xFF;
  dst_view[6] = 0xFF;
  dst_view[7] = 0xFF;
}

void Read_RGB_UNSIGNED_SHORT_565(void* pixels, void* dst) {
  uint16_t* view = static_cast<uint16_t*>(pixels);
  uint8_t* dst_view = static_cast<uint8_t*>(dst);
  dst_view[0] = static_cast<uint8_t>((*view & 0xF800) >> 11);
  dst_view[1] = static_cast<uint8_t>((*view & 0x07E0) >> 5);
  dst_view[2] = static_cast<uint8_t>((*view & 0x001F));
  dst_view[3] = 0xFF;
  dst_view[4] = 0x1F;
  dst_view[5] = 0x3F;
  dst_view[6] = 0x1F;
  dst_view[7] = 0xFF;
}

void Read_LUMINANCE_ALPHA_UNSIGNED_BYTE(void* pixels, void* dst) {
  uint8_t* view = static_cast<uint8_t*>(pixels);
  uint8_t* dst_view = static_cast<uint8_t*>(dst);
  dst_view[0] = view[0];
  dst_view[1] = view[0];
  dst_view[2] = view[0];
  dst_view[3] = view[1];
  dst_view[4] = 0xFF;
  dst_view[5] = 0xFF;
  dst_view[6] = 0xFF;
  dst_view[7] = 0xFF;
}

void Read_ALPHA_UNSIGNED_BYTE(void* pixels, void* dst) {
  uint8_t* view = static_cast<uint8_t*>(pixels);
  uint8_t* dst_view = static_cast<uint8_t*>(dst);
  dst_view[0] = 0xFF;
  dst_view[1] = 0xFF;
  dst_view[2] = 0xFF;
  dst_view[3] = view[0];
  dst_view[4] = 0xFF;
  dst_view[5] = 0xFF;
  dst_view[6] = 0xFF;
  dst_view[7] = 0xFF;
}

void Read_LUMINANCE_UNSIGNED_BYTE(void* pixels, void* dst) {
  uint8_t* view = static_cast<uint8_t*>(pixels);
  uint8_t* dst_view = static_cast<uint8_t*>(dst);
  dst_view[0] = view[0];
  dst_view[1] = view[0];
  dst_view[2] = view[0];
  dst_view[3] = 0xFF;
  dst_view[4] = 0xFF;
  dst_view[5] = 0xFF;
  dst_view[6] = 0xFF;
  dst_view[7] = 0xFF;
}

typedef void (*WriterFn)(void* pixels, uint8_t* src);

void Write_RGBA_UNSIGNED_BYTE(void* pixels, uint8_t* src) {
  uint8_t* view = static_cast<uint8_t*>(pixels);
  view[0] = static_cast<uint8_t>(
      (static_cast<float>(src[0]) / static_cast<float>(src[4])) * 0xFF);
  view[1] = static_cast<uint8_t>(
      (static_cast<float>(src[1]) / static_cast<float>(src[5])) * 0xFF);
  view[2] = static_cast<uint8_t>(
      (static_cast<float>(src[2]) / static_cast<float>(src[6])) * 0xFF);
  view[3] = static_cast<uint8_t>(
      (static_cast<float>(src[3]) / static_cast<float>(src[7])) * 0xFF);
}

void Write_RGBA_UNSIGNED_SHORT_4444(void* pixels, uint8_t* src) {
  uint16_t* view = static_cast<uint16_t*>(pixels);
  auto r = static_cast<uint8_t>(
      (static_cast<float>(src[0]) / static_cast<float>(src[4])) * 0xF);
  auto g = static_cast<uint8_t>(
      (static_cast<float>(src[1]) / static_cast<float>(src[5])) * 0xF);
  auto b = static_cast<uint8_t>(
      (static_cast<float>(src[2]) / static_cast<float>(src[6])) * 0xF);
  auto a = static_cast<uint8_t>(
      (static_cast<float>(src[3]) / static_cast<float>(src[7])) * 0xF);
  view[0] = (r << 12) | (g << 8) | (b << 4) | a;
}

void Write_RGBA_UNSIGNED_SHORT_5551(void* pixels, uint8_t* src) {
  uint16_t* view = static_cast<uint16_t*>(pixels);
  auto r = static_cast<uint8_t>(
      (static_cast<float>(src[0]) / static_cast<float>(src[4])) * 0x1F);
  auto g = static_cast<uint8_t>(
      (static_cast<float>(src[1]) / static_cast<float>(src[5])) * 0x1F);
  auto b = static_cast<uint8_t>(
      (static_cast<float>(src[2]) / static_cast<float>(src[6])) * 0x1F);
  auto a = static_cast<uint8_t>(
      (static_cast<float>(src[3]) / static_cast<float>(src[7])) * 0x1);
  view[0] = (r << 11) | (g << 6) | (b << 1) | a;
}

void Write_RGB_UNSIGNED_BYTE(void* pixels, uint8_t* src) {
  uint8_t* view = static_cast<uint8_t*>(pixels);
  view[0] = static_cast<uint8_t>(
      (static_cast<float>(src[0]) / static_cast<float>(src[4])) * 0xFF);
  view[1] = static_cast<uint8_t>(
      (static_cast<float>(src[1]) / static_cast<float>(src[5])) * 0xFF);
  view[2] = static_cast<uint8_t>(
      (static_cast<float>(src[2]) / static_cast<float>(src[6])) * 0xFF);
}

void Write_RGB_UNSIGNED_SHORT_565(void* pixels, uint8_t* src) {
  uint16_t* view = static_cast<uint16_t*>(pixels);
  auto r = static_cast<uint8_t>(
      (static_cast<float>(src[0]) / static_cast<float>(src[4])) * 0x1F);
  auto g = static_cast<uint8_t>(
      (static_cast<float>(src[1]) / static_cast<float>(src[5])) * 0x3F);
  auto b = static_cast<uint8_t>(
      (static_cast<float>(src[2]) / static_cast<float>(src[6])) * 0x1F);
  view[0] = (r << 11) | (g << 5) | b;
}

void Write_LUMINANCE_ALPHA_UNSIGNED_BYTE(void* pixels, uint8_t* src) {
  uint8_t* view = static_cast<uint8_t*>(pixels);
  auto r = static_cast<uint8_t>(
      (static_cast<float>(src[0]) / static_cast<float>(src[4])) * 0x1F);
  auto g = static_cast<uint8_t>(
      (static_cast<float>(src[1]) / static_cast<float>(src[5])) * 0x3F);
  auto b = static_cast<uint8_t>(
      (static_cast<float>(src[2]) / static_cast<float>(src[6])) * 0x1F);
  // LUMINANCE = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  // https://stackoverflow.com/questions/596216/formula-to-determine-perceived-brightness-of-rgb-color
  view[0] = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  view[1] = src[4];
}

void Write_ALPHA_UNSIGNED_BYTE(void* pixels, uint8_t* src) {
  uint8_t* view = static_cast<uint8_t*>(pixels);
  auto a = static_cast<uint8_t>(
      (static_cast<float>(src[3]) / static_cast<float>(src[7])) * 0xFF);
  view[0] = a;
}

void Write_LUMINANCE_UNSIGNED_BYTE(void* pixels, uint8_t* src) {
  uint8_t* view = static_cast<uint8_t*>(pixels);
  view[0] = src[0];
}

#define KRYPTON_TEX_CONVERTOR_SWITCHER(row)            \
  switch (format) {                                    \
    case GL_RGBA:                                      \
      switch (type) {                                  \
        case GL_UNSIGNED_BYTE:                         \
          return &row##_RGBA_UNSIGNED_BYTE;            \
        case GL_UNSIGNED_SHORT_4_4_4_4:                \
          return &row##_RGBA_UNSIGNED_SHORT_4444;      \
        case GL_UNSIGNED_SHORT_5_5_5_1:                \
          return &row##_RGBA_UNSIGNED_SHORT_5551;      \
        default:                                       \
          break;                                       \
      }                                                \
    case GL_RGB:                                       \
      switch (type) {                                  \
        case GL_UNSIGNED_BYTE:                         \
          return &row##_RGB_UNSIGNED_BYTE;             \
        case GL_UNSIGNED_SHORT_5_6_5:                  \
          return &row##_RGB_UNSIGNED_SHORT_565;        \
        default:                                       \
          break;                                       \
      }                                                \
    case GL_LUMINANCE_ALPHA:                           \
      switch (type) {                                  \
        case GL_UNSIGNED_BYTE:                         \
          return &row##_LUMINANCE_ALPHA_UNSIGNED_BYTE; \
        default:                                       \
          break;                                       \
      }                                                \
    case GL_ALPHA:                                     \
      switch (type) {                                  \
        case GL_UNSIGNED_BYTE:                         \
          return &row##_ALPHA_UNSIGNED_BYTE;           \
        default:                                       \
          break;                                       \
      }                                                \
    case GL_LUMINANCE:                                 \
      switch (type) {                                  \
        case GL_UNSIGNED_BYTE:                         \
          return &row##_LUMINANCE_UNSIGNED_BYTE;       \
        default:                                       \
          break;                                       \
      }                                                \
    default:                                           \
      break;                                           \
  }                                                    \
  return nullptr;

ReaderFn ReaderForFormatAndType(uint32_t format, uint32_t type) {
  KRYPTON_TEX_CONVERTOR_SWITCHER(Read);
}

WriterFn WriterForFormatAndType(uint32_t format, uint32_t type) {
  KRYPTON_TEX_CONVERTOR_SWITCHER(Write);
}

uint32_t TextureFormatConvertor::ComputePadding(uint32_t width, uint32_t bpp,
                                                uint32_t aligment) {
  uint32_t tmp = (width * bpp) % aligment;
  return tmp > 0 ? aligment - tmp : 0;
}

bool TextureFormatConvertor::ConvertFormat(uint32_t src_format,
                                           uint32_t src_type,
                                           uint32_t dst_format,
                                           uint32_t dst_type, uint32_t width,
                                           uint32_t height, uint32_t aligment,
                                           void* src_pixels, void* dst_pixels) {
  if (!src_pixels || !dst_pixels) {
    KRYPTON_LOGE("src pixels & dst pixels must not be null");
    return false;
  }

  auto reader = ReaderForFormatAndType(src_format, src_type);
  auto writer = WriterForFormatAndType(dst_format, dst_type);
  if (!reader || !writer) {
    return false;
  }

  uint32_t src_bpp =
      TextureUtil::ComputeBytesPerPixel(src_format, src_type, nullptr);
  uint32_t dst_bpp =
      TextureUtil::ComputeBytesPerPixel(dst_format, dst_type, nullptr);
  uint8_t* src_pixels_view = static_cast<uint8_t*>(src_pixels);
  uint8_t* dst_pixels_view = static_cast<uint8_t*>(dst_pixels);
  uint32_t src_padding = ComputePadding(width, src_bpp, aligment);
  uint32_t dst_padding = ComputePadding(width, dst_bpp, aligment);

  uint8_t* tmp = static_cast<uint8_t*>(malloc(sizeof(uint8_t) * 8));
  if (!tmp) {
    return false;
  }

  for (int i = 0; i < height; i++) {
    for (int j = 0; j < width; j++) {
      reader(src_pixels_view, tmp);
      writer(dst_pixels_view, tmp);
      src_pixels_view += src_bpp;
      dst_pixels_view += dst_bpp;
    }
    src_pixels_view += src_padding;
    dst_pixels_view += dst_padding;
  }
  free(tmp);
  return true;
}

}  // namespace canvas
}  // namespace lynx
