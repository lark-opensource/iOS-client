// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_TASM_OPERATION_QUEUE_H_
#define LYNX_SHELL_TASM_OPERATION_QUEUE_H_

#include <atomic>
#include <condition_variable>
#include <memory>
#include <vector>

#include "base/closure.h"

namespace lynx {
namespace shell {

// type foy sync
// share operations between tasm thread and layout thread
class TASMOperationQueue {
 public:
  using TASMOperation = base::closure;

  TASMOperationQueue() = default;
  virtual ~TASMOperationQueue() = default;

  virtual void EnqueueOperation(TASMOperation operation);
  virtual bool Flush();
  virtual void AppendPendingTask() {}

  // first screen operation
  // condition variable for first screen between layout thread and tasm thread
  // push into base class, reduce api impl
  std::atomic_bool has_first_screen_{false};
  std::condition_variable first_screen_cv_;

 private:
  std::vector<TASMOperation> operations_;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_TASM_OPERATION_QUEUE_H_
