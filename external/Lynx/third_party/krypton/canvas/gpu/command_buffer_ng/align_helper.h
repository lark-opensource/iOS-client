// Copyright (c) 2023 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_COMMAND_BUFFER_NG_ALIGN_HELPER_H_
#define CANVAS_GPU_COMMAND_BUFFER_NG_ALIGN_HELPER_H_

#include <cstdint>
#include <limits>

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
namespace command_buffer {
template <bool is_32bit = sizeof(void*) == 4>
uint32_t AlignToNext(uint32_t cur) {
  DCHECK((cur + (is_32bit ? 4 : 8)) < std::numeric_limits<uint32_t>::max());
  return is_32bit ? (((cur + 3) >> 2) << 2) : (((cur + 7) >> 3) << 3);
}
}  // namespace command_buffer
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_COMMAND_BUFFER_NG_ALIGN_HELPER_H_
