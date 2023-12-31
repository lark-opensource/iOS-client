// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_COMMAND_BUFFER_NG_COMMAND_INVOKER_H_
#define CANVAS_GPU_COMMAND_BUFFER_NG_COMMAND_INVOKER_H_

#include "canvas/gpu/command_buffer_ng/runnable_buffer.h"

namespace lynx {
namespace canvas {
namespace command_buffer {
typedef size_t (*InvokeFunction)(void*, RunnableBuffer*);

// command invoker
template <typename cls>
class CommandInvoker final {
 public:
  static size_t Invoke(void* ptr, RunnableBuffer* buffer) {
    static_assert(std::is_same_v<InvokeFunction, decltype(&Invoke)>);
    auto cls_ptr = static_cast<cls*>(ptr);
    cls_ptr->Run(buffer);
    cls_ptr->~cls();
    return sizeof(cls);
  }
};
}  // namespace command_buffer
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_COMMAND_BUFFER_NG_COMMAND_INVOKER_H_
