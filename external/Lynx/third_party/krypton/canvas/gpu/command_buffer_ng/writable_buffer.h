// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_COMMAND_BUFFER_NG_WRITABLE_BUFFER_H_
#define CANVAS_GPU_COMMAND_BUFFER_NG_WRITABLE_BUFFER_H_

#include <cstdint>
#include <vector>

#include "canvas/base/data_holder.h"

namespace lynx {
namespace canvas {
namespace command_buffer {
class WritableBuffer {
 public:
  explicit WritableBuffer(size_t buffer_size = 1024 * 200);
  WritableBuffer(const WritableBuffer&) = delete;

  WritableBuffer& operator=(const WritableBuffer&) = delete;

  size_t Offset() const { return state_.offset; }
  /**
   * Allocate a specified size of memory.
   * If nullptr is returned, the current buffer does not
   * have the ability to classify.
   * */
  void* OffsetAlloc(size_t size);

  std::unique_ptr<DataHolder> GetAndClearContents();

 private:
  struct state {
    size_t offset = 0;
  };

  std::vector<uint8_t> buffer_;
  state state_;
};
}  // namespace command_buffer
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_COMMAND_BUFFER_NG_WRITABLE_BUFFER_H_
