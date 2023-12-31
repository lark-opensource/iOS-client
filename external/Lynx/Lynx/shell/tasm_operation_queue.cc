// Copyright 2022 The Lynx Authors. All rights reserved.

#include "shell/tasm_operation_queue.h"

#include <utility>

#include "base/log/logging.h"

namespace lynx {
namespace shell {

// TODO(heshan):support base::OperationQueue, which can be used by
// TASMOperationQueue, UIOperationQueue, cached_tasks_ of LynxRuntime, etc.
void TASMOperationQueue::EnqueueOperation(TASMOperation operation) {
  operations_.emplace_back(std::move(operation));
}

bool TASMOperationQueue::Flush() {
  auto operations = std::move(operations_);
  if (operations.empty()) {
    return false;
  }

  for (auto& operation : operations) {
    operation();
  }
  return true;
}

}  // namespace shell
}  // namespace lynx
