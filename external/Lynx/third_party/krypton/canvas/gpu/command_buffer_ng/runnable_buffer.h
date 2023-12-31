// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_COMMAND_BUFFER_NG_RUNNABLE_BUFFER_H_
#define CANVAS_GPU_COMMAND_BUFFER_NG_RUNNABLE_BUFFER_H_

#include <cstdint>
#include <vector>

#include "canvas/base/data_holder.h"
#include "canvas/base/gtest_prod_helper.h"

namespace lynx {
namespace canvas {
namespace command_buffer {
class RunnableBuffer {
 public:
  explicit RunnableBuffer(std::unique_ptr<DataHolder> data);

  RunnableBuffer(const RunnableBuffer&) = delete;

  RunnableBuffer& operator=(const RunnableBuffer&) = delete;

  void Execute();

 private:
  FRIEND_TEST(RunnableBufferTest, Execute);
  std::unique_ptr<DataHolder> buffer_;
};
}  // namespace command_buffer
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_COMMAND_BUFFER_NG_RUNNABLE_BUFFER_H_
