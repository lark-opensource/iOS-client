//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_UTIL_TEXTURE_FORMAT_CONVERTOR_H_
#define CANVAS_UTIL_TEXTURE_FORMAT_CONVERTOR_H_

#include <cstddef>
#include <cstdint>

namespace lynx {
namespace canvas {
class TextureFormatConvertor {
 public:
  static uint32_t ComputePadding(uint32_t width, uint32_t bpp,
                                 uint32_t aligment);

  static bool ConvertFormat(uint32_t src_format, uint32_t src_type,
                            uint32_t dst_format, uint32_t dst_type,
                            uint32_t width, uint32_t height, uint32_t aligment,
                            void *src_pixels, void *dst_pixels);
};
};  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_UTIL_TEXTURE_FORMAT_CONVERTOR_H_
