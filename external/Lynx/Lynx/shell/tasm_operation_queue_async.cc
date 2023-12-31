// Copyright 2022 The Lynx Authors. All rights reserved.
#include "shell/tasm_operation_queue_async.h"

#include <utility>

#include "base/log/logging.h"
#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace shell {

// @note: run on layout thread
void TASMOperationQueueAsync::EnqueueOperation(TASMOperation operation) {
  pending_operations_.emplace_back(std::move(operation));
}

// @note: run on layout thread
void TASMOperationQueueAsync::AppendPendingTask() {
  std::unique_lock<std::mutex> local_lock(mutex_);
  if (!ready_operations_.empty()) {
    ready_operations_.insert(
        ready_operations_.end(),
        std::make_move_iterator(pending_operations_.begin()),
        std::make_move_iterator(pending_operations_.end()));
  } else {
    ready_operations_ = std::move(pending_operations_);
  }
  pending_operations_.clear();
}

// @note: run on tasm thread
// para type bool: can reduce hood lock
bool TASMOperationQueueAsync::Flush() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "TASMOperationQueueAsync::Flush");
  std::vector<TASMOperation> v_ops;
  {
    std::unique_lock<std::mutex> local_lock(mutex_);
    v_ops = std::move(ready_operations_);
    ready_operations_.clear();
  }
  for (auto& operation : v_ops) {
    operation();
  }
  return !v_ops.empty();
}

}  // namespace shell
}  // namespace lynx
