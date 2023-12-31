// Copyright 2021 The Lynx Authors. All rights reserved.

#include "shell/lynx_ui_operation_queue.h"

#include <utility>

#include "base/debug/lynx_assert.h"
#include "base/threading/task_runner_manufactor.h"
#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace shell {

void LynxUIOperationQueue::EnqueueUIOperation(UIOperation operation) {
  operations_.emplace_back(std::move(operation));
}

void LynxUIOperationQueue::Flush() {
  if (!enable_flush_) {
    return;
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxUIOperationQueue.Flush");
  // need move, else LynxUI may invoke Flush again when Flush...
  ConsumeOperations(std::move(operations_));
}

void LynxUIOperationQueue::SetEnableFlush(bool enable_flush) {
  enable_flush_ = enable_flush;
}

void LynxUIOperationQueue::Destroy() { destroyed_ = true; }

void LynxUIOperationQueue::ForceFlush() { Flush(); }

void LynxUIOperationQueue::ConsumeOperations(
    std::vector<UIOperation> operations) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxUIOperationQueue::ConsumeOperations");
  for (auto& operation : operations) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxUIOperationQueue::ExecuteOperation");
    operation();
  }

  if (error_callback_ == nullptr) {
    return;
  }

  auto& error = base::ErrorStorage::GetInstance().GetError();
  if (error != nullptr) {
    error_callback_(error->error_code_, error->error_message_);
    lynx::base::ErrorStorage::GetInstance().Reset();
  }
}

}  // namespace shell
}  // namespace lynx
