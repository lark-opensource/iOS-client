// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_COMMAND_BUFFER_COMMAND_RECORDER_H_
#define CANVAS_GPU_COMMAND_BUFFER_COMMAND_RECORDER_H_

#include <functional>

#include "canvas/base/data_holder.h"
#include "canvas/base/log.h"
#include "canvas/gpu/command_buffer_ng//runnable_buffer.h"
#include "canvas/gpu/command_buffer_ng//writable_buffer.h"
#include "canvas/gpu/command_buffer_ng/command_invoker.h"

namespace lynx {
namespace canvas {
class CommandRecorder {
 public:
  CommandRecorder(
      std::function<void(CommandRecorder*, bool is_sync)> commit_func);

  std::shared_ptr<command_buffer::RunnableBuffer> FinishRecordingAndRestart();

  bool HasCommandToCommit() const;

  // Helper to automatically encode objects and queue commit
  // Will automatically apply for the buffer,
  // automatically submit when the buffer is full
  template <typename cls, typename... args_t>
  inline cls* Alloc(args_t&&... arguments) {
    uint32_t alloc_size = sizeof(cls) + sizeof(void*);
    auto ptr = writable_buffer_.OffsetAlloc(alloc_size);
    if (nullptr == ptr) {
      commit_func_(this, false);
      ptr = writable_buffer_.OffsetAlloc(alloc_size);
      DCHECK(nullptr != ptr);
    }
    auto func = &(command_buffer::CommandInvoker<cls>::Invoke);
    memcpy(ptr, (void*)(&func), sizeof(void*));
    return new ((void*)((uint8_t*)ptr + sizeof(void*)))
        cls(std::forward<args_t>(arguments)...);
  }

  void Commit(bool is_sync) { commit_func_(this, is_sync); }

 private:
  std::function<void(CommandRecorder*, bool is_sync)> commit_func_;
  command_buffer::WritableBuffer writable_buffer_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_COMMAND_BUFFER_COMMAND_RECORDER_H_
