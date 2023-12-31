// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/gpu/command_buffer_ng/runnable_buffer.h"

#include "canvas/gpu/command_buffer_ng/align_helper.h"
#include "canvas/gpu/command_buffer_ng/command_invoker.h"

namespace lynx {
namespace canvas {
namespace command_buffer {
RunnableBuffer::RunnableBuffer(std::unique_ptr<DataHolder> data)
    : buffer_(std::move(data)) {}

void RunnableBuffer::Execute() {
  auto raw_buffer = static_cast<uint8_t *>(buffer_->WritableData());

  uint32_t cur = 0;
  while (cur < buffer_->Size()) {
    auto current_buffer = raw_buffer + cur;
    auto data_ptr = current_buffer + sizeof(void *);
    auto offset = (*(reinterpret_cast<InvokeFunction *>(current_buffer)))(
        static_cast<void *>(data_ptr), this);
    cur += offset + sizeof(void *);
    cur = AlignToNext(cur);
  }
}
}  // namespace command_buffer
}  // namespace canvas
}  // namespace lynx
