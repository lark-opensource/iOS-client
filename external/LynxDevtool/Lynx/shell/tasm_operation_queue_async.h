// Copyright 2022 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_TASM_OPERATION_QUEUE_ASYNC_H_
#define LYNX_SHELL_TASM_OPERATION_QUEUE_ASYNC_H_

#include <mutex>
#include <vector>

#include "shell/tasm_operation_queue.h"

namespace lynx {
namespace shell {

class TASMOperationQueueAsync final : public TASMOperationQueue {
 public:
  TASMOperationQueueAsync() = default;
  ~TASMOperationQueueAsync() = default;

  // begin override
  void EnqueueOperation(TASMOperation operation) override;
  bool Flush() override;
  void AppendPendingTask() override;
  // end

 private:
  // enqueue and dequeue operate on different thread
  // need use lock for operations
  std::mutex mutex_;
  std::vector<TASMOperation> pending_operations_;
  std::vector<TASMOperation> ready_operations_;
};

}  // namespace shell
}  // namespace lynx
#endif  // LYNX_SHELL_TASM_OPERATION_QUEUE_ASYNC_H_
