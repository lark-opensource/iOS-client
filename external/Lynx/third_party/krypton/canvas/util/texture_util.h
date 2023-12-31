#ifndef CANVAS_UTIL_TEXTURE_UTIL_H_
#define CANVAS_UTIL_TEXTURE_UTIL_H_

#include <cstddef>
#include <cstdint>

namespace lynx {
namespace canvas {

class TextureUtil final {
 public:
  // notice: row bytes
  static void FilpVertical(uint8_t *, uint8_t *, size_t, size_t);

  static void PremultiplyAlpha(uint8_t *src, uint8_t *dst, size_t width_pixel,
                               size_t height_pixel, uint32_t bytes_per_row,
                               uint32_t bytes_per_pixel, uint32_t type);

  static void UnpremultiplyAlpha(uint8_t *src, uint8_t *dst,
                                 uint32_t width_pixel, uint32_t height_pixel,
                                 uint32_t bytes_per_row,
                                 uint32_t bytes_per_pixel, uint32_t type);

  static bool ConvertFormat(uint32_t src_format, uint32_t dst_format,
                            uint32_t src_type, uint32_t dst_type,
                            unsigned int size, void *src_pixels,
                            void *dst_pixels);

  static bool ImageCopy(uint8_t *dst, uint8_t *src, uint32_t width,
                        uint32_t height, bool flip_y, bool premultiply_alpha,
                        uint32_t alignment, uint32_t bytesPerPixel,
                        uint32_t type);

  static void TextureCanvasProcessor(uint32_t target, int32_t level,
                                     uint32_t internal_format, uint32_t format,
                                     uint32_t type, bool flipY,
                                     uint32_t canvas_fb, uint32_t target_tex,
                                     uint32_t width, uint32_t height,
                                     bool isSub, uint32_t xoff, uint32_t yoff);

  static void Blit(uint32_t src_fb, int32_t src_x, int32_t src_y, int32_t src_w,
                   int32_t src_h, uint32_t dst_fb, int32_t dst_x, int32_t dst_y,
                   int32_t dst_w, int32_t dst_h);

  static uint32_t ComputeBytesPerPixel(uint32_t pixel_format,
                                       uint32_t pixel_type, uint32_t *err);

  static bool CanPremulAlpha(uint32_t format);

  static bool CopyTextureOnGPU(uint32_t src, uint32_t dst, uint32_t width,
                               uint32_t height);
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_UTIL_TEXTURE_UTIL_H_
