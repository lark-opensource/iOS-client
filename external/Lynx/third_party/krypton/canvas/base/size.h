// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_BASE_SIZE_H_
#define CANVAS_BASE_SIZE_H_

#include <cstdint>

namespace lynx {
namespace canvas {
struct ISize {
  int32_t width;
  int32_t height;

  void SetWidth(int32_t new_width) { this->width = new_width; }

  void SetHeight(int32_t new_height) { this->height = new_height; }

  void Set(int32_t new_width, int32_t new_height) {
    this->width = new_width;
    this->height = new_height;
  }

  int64_t Area() const { return width * height; }

  bool IsEmpty() const { return width <= 0 || height <= 0; }
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_BASE_SIZE_H_
