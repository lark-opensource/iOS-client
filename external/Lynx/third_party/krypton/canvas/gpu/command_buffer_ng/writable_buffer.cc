// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/gpu/command_buffer_ng/writable_buffer.h"

#include "canvas/base/log.h"
#include "canvas/gpu/command_buffer_ng/align_helper.h"

namespace lynx {
namespace canvas {
namespace command_buffer {
WritableBuffer::WritableBuffer(size_t buffer_size) : buffer_(buffer_size) {}

void *WritableBuffer::OffsetAlloc(size_t size) {
  DCHECK(0 != size && size <= buffer_.size());
  if (buffer_.size() - state_.offset < size) {
    return nullptr;
  }
  auto *data_ptr = static_cast<uint8_t *>(buffer_.data()) + state_.offset;

  state_.offset += size;

  state_.offset = AlignToNext(state_.offset);

  return static_cast<void *>(data_ptr);
}

std::unique_ptr<DataHolder> WritableBuffer::GetAndClearContents() {
  size_t offset = state_.offset;
  state_.offset = 0;
  return DataHolder::MakeWithCopy(buffer_.data(), offset);
}
}  // namespace command_buffer
}  // namespace canvas
}  // namespace lynx
