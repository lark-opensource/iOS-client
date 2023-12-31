// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_BITMAP_H_
#define CANVAS_BITMAP_H_

#include "base/base_export.h"
#include "canvas/base/data_holder.h"
#include "canvas/gpu/gl/gl_api.h"

namespace lynx {
namespace canvas {

// texture data store in mem
class Bitmap {
 public:
  Bitmap(uint32_t width, uint32_t height, uint32_t format, uint32_t type,
         std::unique_ptr<DataHolder> pixels, uint32_t aligment = 1,
         bool has_premultiplied = false, bool has_flip_y = false);

  void PremulAlpha();

  void UnpremulAlpha();

  void FlipY();

  std::unique_ptr<Bitmap> ConvertFormat(uint32_t format, uint32_t type);

  bool HasPremulAlpha();

  bool HasFlipY();

  BASE_EXPORT uint32_t Width() const;

  BASE_EXPORT uint32_t Height() const;

  uint32_t Format() const;

  uint32_t Type() const;

  uint32_t Alignment() const;

  BASE_EXPORT const void* Pixels() const;

  bool IsValidate();

  BASE_EXPORT uint32_t PixelsLen() const;

  BASE_EXPORT uint32_t BytesPerRow() const;

 private:
  std::unique_ptr<DataHolder> pixels_{nullptr};
  uint32_t width_{0};
  uint32_t height_{0};
  uint32_t format_{GL_RGBA};
  uint32_t type_{GL_UNSIGNED_BYTE};

  uint32_t aligment_{4};
  bool has_premul_alpha_{false};
  bool has_flip_y_{false};

  uint32_t bytes_per_pixel_{0};
  uint32_t bytes_per_row_{0};
  uint32_t pixels_len_{0};
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_BITMAP_H_
