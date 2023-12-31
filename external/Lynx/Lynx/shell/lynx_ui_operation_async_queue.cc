// Copyright 2022 The Lynx Authors. All rights reserved.

#include "shell/lynx_ui_operation_async_queue.h"

#include "base/log/logging.h"
#include "base/threading/task_runner_manufactor.h"
#include "base/trace_event/trace_event.h"
#include "tasm/lynx_trace_event.h"
namespace lynx {

namespace shell {

void LynxUIOperationAsyncQueue::EnqueueUIOperation(UIOperation operation) {
  pending_operations_.emplace_back(std::move(operation));
}

void LynxUIOperationAsyncQueue::UpdateStatus(UIOperationStatus status) {
  status_ = status;
}

void LynxUIOperationAsyncQueue::Flush() {
  if (runner_->RunsTasksOnCurrentThread()) {
    FlushOnUIThread();
    return;
  }
  FlushOnTASMThread();
}

void LynxUIOperationAsyncQueue::FlushOnUIThread() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "LynxUIOperationAsyncQueue::FlushOnUIThread.");
  if (!enable_flush_) {
    return;
  }
  // If the |status_| is All_FINISH(which means tasm and layout has finished),
  // there is no need for the UI thread to flush because the screen flickering
  // will no longer appears.
  if (!destroyed_ && status_ != UIOperationStatus::ALL_FINISH) {
    TRACE_EVENT_BEGIN(
        LYNX_TRACE_CATEGORY,
        LYNX_TRACE_UI_OPERATION_QUEUE_ASYNC_RENDER_FLUSH_WAIT_TASM);
    {
      std::unique_lock<std::mutex> tasm_lock(tasm_mutex_);
      bool wait_for_tasm =
          tasm_cv_.wait_for(tasm_lock, kOperationQueueTimeOut,
                            [this] { return tasm_finish_.load(); });
      if (!wait_for_tasm) {
        LOGE("flush on ui thread failed, wait tasm finish timeout");
      }
    }
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);

    FlushInterval();
    TRACE_EVENT_BEGIN(
        LYNX_TRACE_CATEGORY,
        LYNX_TRACE_UI_OPERATION_QUEUE_ASYNC_RENDER_FLUSH_WAIT_LAYOUT);
    {
      std::unique_lock<std::mutex> layout_lock(layout_mutex_);
      bool wait_for_layout =
          layout_cv_.wait_for(layout_lock, kOperationQueueTimeOut,
                              [this] { return layout_finish_.load(); });
      if (!wait_for_layout) {
        LOGE("flush on ui thread failed, wait layout finish timeout");
      }
    }
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);

    FlushInterval();
  }
}

void LynxUIOperationAsyncQueue::FlushOnTASMThread() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              "LynxUIOperationAsyncQueue::FlushOnTASMThread.");
  {
    std::lock_guard<std::mutex> lock(operations_mutex_);
    if (operations_.empty()) {
      operations_ = std::move(pending_operations_);
    } else {
      operations_.insert(operations_.end(),
                         std::make_move_iterator(pending_operations_.begin()),
                         std::make_move_iterator(pending_operations_.end()));
    }
    pending_operations_.clear();
  }

  // The |status_| will be updated when 'tasm finish' or 'layout finish'
  // operation enqueues. And the UI thread may be waiting for these two
  // operations, so here we need to notify the UI thread.
  if (status_ == UIOperationStatus::TASM_FINISH) {
    tasm_finish_ = true;
    tasm_cv_.notify_all();
  } else if (status_ == UIOperationStatus::LAYOUT_FINISH) {
    // In some cases, there are no flush between TASM_FINISH and LAYOUT_FINISH,
    // and the |tasm_cv_| will not be notify. So, we need to notify |tasm_cv_|
    // and set |tasm_finish_| to true here.
    tasm_finish_ = true;
    tasm_cv_.notify_all();
    layout_finish_ = true;
    layout_cv_.notify_all();
  }

  if (!enable_flush_) {
    return;
  }

  auto task = [weak_self = weak_from_this()]() {
    auto self = weak_self.lock();
    if (self && !self->destroyed_) {
      self->FlushInterval();
    }
  };
  runner_->PostTask(std::move(task));
}

void LynxUIOperationAsyncQueue::FlushInterval() {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "LynxUIOperationAsyncQueue::FlushInterval.");
  is_in_flush_ = true;
  std::vector<UIOperation> operations;
  {
    std::lock_guard<std::mutex> lock(operations_mutex_);
    operations = std::move(operations_);
  }

  ConsumeOperations(std::move(operations));
  is_in_flush_ = false;
}

void LynxUIOperationAsyncQueue::MarkDirty() {
  status_ = UIOperationStatus::INIT;
  layout_finish_ = false;
  tasm_finish_ = false;
}

void LynxUIOperationAsyncQueue::ForceFlush() { FlushInterval(); };

uint32_t LynxUIOperationAsyncQueue::GetNativeUpdateDataOrder() {
  return native_update_data_order_;
}

uint32_t LynxUIOperationAsyncQueue::UpdateNativeUpdateDataOrder() {
  native_update_data_order_++;
  return native_update_data_order_;
}
}  // namespace shell
}  // namespace lynx
