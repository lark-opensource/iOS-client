// Copyright 2022 The Lynx Authors. All rights reserved.

#include "shell/dynamic_ui_operation_queue.h"

#include "base/trace_event/trace_event.h"
#include "shell/lynx_ui_operation_async_queue.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace shell {

namespace {

bool IsEngineAsync(base::ThreadStrategyForRendering strategy) {
  return strategy == base::ThreadStrategyForRendering::MULTI_THREADS ||
         strategy == base::ThreadStrategyForRendering::MOST_ON_TASM;
}

}  // namespace

DynamicUIOperationQueue::DynamicUIOperationQueue(
    base::ThreadStrategyForRendering strategy)
    : is_engine_async_(IsEngineAsync(strategy)) {
  CreateImpl();
}

void DynamicUIOperationQueue::Transfer(
    base::ThreadStrategyForRendering strategy) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, "DynamicUIOperationQueue::Transfer");
  // ensure on ui thread.
  DCHECK(base::UIThread::GetRunner()->RunsTasksOnCurrentThread());

  // in Flush, just do nothing.
  if (impl_->IsInFlush()) {
    return;
  }

  if (is_engine_async_ == IsEngineAsync(strategy)) {
    return;
  }
  is_engine_async_ = !is_engine_async_;

  // force flush the existing ui operations.
  // TODO(heshan):for async, here will flush with a std::lock_guard,
  // which can be optimize away.
  impl_->ForceFlush();

  CreateImpl();
}

void DynamicUIOperationQueue::EnqueueUIOperation(UIOperation operation) {
  impl_->EnqueueUIOperation(std::move(operation));
}

void DynamicUIOperationQueue::Destroy() { impl_->Destroy(); }

void DynamicUIOperationQueue::UpdateStatus(UIOperationStatus status) {
  impl_->UpdateStatus(status);
}

void DynamicUIOperationQueue::MarkDirty() { impl_->MarkDirty(); }

void DynamicUIOperationQueue::ForceFlush() { impl_->ForceFlush(); }

void DynamicUIOperationQueue::Flush() { impl_->Flush(); }

void DynamicUIOperationQueue::SetEnableFlush(bool enable_flush) {
  impl_->SetEnableFlush(enable_flush);
}

void DynamicUIOperationQueue::SetErrorCallback(ErrorCallback callback) {
  impl_->SetErrorCallback(std::move(callback));
}

uint32_t DynamicUIOperationQueue::GetNativeUpdateDataOrder() {
  return impl_->GetNativeUpdateDataOrder();
}

uint32_t DynamicUIOperationQueue::UpdateNativeUpdateDataOrder() {
  return impl_->UpdateNativeUpdateDataOrder();
}

void DynamicUIOperationQueue::CreateImpl() {
  impl_ = is_engine_async_ ? std::make_shared<shell::LynxUIOperationAsyncQueue>(
                                 base::UIThread::GetRunner())
                           : std::make_shared<shell::LynxUIOperationQueue>();
}

}  // namespace shell
}  // namespace lynx
