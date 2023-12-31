// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_DYNAMIC_UI_OPERATION_QUEUE_H_
#define LYNX_SHELL_DYNAMIC_UI_OPERATION_QUEUE_H_

#include <memory>
#include <utility>

#include "base/threading/task_runner_manufactor.h"
#include "shell/lynx_ui_operation_queue.h"

namespace lynx {

namespace shell {

class DynamicUIOperationQueue {
 public:
  explicit DynamicUIOperationQueue(base::ThreadStrategyForRendering strategy);
  ~DynamicUIOperationQueue() = default;

  void Transfer(base::ThreadStrategyForRendering strategy);
  void EnqueueUIOperation(UIOperation operation);
  void Destroy();
  void UpdateStatus(UIOperationStatus status);
  void MarkDirty();
  void ForceFlush();
  void Flush();
  void SetEnableFlush(bool enable_flush);
  void SetErrorCallback(ErrorCallback callback);
  uint32_t GetNativeUpdateDataOrder();
  uint32_t UpdateNativeUpdateDataOrder();

 private:
  void CreateImpl();

  bool is_engine_async_;

  std::shared_ptr<LynxUIOperationQueue> impl_;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_DYNAMIC_UI_OPERATION_QUEUE_H_
